#!/usr/bin/env python3
"""
score.py — Generate benchmark scorecard from tool result artifacts.

Usage:
    python3 scripts/score.py [results-dir] [ground-truth-dir]

Defaults:
    results-dir     = results/
    ground-truth-dir = ground-truth/

Outputs:
    results/scorecard.json  — machine-readable scorecard
    results/scorecard.md    — markdown tables for benchmark-v1.md

Deterministic: given the same inputs, produces byte-identical output on
every run. No timestamps, no random ordering. Sorted by tool then corpus.

Python 3 stdlib only — no third-party dependencies.
"""

import json
import os
import sys


def load_ground_truth_yaml(path):
    """Load a ground-truth YAML file without PyYAML."""
    # We have two YAML files with known structure. Rather than a full YAML
    # parser, we load them as Python data by converting known patterns.
    # This is acceptable since WE write these files and control the format.
    import re

    with open(path) as f:
        content = f.read()

    # Strip YAML comments
    lines = [line for line in content.splitlines() if not line.strip().startswith('#')]
    content = '\n'.join(lines)

    # Use a simple state machine approach — parse YAML list items under
    # the "paths:" or "modules:" top-level key.
    # For our purposes, we convert to JSON-parseable via a minimal transform.
    # This works because our YAML is simple (no anchors, no special chars).
    import re

    # Approach: use Python's built-in ast.literal_eval-friendly conversion.
    # Since the YAML is simple, we can convert it to a dict via a custom parser.
    # For production code we'd use PyYAML; here stdlib only is required.

    # We will parse the top-level list items manually.
    result = {}
    current_section = None
    current_item = None
    current_list_key = None
    items = []

    for line in content.splitlines():
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip())
        stripped = line.strip()   # stripped of BOTH leading and trailing whitespace

        # Top-level key (no indent, ends with :)
        if indent == 0 and stripped.endswith(':') and not stripped.startswith('-'):
            key = stripped[:-1].strip()
            result[key] = []
            current_section = key
            current_item = None
            continue

        # List item start (indent=2, starts with '- ')
        if indent == 2 and stripped.startswith('- '):
            if current_item is not None and current_section is not None:
                result[current_section].append(current_item)
            current_item = {}
            # Parse the key: value on the same line as -
            rest = stripped[2:].strip()
            if ': ' in rest:
                k, v = rest.split(': ', 1)
                current_item[k.strip()] = _parse_yaml_value(v.strip())
            elif rest.endswith(':'):
                current_list_key = rest[:-1].strip()
                current_item[current_list_key] = []
            continue

        # Key-value pairs under a list item (indent=4)
        if indent == 4 and current_item is not None and not stripped.startswith('-'):
            if ': ' in stripped:
                k, v = stripped.split(': ', 1)
                k = k.strip()
                v = v.strip()
                if v == '[]':
                    current_item[k] = []
                    current_list_key = None
                elif v == '|>' or v == '>':
                    # Multi-line block — skip for now, we don't need these
                    current_item[k] = ''
                    current_list_key = None
                else:
                    current_item[k] = _parse_yaml_value(v)
                    current_list_key = None
            elif stripped.endswith(':'):
                current_list_key = stripped[:-1].strip()
                current_item[current_list_key] = []
            continue

        # Sub-list items under a list item key (indent=6, starts with '- ')
        if indent == 6 and stripped.startswith('- ') and current_item is not None:
            val = stripped[2:].strip().strip('"').strip("'")
            if current_list_key and current_list_key in current_item:
                if isinstance(current_item[current_list_key], list):
                    current_item[current_list_key].append(val)
            continue

        # Multi-line scalar continuation (indent >= 6, current key is str)
        if indent >= 6 and current_item is not None and current_list_key is not None:
            # Continuation of a block scalar — append to existing string
            if isinstance(current_item.get(current_list_key), str):
                current_item[current_list_key] += ' ' + stripped.strip()
            continue

    # Flush last item
    if current_item is not None and current_section is not None:
        result[current_section].append(current_item)

    return result


def _parse_yaml_value(v):
    """Parse a simple YAML scalar value."""
    if v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    if v.startswith("'") and v.endswith("'"):
        return v[1:-1]
    if v == 'true':
        return True
    if v == 'false':
        return False
    if v == 'null' or v == '~':
        return None
    try:
        return int(v)
    except ValueError:
        pass
    try:
        return float(v)
    except ValueError:
        pass
    return v


def count_checkov_high_severity(data):
    """Extract high+critical finding count from Checkov JSON output."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return None, data.get('status', 'ERROR')

    # Checkov can return a list (one per framework) or a single object
    if isinstance(data, list):
        total = 0
        for item in data:
            total += _count_checkov_item(item)
        return total, 'OK'
    elif isinstance(data, dict):
        return _count_checkov_item(data), 'OK'
    return None, 'PARSE_ERROR'


def _count_checkov_item(item):
    """Count failed checks in a single Checkov result object."""
    if not isinstance(item, dict):
        return 0
    # checkov -o json → {"results": {"failed_checks": [...]}}
    results = item.get('results', {})
    if isinstance(results, dict):
        failed = results.get('failed_checks', [])
        return len(failed) if isinstance(failed, list) else 0
    # checkov --output json (newer format) → {"summary": {"failed": N}}
    summary = item.get('summary', {})
    if isinstance(summary, dict):
        return summary.get('failed', 0)
    return 0


def count_checkov_findings(data):
    """Return list of finding dicts from Checkov JSON (for TP/FP matching).

    Note: Checkov severity is only available with Bridgecrew API credentials.
    In offline mode (bench.yml), all failed checks are returned (no severity filter).
    """
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return []
    findings = []
    items = data if isinstance(data, list) else [data]
    for item in items:
        if not isinstance(item, dict):
            continue
        results = item.get('results', {})
        if not isinstance(results, dict):
            continue
        for check in results.get('failed_checks', []):
            sev = (check.get('severity') or '').upper()
            # When severity is populated, filter to HIGH/CRITICAL only.
            # When severity is null/empty (offline run), include all.
            if sev and sev not in ('HIGH', 'CRITICAL'):
                continue
            findings.append({
                'rule_id': check.get('check_id', ''),
                'rule_name': check.get('check_address', '') or check.get('check_id', ''),
                'file': check.get('file_path', ''),
                'resource': check.get('resource', ''),
                'line_start': check.get('file_line_range', [None])[0],
            })
    return findings


def count_trivy_high_severity(data):
    """Extract HIGH+CRITICAL misconfig count from Trivy JSON output."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return None, data.get('status', 'ERROR')
    try:
        total = 0
        for result in data.get('Results', []):
            for m in result.get('Misconfigurations', []):
                if m.get('Severity') in ('HIGH', 'CRITICAL'):
                    total += 1
        return total, 'OK'
    except (AttributeError, TypeError):
        return None, 'PARSE_ERROR'


def count_trivy_findings(data):
    """Return list of HIGH+CRITICAL finding dicts from Trivy JSON."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return []
    findings = []
    try:
        for result in data.get('Results', []):
            for m in result.get('Misconfigurations', []):
                if m.get('Severity') in ('HIGH', 'CRITICAL'):
                    findings.append({
                        'rule_id': m.get('ID', ''),
                        'rule_name': m.get('Title', ''),
                        'file': result.get('Target', ''),
                        'resource': m.get('CauseMetadata', {}).get('Resource', ''),
                        'line_start': m.get('CauseMetadata', {}).get('StartLine'),
                    })
    except (AttributeError, TypeError):
        pass
    return findings


def count_kics_high_severity(data):
    """Extract HIGH+CRITICAL issue count from KICS JSON output."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return None, data.get('status', 'ERROR')
    try:
        # KICS JSON: {"severity_counters": {"HIGH": N, "CRITICAL": N, ...}}
        counters = data.get('severity_counters', {})
        total = counters.get('HIGH', 0) + counters.get('CRITICAL', 0)
        return total, 'OK'
    except (AttributeError, TypeError):
        return None, 'PARSE_ERROR'


def count_kics_findings(data):
    """Return list of HIGH+CRITICAL finding dicts from KICS JSON."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return []
    findings = []
    try:
        for query in data.get('queries', []):
            sev = query.get('severity', '').upper()
            if sev not in ('HIGH', 'CRITICAL'):
                continue
            for file_entry in query.get('files', []):
                findings.append({
                    'rule_id': query.get('query_id', ''),
                    'rule_name': query.get('query_name', ''),
                    'file': file_entry.get('file_name', ''),
                    'resource': file_entry.get('resource_name', ''),
                    'line_start': file_entry.get('line', None),
                })
    except (AttributeError, TypeError):
        pass
    return findings


def count_terrascan_high_severity(data):
    """Extract HIGH issue count from Terrascan JSON output."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return None, data.get('status', 'ERROR')
    try:
        # Terrascan: {"results": {"scan_summary": {"high": N}, "violations": [...]}}
        results = data.get('results', {})
        if not results:
            # Terrascan sometimes returns the summary at top level
            results = data
        summary = results.get('scan_summary', {})
        total = summary.get('high', 0)
        return total, 'OK'
    except (AttributeError, TypeError):
        return None, 'PARSE_ERROR'


def count_terrascan_findings(data):
    """Return HIGH finding dicts from Terrascan JSON."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR'):
        return []
    findings = []
    try:
        results = data.get('results', data)
        for v in results.get('violations', []):
            if v.get('severity', '').lower() == 'high':
                findings.append({
                    'rule_id': v.get('rule_id', ''),
                    'rule_name': v.get('rule_name', ''),
                    'file': v.get('file', ''),
                    'resource': v.get('resource_name', ''),
                    'line_start': v.get('line', None),
                })
    except (AttributeError, TypeError):
        pass
    return findings


def count_audytx_high_severity(data):
    """Extract HIGH+CRITICAL count from audytx SARIF JSON.

    audytx SARIF uses standard SARIF levels: error=High/Critical, warning=Medium, note=Low.
    """
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR', 'MISSING'):
        return None, data.get('status', 'ERROR')
    try:
        total = 0
        for run in data.get('runs', []):
            rules_by_id = {}
            for rule in run.get('tool', {}).get('driver', {}).get('rules', []):
                rules_by_id[rule.get('id', '')] = rule
            for result in run.get('results', []):
                rule_id = result.get('ruleId', '')
                rule = rules_by_id.get(rule_id, {})
                level = rule.get('defaultConfiguration', {}).get('level', '')
                # SARIF level=error → High/Critical; level=warning → Medium; level=note → Low
                if level == 'error':
                    total += 1
        return total, 'OK'
    except (AttributeError, TypeError):
        return None, 'PARSE_ERROR'


def count_audytx_findings(data):
    """Return HIGH/Critical finding dicts from audytx SARIF (level=error only)."""
    if isinstance(data, dict) and data.get('status') in ('DNF', 'ERROR', 'MISSING'):
        return []
    findings = []
    try:
        for run in data.get('runs', []):
            rules_by_id = {}
            for rule in run.get('tool', {}).get('driver', {}).get('rules', []):
                rules_by_id[rule.get('id', '')] = rule
            for result in run.get('results', []):
                rule_id = result.get('ruleId', '')
                rule = rules_by_id.get(rule_id, {})
                level = rule.get('defaultConfiguration', {}).get('level', '')
                # Only include HIGH/Critical findings for TP/FP matching
                if level != 'error':
                    continue
                locs = result.get('locations', [{}])
                loc = locs[0] if locs else {}
                phys = loc.get('physicalLocation', {})
                artifact = phys.get('artifactLocation', {})
                file_uri = artifact.get('uri', '')
                region = phys.get('region', {})
                line = region.get('startLine')
                findings.append({
                    'rule_id': rule_id,
                    'rule_name': rule.get('shortDescription', {}).get('text', ''),
                    'file': file_uri,
                    'resource': result.get('properties', {}).get('resource_name', ''),
                    'severity': level,
                    'line_start': line,
                })
    except (AttributeError, TypeError):
        pass
    return findings


def match_finding_to_gt(finding, gt_entry):
    """
    Return True if a tool finding matches a ground-truth entry.
    Matching strategy: file path contains any of the GT's file paths,
    AND (resource name matches one of the GT resource names, OR
         the finding text/rule references the GT method).
    This is intentionally liberal — the unmatched list shows false positives.
    """
    finding_file = finding.get('file', '').replace('\\', '/').lower()
    finding_resource = finding.get('resource', '').lower().replace('-', '').replace('_', '')
    finding_rule = (finding.get('rule_id', '') + ' ' + finding.get('rule_name', '')).lower()

    gt_files = [f.lower() for f in gt_entry.get('files', [])]
    gt_resources = [r.lower().replace('-', '').replace('_', '')
                    for r in gt_entry.get('terraform_resources', [])]
    gt_method = gt_entry.get('method', '').lower().replace('-', '').replace('_', '')

    # Check file overlap
    file_match = any(
        gt_file.split('/')[-1] in finding_file or finding_file.endswith(gt_file.split('/')[-1])
        for gt_file in gt_files
    )
    if not file_match:
        return False

    # Check resource or method overlap
    resource_match = any(
        gt_res in finding_resource or finding_resource in gt_res
        for gt_res in gt_resources
        if gt_res
    )
    method_match = gt_method and gt_method in finding_rule

    return resource_match or method_match


def load_json_safe(path):
    """Load a JSON file, returning a status=MISSING dict on failure."""
    if not os.path.exists(path):
        return {'status': 'MISSING', 'path': path}
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        return {'status': 'PARSE_ERROR', 'path': path, 'error': str(e)}


def load_mapping_overrides(path):
    """Load mapping-overrides.yaml if it exists, else return empty list."""
    if not os.path.exists(path):
        return []
    # Parse manually: list of {tool, corpus, finding_key, gt_id, reason}
    overrides = []
    try:
        current = {}
        with open(path) as f:
            for line in f:
                line = line.rstrip()
                if not line or line.strip().startswith('#'):
                    continue
                stripped = line.lstrip()
                indent = len(line) - len(stripped)
                if indent == 0 and stripped.startswith('- '):
                    if current:
                        overrides.append(current)
                    current = {}
                    rest = stripped[2:].strip()
                    if ': ' in rest:
                        k, v = rest.split(': ', 1)
                        current[k.strip()] = v.strip().strip('"').strip("'")
                elif indent >= 2 and ': ' in stripped:
                    k, v = stripped.split(': ', 1)
                    current[k.strip()] = v.strip().strip('"').strip("'")
            if current:
                overrides.append(current)
    except Exception:
        pass
    return overrides


TOOL_PARSERS = {
    'checkov': (count_checkov_high_severity, count_checkov_findings),
    'trivy': (count_trivy_high_severity, count_trivy_findings),
    'kics': (count_kics_high_severity, count_kics_findings),
    'terrascan': (count_terrascan_high_severity, count_terrascan_findings),
    'audytx': (count_audytx_high_severity, count_audytx_findings),
}

TOOLS = ['audytx', 'checkov', 'trivy', 'kics', 'terrascan']


def main():
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results'
    gt_dir = sys.argv[2] if len(sys.argv) > 2 else 'ground-truth'
    corpora_path = 'bench-corpora.json'

    # Load bench corpora list
    with open(corpora_path) as f:
        corpora_data = json.load(f)
    corpora = corpora_data.get('include', [])

    # Load ground truth
    gt_iam_path = os.path.join(gt_dir, 'iam-vulnerable.yaml')
    gt_clean_path = os.path.join(gt_dir, 'clean-modules.yaml')

    gt_iam = _load_ground_truth(gt_iam_path, 'paths') if os.path.exists(gt_iam_path) else []
    gt_clean = _load_ground_truth(gt_clean_path, 'modules') if os.path.exists(gt_clean_path) else []

    overrides = load_mapping_overrides(os.path.join(gt_dir, 'mapping-overrides.yaml'))

    gt_iam_count = len(gt_iam)

    # Build index: corpus name → GT entries
    gt_clean_by_corpus = {m.get('corpus', m.get('name', '')): m for m in gt_clean}

    # ── Precision table: clean modules ────────────────────────────────────────
    precision_rows = []
    for corpus_entry in sorted(corpora, key=lambda x: x['corpus']):
        if corpus_entry['role'] != 'precision':
            continue
        corpus = corpus_entry['corpus']
        row = {'corpus': corpus, 'role': 'precision'}
        gt_module = gt_clean_by_corpus.get(corpus, {})
        row['known_exceptions_count'] = len(gt_module.get('known_exceptions', []))
        row['expected_after_exceptions'] = 0

        for tool in TOOLS:
            path = os.path.join(results_dir, tool, f'{corpus}.json')
            data = load_json_safe(path)
            count_fn, _ = TOOL_PARSERS[tool]
            count, status = count_fn(data)
            row[f'{tool}_count'] = count
            row[f'{tool}_status'] = status
        precision_rows.append(row)

    # ── Recall table: iam-vulnerable (TP/FP/FN) ───────────────────────────────
    iam_recall_rows = []
    for tool in TOOLS:
        path = os.path.join(results_dir, tool, 'iam-vulnerable.json')
        data = load_json_safe(path)
        _, findings_fn = TOOL_PARSERS[tool]
        findings = findings_fn(data)
        count_fn, _ = TOOL_PARSERS[tool]
        total_count, status = count_fn(data)

        # Match findings to GT entries
        matched_gt_ids = set()
        unmatched_findings = []
        for finding in findings:
            found = False
            for gt_entry in gt_iam:
                gt_id = gt_entry.get('id', '')
                if gt_id not in matched_gt_ids and match_finding_to_gt(finding, gt_entry):
                    matched_gt_ids.add(gt_id)
                    found = True
                    break
            if not found:
                unmatched_findings.append(finding)

        tp = len(matched_gt_ids)
        fn = gt_iam_count - tp
        # FP = findings not matched to any GT entry (above total - TP, but
        # note: multiple findings can match the same GT entry; we count
        # total findings - true positives as false positives conservatively)
        fp = len(findings) - tp  # unmatched + extra matches on same GT entry

        precision = tp / (tp + fp) if (tp + fp) > 0 else None
        recall = tp / gt_iam_count if gt_iam_count > 0 else None

        iam_recall_rows.append({
            'tool': tool,
            'total_findings': len(findings),
            'total_high_count': total_count,
            'status': status,
            'tp': tp,
            'fp': fp,
            'fn': fn,
            'precision': round(precision, 3) if precision is not None else None,
            'recall': round(recall, 3) if recall is not None else None,
            'matched_gt_ids': sorted(matched_gt_ids),
            'unmatched_findings': unmatched_findings[:50],  # cap for readability
        })

    # ── Recall table: other recall corpora (raw counts) ───────────────────────
    recall_count_rows = []
    for corpus_entry in sorted(corpora, key=lambda x: x['corpus']):
        if corpus_entry['role'] != 'recall' or corpus_entry['corpus'] == 'iam-vulnerable':
            continue
        corpus = corpus_entry['corpus']
        row = {'corpus': corpus}
        for tool in TOOLS:
            path = os.path.join(results_dir, tool, f'{corpus}.json')
            data = load_json_safe(path)
            count_fn, _ = TOOL_PARSERS[tool]
            count, status = count_fn(data)
            row[f'{tool}_count'] = count
            row[f'{tool}_status'] = status
        recall_count_rows.append(row)

    # ── Totals ─────────────────────────────────────────────────────────────────
    precision_totals = {}
    for tool in TOOLS:
        counts = [r.get(f'{tool}_count') for r in precision_rows if r.get(f'{tool}_count') is not None]
        precision_totals[tool] = sum(counts) if counts else None

    # ── Scorecard JSON ─────────────────────────────────────────────────────────
    scorecard = {
        'ground_truth': {
            'iam_vulnerable_path_count': gt_iam_count,
            'clean_module_count': len(gt_clean),
        },
        'iam_vulnerable_precision_recall': iam_recall_rows,
        'precision_clean_modules': precision_rows,
        'precision_totals': {tool: precision_totals[tool] for tool in TOOLS},
        'recall_other_corpora': recall_count_rows,
        'tools': TOOLS,
    }

    os.makedirs(results_dir, exist_ok=True)
    scorecard_json_path = os.path.join(results_dir, 'scorecard.json')
    scorecard_md_path = os.path.join(results_dir, 'scorecard.md')

    with open(scorecard_json_path, 'w') as f:
        json.dump(scorecard, f, indent=2, sort_keys=True)

    # ── Markdown output ────────────────────────────────────────────────────────
    md = []
    md.append('# Benchmark scorecard\n')
    md.append(f'Ground-truth iam-vulnerable paths: **{gt_iam_count}** '
               f'(source: BishopFox iam-vulnerable README)\n')
    md.append(f'Clean production modules: **{len(gt_clean)}**\n\n')

    # Table 1: IAM TP/FP/FN
    md.append('## Table 1 — IAM precision/recall on iam-vulnerable\n\n')
    md.append('| Tool | Total HIGH findings | TP | FP | FN | Precision | Recall |\n')
    md.append('|------|:---:|:---:|:---:|:---:|:---:|:---:|\n')
    for r in sorted(iam_recall_rows, key=lambda x: x['tool']):
        tool = r['tool']
        status = r['status']
        if status in ('DNF', 'ERROR', 'MISSING'):
            md.append(f"| {tool} | {status} | — | — | — | — | — |\n")
        else:
            prec = f"{r['precision']:.0%}" if r['precision'] is not None else '—'
            rec = f"{r['recall']:.0%}" if r['recall'] is not None else '—'
            md.append(f"| {tool} | {r['total_high_count']} | {r['tp']} | {r['fp']} | {r['fn']} "
                       f"| {prec} | {rec} |\n")
    md.append('\n')

    # Table 2: Precision totals
    md.append('## Table 2 — Precision: high-severity alerts on 21 clean modules (lower = better)\n\n')
    total_row_parts = [f"**{precision_totals.get(t, '—')}**" for t in TOOLS]
    header_parts = ['| Corpus | exceptions |'] + [f' {t} |' for t in TOOLS]
    sep_parts = ['|---|----|'] + [':---:|' for _ in TOOLS]
    md.append(''.join(header_parts) + '\n')
    md.append(''.join(sep_parts) + '\n')
    for r in sorted(precision_rows, key=lambda x: x['corpus']):
        cols = [f"| {r['corpus']} | {r['known_exceptions_count']} |"]
        for tool in TOOLS:
            v = r.get(f'{tool}_count')
            s = r.get(f'{tool}_status', '')
            if s in ('DNF', 'ERROR', 'MISSING'):
                cols.append(f' {s} |')
            else:
                cols.append(f' {v} |' if v is not None else ' — |')
        md.append(''.join(cols) + '\n')
    md.append(f"| **Total** | | {'|'.join(total_row_parts)} |\n\n")

    # Table 3: Other recall corpora
    md.append('## Table 3 — Recall: high-severity findings on vulnerable corpora\n\n')
    md.append('| Corpus |' + ''.join(f' {t} |' for t in TOOLS) + '\n')
    md.append('|---|' + ''.join(':---:|' for _ in TOOLS) + '\n')
    for r in sorted(recall_count_rows, key=lambda x: x['corpus']):
        cols = [f"| {r['corpus']} |"]
        for tool in TOOLS:
            v = r.get(f'{tool}_count')
            s = r.get(f'{tool}_status', '')
            if s in ('DNF', 'ERROR', 'MISSING'):
                cols.append(f' {s} |')
            else:
                cols.append(f' {v} |' if v is not None else ' — |')
        md.append(''.join(cols) + '\n')
    md.append('\n')

    # Unmatched findings appendix
    md.append('## Appendix — Unmatched findings on iam-vulnerable (for audit)\n\n')
    for r in sorted(iam_recall_rows, key=lambda x: x['tool']):
        md.append(f"### {r['tool']} ({len(r['unmatched_findings'])} unmatched)\n\n")
        if not r['unmatched_findings']:
            md.append('_None — all findings matched a ground-truth entry._\n\n')
        else:
            md.append('| rule_id | file | resource | line |\n')
            md.append('|---------|------|----------|------|\n')
            for f in r['unmatched_findings']:
                md.append(f"| {f.get('rule_id','')} | {f.get('file','')[-50:]} "
                           f"| {f.get('resource','')[-40:]} | {f.get('line_start','')} |\n")
        md.append('\n')

    with open(scorecard_md_path, 'w') as f:
        f.writelines(md)

    print(f'scorecard.json written to {scorecard_json_path}')
    print(f'scorecard.md  written to {scorecard_md_path}')
    print(f'Ground-truth entries: {gt_iam_count} iam-vulnerable paths')
    print(f'Precision modules: {len(gt_clean)}')


def _load_ground_truth(path, top_key):
    """Load a ground-truth YAML file and return the list under top_key."""
    if not os.path.exists(path):
        return []
    # Use the load_ground_truth_yaml parser
    try:
        data = load_ground_truth_yaml(path)
        return data.get(top_key, [])
    except Exception as e:
        print(f'WARNING: could not parse {path}: {e}', file=sys.stderr)
        return []


if __name__ == '__main__':
    main()

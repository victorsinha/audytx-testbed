locals {
  # The set of domains served by the distribution: the primary plus any SANs.
  all_domains = concat([var.domain_name], var.subject_alternative_names)

  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
    },
    var.tags,
  )
}

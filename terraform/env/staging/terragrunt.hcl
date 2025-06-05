terraform {
  source = "../..//aws"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  n8n_database_instance_class  = "db.serverless"
  n8n_database_instances_count = 1
  n8n_database_min_capacity    = 0.5
  n8n_database_max_capacity    = 2
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the Network & corresponding Router to attach other resources to
# Networks that preserve the default route are automatically enabled for Private Google Access to GCP services
# provided subnetworks each opt-in; in general, Private Google Access should be the default.
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = "~> 0.12.7"
  experiments = [
    variable_validation
  ]
}

resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  project_name_parts = split("-", var.gcp_project)
  suffix             = var.random_suffix ? format("-%s", random_id.suffix.hex) : ""
  # ---------------------------------------------------------------------
  # In project name format `<org>-<project>-<env>`, project_name_parts[2]
  # and project_name_parts[1] contains env and project name respectively
  # ---------------------------------------------------------------------
  vpc_name            = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "vpc", local.suffix)
  public_subnet_name  = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "subnet-public", local.suffix)
  private_subnet_name = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "subnet-private", local.suffix)
  bastion_vm_name     = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "bastion", local.suffix)
  cloud_nat_name      = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "cloud-nat", local.suffix)
  cloud_router_name   = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "cloud-router", local.suffix)
}

resource "google_compute_network" "vpc" {
  name    = local.vpc_name
  project = var.gcp_project

  # Always define custom subnetworks- one subnetwork per region isn't useful for an opinionated setup
  auto_create_subnetworks = "false"

  # A global routing mode can have an unexpected impact on load balancers; always use a regional mode
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "vpc_public_subnet" {
  name = local.public_subnet_name

  project = var.gcp_project
  region  = var.region
  network = google_compute_network.vpc.self_link

  # Whether the VMs in this subnet can access Google services without assigned external IP addresses.
  private_ip_google_access = true
  # The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended.
  ip_cidr_range = "10.0.0.0/16"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "vpc_private_subnet" {
  name = local.private_subnet_name

  project = var.gcp_project
  region  = var.region
  network = google_compute_network.vpc.self_link

  # Whether the VMs in this subnet can access Google services without assigned external IP addresses.
  private_ip_google_access = true
  # The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended.
  ip_cidr_range = "10.1.0.0/16"

  secondary_ip_range {
    ip_cidr_range = "10.2.0.0/16"
    range_name    = "pod-ip-cidr"
  }
  secondary_ip_range {
    ip_cidr_range = "10.3.0.0/16"
    range_name    = "service-ip-cidr"
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "cloud_router" {
  name    = local.cloud_router_name
  project = var.gcp_project
  region  = var.region
  network = google_compute_network.vpc.self_link
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = local.cloud_nat_name
  project                            = var.gcp_project
  region                             = var.region
  router                             = google_compute_router.cloud_router.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.vpc_private_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  nat_ip_allocate_option = "AUTO_ONLY"
}

module "bastion" {
  source                             = "terraform-google-modules/bastion-host/google"
  version                            = "2.0.0"
  name                               = local.bastion_vm_name
  project                            = var.gcp_project
  region                             = var.region
  zone                               = "${var.region}-a"
  network                            = google_compute_network.vpc.self_link
  subnet                             = google_compute_subnetwork.vpc_private_subnet.self_link
  members                            = var.bastion_allowed_members
  service_account_roles_supplemental = ["roles/container.admin"]
}
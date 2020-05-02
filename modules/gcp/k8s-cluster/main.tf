terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"
  experiments      = [variable_validation]
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = var.gcp_project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}

# ----------------------------------------------
# Pull necessary data.
# ----------------------------------------------
# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

provider "kubernetes" {
  version = "~> 1.7.0"

  load_config_file       = false
  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
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
  cluster_name                 = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "cluster", local.suffix)
  cluster_service_account_name = format("%s-%s-%s%s", local.project_name_parts[2], local.project_name_parts[1], "sa", local.suffix)
  cluster_location             = var.cluster_location != null ? var.cluster_location : "${var.region}-a"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SERVICE ACCOUNT FOR NODES IN THE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------
module "gke_service_account" {
  source      = "./modules/service-account"
  name        = var.cluster_service_account_name != "" ? var.cluster_service_account_name : local.cluster_service_account_name
  gcp_project = var.gcp_project
  description = var.cluster_service_account_description
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CLUSTER
# ---------------------------------------------------------------------------------------------------------------------
module "gke_cluster" {
  source                            = "./modules/gke-cluster"
  name                              = var.cluster_name != "" ? var.cluster_name : local.cluster_name
  gcp_project                       = var.gcp_project
  location                          = local.cluster_location
  network                           = var.private_network
  subnetwork                        = var.private_subnet
  service_account_email             = module.gke_service_account.email
  initial_node_count                = var.initial_node_count
  max_node_count                    = var.max_node_count
  machine_type                      = var.machine_type
  disk_type                         = var.disk_type
  disk_size                         = var.disk_size
  enable_private_nodes              = var.enable_private_nodes
  master_authorized_networks_config = var.master_authorized_networks_config
}

# Configure kubectl with the credentials of the GKE cluster if cluster is public.
resource "null_resource" "configure_kubectl" {
  count = var.enable_private_nodes ? 0 : 1
  provisioner "local-exec" {
    command = "gcloud components install beta && gcloud beta container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.gcp_project}"

    # Use environment variables to allow custom kubectl config paths
    environment = {
      KUBECONFIG = var.kubectl_config_path != "" ? var.kubectl_config_path : ""
    }
  }

  depends_on = [
    module.gke_cluster
  ]
}

# Create the predefined namespaces.
resource "kubernetes_namespace" "namespace" {
  provider = kubernetes
  for_each = toset(var.kubernetes_namespace_list)
  metadata {
    name = each.value
  }
}

# Create predefined secrets.
resource "kubernetes_secret" "secret" {
  provider = kubernetes
  for_each = var.kubernetes_secrets

  metadata {
    name      = split(":", each.key)[1]
    namespace = split(":", each.key)[0]
  }

  data = each.value
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKAROUNDS
# ---------------------------------------------------------------------------------------------------------------------
# This is a workaround for the Kubernetes as Terraform doesn't currently support passing in module
# outputs to providers directly.
data "template_file" "gke_host_endpoint" {
  template = module.gke_cluster.endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "cluster_ca_certificate" {
  template = module.gke_cluster.cluster_ca_certificate
}

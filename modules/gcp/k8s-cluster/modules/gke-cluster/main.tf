terraform {
  required_version = ">= 0.12.7"
}

locals {
  latest_version = data.google_container_engine_versions.location.latest_master_version
  node_pool_name = format("%s-%s", var.name, "node-pool")
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the GKE Cluster
# We want to make a cluster with no node pools, and manage them all with the fine-grained google_container_node_pool resource
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_cluster" "cluster" {
  name        = var.name
  description = var.description

  project    = var.gcp_project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  min_master_version = local.latest_version

  # The API requires a node pool or an initial count to be defined; that initial count creates the
  # "default node pool" with that # of nodes.
  # So, we need to set an initial_node_count of 1. This will make a default node
  # pool with server-defined defaults that Terraform will immediately delete as
  # part of Create. This leaves us in our desired state- with a cluster master
  # with no node pools.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "node_pool" {
  name               = local.node_pool_name
  project            = var.gcp_project
  location           = var.location
  cluster            = google_container_cluster.cluster.name
  initial_node_count = var.initial_node_count

  autoscaling {
    min_node_count = var.initial_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type

    disk_size_gb = var.disk_size
    disk_type    = var.disk_type
    preemptible  = false

    service_account = var.service_account_email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Pull in data
# ---------------------------------------------------------------------------------------------------------------------

// Get available master versions in our location to determine the latest version
data "google_container_engine_versions" "location" {
  location = var.location
  project  = var.gcp_project
}

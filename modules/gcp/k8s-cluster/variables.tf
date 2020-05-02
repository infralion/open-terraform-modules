variable "gcp_project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

variable "region" {
  description = "The region for the network. If the cluster is regional, this must be the same region. Otherwise, it should be the region of the zone."
  type        = string
}

variable "cluster_location" {
  description = "The location of the cluster. If the cluster is regional, this must be the same region. Otherwise, it should be the zone of the region. Defaults to first zone of the region"
  type        = string
  default     = null
}

variable "private_network" {
  description = "The self link of the VPC with which the cluster needs to be attached to."
  type        = string
}

variable "private_subnet" {
  description = "The self link of the subnetwork with which the cluster needs to be attached to."
  type        = string
}
# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "kubernetes_namespace_list" {
  description = "A list of namespaces that has to be created in kubernetes."
  type        = list(string)
  default     = []
}

variable "kubernetes_secrets" {
  description = "The secrets that has to be created in the different namespaces. Example- {\"namespacename:mysql\": {\"username\": \"hereditas\", \"password\": \"password123\"}}"
  type        = map(map(string))
  default     = {}
}

variable "initial_node_count" {
  description = "Number of nodes the cluster must have."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Number of nodes the cluster can have at max."
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Type of the machine for each nodes."
  type        = string
  default     = "n1-standard-1"
}

variable "disk_size" {
  description = "Size of the disk space for each node."
  type        = number
  default     = 10
}

variable "enable_private_nodes" {
  description = "Control whether nodes have internal IP addresses only. If enabled, all nodes are given only RFC 1918 private addresses and communicate with the master via private networking."
  type        = bool
  default     = true
}

variable "master_authorized_networks_config" {
  description = "The desired configuration options for master authorized networks. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

variable "random_suffix" {
  type        = bool
  description = "Whether to add a random suffix in resource names or not. Default is false."
  default     = false
}

variable "disk_type" {
  description = "Type of the disk for each nodes. It can also be `pd-ssd`, which is more costly."
  type        = string
  default     = "pd-standard"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
  default     = ""
}

variable "cluster_service_account_name" {
  description = "The name of the custom service account used for the GKE cluster. This parameter is limited to a maximum of 28 characters."
  type        = string
  default     = ""
}

variable "cluster_service_account_description" {
  description = "A description of the custom service account used for the GKE cluster."
  type        = string
  default     = "Example GKE Cluster Service Account managed by Terraform"
}

# Kubectl options

variable "kubectl_config_path" {
  description = "Path to the kubectl config file. Defaults to $HOME/.kube/config"
  type        = string
  default     = ""
}

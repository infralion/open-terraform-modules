output "network" {
  description = "A reference (self_link) to the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet" {
  description = "A reference (self_link) to the public subnetwork"
  value       = google_compute_subnetwork.vpc_public_subnet.self_link
}

output "private_subnet" {
  description = "A reference (self_link) to the priavte subnetwork"
  value       = google_compute_subnetwork.vpc_private_subnet.self_link
}

output "public_subnet_name" {
  description = "Name of the public subnetwork"
  value       = google_compute_subnetwork.vpc_public_subnet.name
}

output "private_subnet_name" {
  description = "Name of the priavte subnetwork"
  value       = google_compute_subnetwork.vpc_private_subnet.name
}

output "public_subnet_cidr_block" {
  value = google_compute_subnetwork.vpc_public_subnet.ip_cidr_range
}

output "private_subnet_cidr_block" {
  value = google_compute_subnetwork.vpc_private_subnet.ip_cidr_range
}

output "public_subnet_gateway" {
  value = google_compute_subnetwork.vpc_public_subnet.gateway_address
}

output "private_subnet_gateway" {
  value = google_compute_subnetwork.vpc_private_subnet.gateway_address
}

output "private_subnet_secondary_cidr_block" {
  value = google_compute_subnetwork.vpc_private_subnet.secondary_ip_range.0.ip_cidr_range
}

output "private_subnet_secondary_range_name" {
  value = google_compute_subnetwork.vpc_private_subnet.secondary_ip_range.0.range_name
}

output "bastion_host_ip" {
  value = module.bastion.ip_address
}

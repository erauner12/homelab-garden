output "cluster_name" {
  description = "Disposable hcloud lab cluster name prefix."
  value       = var.cluster_name
}

output "kubeconfig" {
  description = "Sensitive kubeconfig emitted by the hcloud-talos module."
  value       = module.talos.kubeconfig
  sensitive   = true
}

output "talosconfig" {
  description = "Sensitive talosconfig emitted by the hcloud-talos module."
  value       = module.talos.talosconfig
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Local generated kubeconfig path for Garden/operator use after apply."
  value       = local_sensitive_file.kubeconfig.filename
}

output "talosconfig_path" {
  description = "Local generated talosconfig path."
  value       = local_sensitive_file.talosconfig.filename
}

output "public_ipv4_list" {
  description = "Public IPv4 addresses of control-plane nodes, from the module."
  value       = module.talos.public_ipv4_list
}

output "hetzner_network_id" {
  description = "Hetzner Cloud network ID used by the module."
  value       = module.talos.hetzner_network_id
}

locals {
  disposable_labels = {
    "homelab-garden.io/lab"        = "hcloud"
    "homelab-garden.io/disposable" = "true"
  }

  talos_image_url_arm = "https://factory.talos.dev/image/${var.talos_image_factory_schematic_id}/${var.talos_version}/hcloud-arm64.raw.xz"
  talos_image_url_x86 = "https://factory.talos.dev/image/${var.talos_image_factory_schematic_id}/${var.talos_version}/hcloud-amd64.raw.xz"
}

provider "imager" {
  token = var.hcloud_token
}

resource "imager_image" "talos_arm" {
  count = var.architecture == "arm" && var.talos_image_id_arm == null ? 1 : 0

  image_url    = local.talos_image_url_arm
  architecture = "arm"
  location     = var.location_name
  server_type  = var.talos_imager_server_type
  description  = "${var.cluster_name} Talos ${var.talos_version} ARM snapshot"
  labels       = local.disposable_labels
}

resource "imager_image" "talos_x86" {
  count = var.architecture == "x86" && var.talos_image_id_x86 == null ? 1 : 0

  image_url    = local.talos_image_url_x86
  architecture = "x86"
  location     = var.location_name
  server_type  = var.talos_imager_server_type
  description  = "${var.cluster_name} Talos ${var.talos_version} x86 snapshot"
  labels       = local.disposable_labels
}

module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "3.4.12"

  hcloud_token       = var.hcloud_token
  cluster_name       = var.cluster_name
  cluster_prefix     = true
  location_name      = var.location_name
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  # Set explicit non-null hostnames because module v3.4.12 validates these
  # optional inputs with string functions during terraform validate.
  cluster_api_host_private = "kube.cluster.local"
  cluster_api_host         = "kube.${var.cluster_name}.invalid"

  firewall_use_current_ip   = var.firewall_use_current_ip
  firewall_kube_api_source  = var.firewall_kube_api_source
  firewall_talos_api_source = var.firewall_talos_api_source

  # Use a Terraform-managed custom Talos snapshot from hcloud-talos/imager
  # unless an existing snapshot override is supplied for the selected architecture.
  disable_x86         = var.architecture == "arm"
  disable_arm         = var.architecture == "x86"
  talos_image_id_arm  = var.architecture == "arm" ? coalesce(var.talos_image_id_arm, try(imager_image.talos_arm[0].image_id, null)) : null
  talos_iso_id_arm    = null
  talos_image_id_x86  = var.architecture == "x86" ? coalesce(var.talos_image_id_x86, try(imager_image.talos_x86[0].image_id, null)) : null
  talos_iso_id_x86    = null
  control_plane_nodes = [{ id = 1, type = var.control_plane_type, labels = local.disposable_labels }]
  worker_nodes        = [{ id = 1, type = var.worker_type, labels = local.disposable_labels }]
}

resource "local_sensitive_file" "kubeconfig" {
  content         = module.talos.kubeconfig
  filename        = var.kubeconfig_path
  file_permission = "0600"
}

resource "local_sensitive_file" "talosconfig" {
  content         = module.talos.talosconfig
  filename        = var.talosconfig_path
  file_permission = "0600"
}

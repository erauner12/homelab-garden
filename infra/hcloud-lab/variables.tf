variable "hcloud_token" {
  description = "Hetzner Cloud API token. Set via TF_VAR_hcloud_token; never put this in tfvars."
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Strict name prefix for the disposable hcloud lab cluster."
  type        = string
  default     = "homelab-garden-hcloud-lab"

  validation {
    condition     = can(regex("^homelab-garden-hcloud-lab(-[a-z0-9-]+)?$", var.cluster_name))
    error_message = "cluster_name must start with homelab-garden-hcloud-lab and contain only lowercase letters, numbers, and dashes."
  }
}

variable "location_name" {
  description = "Hetzner Cloud location for the disposable lab."
  type        = string
  default     = "fsn1"
}

variable "talos_version" {
  description = "Talos version used for generated machine configuration and matching custom image snapshots."
  type        = string
  default     = "v1.12.2"
}

variable "kubernetes_version" {
  description = "Kubernetes version required by the hcloud-talos module. Keep compatible with talos_version and Cilium."
  type        = string
  default     = "1.35.0"
}

variable "architecture" {
  description = "Node/image architecture for the disposable lab. Use arm for cax* types or x86 for cx*/cpx*/ccx* types."
  type        = string
  default     = "arm"

  validation {
    condition     = contains(["arm", "x86"], var.architecture)
    error_message = "architecture must be either arm or x86."
  }
}

variable "control_plane_type" {
  description = "Minimal non-HA control-plane server type from the module README example."
  type        = string
  default     = "cax11"
}

variable "worker_type" {
  description = "Minimal worker server type for the disposable lab."
  type        = string
  default     = "cax11"
}

variable "talos_imager_server_type" {
  description = "Temporary ARM server type used by hcloud-talos/imager while creating the Talos ARM snapshot."
  type        = string
  default     = "cax11"
}

variable "talos_image_id_arm" {
  description = "Optional existing ARM Talos snapshot ID override. Leave null to let Terraform create one with hcloud-talos/imager."
  type        = string
  default     = null

  validation {
    condition     = var.talos_image_id_arm == null || can(regex("^[0-9]+$", var.talos_image_id_arm))
    error_message = "talos_image_id_arm must be a numeric custom Talos ARM snapshot ID when set."
  }
}

variable "talos_image_id_x86" {
  description = "Optional existing x86 Talos snapshot ID override. Leave null to let Terraform create one with hcloud-talos/imager."
  type        = string
  default     = null

  validation {
    condition     = var.talos_image_id_x86 == null || can(regex("^[0-9]+$", var.talos_image_id_x86))
    error_message = "talos_image_id_x86 must be a numeric custom Talos x86 snapshot ID when set."
  }
}

variable "talos_image_factory_schematic_id" {
  description = "Talos Image Factory schematic ID used for the managed ARM hcloud raw image. Defaults to the documented vanilla schematic with no custom extensions."
  type        = string
  default     = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.talos_image_factory_schematic_id))
    error_message = "talos_image_factory_schematic_id must be a 64-character lowercase hex schematic ID."
  }
}

variable "firewall_use_current_ip" {
  description = "Restrict public Kubernetes/Talos API firewall rules to this runner's current IP by default."
  type        = bool
  default     = true
}

variable "firewall_kube_api_source" {
  description = "Optional explicit CIDR source ranges for the public Kubernetes API firewall rule. Leave null to preserve firewall_use_current_ip behavior; set when runner egress rotates across a known NAT range."
  type        = list(string)
  default     = null

  validation {
    condition     = var.firewall_kube_api_source == null || alltrue([for cidr in var.firewall_kube_api_source : can(cidrhost(cidr, 0))])
    error_message = "firewall_kube_api_source entries must be valid CIDR ranges, for example [\"203.0.113.0/29\"]."
  }
}

variable "firewall_talos_api_source" {
  description = "Optional explicit CIDR source ranges for the public Talos API firewall rule. Leave null to preserve firewall_use_current_ip behavior; set when runner egress rotates across a known NAT range."
  type        = list(string)
  default     = null

  validation {
    condition     = var.firewall_talos_api_source == null || alltrue([for cidr in var.firewall_talos_api_source : can(cidrhost(cidr, 0))])
    error_message = "firewall_talos_api_source entries must be valid CIDR ranges, for example [\"203.0.113.0/29\"]."
  }
}

variable "kubeconfig_path" {
  description = "Local path for the generated sensitive kubeconfig. Keep under ./generated/ and out of Git."
  type        = string
  default     = "./generated/kubeconfig"
}

variable "talosconfig_path" {
  description = "Local path for the generated sensitive talosconfig. Keep under ./generated/ and out of Git."
  type        = string
  default     = "./generated/talosconfig"
}

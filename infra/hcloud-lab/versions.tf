terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }

    imager = {
      source  = "hcloud-talos/imager"
      version = ">= 1.0.15"
    }
  }
}

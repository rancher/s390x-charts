terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  auth_url = "https://cicmgmt.suse.de/icic/openstack/identity/v3"
  insecure = true
  domain_name = "default"
  region = "RegionOne"
}

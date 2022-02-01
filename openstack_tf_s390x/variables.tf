variable "stack_name" {
  default = "validation"
}

variable "workers" {
  default = "1"
}

variable "masters" {
  default = "1"
}

# Image name "210106-s15s2-jeos-1part-ext4"
variable "image_id" {
  default = "93ce2047-bdcc-4f93-81c0-27c40b4b71e3"
  description = "You can get list of images by openstack image list"
}

variable "flavor_id" {
  default = "cdf84a1ea01ac47d387ed13cd997c2d8"
  description = "You can get list of flavors by openstack flavor list"
}

variable "username" {
  default = "sles"
}

variable "password" {
  default = "linux"
}

variable "hostname_from_dhcp" {
  default = "yes"
}

variable "ntp_servers" {
  type        = list(string)
  default     = [
    "0.suse.pool.ntp.org",
    "1.suse.pool.ntp.org",
    "2.suse.pool.ntp.org",
    "3.suse.pool.ntp.org",
  ]
  description = "List of ntp servers to configure"
}


variable "authorized_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into all the nodes"
}

variable "sle_registry_code_s390x" {
  default = ""
  description = "Used for registering SLE via SUSEConnect"
}

variable "packages" {
  type = list(string)
  default = []
  description = "list of additional packages to install"
}

variable "repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

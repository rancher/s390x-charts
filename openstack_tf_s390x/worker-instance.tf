data "template_file" "worker_repositories" {
  template = file("cloud-init/repository.tpl")
  count    = length(var.repositories)

  vars = {
    repository_url  = element(values(var.repositories), count.index)
    repository_name = element(keys(var.repositories), count.index)
  }
}

data "template_file" "worker_register_scc" {
  template = file("cloud-init/register-scc.tpl")
  count    = var.sle_registry_code_s390x == "" ? 0 : 1

  vars = {
    sle_registry_code_s390x = var.sle_registry_code_s390x
  }
}

data "template_file" "worker_commands" {
  template = file("cloud-init/commands.tpl")
  count    = join("", var.packages) == "" ? 0 : 1

  vars = {
    packages = join(", ", var.packages)
  }
}

data "template_file" "worker-cloud-init" {
  template = file("cloud-init/common.tpl")
  count    = var.workers

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    repositories       = join("\n", data.template_file.worker_repositories.*.rendered)
    register_scc       = join("\n", data.template_file.worker_register_scc.*.rendered)
    commands           = join("\n", data.template_file.worker_commands.*.rendered)
    username           = var.username
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    hostname           = "rke2-worker-${var.stack_name}-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true ? "yes" : "no"
  }
}

# ------ res ------

resource "openstack_compute_instance_v2" "worker" {
  count     = var.workers
  name      = "rke2-worker-${var.stack_name}-${count.index}"
  image_id  = var.image_id
  flavor_id = var.flavor_id
  key_pair  = "" # will accept the one from authorized_keys
  security_groups = ["default"]
  region = "RegionOne"

  network {
    name = "devnet"
  }

  user_data = data.template_file.worker-cloud-init[count.index].rendered
}

resource "null_resource" "worker_wait_cloudinit" {
  depends_on = [openstack_compute_instance_v2.worker,]
  count      = var.workers

  connection {
    host = element(
      openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4,
      count.index,
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "worker_reboot" {
  depends_on = [null_resource.worker_wait_cloudinit]
  count      = var.workers

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4,
        count.index,
      )
    }

    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# wait for ssh ready after reboot
until nc -zv $host 22; do sleep 5; done
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60 $user@$host /usr/bin/true
EOT

  }
}


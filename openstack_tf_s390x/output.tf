output "ip_masters" {
  value = zipmap(
    openstack_compute_instance_v2.master.*.name,
    openstack_compute_instance_v2.master.*.network.0.fixed_ip_v4,
  )
}

output "ip_workers" {
  value = zipmap(
    openstack_compute_instance_v2.worker.*.name,
    openstack_compute_instance_v2.worker.*.network.0.fixed_ip_v4,
  )
}

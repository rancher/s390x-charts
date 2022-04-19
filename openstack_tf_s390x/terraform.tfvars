# will use the defaults from variables.tf - the default values can be overwritten here
stack_name = "s390x-charts-validation"

authorized_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2G7k0zGAjd+0LzhbPcGLkdJrJ/LbLrFxtXe+LPAkrphizfRxdZpSC7Dvr5Vewrkd/kfYObiDc6v23DHxzcilVC2HGLQUNeUer/YE1mL4lnXC1M3cb4eU+vJ/Gyr9XVOOReDRDBCwouaL7IzgYNCsm0O5v2z/w9ugnRLryUY180/oIGeE/aOI1HRh6YOsIn7R3Rv55y8CYSqsbmlHWiDC6iZICZtvYLYmUmCgPX2Fg2eT+aRbAStUcUERm8h246fs1KxywdHHI/6o3E1NNIPIQ0LdzIn5aWvTCd6D511L4rf/k5zbdw/Gql0AygHBR/wnngB5gSDERLKfigzeIlCKf Unsafe Shared Key",
  ]
  
#file("${path.module}/input.json")
packages = [
  "kernel-default",
  "apparmor-parser",
  "bash-completion",
  "command-not-found",
  "screen",
]

repositories = {}

masters = 1

workers = 0

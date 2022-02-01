# will use the defaults from variables.tf - the default values can be overwritten here
stack_name = "validation"

authorized_keys = [
  file("/root/secrets/id_shared.pub"),
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

workers = 1

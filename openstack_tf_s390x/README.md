## Info

Terraform states configured for SUSE s390x infrastructure managed by 
mikef@suse.com, webUI is available on https://cicmgmt.suse.de/icic (use Okta 
credentials). These terraform states were inspired by the ones used in CaaSP 
product. The nodes are preconfigured for deploying SLE15SP2-s390x prepared
for manual RKE2 cluster bootstrap.

## Usage
Before deploying please modify variables in terraform.tfvars accordingly to
your needs, mainly `stack_name`, `masters` and `workers` (count, can be 0), `packages`,
`repositories`, `authorized_keys` etc.

**WARNING:** It's mandatory to set `TF_VAR_sle_registry_code_s390x=<SLE_REG_CODE>` environment variable.

Also take a look into `cloud-init/common.tpl` and `[master|worker]-instance.tf`
for additional configuration.

Only dependency should be `terraform` package.

Once the initial configuration is done run `source developer-s390-openrc.sh`
and fill in your Okta credentials.

After running `terraform init` and `terraform apply --auto-approve` you will 
wait approx. 13 minutes for nodes deployment.

Once the nodes (default 2) are deployed it will return list of master and
worker node names and their IPs. Use `ssh -i id_shared sles@node_ip` and you
may perform `sudo su` to became root.

Once you are done with your nodes run `terraform destroy --auto-approve` and
the VMs will be destroyed within a minute.

### Note about redeploying nodes
For another terraform deployment you have to wait for more than 10 minutes, 
maybe if you deploy another VM over cicmgmt webUI it will be unblocked and 
following terraform message will not appear:
```
Error waiting for instance () to become ready: unexpected state 'DELETED', wanted target 'ACTIVE'.
```


step "Uninstall rke2"

nodes_run "rke2-killall.sh"
nodes_run "rke2-uninstall.sh"

: # return 0 instead of $?

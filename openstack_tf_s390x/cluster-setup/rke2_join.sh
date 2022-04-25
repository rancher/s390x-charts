step "Create cluster - $RKE2_VERSION"
# ENV parameters:
# -e AIRGAP=true

rke2_latest=$(curl -H "Accept: application/vnd.github.v3+json" 'https://api.github.com/repos/rancher/rke2/releases' |\
    jq -r 'first(.[] | select (.assets[].name == "rke2.linux-s390x")) | .name')
[ $RKE2_VERSION != $rke2_latest ] && warn "RKE2 update: $rke2_latest"

# prevent workload on server nodes
config_taint_noexecute() {
    local addr=$1
    yq e -n '.node-taint = ["CriticalAddonsOnly=true:NoExecute"]' |\
        ssh $addr "cat - >> /etc/rancher/rke2/config.yaml"
}

# point additional nodes to first server
config_init_server() {
    local addr=$1
    yq e -n ".server = \"https://$INIT_SERVER:9345\", .token = \"$INIT_TOKEN\"" |\
        ssh $addr "cat - >> /etc/rancher/rke2/config.yaml"
}

node_join() {
    local type=$1    # init (= 1st server) | server | agent
    local addr=$2    # IP of the node to join

    # Configure service
    # [[ $type =~ init|server ]] && config_taint_noexecute $addr
    [[ $type =~ server|agent ]] && config_init_server $addr

    # INSTALL_RKE2_CHANNEL - select 1.21 / 1.22 / latest (default)
    # INSTALL_RKE2_VERSION - version of rke2 to download from github
    local params="INSTALL_RKE2_TYPE=${type/init/server}"
    if [ -v AIRGAP ]; then
        ssh $addr "$params INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh /root/install.sh"
    else
        ssh $addr "$params INSTALL_RKE2_VERSION=$RKE2_VERSION sh /root/install.sh"
    fi

    # Start rke2 service
    ssh $addr "systemctl enable --now rke2-${type/init/server}"
    ssh $addr "journalctl -u rke2-${type/init/server} | grep 'Started Rancher Kubernetes Engine v2'"

    if [ $type == init ]; then
        INIT_SERVER=$addr
        INIT_TOKEN=$(ssh $addr cat /var/lib/rancher/rke2/server/node-token)
        scp $addr:/etc/rancher/rke2/rke2.yaml "$WORKDIR/admin.conf"
        kubectl config set-cluster default --server=https://$addr:6443
    fi

}

setup_airgap() {
    nodes_run 'mkdir -p \
        /root/rke2-artifacts \
        /var/lib/rancher/rke2/agent/images'

    info 'get artifacts'
    local gitpath="https://github.com/rancher/rke2/releases/download/$RKE2_VERSION_ENC"
    nodes_run "curl -sL $gitpath/rke2.linux-s390x.tar.gz -o /root/rke2-artifacts/rke2.linux-s390x.tar.gz"
    nodes_run "curl -sL $gitpath/sha256sum-s390x.txt -o /root/rke2-artifacts/sha256sum-s390x.txt"
    nodes_run_parallel "curl -sL $gitpath/rke2-images.linux-s390x.tar.zst -o /var/lib/rancher/rke2/agent/images/rke2-images.linux-s390x.tar.zst"

    info 'block traffic'
    # Allow kubectl to master node
    ssh ${IP_MASTERS[0]} "iptables -A INPUT -p tcp --dport 6443 -m state --state NEW,ESTABLISHED -j ACCEPT"
    ssh ${IP_MASTERS[0]} "iptables -A OUTPUT -p tcp --sport 6443 -m state --state ESTABLISHED -j ACCEPT"

    # Allow traffic between nodes
    local ips=$(echo ${IP_NODES[@]} | tr ' ' ,)
    nodes_run "iptables -A INPUT -s $ips -j ACCEPT"
    nodes_run "iptables -A OUTPUT -d $ips -j ACCEPT"

    # Allow incoming ssh
    nodes_run "iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT"
    nodes_run "iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT"

    # Block other traffic on eth1000
    nodes_run "iptables -A INPUT -i eth1000 -j DROP"
    nodes_run "iptables -A OUTPUT -o eth1000 -j DROP"

    # Save rules for reboot
    nodes_scp ${DATADIR}/airgap.service /usr/lib/systemd/system/iptables.service
    nodes_run 'iptables-save > /etc/sysconfig/iptables'
    nodes_run 'systemctl enable iptables'

    # Make sure traffic is blocked
    ssh ${IP_MASTERS[0]} ping -c1 -W1 8.8.8.8 && false
    true
}


nodes_run 'mkdir -p /etc/rancher/rke2'
nodes_run "curl -sL https://raw.githubusercontent.com/rancher/rke2/$RKE2_VERSION_ENC/install.sh -o /root/install.sh"

[ -v AIRGAP ] && setup_airgap

info "init master #0"
node_join 'init' "${IP_MASTERS[0]}"

for ((i=1; i<${#IP_MASTERS[@]}; i++)); do
    info "join master #$i"
    node_join 'server' "${IP_MASTERS[$i]}"
done

info "join ${#IP_WORKERS[@]} workers"
bgpids=""
for ((i=0; i<${#IP_WORKERS[@]}; i++)); do
    node_join agent "${IP_WORKERS[$i]}" &
    bgpids+=" $!"
    sleep 2
done
for p in $bgpids; do
    wait $p || { err=$?; kill $bgpids 2>/dev/null ||:; wait $bgpids ||:; exit $err; }
done

# kubectl get nodes | tee -a "$OUTPUT" | grep -c worker | grep -qx ${#IP_WORKERS[@]}
# kubectl get nodes | grep -c master | grep -qx ${#IP_MASTERS[@]}

info "wait for nodes & pods"
wait_nodes
wait_pods

: # return 0 instead of $?

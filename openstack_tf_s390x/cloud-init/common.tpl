#cloud-config

# set locale
locale: en_US.UTF-8

# set timezone
timezone: Etc/UTC

# Inject the public keys
ssh_authorized_keys:
${authorized_keys}

ntp:
  enabled: true
  ntp_client: chrony
  config:
    confpath: /etc/chrony.conf
  servers:
${ntp_servers}

# need to disable gpg checks because the cloud image has an untrusted repo
zypper:
  repos:
${repositories}
  config:
    gpgcheck: "off"
    solver.onlyRequires: "true"
    download.use_deltarpm: "true"

# need to remove the standard docker packages that are pre-installed on the
# cloud image because they conflict with the kubic- ones that are pulled by
# the kubernetes packages
# WARNING!!! Do not use cloud-init packages module when SUSE CaaSP Registraion
# Code is provided. In this case repositories will be added in runcmd module
# with SUSEConnect command after packages module is ran
#packages:

# set hostname
hostname: ${hostname}

bootcmd:
  - ip link set dev eth1000 mtu 1400
  # Hostnames from DHCP - otherwise localhost will be used
  - /usr/bin/sed -ie "s#DHCLIENT_SET_HOSTNAME=\"no\"#DHCLIENT_SET_HOSTNAME=\"yes\"#" /etc/sysconfig/network/dhcp
  - netconfig update -f

runcmd:
  # workaround for bsc#1119397 . If this is not called, /etc/resolv.conf is empty
  - netconfig -f update
  - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
  - sed -i -e '/^#PasswordAuthentication/s/^.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - rm /root/.ssh/authorized_keys
  - cp /home/sles/.ssh/authorized_keys /root/.ssh/authorized_keys
  - sshd -t || echo "ssh syntax failure"
  - systemctl restart sshd
  # Set node's hostname from DHCP server
  - sed -i -e '/^DHCLIENT_SET_HOSTNAME/s/^.*$/DHCLIENT_SET_HOSTNAME=\"yes\"/' /etc/sysconfig/network/dhcp
  - systemctl restart wicked
  # Hack to write /root/.bashrc with exports and aliases
  - echo 'IyEvYmluL3NoCmV4cG9ydCBLVUJFQ09ORklHPS9ldGMvcmFuY2hlci9ya2UyL3JrZTIueWFtbApleHBvcnQgUEFUSD0vdmFyL2xpYi9yYW5jaGVyL3JrZTIvYmluOiRQQVRICmFsaWFzIGs9a3ViZWN0bAppZiBbIC14ICIkKGNvbW1hbmQgLXYga3ViZWN0bCkiIF07IHRoZW4KICBzb3VyY2UgPChrdWJlY3RsIGNvbXBsZXRpb24gYmFzaCkKICBzb3VyY2UgPChrdWJlY3RsIGNvbXBsZXRpb24gYmFzaCB8IHNlZCAncy9rdWJlY3RsL2svZycpCmZpCg==' | base64 -d - | tee /root/.bashrc
${register_scc}
${commands}

final_message: "The system is finally up, after $UPTIME seconds"

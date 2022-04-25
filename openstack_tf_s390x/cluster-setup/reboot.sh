step 'Reboot'

info 'ssh reboot'
ssh "${IP_MASTERS[0]}" sudo reboot ||:
ssh "${IP_WORKERS[0]}" sudo reboot ||:
sleep 10

# Check they are really rebooting
nc -zw1 ${IP_MASTERS[0]} 22 && false
nc -zw1 ${IP_WORKERS[0]} 22 && false

info 'wait for resources'
wait_cluster

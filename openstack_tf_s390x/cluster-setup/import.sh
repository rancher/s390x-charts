step "Import cluster"

# setup variables
export RANCHER_URL="https://${IP_MASTERS[0]}.nip.io"
import_kubeconfig=$BASEDIR/$IMPORTDIR/admin.conf
import_yamlfile=$BASEDIR/$IMPORTDIR/rancher-import.yaml

# check cluster to import is online
kubectl cluster-info --kubeconfig=$import_kubeconfig
# check cluster is not imported yet
kubectl get ns cattle-system --kubeconfig=$import_kubeconfig 2>/dev/null && { echo "Already imported: ${IMPORTDIR}"; false; }

info 'create cluster import'
python3 "$TESTDIR"/import.py --action=import --cluster=$IMPORTDIR
mv import.yaml $import_yamlfile

info 'run import yaml'
kubectl apply -f $import_yamlfile --kubeconfig=$import_kubeconfig
kubectl rollout status deploy/cattle-cluster-agent -n cattle-system --kubeconfig=$import_kubeconfig
# kubectl rollout status deploy/fleet-agent -n cattle-fleet-system --kubeconfig=$import_kubeconfig # does not exist yet

info 'check imported cluster'
python3 "$TESTDIR"/import.py --action=check --cluster=$IMPORTDIR

:
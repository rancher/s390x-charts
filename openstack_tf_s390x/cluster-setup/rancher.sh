# https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/
# https://confluence.suse.com/display/PM/Rancher+on+IBM+Z
step "Deploy rancher"

# Update your local Helm chart repository cache
# helm repo update (no charts yet)

info 'install cert-manager'
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install=true cert-manager jetstack/cert-manager --create-namespace \
  --namespace cert-manager \
  --version v1.5.1 \
  --set installCRDs=true
kubectl -n cert-manager rollout status deploy/cert-manager


helm repo add rancher-alpha https://releases.rancher.com/server-charts/alpha
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
lastver=$(helm search repo rancher-latest -l --devel | awk '{print $3}' | sort --version-sort | tail -1)
info "install rancher $lastver"
helm upgrade --install=true rancher rancher-latest/rancher --create-namespace \
    --namespace cattle-system \
    --set hostname=${IP_MASTERS[0]}.nip.io \
    --set bootstrapPassword=sa \
    --set replicas=1 \
    --set rancherImageTag=$lastver \
    --devel

kubectl -n cattle-system rollout status deploy/rancher

# Raul's custom image & agent
#  --set rancherImage=raulcabm/rancher \
#  --set rancherImageTag=s390x-10 \
#  --set "extraEnv[0].name=CATTLE_AGENT_IMAGE" --set "extraEnv[0].value=raulcabm/rancher-agent:s390x-10"


info "Open https://${IP_MASTERS[0]}.nip.io/"
export RANCHER_URL="https://${IP_MASTERS[0]}.nip.io" # beware of trailing slash

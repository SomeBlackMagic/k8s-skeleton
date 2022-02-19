include .env

include kubespray_config/kubespray.mk

SSH_PARAMS=${MASTER_NODE_USER}@${MASTER_NODE_HOST} -p ${MASTER_NODE_PORT}
SCP_HOST=${MASTER_NODE_USER}@${MASTER_NODE_HOST}

.PHONY: help
help: ## Display this help message
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

pkg_install: ## Install helm pkg manager
	ssh ${SSH_PARAMS} 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
	ssh ${SSH_PARAMS} "echo 'source <(kubectl completion bash)' >>~/.bashrc"

base_config_apply: ## Apply base config after install. Network fix and priority class
	scp -P ${MASTER_NODE_PORT} -rp configs/base/ ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/base/priorityclass.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/base/networking.yaml'
	ssh ${SSH_PARAMS} 'helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${METRICS_SERVER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	ssh ${SSH_PARAMS} 'helm upgrade --install --debug metrics-server metrics-server/metrics-server --namespace ${METRICS_SERVER_NAMESPACE} --version ${METRICS_SERVER_VERSION} -f /tmp/base/metrics-server.yaml'
	ssh ${SSH_PARAMS} 'kubectl get csr'

base_config_revert: ## remove base config
	ssh ${SSH_PARAMS} 'helm uninstall  metrics-server --namespace ${METRICS_SERVER_NAMESPACE}'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/base/networking.yaml'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/base/priorityclass.yaml'

cilium-install: ## install cilium
	ssh ${SSH_PARAMS} 'helm repo add cilium https://helm.cilium.io/'
	ssh ${SSH_PARAMS} 'helm repo add someblackmagic https://someblackmagic.github.io/helm-charts/'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${CILIUM_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/cilium ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --install --wait --debug cilium cilium/cilium --namespace ${CILIUM_NAMESPACE} --version ${CILIUM_VERSION} -f /tmp/cilium/cilium.yaml'
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install cilium-monitoring someblackmagic/cilium-monitoring --namespace ${CILIUM_NAMESPACE} --version ${CILIUM_MONITORING_VERSION} -f /tmp/cilium/monitoring.yaml'


cilium-uninstall: ## uninstall cilium
	ssh ${SSH_PARAMS} 'helm uninstall cilium-monitoring --debug --namespace ${CILIUM_NAMESPACE}'
	ssh ${SSH_PARAMS} 'helm uninstall cilium --debug --namespace ${CILIUM_NAMESPACE}'

longhorn_install: ## install Volume manager longhorn
	# if has problem with mounetd volumes https://longhorn.io/kb/troubleshooting-volume-with-multipath/
	#./configs/longhorn/lib.sh kubespray_config
	ssh ${SSH_PARAMS} 'helm repo add longhorn https://charts.longhorn.io'
	ssh ${SSH_PARAMS} 'helm repo add someblackmagic https://someblackmagic.github.io/helm-charts/'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${LONGHORN_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/longhorn ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install longhorn longhorn/longhorn --namespace ${LONGHORN_NAMESPACE} --version ${LONGHORN_VERSION} -f /tmp/longhorn/longhorn-values.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/longhorn/longhorn-local.yaml'
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install longhorn-monitoring someblackmagic/longhorn-monitoring --namespace ${LONGHORN_NAMESPACE} --version ${LONGHORN_MONITORING_VERSION} -f /tmp/longhorn/longhorn-monitoring-values.yaml'

longhorn_uninstall: ## uninstall longhorn
	ssh ${SSH_PARAMS} 'helm uninstall longhorn-monitoring --debug --namespace ${LONGHORN_NAMESPACE}'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/longhorn/longhorn-local.yaml'
	ssh ${SSH_PARAMS} 'helm uninstall longhorn --debug --namespace ${LONGHORN_NAMESPACE}'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/longhorn/longhorn-local.yaml'


rancher_monitoring_install: ## install rancher monitoring chart(prom stack)
	ssh ${SSH_PARAMS} 'helm repo add rancher-charts https://raw.githubusercontent.com/rancher/charts/release-v2.6'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${RANCHER_MONITORING_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/rancher_monitoring ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} "cat /tmp/rancher_monitoring/* > /tmp/rancher_monitoring.yaml"
	ssh ${SSH_PARAMS} 'helm upgrade --timeout=10m0s --install --wait --debug rancher-monitoring rancher-charts/rancher-monitoring --namespace ${RANCHER_MONITORING_NAMESPACE} --version ${RANCHER_MONITORING_VERSION} -f /tmp/rancher_monitoring.yaml'

rancher_monitoring_uninstall:  ## TODO add description
	ssh ${SSH_PARAMS} 'helm uninstall rancher-monitoring --namespace ${RANCHER_MONITORING_NAMESPACE}'


alertMapper_install:  ## TODO add description
	ssh ${SSH_PARAMS} 'helm repo add someblackmagic https://someblackmagic.github.io/helm-charts/'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${ALERT_MAPPER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/alertMapper ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --install --wait --debug alert-mapper someblackmagic/alert-mapper --namespace ${ALERT_MAPPER_NAMESPACE} --version v${ALERT_MAPPER_VERSION} -f /tmp/alertMapper/values.yaml'

alertMapper_uninstall:  ## TODO add description
	ssh ${SSH_PARAMS} 'helm uninstall alert-mapper --namespace ${ALERT_MAPPER_NAMESPACE}'

cert_manager_install: ## install cert_manager
	ssh ${SSH_PARAMS} 'helm repo add jetstack https://charts.jetstack.io'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.crds.yaml'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${CERT_MANAGER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/cert-manager ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --install --wait --debug cert-manager jetstack/cert-manager --namespace ${CERT_MANAGER_NAMESPACE} --version v${CERT_MANAGER_VERSION} -f /tmp/cert-manager/values.yaml'
	ssh ${SSH_PARAMS} 'kubectl get pods --namespace ${CERT_MANAGER_NAMESPACE}'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/cert-manager/clusterissuer.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/cert-manager/tls-check.yaml'
	#TODO https://github.com/adfinis-sygroup/helm-charts/tree/master/charts/cert-manager-issuers
	#TODO https://github.com/adfinis-sygroup/helm-charts/tree/master/charts/cert-manager-monitoring

cert_manager_uninstall: ## uninstall cert_manager
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/cert-manager/tls-check.yaml'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/cert-manager/clusterissuer.yaml'
	ssh ${SSH_PARAMS} 'helm uninstall cert-manager --namespace ${CERT_MANAGER_NAMESPACE}'
	ssh ${SSH_PARAMS} 'kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.crds.yaml'
	ssh ${SSH_PARAMS} 'kubectl delete namespaces ${CERT_MANAGER_NAMESPACE}'

ingress_internal_install:  ## TODO add description
	ssh ${SSH_PARAMS} 'helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${INGRESS_INTERNAL_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/ingress_internal ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install ingress ingress-nginx/ingress-nginx  --namespace ${INGRESS_INTERNAL_NAMESPACE} --version ${INGRESS_INTERNAL_VERSION} -f /tmp/ingress_internal/ingress-values.yaml -f /tmp/ingress_internal/ingress-cloudflare.yaml'
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install ingress-monitoring someblackmagic/ingress-nginx-monitoring --namespace ${INGRESS_INTERNAL_NAMESPACE} --version ${INGRESS_INTERNAL_MONITORING_VERSION} -f /tmp/cilium/monitoring.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f  /tmp/ingress_internal/api-server.yaml'

ingress_internal_uninstall: ## TODO add description
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/ingress_internal/api-server.yaml'
	ssh ${SSH_PARAMS} 'helm uninstall ingress --debug --namespace ${INGRESS_INTERNAL_NAMESPACE}'
	ssh ${SSH_PARAMS} 'helm uninstall ngress-monitoring --debug --namespace ${INGRESS_INTERNAL_NAMESPACE}'


logging_install: ## TODO add description
	ssh ${SSH_PARAMS} 'helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com'
	ssh ${SSH_PARAMS} 'helm repo add someblackmagic https://someblackmagic.github.io/helm-charts/'
	ssh ${SSH_PARAMS} 'helm repo update'
	ssh ${SSH_PARAMS} 'kubectl create namespace ${LOGGING_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/logging ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'helm upgrade --install --wait logging-operator banzaicloud-stable/logging-operator --namespace ${LOGGING_NAMESPACE} --version ${LOGGING_VERSION}  -f /tmp/logging/values.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/logging/logging-config.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/logging/hub.yaml'
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/logging/logging-loki.yaml'
	ssh ${SSH_PARAMS} 'helm upgrade --wait --debug --install cilium-monitoring someblackmagic/banzaicloud-logging-operator-monitoring --namespace ${LOGGING_NAMESPACE} --version ${LOGGING_MONITORING_VERSION} -f /tmp/logging/monitoring.yaml'

logging_uninstall: ## TODO add description
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/logging/logging-loki.yaml'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/logging/hub.yaml'
	ssh ${SSH_PARAMS} 'kubectl delete -f /tmp/logging/logging-config.yaml'
	ssh ${SSH_PARAMS} 'helm uninstall logging-operator --debug --namespace ${LOGGING_NAMESPACE}'

gitlab_deploy_setup: ## TODO add description
	ssh ${SSH_PARAMS} 'kubectl create namespace ${GITLAB_DEPLOY_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -'
	scp -P ${MASTER_NODE_PORT} -rp configs/RBAC ${SCP_HOST}:/tmp/
	ssh ${SSH_PARAMS} 'kubectl apply -f /tmp/RBAC/deploy-user-perm.yaml'
	ssh ${SSH_PARAMS} 'bash /tmp/RBAC/user_generator.sh ${GITLAB_DEPLOY_NAMESPACE} ${GITLAB_DEPLOY_SERVICE_ACCOUNT_NAME}'
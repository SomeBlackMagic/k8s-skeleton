export KUBE_NAMESPACE=$1
export KUBE_USER=$2

#!LEGACY mode!
#openssl genrsa -out ${KUBE_USER}.key 2048
#openssl req -new -key ${KUBE_USER}.key -out ${KUBE_USER}.csr -subj "/CN=${KUBE_USER}"
#openssl x509 -req -in ${KUBE_USER}.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out ${KUBE_USER}.crt
#rm ${KUBE_USER}.csr
#
#echo "certificate-authority-data:"
#base64 /etc/kubernetes/pki/ca.crt
#
#echo "client-certificate:"
#base64 ${KUBE_USER}.crt
#
#echo "client-key:"
#base64 ${KUBE_USER}.key

kubectl -n ${KUBE_NAMESPACE} create serviceaccount ${KUBE_USER} --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding gitlab-clusterrolebinding --clusterrole=gitlab-deployment-custer-role --serviceaccount=${KUBE_NAMESPACE}:${KUBE_USER}

export TOKEN_NAME=$(kubectl -n ${KUBE_NAMESPACE} get serviceaccount/${KUBE_USER} -o jsonpath='{.secrets[0].name}')
export TOKEN=$(kubectl -n ${KUBE_NAMESPACE} get secret ${TOKEN_NAME} -o jsonpath='{.data.token}' | base64 --decode)

echo "kube-token:"
echo ${TOKEN}


KUBERNETES_CLUSTER_IP="192.168.99.106"

if [ "$APPLICATION_NAME" == "NONE" ]
then
    echo "No application name passed"
    exit 1
fi

# Since we are running using minikube
if kubectl get svc $APPLICATION_NAME -n $APPLICATION_NAME 
then
    application_port=$(kubectl get svc $APPLICATION_NAME -n $APPLICATION_NAME -o jsonpath="{.spec.ports[0].nodePort}")
    code_status=$(curl -s -w "%{http_code}" -o /dev/null $KUBERNETES_CLUSTER_IP:$application_port)
    
else
    echo "No sevice resource found in ${APPLICATION_NAME} namespace"
    exit 1
fi 


if [[ $code_status -ne 200 ]]; then
	exit 1
else
	exit 0
fi

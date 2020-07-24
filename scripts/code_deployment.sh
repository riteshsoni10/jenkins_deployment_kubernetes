DOCKER_REPOSITORY="riteshsoni296"
DOCKER_PHP_IMAGE_NAME="apache-php7:latest"
DOCKER_APACHE_IMAGE_NAME="httpd"
# It  could be LoadBalancer or NodePort
SERVICE_EXPOSE_TYPE="NodePort"

# Changing into code directory
cd /opt/code

flag=0
## Checking if the HTML and PHP both language code is present 
if [ $(find . -type f \( -name "*.php" -a -name "*.html" \) | wc -l ) -gt 0 ]; then
	echo "PHP and HTML Code found"
    flag=$(( $flag+1 ))
	sed -i "s/^FROM.*/FROM ${DOCKER_REPOSITORY}\/${DOCKER_PHP_IMAGE_NAME}/" Dockerfile
	sed -i 's/^COPY.*/COPY . \/var\/www\/localhost\/htdocs/' Dockerfile
	DEPLOYMENT_NAME="php-application"

## Checking if the only HTML language code is present
elif [ $(find . -type f  -name "*.html" | wc -l ) -gt 0 ]; then
	echo "HTML Code found"
    flag=$(( $flag+2 ))
	sed -i "s/^FROM.*/FROM ${DOCKER_APACHE_IMAGE_NAME}/" Dockerfile
	sed -i 's/^COPY.*/COPY . \/usr\/local\/apache2\/htdocs/' Dockerfile
	DEPLOYMENT_NAME="web-application"
fi

# Pushing Image to repository
# Build new image  
docker build . -t $DOCKER_REPOSITORY/$DEPLOYMENT_NAME:v${BUILD_NUMBER} --no-cache

# Check if docker hub credentials already provided
if ! cat ~/.docker/config.json | grep "auth\b" >/dev/null
then
	docker login -u="$docker_user" -p="$docker_password"
fi

#Push the image to the docker repository
docker push $DOCKER_REPOSITORY/$DEPLOYMENT_NAME:v${BUILD_NUMBER}

#Create Custom Application Namespace
if ! kubectl get ns $DEPLOYMENT_NAME >/dev/null
then
	kubectl create ns $DEPLOYMENT_NAME
fi

# Check if application already deployed
if kubectl get deployment $DEPLOYMENT_NAME -n $DEPLOYMENT_NAME > /dev/null
then
	#Get all running container names from deployment configuration 
	container_name=`kubectl get deploy $DEPLOYMENT_NAME -n $DEPLOYMENT_NAME -o jsonpath="{.spec.template.spec.containers[*].name}"`

	#Rollout of new application
	kubectl set image deployment/$DEPLOYMENT_NAME -n $DEPLOYMENT_NAME $container_name=$DOCKER_REPOSITORY/$DEPLOYMENT_NAME:v${BUILD_NUMBER}
	
	# Wait for the rollout to be complete
	if ! kubectl rollout status deploy/$DEPLOYMENT_NAME -n $DEPLOYMENT_NAME| grep success
	then
		echo "Rollout of new Application Failed"
		exit 1
	fi

#If application is not yet deployed
else
	# Create new deployment for the application
	if kubectl create deployment $DEPLOYMENT_NAME -n $DEPLOYMENT_NAME --image $DOCKER_REPOSITORY/$DEPLOYMENT_NAME:v${BUILD_NUMBER}
	then
		#Wait till the pods are in running state
		while kubectl get pods -n $DEPLOYMENT_NAME -l app=$DEPLOYMENT_NAME -o jsonpath="{.items[*].status.containerStatuses[*].state.running}" 
		do
			sleep 5
		done

		#Expose the application using service
		kubectl expose deployment/$DEPLOYMENT_NAME -n $DEPLOYMENT_NAME --port 80 --type=$SERVICE_EXPOSE_TYPE
	else
		echo "Failed to create a deployment"
		exit 1
	fi
fi 

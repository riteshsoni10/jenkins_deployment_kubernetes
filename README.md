# Automated Deployment and Testing on Kuberenetes  Cluster

The project deploys the code as soon as the code is pushed to the repository using POLL SCM in `code_checkout` Jenkins Job. Here, we are using POLL SCM due to the fact that the jenkins is hosted in private network and github is present in public network. All the resources in the project are launched over kubernetes cluster. The Configuration of kubernetes cluster can be multi-node cluster or single node cluster i.e minikube. 

**Project Infra Diagram**
<p align="center">
  <img src="screenshots/infra_flow.png" width="800" title="Project Infra Flow">
  <br>
  <em>Fig 1.: Project Flow  </em>
</p>


## Tasks

#### Pre-requisites
- Kubernetes Cluster


### Jenkins Image using Dockerfile

The Dockerfile is created from the `alpine:latest` linux image minimising the storage required to run the jenkins container. The image contains the kubectl binary to launch the kubernetes resources. The files for authentication is copied in the image. You can create the custom image using the already provided image `riteshsoni296/jenkins_kubectl:v2` and paste the kubernetes authentication files i.e; client.crt,client.key and ca.crt. The kubectl *config.template* file is present in the scripts directory in the repository

The dockerfile extract to be as follows :

```
FROM riteshsoni296/jenkins_kubectl:v2
COPY client.crt client.key ca.crt config.template /root/.kube/
EXPOSE 8080
CMD /bin/sh -c "envsubst \"`env | awk -F = '{printf \" \\\\$%s\", \$1}'`\" < /root/.kube/config.template \
    > /root/.kube/config  && java -jar /usr/share/webapps/jenkins/jenkins.war"
```

The dockerfile should always start with `FROM` instruction. The FROM instruction specifies the Parent Image from which we are building. The `RUN` instruction is used to execute the shell commands during the build creation. The `ENV` instruction is used to set environment variables for the image. The `EXPOSE` instruction is used to perform Port Address Translation in the container i.e; exposing a service to the outside world. The `CMD` instructions are executed at the run time i.e during the container creation. 


The image can be easily created using  dockerfile using `docker build` command. 

```
mkdir /opt/jenkins
cd /opt/jenkins

# Create file name Dockerfile with the earlier mentioned steps and copy the files for cluster authentication.

docker build -t jenkins:v1 /opt/jenkins/ --network=host
```

*-t* parameter denotes the tag for the image

*/opt/jenkins* represents the directory that consists Dockerfile.


Initialising **jenkins container** using image on kubernetes cluster. The kubernetes configuration file for jenkins server will launch resources as  follows:

*a. Namespace*

    To launch all the resources in custom namespace
 
*b. Service*
  
    To connect with the jenkins pods from outside world.
    
*c. PersistentVolumeClaim*

    For persistentency of data in Jenkins Server pods to preserve the data in case of pod failure.

*d. Deployment*

    Deployment resource maintains and monitors the pods. It restarts the pods in case of fault-tolerance.
 
The configuration file for `Jenkins Server Resources` is present in the repository at `scripts/kubernetes_resources` directory. 

```
kubectl create -f jenkins_deployment.yml
```

The kubernetes resources created for jenkins server pods are as shown in below figure

<p align="center">
  <img src="screenshots/jenkins_resources.png" width="800" title="Kubernetes Jenkins Resources">
  <br>
  <em>Fig 2.: Jenkins Kubernetes Resources  </em>
</p>

The jenkins container data directory `/var/lib/jenkins` is mounted using PVC for data persistency to avoid data loss during unavoidable circumstances.

During the initialisation of jenkins server for the first time, the Jenkins server proides `secret key` in the console logs for the first time login.

<p align="center">
  <img src="screenshots/jenkins_boot_log.png" width="800" title="Server Startup Diagram">
  <br>
  <em>Fig 3.: Jenkins Server Startup  </em>
</p>

<p align="center">
  <img src="screenshots/jenkins_startup_login_page.png" width="800" title="Jenkins Initial Login Page">
  <br>
  <em>Fig 4.: Jenkins Initial Login Page </em>
</p>

### Jenkins Plugins to be installed
 - Github
 - Build Pipeline

### Configure DockerHub Credentials

We need to configure the docker hub credentials repository where we will be uploading the latest application image. The following  steps to configure the credentials in JENKINS Server.

1. Click on *Manage Jenkins* in Jenkins Welcome Page

2. Click on *Manage Credentials*

<p align="center">
  <img src="screenshots/docker_manage_credentials.png" width="800" title="Jenkins Manage Credentials">
  <br>
  <em>Fig 5.: Manage Credentials  </em>
</p>

3. Click on *domains* below global column

<p align="center">
  <img src="screenshots/docker_add_credentials.png" width="800" title="Add Credentials">
  <br>
  <em>Fig 6.: Configure Credentials in Jenkins  </em>
</p>

4. Configure the Username and Password of Docker Hub Repository

    We will be providing the docker hub repository username and password.
    
<p align="center">
  <img src="screenshots/docker_configure_credentials.png" width="800" title="Configure Credentials">
  <br>
  <em>Fig 7.: Add Credentials in Jenkins  </em>
</p>


### Trigger Deployment when changes are pushed to SCM

### Job1 : Trigger Job due to SCM Changes

Steps to create the `code_checkout` job are as follows:

1. Create a *New Item* at the left column in Jenkins Welcome page

2. Configure *Job Name*

<p align="center">
  <img src="screenshots/code_checkout_first.png" width="800" title="Job Name Configure">
  <br>
  <em>Fig 8.: Job Name Configuration  </em>
</p>

3. Configure *GitHub Project URL*

<p align="center">
  <img src="screenshots/code_checkout_demo_project.png" width="800" title="Git Hub Project URL">
  <br>
  <em>Fig 9.: GitHub Project URL </em>
</p>

4. Configure **Source Code Management**

  We are only tracking the master branch, since the code is pushed finally in master branch.

<p align="center">
  <img src="screenshots/code_checkout_demo_git_repository.png" width="800" title="SCM Configure">
  <br>
  <em>Fig 10.: Source Code Management Configuration  </em>
</p>

5. Configure **Build Triggers**

   The Job should be triggered only when any changes are pushed to the code repository. So we need to enable the checkbox near `Poll SCM` and configure the schedular to run at every minute by setting "* * * * * " value.
  
<p align="center">
  <img src="screenshots/code_checkout_github_polling.png" width="800" title="Build Stage">
  <br>
  <em>Fig 11.: Poll SCM </em>
</p>


6. Steps to perform at **Build Stage**

   From the **Add Build Step** drop-down, `Execute Shell` is selected to run the operations at build stage. The source code is copied into the project deployment directory i.e */opt/code*. The script is present in scripts directory in this repository with name 'code_checkout.sh'. The contents of script needs to be copied in the build stage of the job.
 
 <p align="center">
  <img src="screenshots/code_checkout_directory.png" width="800" title="Build Stage">
  <br>
  <em>Fig 12.: Code Checkout Build Stage  </em>
</p>

7. Click on Apply and Save


### Job2 : Check the language of code and deploy the code

Steps to create the `code_deployment` job are as follows:

1. Create a *New Item* at the left column in Jenkins Welcome page

2. Configure *Job Name*

3. Configure **Build Triggers**
   The build trigger is configured to trigger the job when the upstream job `code_checkout` is stable i.e successful.
   
<p align="center">
  <img src="screenshots/code_deployment_build_triggers.png" width="800" title="Build trigger">
  <br>
  <em>Fig 13.: Deployment Job Build Triggers Configuration  </em>
</p>

4. **Build Environment**

    The *Use Secret Text or Files* checkbox needs to be enabled, so that we can use docker hub credentials in Build Stage. From *Add Bindings* dropdown, we need to select *Username and Password (seperated)* to add our docker hub credentials. We will be using `docker_user` and `docker_password` variables for username and password respectively.
    
<p align="center">
  <img src="screenshots/code_deployment_build.png" width="800" title="Build Environment">
  <br>
  <em>Fig 14.: Build Environment  </em>
</p>

5. Operations to perform at **Build stage**

   From the **Add Build Step** drop-down, `Execute Shell` is selected to run the operations at build stage. In the build stage, the project deployment directory is scanned for HTML and PHP pages with extension .html and .php respectively. If the project directory contains both HTML annd PHP language code, then customised image i.e; `riteshsoni296/apache-php7:latest` will be used to launch the container otherwise the apache web server image will be used to launch the apache web server container for HTML code deployment.
   
   The customised php along with apache server docker image contains only selected packages i.e;php7, php7-fpm, php7-opcache, php7-gd, php7-mysqli, php7-zlib, php7-curl. The image can be extended as per requirements using Dockerfile. A new docker image is created everytime the job is executed to perform a rollout deployment in kubernetes of application, if exists or to create a new deployment with updated image code.
   
  The shell script that is to copied in the Build Stage is present in the respository at location `scripts/code_deployment.sh`
   
<p align="center">
  <img src="screenshots/code_deployment_build_step.png" width="800" title="Build Stage">
  <br>
  <em>Fig 15.: Deployment Job Build Stage Configuration  </em>
</p>

6. Configure **Post Build Actions**

    The application name that is rolloed out or created will be passed to the testing job for further process i.e testing of application

<p align="center">
  <img src="screenshots/code_deployment_post_build_actions.png" width="800" title="Post Build Stage">
  <br>
  <em>Fig 16.: Post Build Stage Configuration  </em>
</p>  
    
6. Apply and Save 


Application Server Kubernetes resources launched are as shown in figure :

<p align="center">
  <img src="screenshots/application_resources.png" width="800" title="Application Kubernetes Resources">
  <br>
  <em>Fig 17.: Application Resources  </em>
</p>  
    

### Job3 and Job4 : Test the code and Send alerts to developer

Steps to create the `code_test` job are as follows:

1. Create a *New Item* at the left column in Jenkins Welcome page

2. Configure *Job Name*

3. Configure Parameter Name

    Enable the checkbox `This project is parameterized` option. Select the *String parameter* from *Add parameter* dropdown. Then the parameter name i.e *APPLICATION_NAME* and its default value that is to be passed in case no value is passed during build Execution. We are recieving the parameter from the upstream Job *code_deployment* which is expected to contain the application name runnning in kubernetes  cluster.
    
<p align="center">
  <img src="screenshots/code_test_parameter.png" width="800" title="Test Parameter Stage ">
  <br>
  <em>Fig 18.: Parameter Configuration  </em>
</p>
    

4.  Operations to perform at **Build stage**

    From the **Add Build Step** drop-down, `Execute Shell` is selected to run the operations at build stage. In case of Web container is running, then the private IP of container is fetched and the code reachability is verified using curl command. If the curl command output gives numeric value other than 200, the job is considered as failed by passing exit status 1.
    
    ```
    curl -s -w "%{http_code}" -o /dev/null http://10.10.15.12
    ```
    
    In the above command, 
    *-s,* is used to execute command in silent mode
    *-w,* used to write output of the curl command
    *http_code,* parameter prints out the return HTTP status code
    *-o /dev/null,* used to dump the output of the curl command.
    *10.10.15.12,* IP Address of Minikube master node 
    
    The script is present for reference in repository at location `scripts/code_test.sh`.
    
<p align="center">
  <img src="screenshots/code_test_stage.png" width="800" title="Test Build Stage ">
  <br>
  <em>Fig 19.: Test Job Build Stage Configuration  </em>
</p>
    
    
5. Configuration of **Post build actions** 
   
   The `Post Build Aptions` is configured to **send the email alerts** to *developers* with the last commit about the `failure of  the JOB` or Code with the full build status Logs of the current Job.
   
   We need to click on `Add Post Build Action` drop-down and select **E-Mail Notification**.
   
<p align="center">
  <img src="screenshots/code_test_post_build.png" width="800" title="Post Build Actions ">
  <br>
  <em>Fig 20.: Test Job Post Build Actions Configuration  </em>
</p>

   Sending Alerts only for Unstable builds or the broken builds
   
<p align="center">
  <img src="screenshots/code_test_email.png" width="800" title="Post Build Email ">
  <br>
  <em>Fig 21.: Test Job Post Build Email Configuration  </em>
</p>
    
6. Click on Apply and Save

 To `send Email` from jenkins Server we need to **configure SMTP** in Jenkins. For cconfiguration of SMTP in Jenkins Server, following steps are to be followed: 
   
   -  Click on **Manage Jenkins** on the left pane
   
   - Click on **Configure system** under  System Configuration
    
<p align="center">
  <img src="screenshots/smtp_configuration.png" width="800" title="SMTP Configuration ">
  <br>
  <em>Fig 22.: SMTP Configuration  </em>
</p>

   - Click on Advanced in **E-Mail  Notification**
     
     Scroll down to the bottom and click on advanced in E-Mail Notification block. The details that are required:
     
     a. SMTP Server like *smtp.gmail.com*
     
     b. Enable checkbox for **Use SMTP Authentication**, if using gmail SMTP Server
     
     c. Enter the **Username and Password**
     
     d. Enable checkbox for **Enable TLS**
     
     e. SMTP Port like 587 for *gmail*
     
<p align="center">
  <img src="screenshots/email_configuration.png" width="800" title="SMTP Configuration ">
  <br>
  <em>Fig 23.: SMTP Server Configuration  </em>
</p>   

   If using gmail SMTP Server, then  **Less Secure App Access** needs to be turned on from the sender email id.
       
<p align="center">
  <img src="screenshots/less_secure_app_access.png" width="650" title="Additional Configuration ">
  <br>
  <em>Fig 24.: Gmail Configuration  </em>
</p>  
   
   - Click on Apply and Save

 
### Build Pipeline Plugin Configuration
 
#### Installation

1. Click on  **Manage Jenkins** on the leeft pane

2. Click on **Manage Plugins** under System Configuration

3. Click on **Available Tab**, and 

4. Type in the *search bar* **Build Pipeline Plugin**

5. Select the checkbox

6. Click on  `Install without restart`


#### Configuration

1. Click on **+** symbol in the bar just beside ALL

<p align="center">
  <img src="screenshots/build_pipeline_select.png" width="800" title="Build Pipeline ">
  <br>
  <em>Fig 25.: Create a New View </em>
</p>  

2. Configure  Name for the view

    Select radio-button near `Build Pipeline View`
    
 <p align="center">
  <img src="screenshots/build_pipeline_view_name.png" width="800" title="Build Pipeline ">
  <br>
  <em>Fig 26.: Build Pipeline View </em>
</p>

3. Configure **Build Pipeline** View

   Select the upstream Job from which the deployment chain starts.
   
<p align="center">
  <img src="screenshots/build_pipeline_configure.png" width="800" title="Build Pipeline ">
  <br>
  <em>Fig 27.: Build Pipeline Configure </em>
</p>

4. Build Pipeline View

   We can start, restart jobs from Build Pipeline View.
   
<p align="center">
  <img src="screenshots/build_pipeline_successes.png" width="800" title="Build Pipeline ">
  <br>
  <em>Fig 28.: Build Pipeline  </em>
</p>
   
   
   
 > Source: LinuxWorld Informatics. Private Ltd.
 > 
 > Under Guidance of : Mr. [Vimal Daga](https://in.linkedin.com/in/vimaldaga)

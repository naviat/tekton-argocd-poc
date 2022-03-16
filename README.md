# Tekton and Argo CD PoC

This is a PoC to check Tekton, Argo CD and how both tools can work together following a GitOps way

## Requirements

To execute this PoC it's you need to have:

- A Kubernetes cluster. If you don't have one, you can create a K3D one using the script `create-local-cluster.sh` but, obviously, you need to have installed K3D (it's included in script)
  - Other option with kind (in progress)
- Docker
- Kubectl

## PoC Structure

- `poc`: this is the main folder. Here, you can find three scripts:

  - `create-local-cluster.sh`: this script creates a local Kubernetes cluster based on K3D.

  - `delete-local-cluster.sh`: this script removes the local cluster

  - `setup-poc.sh`: this script installs and configure everything neccessary in the cluster (Tekton, Argo CD, Nexus, Sonar, etc...)

- `resources`: this the folder used to manage the two repositories (code and gitops):
  - `sources-repo`: source code of the service used in this poc to test the CI/CD process
  - `gitops_repo`: repository where Kubernetes files associated to the service to be deployed are

## Steps

### 1) Fork

The first step is to fork the repo <https://github.com/naviat/tekton-argocd-poc> because:

- You have to modify some files to add a token
- You need your own repo to perform Gitops operations

### 2) Add Github token

It's necessary to add a Github Personal Access Token to Tekton can perform git operations, like push to gitops repo. If you need help to create this token, you can follow these instructions: <https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token>

> ** The token needs to be allowed with "repo" grants.

Once the token is created, you have to copy it in these files (`## INSERT TOKEN HERE`):

`poc/conf/argocd/git-repository.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    managed-by: argocd.argoproj.io
  name: repo-gitops
  namespace: argocd
type: Opaque
stringData:
  username: tekton
  password: ## INSERT TOKEN HERE
```

`poc/conf/tekton/git-access/secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: git-auth
  namespace: cicd
  annotations:
    tekton.dev/git-0: https://github.com/
type: kubernetes.io/basic-auth
stringData:
  username: tekton
  password: ## INSERT TOKEN HERE
```

> ** In fact, for Argo CD, create secret with the token isn't necessary because the gitops repository in Github has public access but I think it's interesting to keep it in order to know what you need to do in case the repository be private.

### 3) Create Kubernetes cluster (optional)

This step is optional. If you already have a cluster, perfect, but if not, you can create a local one based on K3D, just executing the script `poc/create-local-cluster.sh`. This script creates the local cluster and configure the private image registry to manage Docker images.

### 4) Setup

This step is the most important because installs and configures everything necessary in the cluster:

- Installs Tekton and Argo CD, including secrets to access to Git repo
- Creates the volume and claim necessary to execute pipelines
- Deploys Tekton dashboard
- Deploys Sonarqube
- Deploys Nexus and configure an standard instance
- Creates the configmap associated to Maven settings.xml, ready to publish artifacts in Nexus (with user and password)
- Installs Tekton tasks and pipelines
  - [Git-clone](https://hub-preview.tekton.dev/detail/34) (from Tekton Hub)
  - [Maven](https://hub-preview.tekton.dev/detail/65) (from Tekton Hub)
  - [Buildah](https://hub-preview.tekton.dev/detail/13) (from Tekton Hub)
  - Prepare Image (custom task: `poc/conf/tekton/tasks/prepare-image-task.yaml`)
  - Push to GitOps repo (custom task: `poc/conf/tekton/tasks/push-to-gitops-repo.yaml`)
- Installs Argo CD application, configured to check changes in gitops repository (`resources/gitops_repo`)
- Update Argo CD password

> **Be patient**: The process takes some minutes.

> **This message isn't an error** It just waiting for to Nexus admin password created when the container starts. When the Nexus container starts, at some moment, it creates a file containing the default password.

```sh
Configuring settings.xml (MAVEN) to work with Nexus
cat: /nexus-data/admin.password: No such file or directory
command terminated with exit code 1
```

### 5) Explore and play

Once everything is installed, you can play with this project:

>> For the first time you run pipeline, you need to login Sonarquebe, change password and disable forced user authentication, and allow anonymous users to browse projects and run analyses in your instance. To do this, log in as a system administrator, go to **Administration > Configuration > General Settings > Security**, and disable the `Force user authentication property`.

#### Tekton Part

Tekton dashboard could be exposed locally using this command:

```sh
kubectl proxy --port=8080
```

Then, just open this url in the browser:

```sh
http://localhost:8080/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/#/namespaces/cicd/pipelineruns
```

By that link you'll access to **PipelineRuns options** and you'll see a pipeline executing.

Each stage is executed by a pod. For instance, you can execute:

`kubectl get pods -n cicd -l "tekton.dev/pipelineRun=products-ci-pipelinerun"`

to see how different pods are created to execute different stages.

#### Argo CD Part

To access to Argo CD dashboard you need to perform a port-forward:

`kubectl port-forward svc/argocd-server -n argocd 9080:443`

Then, just open this url in the browser:

`https://localhost:9080/`

I’ve set the admin user with these credentials: `admin / admin123`

### 6) Delete the local cluster (optional )

If you create a local cluster in step 3, there is an script to remove the local cluster. This script is `poc/delete-local-cluster.sh`

# CHANGELOG

- Test 1

# HelloPy

A simple demonstration application (s) development for the application deployment POC using:

- skaffold
- kustomize
- argo-cd
- jenkins-x
- harness ?


## Install slack webhook

```sh
export DEFAULT_SLACK_WEBHOOK_URI=https://hooks.slack.com/services/.../.../...
```

## Install the mclabs-route53-operator

```sh
# set the following ENV variables
export AWS_ACCCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export REGION=eu-west-1
# install
cat vendors/mclabs-route53-operator/install-0.1.0.yaml | envsubst | kubectl apply -f -
```



## Install Bitbucket creds

```
export BITBUCKET_USERNAME=...
export BITBUCKET_PASSWORD=...
```

### Install argocd

```sh
# install the cli tool
brew install argocd
# install the platforms
kustomize build vendors/argocd | envsubst | kubectl apply -f -
# port forward to the service ## REPLACED BY NodePort
# kubectl port-forward svc/argocd-server -n argo-cd 8080:443
```

```sh
# view Argo-CD ui
open http://$(minikube ip):31237

# setup project via cli
ARGO_PASS=$(kubectl get pods -n argo-cd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
argocd login $(minikube ip):31237 --username admin --password $ARGO_PASS
argocd proj create helloworld \
       --description 'example application' \
       --src https://bitbucket.org/mindcurv/basic-application.git\
       --dest https://kubernetes.default.svc,default

argocd repo add https://bitbucket.org/mindcurv/basic-application.git \
       --username $BITBUCKET_USERNAME \
       --password $BITBUCKET_PASSWORD

 argocd app create helloworld \
       --project helloworld \
       --repo https://bitbucket.org/mindcurv/basic-application.git \
       --path kustomize/argocd/prod \
       --dest-server https://kubernetes.default.svc \
       --dest-namespace default \
       --auto-prune --sync-policy automated --upsert

# helloworld-svc-active env
open http://$(minikube ip):31234
# helloworld-svc-preview env
open http://$(minikube ip):31235

```

## ArgoCD - blue/green unpause a rollout

The Green/Blue deployment Strategy will pause after it has rolled out the preview images
It will wait for a patch to set paused: false and will then proceed with updates
During this time you are able to view the preview service at its url on the cluster

NOTE: if the preview url is not-available, it probably means that there is no pending rollout of the preview

### roll the preview application out

```sh
kubectl patch rollouts helloworld --type merge --patch '{"spec": {"paused": false}}'
```

## Notes

1. kustomize/rollout.yaml makes use of ArgoCD "Rollout" kind, this kind is the same as a Deployment kind, but with some added functionality (canary, b/g capabilities)


## Jenkins-X


```sh
skaffold build -f skaffold-jenkins-x.yaml
```

```sh
 kustomize build kustomize/jenkins-x/prod | envsubst
```

## Harness

```sh
skaffold build -f skaffold-harness.yaml
```

```sh
 kustomize build kustomize/harness/prod | envsubst
```


## Developer Usage

### CI Usage - as a developer

```sh
# ensure the minikube context is active for local development
# skaffold dev        # run as a developer making code changes
# skaffold deploy     # to deploy the k8s files files with kustomize
# skaffold run        # to build the image and deploy the k8s files with kustomize
skaffold build                        # will output a image:tag rosscdh/hellopy:3dec2d3
docker push rosscdh/hellopy:3dec2d3   # then push the tag
```

### Usage - as CD

A deliberate seperate configuration for audit and change control
where a dev will change the image tag to a specific version and commit to git
the CD systems then take over.


## Developer workflow

```sh
# roll out the standard simple Deployment
kustomize build kustomize/*/dev | kubectl apply -f -
```
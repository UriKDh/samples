# project config
PROJECT=project_name
gcloud config set project $PROJECT
gcloud container clusters get-credentials container_name \
    --zone europe-west1-b --project $PROJECT

# image config
IMAGE=gcr.io/project_name/image_name:v10

# reload deployment: uncomment when neccesary
# kubectl delete -f ./kube/app_deployment.yml
# kubectl delete -f ./kube/app_service.yml
# kubectl create -f ./kube/app_deployment.yml --record
# kubectl create -f ./kube/app_service.yml

# build container
docker build -t image_name -f Dockerfile .
# tag container version
docker tag image_name $IMAGE
# push to google container registry
gcloud docker -- push $IMAGE

# update image
kubectl set image deployment app app=$IMAGE --record
kubectl rollout status deployment app

while read -r POD; do
    POD_STATUS=`echo $POD | awk 'BEGIN {FS=" "}; {print $3}'`
    if [ "$POD_STATUS"="Running" ]; then
        POD_NAME=`echo $POD | awk 'BEGIN {FS=" "}; {print $1}'`
        # migrations and assets
        kubectl exec $POD_NAME -- bash -c 'cd /app && RAILS_ENV=production bin/rake db:migrate'
        kubectl exec $POD_NAME -- bash -c 'cd /app && RAILS_ENV=production bin/rake assets:precompile'

        # reload unicorn
        UNICORN_PID=`kubectl exec $POD_NAME -- bash -c 'cat tmp/unicorn.pid'`
        kubectl exec $POD_NAME -- bash -c "kill -HUP $UNICORN_PID"
    fi
done <<< "`kubectl get pods | sed '1d'`"

# check conection
# curl --retry 10 --retry-delay 10 -v https://url -k

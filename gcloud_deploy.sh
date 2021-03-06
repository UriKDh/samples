# project config
export PROJECT=project_name
echo $PROJECT
gcloud config set project $PROJECT
gcloud container clusters get-credentials cluster_name \
    --zone europe-west1-b --project $PROJECT

# image config
export IMAGE=gcr.io/$PROJECT/project_name:v1
echo $IMAGE

# build container
docker build -t project_name -f Dockerfile .
# tag container version
docker tag project_name $IMAGE
# push to google container registry
gcloud docker -- push $IMAGE

# update image
kubectl set image deployment app app=$IMAGE --record
kubectl rollout status deployment app

# migrations and assets
while read -r POD; do
    POD_STATUS=`echo $POD | awk 'BEGIN {FS=" "}; {print $3}'`
    if [ "$POD_STATUS"="Running" ]; then
        POD_NAME=`echo $POD | awk 'BEGIN {FS=" "}; {print $1}'`
        # migrations and assets
        kubectl exec $POD_NAME -- bash -c 'cd /app && RAILS_ENV=production bin/rake db:migrate'
        kubectl exec $POD_NAME -- bash -c 'cd /app && RAILS_ENV=production bin/rake assets:precompile'

        # reload puma
        kubectl exec $POD_NAME -- bash -c "rails restart"
    fi
done <<< "`kubectl get pods | sed '1d'`"

# check conection
# curl --retry 10 --retry-delay 10 -v https://url -k

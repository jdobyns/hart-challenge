#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: ./run.sh app-name"
  exit 1
fi

echo `date`
echo ""

cd bin
./services/elasticsearch.sh $1 &
PID1=$!
echo `date`

echo "Launch Autoscaling group to back app.opsflo.com"
./launch_group.sh $1
PID2=$!

wait $PID1
while true
  do
    sleep 5
    es_endpoint=`aws es describe-elasticsearch-domain --domain-name $1 | jq .DomainStatus.Endpoint | grep -v null`
    if [ ! -z $es_endpoint ]; then
      break
    fi
    echo "waiting for es_endpoint to become available - `date` "
    sleep 5
done
echo "ES url https://$es_endpoint "

wait $PID2


echo "https://app.opsflo.com will be up as soon as the elb activates. "
#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: ./run.sh app-name"
  exit 1
fi
echo `date`
echo "Go get a beer, AWS takes about 7 mins to activate a new ES domain"
cd bin
./services/elasticsearch.sh $1 & > outputs/es.json
PID1=$!
wait $PID1
echo `date`

es_endpoint=`aws es describe-elasticsearch-domain --domain-name $1 | jq .DomainStatus.Endpoint`
echo "ES is up at $es_endpoint.\n"

echo "Launching Autoscaling group to back app.opsflo.com"
./launch_group.sh $1 &
PID2=$!
wait $PID2

echo "https://app.opsflo.com will be up as soon as the elb's activate."
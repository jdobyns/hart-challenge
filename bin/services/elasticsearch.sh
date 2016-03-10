#!/bin/bash

es_name=$1

json=$(< <(cat <<EOF
{
    "DomainName": "$es_name", 
    "ElasticsearchClusterConfig": {
        "InstanceType": "t2.medium.elasticsearch", 
        "InstanceCount": 2, 
        "DedicatedMasterEnabled": false 
    }, 
    "EBSOptions": {
        "EBSEnabled": true, 
        "VolumeType": "gp2", 
        "VolumeSize": 20
    }
}
EOF
))

aws es create-elasticsearch-domain --cli-input-json "$json"

while true; 
  do
    es_ready=`aws es describe-elasticsearch-domain-config --domain-name $1 | jq '.DomainConfig[].Status.State' | grep Active | wc -l`
    if [ $es_ready -eq 5 ]; then
        break
    fi
#    echo "wait for es all services: ready $es_ready/5 - `date`  "
    sleep 10
done

while true;
  do
    es_endpoint=`aws es describe-elasticsearch-domain --domain-name $1 | jq .DomainStatus.Endpoint`
    if [[ -n "${es_endpoint}" ]]; then
      break
    fi
#    echo "$1"
#    echo $es_endpoint
#    echo "waiting for es_endpoint to become available"
    sleep 10
done

echo $es_endpoint

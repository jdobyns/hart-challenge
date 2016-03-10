#!/bin/bash

aws autoscaling create-launch-configuration \
	--launch-configuration-name "$1" \
	--image-id 'ami-fce3c696' \
	--key-name 'opsflo_hart_challenge' \
	--security-groups 'sg-858432fd' \
	--instance-type 't2.medium' \
	--user-data file://user-data/app_node.sh

aws autoscaling create-auto-scaling-group \
	--auto-scaling-group-name "$1" \
	--launch-configuration-name "$1" \
	--min-size 2 \
	--max-size 10 \
	--vpc-zone-identifier 'subnet-5ee67528,subnet-051db65d,subnet-2eb6c213' \
	--load-balancer-names 'app-opsflo-com' \
	--termination-policies NewestInstance

aws autoscaling put-scaling-policy \
	--auto-scaling-group-name "$1" \
	--policy-name 'app-node-2' \
	--scaling-adjustment 2 \
	--adjustment-type 'ChangeInCapacity' \
	--cooldown 300


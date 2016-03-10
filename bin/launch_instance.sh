#!/bin/bash

aws ec2 run-instances 	--image-id ami-fce3c696 \
			--count 1 \
			--instance-type t1.medium \
			--key-name opsflo_hart_challenge \
			--security-group-ids sg-858432fd \
			--user-data file://services/app_node.sh

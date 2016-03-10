#!/bin/bash

aws ec2 run-instances 	--image-id ami-fce3c696 \
			--count 1 \
			--instance-type t1.micro \
			--key-name opsflo_hart_challenge \
			--security-groups opsflo_hart_challenge \
			--user-data file://services/logstash.sh

#!/bin/bash

SG_ID="sg-0e263b6954d7e9575"
AMI_ID="ami-0fe18bc3cfa53a248"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name my-key \
    --security-group-ids $SG_ID \
    --subnet-id subnet-xxxxxxxx \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DevServer}]' \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances 
            --instance-ids $INSTANCE_ID 
            --query 'Reservations[0].Instances[0].PublicIpAddress' 
            --output text 
        ) 
    else 
        IP=$(
            aws ec2 describe-instances 
            --instance-ids $INSTANCE_ID 
            --query 'Reservations[0].Instances[0].PrivateIpAddress' 
            --output text        
        )
    fi  
done
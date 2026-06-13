#!/bin/bash

SG_ID="sg-011fc2a12c2612b4"
AMI_ID="ami-0fe18bc3cfa53a248"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0fe18bc3cfa53a248 \
    --instance-type t3.micro \
    --key-name kubernates_keypair \
    --security-group-ids sg-011fc2a12c2612b4 \
    --subnet-id subnet-xxxxxxxx \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mongodb}]' \
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
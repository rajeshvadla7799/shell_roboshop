#!/bin/bash

SG_ID="sg-011fc2a12c2612b46"
AMI_ID="ami-0fe18bc3cfa53a248"
Zone_ID="Z008257517FWWZQ7V2B3N"
Domain_NAME="roboshop.com"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name Kubernates_keypair \
    --security-group-ids $SG_ID \
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
        RECORD_NAME="$Domain_NAME" # roboshop.com
    else 
        IP=$(
            aws ec2 describe-instances 
            --instance-ids $INSTANCE_ID 
            --query 'Reservations[0].Instances[0].PrivateIpAddress' 
            --output text        
        )
        RECORD_NAME="$instance.$Domain_NAME" # roboshop.com
    fi  

echo "IP address of $instance is $IP"

aws route53 change-resource-record-sets \
  --hosted-zone-id $Zone_ID \
  --change-batch 
{
  "Comment": "updating record"
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}

echo "Record updated for $instance with IP $IP"
done
#!/bin/bash

SG_ID="sg-011fc2a12c2612b46"
AMI_ID="ami-0741dc526e1106ae5"
ZONE_ID="Z008257517FWWZQ7V2B3N"
DOMAIN_NAME="roboshop.com"

for instance in "$@"
do
    echo "Creating instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --key-name Kubernates_keypair \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "Created Instance ID: $INSTANCE_ID"

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$instance" == "frontend" ]; then

        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)

        RECORD_NAME="$DOMAIN_NAME"

    else

        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)

        RECORD_NAME="$instance.$DOMAIN_NAME"

    fi

    echo "IP address of $instance is $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Comment\": \"Creating DNS record for $instance\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 1,
                    \"ResourceRecords\": [{
                        \"Value\": \"$IP\"
                    }]
                }
            }]
        }"

    echo "Route53 record updated: $RECORD_NAME -> $IP"

done
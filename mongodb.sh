#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/Shell_roboshop"
LOGS_FILE="$LOGS_FOLDER/mongodb.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2... Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2... Success $N" | tee -a $LOGS_FILE
    fi
}

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run as root user $N"
    exit 1
fi

apt update -y &>> $LOGS_FILE
apt install curl gnupg -y &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

# Force gpg to overwrite the key automatically without prompting
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
gpg --batch --yes --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg &>> $LOGS_FILE
VALIDATE $? "Adding MongoDB GPG key"

# MATCHED TO mongo.repo
cp mongo.repo /etc/apt/sources.list.d/mongodb-org-7.0.list
VALIDATE $? "Copying MongoDB repo file"

apt update -y &>> $LOGS_FILE
VALIDATE $? "Updating package cache"

apt install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> $LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>> $LOGS_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing MongoDB to listen on all IP addresses"

systemctl restart mongod &>> $LOGS_FILE
VALIDATE $? "Restarting MongoDB"
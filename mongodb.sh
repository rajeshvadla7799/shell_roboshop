#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/Shell_roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
M="\e[35m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo "$R Please run this script as root user $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2... Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2... Success $N" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/apt/sources.list.d/*.list
VALIDATE $? "Copying MongoDB repo file"

apt install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB"

sed -i s/127.0.0.1/0.0.0.0/g /etc/mongod.conf
VALIDATE $? "Allowing MongoDB to listen on all IP addresses"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB"
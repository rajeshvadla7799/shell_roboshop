#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/Shell_roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)
MONGODB_HOST="mongodb.roboshop.com"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script as root user $N"
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2... Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2... Success $N" | tee -a $LOGS_FILE
    fi
}

echo "Catalogue setup started at $(date)" | tee -a $LOGS_FILE

dnf install nodejs unzip -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS and unzip"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop user already exists, skipping $N" | tee -a $LOGS_FILE
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating application directory"

curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue application"

cd /app

rm -rf /app/*
VALIDATE $? "Removing old application content"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Extracting catalogue application"

cd /app

npm install &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloading systemd"

systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOGS_FILE
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Shell"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ "$INDEX" -lt 0 ]; then
    mongosh --host $MONGODB_HOST < /app/db/master-data.js &>>$LOGS_FILE
    VALIDATE $? "Loading catalogue data into MongoDB"
else
    echo -e "$Y Catalogue database already exists, skipping data load $N" | tee -a $LOGS_FILE
fi

systemctl restart catalogue &>>$LOGS_FILE
VALIDATE $? "Restarting catalogue service"

echo -e "$G Catalogue setup completed successfully $N"
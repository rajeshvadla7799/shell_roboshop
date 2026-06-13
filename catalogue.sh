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
SCRIPT_DIR=$(pwd)
MONGODB_HOST="roboshop.com"

if [ $USERID -ne 0 ]; then
    echo "$R Please run this script as root user $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE () {
    if [ $? -ne 0 ]; then
        echo -e "$R $2... Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2... Success $N" | tee -a $LOGS_FILE
    fi
}

sudo dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
sudo useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
VALIDATE $? "Adding roboshop user"
else
    echo -e "$Y roboshop user already exists, skipping user creation $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue code"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing directory to /app"

rm -rf * &>>$LOGS_FILE
VALIDATE $? "Cleaning old application content"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Extracting catalogue code"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing directory to /app"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
VALIDATE $? "Copying systemd service file"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloading systemd"

systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOGS_FILE
VALIDATE $? "Copying MongoDB repo file"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
VALIDATE $? "Loading master data to MongoDB"






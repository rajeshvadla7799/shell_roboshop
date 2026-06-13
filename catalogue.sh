#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/Shell_scripts"
SCRIPT_NAME=$(basename "$0" .sh)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script as root user $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 ... FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2 ... SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

apt module disable nodejs &>> $LOGS_FILE
VALIDATE $? "Disabling Node.js Module"

apt module enable nodejs &>> $LOGS_FILE
VALIDATE $? "Enabling Node.js Module"

apt install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing Node.js"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
VALIDATE $? "Adding Application User"

mkdir /app &>> $LOGS_FILE
VALIDATE $? "Creating Application Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading Application Code"

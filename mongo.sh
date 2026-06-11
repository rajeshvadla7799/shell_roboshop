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

echo "MongoDB Installation Started: $(date)" | tee -a $LOGS_FILE

sudo apt update &>> $LOGS_FILE
sudo apt install curl gnupg -y &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

sudo curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg &>> $LOGS_FILE
VALIDATE $? "Adding MongoDB GPG Key"

sudo cp mongodb-org-7.0.list /etc/apt/sources.list.d/mongodb-org-7.0.list &>> $LOGS_FILE
VALIDATE $? "Copying MongoDB Repository File"

sudo apt update -y &>> $LOGS_FILE
VALIDATE $? "Updating Package Cache"

sudo apt install -y mongodb-org &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB"

sudo systemctl enable mongod &>> $LOGS_FILE
VALIDATE $? "Enabling MongoDB"

sudo systemctl start mongod &>> $LOGS_FILE
VALIDATE $? "Starting MongoDB"

sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGS_FILE
VALIDATE $? "Allowing Remote Connections"

sudo systemctl restart mongod &>> $LOGS_FILE
VALIDATE $? "Restarting MongoDB"

echo -e "$G MongoDB Installation Completed Successfully $N" | tee -a $LOGS_FILE
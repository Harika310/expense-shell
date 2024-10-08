#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0  | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT()
{
    if [ $USERID -ne 0 ]
    then
    echo -e "$R Please run the script with root priveleges $N" | tee -a $LoG_FILE
    exit 1
    fi
}

VALIDATE()
{
    if [ $1 -ne 0 ]
    then
    echo -e "$2 is...$R Failed $N" | tee -a $LoG_FILE
    exit 1
    else
    echo -e "$2 is...$G Success $N" | tee -a $LoG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disable default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ] 
then 
echo -e "expense user not exist..$G creating $N"
useradd expense &>>$LOG_FILE
VALIDATE $? "Creating expense user"
else
echo -e "expense user already exists...$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* #remove the existing code

unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE  #installing dependencies 

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copied expense conf"
# load the data before running backend 
dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing mysql client" 

mysql -h mysql.daws-81s.online -uroot -pExpenseApp@1 < /app/schema/backend.sql  &>>$LOG_FILE
VALIDATE $? "schema loading"

systemctl daemon-reload  &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable backend  &>>$LOG_FILE
VALIDATE $? "enabled backend" 

systemctl restart backend  &>>$LOG_FILE
VALIDATE $? "Restarted backend"





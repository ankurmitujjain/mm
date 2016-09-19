#!/bin/bash

usage(){
    echo "Usage: -c (create database) -u (create user) -h (help)"
}

file_input=$1

OPTIND=1
while getopts "hcu" opt ; do
    case "${opt}" in
        h) usage ;;
        c) runtype="create";;
        u) runtype="user";;
        *)
    esac
done

if [ "${*}" = "" ] ; then
    usage
fi

#create database
if [ "$runtype" = "create" ] ; then
echo "please enter the location the database will be created"
read DB_HOST
echo "Please enter root password for mysql:"
mysql_config_editor set --login-path=tempsetting --host="$DB_HOST" --user=root --password
echo "Please enter name of DB to be created"
read DB_NAME
echo "CREATE DATABASE "$DB_NAME"" | mysql --login-path=testdbcreator
echo "CREATE TABLE object (objectIdentifierValue varchar(1000) NOT NULL,contentLocationValue varchar (300),PRIMARY KEY (objectIdentifierValue))" | mysql --login-path=testdbcreator "$DB_NAME"
echo "CREATE TABLE event (eventIdentifierValue bigint NOT NULL AUTO_INCREMENT,objectIdentifierValue varchar(1000) NOT NULL,eventType varchar(100) NOT NULL,eventDateTime datetime NOT NULL DEFAULT NOW(),eventDetail varchar(30) NOT NULL,eventDetailOPT varchar(1000),eventDetailCOMPNAME varchar(50) NOT NULL,linkingAgentIdentifierValue varchar(30) NOT NULL,PRIMARY KEY (eventIdentifierValue),FOREIGN KEY (objectIdentifierValue) REFERENCES object(objectIdentifierValue))" | mysql --login-path=testdbcreator "$DB_NAME"
echo "CREATE TABLE fixity (fixityIdentifierValue bigint NOT NULL AUTO_INCREMENT,objectIdentifierValue varchar(1000),eventDateTime datetime NOT NULL DEFAULT NOW(),messageDigestAlgorithm varchar (20) NOT NULL,messageDigestPATH varchar (8000) NOT NULL,messageDigestFILENAME varchar (8000) NOT NULL,messageDigestHASH varchar (32) NOT NULL,PRIMARY KEY (fixityIdentifierValue),FOREIGN KEY (objectIdentifierValue) REFERENCES object(objectIdentifierValue))" | mysql --login-path=testdbcreator "$DB_NAME"
mysql_config_editor remove --login-path=tempsetting
fi

#create user
if [ "$runtype" = "user" ] ; then
echo "please enter the name of target database"
read DB_NAME
echo "please enter the location of target database"
read DB_HOST
echo "please enter the name of user to be created"
read USER_NAME
echo "please enter the password for the new user"
read USER_PASSWORD
echo "please enter the location of user to be created"
read USER_HOST
echo "please enter mysql root password"
mysql_config_editor set --login-path=tempsetting --host="$DB_HOST" --user=root --password

#set up and run expect script for creation of mysql login config
expect="$HOME/.$(basename "${0}").exp"
touch "${expect}"
echo "#!/usr/bin/expect" > "${expect}"
echo "spawn mysql_config_editor set --login-path="$USER_NAME"_config --host="$USER_HOST" --user="$USER_NAME" --password" >> "${expect}"
echo "expect \"Enter password: \"" >> "${expect}"
echo "send \""$USER_PASSWORD"\r\"" >> "${expect}"
echo "expect eof" >> "${expect}"
chmod 755 "${expect}"
expect "${expect}"
rm "${expect}"

echo "Use the following settings in mmconfig"
echo "Database Profile is "$USER_NAME"_config"
echo "Database Name is DB_NAME"

mysql_config_editor remove --login-path=tempsetting
fi
#!/bin/bash

echo "Enter backup password"
read dump

mongodump --db cameoProd -u cameoBackup -p $dump --host mongodb-prod01

echo "Enter restore password"
read restore

mongorestore --drop --db cameoStage -u cameoRestore -p $restore --host mongodb-dev01 dump/cameoProd/

rm -rf dump

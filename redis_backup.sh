#!/bin/bash
#Declare connection details
 redis_host=xx.xx.xx.xx
 redis_port=xxx
 redis_pass="xxxxxxxx"
 redis_home=`find / -name "redis.conf" -exec grep "^dir" {} \; 2> /dev/null |awk '{print $2}' | sed 's/"//g'`
 redis_backupfile=dump.rdb

#Check redis is running
 redis_status=`redis-cli -h $redis_host -p $redis_port -a "$redis_pass" ping`

if [ "$redis_status" = "PONG" ]
 then
 echo "Connected to Redis"
 #Backup redis database
 echo "Running Redis backup"
 status=`redis-cli -h $redis_host -p $redis_port -a "$redis_pass" save`
 if [ $? -eq 0 ]
 then
 echo "Backup completed successfully"
 echo "Backup saved to directory $redis_home with filename $redis_backupfile"
 else
 echo "Backup failed with error $status"
 fi
 else
 echo "Redis is not running or can't connect"
 exit 1
 fi
#!/bin/bash
#Declare connection details
redis_host=xx.xx.xx.xx
redis_port=xxxx
redis_pass="xxxxxxxx"
redis_home=`find / -name "redis.conf" -exec grep "^dir" {} \; 2> /dev/null |awk '{print $2}' | sed 's/"//g'`
redis_backupfile=dump.rdb
#Remote server details
redis_remote_host=xx.xx.xx.xx #Remote redis ip address
remote_server=xx.xx.xx.xx #Remote Server IP to copy database backup
remote_user=user
remote_dir=/tmp

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

#Copy backup to remote server
 scp $redis_home/$redis_backupfile $remote_user@$remote_server:$remote_dir
 remote_status=`ssh $remote_user@$remote_server [[ -f $remote_dir/$redis_backupfile ]] `
 if [ $? -eq 0 ]
 then
 echo "Backup file copied to remote server successfuly"
 else
 echo "File not found, please reinitiate remote copy"
 exit 1
 fi
#Check remote server redis status
remote_redis_status=`ssh $remote_user@$remote_server 'redis-cli -h '$redis_remote_host' -p '$redis_port' -a "'$redis_pass'" ping'`

if [ "$remote_redis_status" = "PONG" ]
 then
 echo "Connected to Remote Redis"
#Restore redis database
 echo "Running Redis Restore"
 status=`ssh $remote_user@$remote_server 'redis-cli -h '$redis_remote_host' -p '$redis_port' -a "'$redis_pass'" --rdb /tmp/dump.rdb'`
 if [ $? -eq 0 ]
 then
 echo "Restore completed successfully"
 else
 echo "Backup failed with error $status" 
 fi
 else
 echo "Redis is not running on remote server or can't connect"
 exit 1
 fi
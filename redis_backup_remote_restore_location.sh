#!/bin/bash
#Declare connection details
redis_host=xx.xx.xx.xx
redis_port=xxxx
redis_pass="xxxxxxxx"
redis_home=`find / -name "redis.conf" -exec grep "^dir" {} \; 2> /dev/null |awk '{print $2}' | sed 's/"//g'`
redis_backupfile=dump.rdb
#Remote server details
redis_remote_host=xx.xx.xx.xx  #Remote redis IP address
remote_server=xx.xx.xx.xx #Remote server IP to copy datbase
remote_user=user
remote_dir=/tmp
#Website location before restore
domain=example.com #domain name to check
#Check required packages are installed
command -v dig >/dev/null 2>&1 || { echo "Script require "dig" but it's not installed. Aborting." >&2; exit 1; }
command -v whois >/dev/null 2>&1 || { echo "Script require "whois" but it's not installed. Aborting." >&2; exit 1; }
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
#Check website is served from which location
echo "Checking website location"
site_ip=`dig +short $domain`
ip_owner=`whois $site_ip |grep OrgName |awk '{print $2,$3}' |sed 's/,//g'`
 if [ "$ip_owner" = "XXX" ]  #specify the name of owner IP address for primary site
 then 
 echo "Websites are running from primary location"
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
 else 
 echo "Websites are running from DR Site"
 exit 1
 fi
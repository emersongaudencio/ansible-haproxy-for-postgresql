#!/bin/bash
echo "HOSTNAME: " `hostname`
echo "BEGIN - [`date +%d/%m/%Y" "%H:%M:%S`]"
echo "##############"

PORT=${1}
PRIMARY=${2}
BACKUP=${3}

if [ $PRIMARY == $BACKUP ]; then
  BACKUP=""
fi

total_backup=`echo $BACKUP | wc -w`

if [ $total_backup -gt 0 ]; then
counter=$total_backup
cnt=1
echo "" > /tmp/SERVERS
while [ $counter -gt 0 ]
 do
   for SERVERS in $BACKUP; do
    echo $"server db$(( $cnt + 1 ))-live.a $SERVERS:$PORT check non-stick backup \n" >> /tmp/SERVERS; ec=$?
    if [ $ec -ne 0 ]; then
         echo "Script execution failed - `date +"%Y-%m-%d_%T"`"
         exit 1
    else
    cnt=$(( $cnt + 1 ))
    counter=$(( $counter - 1 ))
    fi
  done;
 done;

BACKUP_ADDRESS=$(cat /tmp/SERVERS)
BACKUP_ADDRESS=$(echo -en $BACKUP_ADDRESS)

sed -ie 's/backup//g' /tmp/SERVERS
BACKUP_ADDRESS_RO=$(cat /tmp/SERVERS)
BACKUP_ADDRESS_RO=$(echo -en $BACKUP_ADDRESS_RO)

FRONT_BACKEND_RO="frontend frontend_postgres_ro
        bind 127.0.0.1:5433
        mode tcp
        default_backend backend_postgres_ro"

PG_BACKEND_RO="# ------------------------------------------------- #
# Backend - PostgreSQL Servers for read only workload    #
# ------------------------------------------------- #
backend backend_postgres_ro
 mode tcp
 timeout client  10800s
 timeout server  10800s
 balance leastconn
 option httpchk
 option allbackups
 default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 64 maxqueue 128 weight 100 on-marked-down shutdown-sessions on-marked-up shutdown-backup-sessions
 $BACKUP_ADDRESS_RO"

fi

PRIMARY_ADDRESS="server db1-live.a $PRIMARY:$PORT check non-stick"

echo $PRIMARY_ADDRESS
echo $BACKUP_ADDRESS

echo "# ------------------------------------------------- #
# Global settings                                   #
# ------------------------------------------------- #
global
    log         127.0.0.1 local2 debug
    daemon
    stats socket /var/run/haproxy.sock mode 660 user root group haproxy level user

# ------------------------------------------------- #
# Defaults                                          #
# ------------------------------------------------- #
defaults
    log                     global
    retries                 2
    timeout connect         3s
    timeout client          8h
    timeout server          8h
    timeout tunnel          8h

# ------------------------------------------------- #
# Stats and admin interface                         #
# ------------------------------------------------- #
listen stats
        bind :9600
        mode http
        stats enable
        stats uri /
        stats realm Haproxy\ Statistics
        stats auth proxyadmin:test123
        stats admin if TRUE

# ------------------------------------------------- #
# Frontend                                          #
# ------------------------------------------------- #
frontend frontend_postgres
        bind 127.0.0.1:5432
        mode tcp
        default_backend backend_postgres

$FRONT_BACKEND_RO
# ------------------------------------------------- #
# Backend - MySQL Servers with only one master      #
# ------------------------------------------------- #
backend backend_postgres
 mode tcp
 balance leastconn
 option httpchk
 default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 64 maxqueue 128 weight 100 on-marked-down shutdown-sessions on-marked-up shutdown-backup-sessions
 $PRIMARY_ADDRESS
 $BACKUP_ADDRESS

$PG_BACKEND_RO" > /etc/haproxy/haproxy.cfg

### start haproxy service ###
systemctl enable haproxy.service
systemctl restart haproxy.service

### remove tmp files ###
rm -rf /tmp/SERVERS

echo "##############"
echo "END - [`date +%d/%m/%Y" "%H:%M:%S`]"

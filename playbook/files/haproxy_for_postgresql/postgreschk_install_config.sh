#!/bin/bash
verify_xinetd=`rpm -qa | grep xinetd`
if [[ $verify_xinetd == "xinetd"* ]]
then
  echo "$verify_xinetd is installed!"
else

### install xinetd #####
yum -y install xinetd telnet

user=${1}
pass=${2}
server_address=${3}

### copy from /tmp directory ###
cd /tmp
cp postgreschk /usr/local/bin/
chown nobody: /usr/local/bin/postgreschk
chmod 744 /usr/local/bin/postgreschk
echo "$server_address:5432:postgres:${user}:${pass}" > /opt/.pgpass
echo "${user}" > /opt/.pgpass
echo "${server_address}" > /opt/.pgserver
chown nobody: /opt/.pguser /opt/.pgpass /opt/.pgserver
chmod 0400 /opt/.pguser /opt/.pgpass /opt/.pgserver

##### Add postgreschk in the last line ###########################
# /etc/services
echo "# postgreschk preps
postgreschk        9200/tcp                # postgreschk" >> /etc/services

echo "# postgres
# default: on
# description: postgreschk
service postgres
{
  disable            = no
  flags              = REUSE
  socket_type        = stream
  port               = 9200
  wait               = no
  user               = nobody
  server             = /usr/local/bin/postgreschk
  log_on_failure     += USERID
  log_on_success     =
  only_from          = 0.0.0.0/0
  per_source         = UNLIMITED
}" >  /etc/xinetd.d/postgreschk

### starting xinetd service ###
systemctl enable xinetd.service
systemctl restart xinetd.service
sleep 5

## testing the service ####
#telnet 127.0.0.1 9200
sh /usr/local/bin/postgreschk
fi

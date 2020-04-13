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

### copy from /tmp directory ###
cd /tmp
cp postgreschk /usr/local/bin/
chown nobody: /usr/local/bin/postgreschk
chmod 744 /usr/local/bin/postgreschk
touch /opt/.pgpass
echo "localhost:5432:postgres:${user}:${user}" >> /opt/.pgpass
chown nobody: /opt/.pgpass
chmod 0600 /opt/.pgpass

##### Add postgreschk in the last line ###########################
# /etc/services
echo ' ' >> /etc/services
echo '# postgreschk preps' >> /etc/services
echo 'postgreschk        9200/tcp                # postgreschk' >> /etc/services

echo ' '                                               >  /etc/xinetd.d/postgreschk
echo '# postgres'                                      >> /etc/xinetd.d/postgreschk
echo '# default: on'                                   >> /etc/xinetd.d/postgreschk
echo '# description: postgreschk'                      >> /etc/xinetd.d/postgreschk
echo 'service postgres'                                >> /etc/xinetd.d/postgreschk
echo '{ '                                              >> /etc/xinetd.d/postgreschk
echo '  disable            = no'                       >> /etc/xinetd.d/postgreschk
echo '  flags              = REUSE'                    >> /etc/xinetd.d/postgreschk
echo '  socket_type        = stream'                   >> /etc/xinetd.d/postgreschk
echo '  port               = 9200'                     >> /etc/xinetd.d/postgreschk
echo '  wait               = no'                       >> /etc/xinetd.d/postgreschk
echo '  user               = nobody'                   >> /etc/xinetd.d/postgreschk
echo '  server             = /usr/local/bin/postgreschk'  >> /etc/xinetd.d/postgreschk
echo '  log_on_failure     += USERID'                  >> /etc/xinetd.d/postgreschk
echo '  log_on_success     ='                          >> /etc/xinetd.d/postgreschk
echo '  only_from          = 0.0.0.0/0'                >> /etc/xinetd.d/postgreschk
echo '  per_source         = UNLIMITED'                >> /etc/xinetd.d/postgreschk
echo '}'                                               >> /etc/xinetd.d/postgreschk
echo ' '                                               >> /etc/xinetd.d/postgreschk

### starting xinetd service ###
systemctl enable xinetd.service
systemctl restart xinetd.service
sleep 5

## testing the service ####
#telnet 127.0.0.1 9200
sh /usr/local/bin/postgreschk
fi

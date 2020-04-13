#!/bin/bash
echo "HOSTNAME: " `hostname`
echo "BEGIN - [`date +%d/%m/%Y" "%H:%M:%S`]"
echo "##############"

verify_haproxy=`rpm -qa | grep haproxy`
if [[ $verify_haproxy == "haproxy"* ]]
then
  echo "$verify_haproxy is installed!"
else
  ##### FIREWALLD DISABLE #########################
  systemctl disable firewalld
  systemctl stop firewalld
  ######### SELINUX ###############################
  sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  # disable selinux on the fly
  /usr/sbin/setenforce 0

  ### clean yum cache ###
  yum clean headers
  yum clean packages
  yum clean metadatas

  ####### PACKAGES ###########################
  # -------------- For RHEL/CentOS 7 --------------
  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

  ### install pre-packages ####
  yum -y install psql yum-utils screen expect nload bmon iptraf glances perl perl-DBI openssl pigz zlib file sudo  libaio rsync snappy net-tools wget nmap htop dstat sysstat perl-IO-Socket-SSL perl-Digest-MD5 perl-TermReadKey socat libev gcc zlib zlib-devel openssl openssl-devel python-pip python-devel zip unzip

  ### clean yum cache ###
  yum clean headers
  yum clean packages
  yum clean metadata

  #### Haproxy ######
  yum -y install https://github.com/emersongaudencio/linux_packages/raw/master/RPM/haproxy-1.8.4-3.el7.centos.x86_64.rpm

  ##### SYSCTL Haproxy ###########################
  # insert parameters into /etc/sysctl.conf for incresing Haproxy limits
  echo "# haproxy preps
  vm.swappiness = 1
  fs.suid_dumpable = 1
  fs.aio-max-nr = 1048576
  fs.file-max = 6815744
  kernel.shmall = 1073741824
  kernel.shmmax = 4398046511104
  kernel.shmmni = 4096
  # semaphores: semmsl, semmns, semopm, semmni
  kernel.sem = 250 32000 100 128
  net.ipv4.ip_local_port_range = 9000 65500
  net.core.rmem_default=4194304
  net.core.rmem_max=4194304
  net.core.wmem_default=262144
  net.core.wmem_max=1048586" > /etc/sysctl.conf

  # reload confs of /etc/sysctl.confs
  sysctl -p

  #####  Haproxy LIMITS ###########################
  echo ' ' >> /etc/security/limits.conf
  echo '# haproxy' >> /etc/security/limits.conf
  echo 'haproxy              soft    nproc   2047' >> /etc/security/limits.conf
  echo 'haproxy              hard    nproc   16384' >> /etc/security/limits.conf
  echo 'haproxy              soft    nofile  4096' >> /etc/security/limits.conf
  echo 'haproxy              hard    nofile  65536' >> /etc/security/limits.conf
  echo 'haproxy              soft    stack   10240' >> /etc/security/limits.conf
  echo '# all_users' >> /etc/security/limits.conf
  echo '* soft nofile 102400' >> /etc/security/limits.conf
  echo '* hard nofile 102400' >> /etc/security/limits.conf

  # configure user
  adduser haproxy
  chsh -s /bin/bash haproxy

  ##### CONFIG PROFILE #############
  echo ' ' >> /etc/profile
  echo '# haproxy' >> /etc/profile
  echo 'if [ $USER = "haproxy" ]; then' >> /etc/profile
  echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
  echo '    ulimit -u 16384 -n 65536' >> /etc/profile
  echo '  else' >> /etc/profile
  echo '    ulimit -u 16384 -n 65536' >> /etc/profile
  echo '  fi' >> /etc/profile
  echo 'fi' >> /etc/profile
fi

echo "##############"
echo "END - [`date +%d/%m/%Y" "%H:%M:%S`]"

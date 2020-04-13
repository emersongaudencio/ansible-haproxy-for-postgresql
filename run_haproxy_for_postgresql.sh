#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST=${1}
VAR_PORT=${2}
VAR_PRIMARY_SERVER=${3}
VAR_BACKUP_SERVERS=${4}

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_PORT}" == '' ] ; then
  echo "No Port specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_PRIMARY_SERVER}" == '' ] ; then
  echo "No Primary Server specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_BACKUP_SERVERS}" == '' ] ; then
  VAR_BACKUP_SERVERS=${VAR_PRIMARY_SERVER}
fi

### Ping host ####
ansible -i $SCRIPT_PATH/hosts -m ping $VAR_HOST -v

### Haproxy setup ####
ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{pg_port: '$VAR_PORT', pg_primary_server: '$VAR_PRIMARY_SERVER', pg_backup_servers: '$VAR_BACKUP_SERVERS'}" $SCRIPT_PATH/playbook/haproxy_for_postgres.yml -l $VAR_HOST

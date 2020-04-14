#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST=${1}
VAR_PG_USER=${2}
VAR_PG_PASSWORD=${3}
VAR_PG_SERVER_ADDRESS=${4}

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_PG_USER}" == '' ] ; then
  echo "No PostgreSQL User specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_PG_PASSWORD}" == '' ] ; then
  echo "No PostgreSQL Password specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_PG_SERVER_ADDRESS}" == '' ] ; then
  echo "No PostgreSQL Server Address specified. Please have a look at README file for futher information!"
  exit 1
fi

### Ping host ####
ansible -i $SCRIPT_PATH/hosts -m ping $VAR_HOST -v

### Haproxy Check setup ####
ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{pg_user: '$VAR_PG_USER', pg_password: '$VAR_PG_PASSWORD', pg_server_address: '${VAR_PG_SERVER_ADDRESS}'}" $SCRIPT_PATH/playbook/haproxy_postgreschk.yml -l $VAR_HOST

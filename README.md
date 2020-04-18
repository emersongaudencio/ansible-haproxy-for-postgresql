# ansible-haproxy-for-postgresql
### Ansible Routine to setup HaProxy for PostgreSQL

# Translation in English en-us

 In this file, I will present and demonstrate how to Install HaProxy for PostgreSQL in an automated and easy way.

 For this, I will be using the scenario described down below:
 ```
 1 Linux server for Ansible
 ```

 First of all, we have to prepare our Linux environment to use Ansible

 Please have a look below how to install Ansible on CentOS/Red Hat:
 ```
 yum install ansible -y
 ```
 Well now that we have Ansible installed already, we need to install git to clone our git repository on the Linux server, see below how to install it on CentOS/Red Hat:
 ```
 yum install git -y
 ```

 Copying the script packages using git:
 ```
 cd /root
 git clone https://github.com/emersongaudencio/ansible-haproxy-for-postgresql.git
 ```
 Alright then after we have installed Ansible and git and clone the git repository. We have to generate ssh heys to share between the Ansible control machine and the database machines. Let see how to do that down below.

 To generate the keys, keep in mind that is mandatory to generate the keys inside of the directory who was copied from the git repository, see instructions below:
 ```
 cd /root/ansible-haproxy-for-postgresql
 ssh-keygen -f ansible
 ```
 After that you have had generated the keys to copy the keys to the database machines, see instructions below:
 ```
 ssh-copy-id -i ansible.pub 172.16.122.159
 ```

 Please edit the file called hosts inside of the ansible git directory :
 ```
 vi hosts
 ```
 Please add the hosts that you want to install your database and save the hosts file, see an example below:

 ```
 # This is the default ansible 'hosts' file.
 #

 ## [dbservers]
 ##
 ## db01.intranet.mydomain.net
 ## db02.intranet.mydomain.net
 ## 10.25.1.56
 ## 10.25.1.57

 [dbproxy]
 dbproxy ansible_ssh_host=172.16.122.159
 [dbservers]
 dbpg11 ansible_ssh_host=172.16.122.160
 ```

 For testing if it is all working properly, run the command below :
 ```
 ansible -m ping dbproxy -v
 ansible -m ping dbpg11 -v
 ```

 Alright then, finally we can perform the script to install HaProxy for PostgreSQL on our Proxy Server/App servers using Ansible as we planned to, please execute the command below:
 ```
 sh run_haproxy_for_postgresql.sh dbproxy 5432 172.16.122.160
 ```

 Alright then, finally we can perform the script to install PostgreSQL Check on our Database machine using Ansible as we planned to, please execute the command below:
 ```
 sh run_haproxy_postgreschk.sh dbpg11 postgreschk YOURPASSWORD 172.16.122.160
 ```

### Parameters specification:

#### run_haproxy_for_postgresql.sh
Parameter  | Value           | Mandatory | Order
------------ | ------------- | ------------- | -------------
host | dbproxy | Yes | 1
db port | 5432 | Yes | 2
Primary db server address | 172.16.122.160 | Yes | 3
Replicas db server address | 172.16.122.161,172.16.122.162 | No | 4

#### run_haproxy_postgreschk.sh
Parameter | Value | Mandatory | Order
------------ | ------------- | ------------- | -------------
host | dbpg11 | Yes | 1
db username | postgreschk | Yes | 2
db user password | YOURPASSWORD | Yes | 3
db server address | 172.16.122.160 | Yes | 4


Suggested grants privileges to a PostgreSQL User for postgreschk verification purpose on the master/slave database point it to:

```
############ Setting a proper privileges towards a database #####
CREATE USER postgreschk REPLICATION LOGIN ENCRYPTED PASSWORD 'YOURPASSWORD';
```

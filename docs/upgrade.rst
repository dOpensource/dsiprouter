Upgrade dSIPRouter
====================

In this section we will show you how to upgrading from 0.50 to 0.51.

Before starting the upgrade process you will need to backup your kamailio database using the following command: 

::
  
  cd /opt/

  mysqldump kamailio > kamailio-bk.sql
|

After you've backed up your database you can now uninstall dsiprouter v0.50 by running the following commands: 

::
  
  cd /opt/dsiprouter 

  ./dsiprouter.sh uninstall
|  

Once the uninstall is complete you will need to either move or delete the /dsiprouter directory using the following command.

::
  
  mv /dsiprouter /usr/local/src (moving directory)
  or 
  rm -r /dsiprouter (removing directory)
|  

Installing dsiprouter v0.51

::
  
  cd /opt/ 

  apt-get update
  apt-get install -y git curl
  cd /opt
  git clone -b v0.51 https://github.com/dOpensource/dsiprouter.git
  cd dsiprouter
  ./dsiprouter.sh install
|

After the install is complete your dSIPRouter login screen should now reflect v0.51.





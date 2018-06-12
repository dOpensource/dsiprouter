#!/bin/bash
#set -x
ENABLED=1

function installSQL {

#Check to see if the acc table or cdr tables are in use

mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME -e "select count(*) from dsip_fusionpbx_db limit 10" > /dev/null 2>&1  
if [ "$?" -eq 0 ]; then
	echo -e "The FusionPBX Domain Support (dsip_fusionpbx_db) table already exists.  Please backup this table before moving forward if you want the data."  	
	echo -e "Would you like to install the FusionPBX Domain Support module now [y/n]:\c"
	read ANSWER
	if [ "$ANSWER" == "n" ]; then
		return
	fi
fi

# Replace the FusionPBX Domain Support tables and add some Kamailio stored procedures
echo "Adding/Replacing the tables needed for FusionPBX Domain Support tables  within dSIPRouter..."
mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME < ./gui/modules/fusionpbx/fusionpbx.sql

}

function installNginx {

	apt-get install -y \
    	apt-transport-https \
    	ca-certificates \
    	software-properties-common

	curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -


	add-apt-repository \
   	"deb [arch=amd64] https://download.docker.com/linux/debian \
   	$(lsb_release -cs) \
   	stable"

	apt-get update

	apt-get install -y docker-ce
	if [ $? == 0 ]; then
		echo "Docker is installed"
	fi

	# Install Nginx
	abspath=`pwd`/gui/modules/fusionpbx
	echo $abspath
	docker create nginx
	#docker run --name docker-nginx -p 80:80  -v ${abspath}/dsiprouter.nginx:/etc/nginx/conf.d/default.conf  -d nginx

}

function uninstallNginx {

	# Can't remove packages because it removes python3-pip package
	#apt-get remove -y \
	#apt-transport-https \
	#ca-certificates 
	#software-properties-common

	# Forcefully stop all docker containers and remove them
	docker ps -a -q > /dev/null
	if [ $? == 1 ]; then
		docker rm -f $(docker ps -a -q) > /dev/null
		echo "Stopped and removed all docker containers"
	else
		echo "No docker containers to remove"
	fi

	# Remove Docker Engine
	apt-get remove -y docker-ce
	if [ $? == 0 ]; then
		echo "Removed the docker engine"
	fi
	
	# Remove docker repository
	#sed -i 's|https://download\.docker\.com|d|' /etc/apt/sources.list
	#if [ $? == 0 ]; then
	#	echo "Removed the docker repository"
	#fi

	# Stop trusting the docker key
	key=`apt-key list | grep -B 1 docker | head -n1`
	apt-key del $key
}


function install {

if [ $ENABLED == "0" ];then
    exit
fi

installSQL
installNginx
}





function install {

if [ $ENABLED == "0" ];then
    exit
fi

installSQL
installNginx
}



function uninstall {

echo ""
uninstallNginx

}

# This installer will be kicked off by the main dSIPRouter installer by passing the MySQL DB root username, database name, and/or the root password
# This is needed since we are installing stored procedures which require SUPER privileges on MySQL

if [ $# -gt 2 ]; then

	MYSQL_ROOT_USERNAME="-u$1"
	MYSQL_ROOT_PASSWORD="-p$2"
	MYSQL_KAM_DBNAME=$3

elif [ $# -gt 1 ]; then
    MYSQL_ROOT_USERNAME="-u$1"
    MYSQL_ROOT_PASSWORD=""
    MYSQL_KAM_DBNAME=$2

else

	MYSQL_ROOT_USERNAME="-u$1"
    MYSQL_ROOT_PASSWORD=-p$2
    MYSQL_KAM_DBNAME=$3
fi


install

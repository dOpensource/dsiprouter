PYTHON_CMD=python3.5

function install
{
		# Install dependencies for dSIPRouter
		apt-get -y install build-essential curl python3 python3-pip python-dev libmariadbclient-dev libmariadb-client-lgpl-dev libpq-dev firewalld

		#Setup Firewall for DSIP_PORT
		firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
		firewall-cmd --reload
	
		PIP_CMD="pip"
		$PYTHON_CMD -m ${PIP_CMD} install -r ./gui/requirements.txt
		if [ $? -eq 1 ]; then
			echo "dSIPRouter install failed: Couldn't install required libraries"
                	exit 1
        	fi
	
}

install

set -x
. $PWD/shared.sh

function startConsole {


	    docker run -it -p 8545:8545 -p 30303:30303 --name $NETWORKID -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable --rpc --rpcaddr "0.0.0.0" -networkid $NETWORKID --nodiscover --verbosity 4 console

	    if [ ! "$(docker ps -q -f name=$NETWORKID)" ]; then
	    	    docker start $NETWORKID
		    docker attach $NETWORKID
	    else
		docker run -it -p 8545:8545 -p 30303:30303 --name $NETWORKID -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable --rpc --rpcaddr "0.0.0.0" -networkid $NETWORKID --nodiscover --verbosity 4 console

	    fi    
}

if [ -z "$1" ];then
	echo "usage: $0 <NETWORKID>"
	echo "Please provide the NETWORKID of the docker image that contains the docker Ethereum network you want to join"
	exit
else
	NETWORKID=$1
fi

startConsole

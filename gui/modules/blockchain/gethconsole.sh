set -x
. ./gui/modules/blockchain/shared.sh

function startConsole {


	    docker run -it -p 8545:8545 -p 30303:30303 --name $NETWORKID -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable --rpc --rpcaddr "0.0.0.0" -networkid $NETWORKID --nodiscover --verbosity 4 console

    }

if [ -z "$1" ];then
	echo "usage: $0 <NETWORKID>"
	echo "Plese provide the NETWORKID of the Ethereum network that you want to join"
	exit
else
	NETWORKID=$1
fi

startConsole

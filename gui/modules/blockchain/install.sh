#!/bin/bash
#set -x
ENABLED=1
MODULEDIR=$PWD/gui/modules/blockchain
GETHDATADIR=$MODULEDIR/gethDataDir

function createGenesisFile {

GENESISFILE=`cat <<EOF
{
    "config": {
        "chainId": 88888,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
    "coinbase" : "0x0000000000000000000000000000000000000000",
    "difficulty" : "0x1",
    "extraData" : "0x00",
    "gasLimit" : "8000000",
    "nonce" : "0x0000000000000042",
    "mixhash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
    "parentHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
    "timestamp" : "0x00",
    "alloc" : {
        "$ACCOUNT": {"balance": "888888888888888888888888"}
    }
}
EOF
`
echo $GENESISFILE > $GETHDATADIR/genesis.json


}


function init {

    if [ -e $GETHDATADIR ]; then

	    rm -rf  $GETHDATADIR
    fi

    mkdir $GETHDATADIR
    cp $MODULEDIR/password.txt $GETHDATADIR
    
    #Download the geth docker image and generate an ethereum account
    ACCOUNT=$(docker run -it -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable account new --password /root/.ethereum/password.txt | sed '1,2d')

    #Parse out the account number
    ACCOUNT=`echo $ACCOUNT | cut -d " " -f 2 |  awk '{print substr($0,2,length($0)-3)}'`
    echo $ACCOUNT

    #Generate a GenesisFile based on the Account Number
    createGenesisFile

    #Initialize the block chain
    docker run -it -p 8545:8545 -p 30303:30303 -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable --rpc --rpcaddr "127.0.0.1" init /root/.ethereum/genesis.json



}

function startConsole {


    docker run -it -p 8545:8545 -p 30303:30303 -v $GETHDATADIR:/root/.ethereum ethereum/client-go:stable --rpc --rpcaddr "127.0.0.1" --networkid $NETWORKID --nodiscover --verbosity 4 console

}


function uninstall {

echo ""

}

function install {

if [ $ENABLED == "0" ];then
    exit
fi

init
NETWORKID=12345
startConsole
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

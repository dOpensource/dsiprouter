DATADIR=~/gethDataDir
PASSPHASE=testing
GETH_HOME=/root/go-ethereum
GENESISFILE=

#Make Data Directory
rm -rf $DATADIR
mkdir $DATADIR

#Create Password File

echo $PASSPHRASE > ~/password.txt

#Generate an account

ACCOUNT=`./go-ethereum/build/bin/geth account new --password ~/password.txt --datadir $DATADIR  2>/dev/null`

ACCOUNT=`echo $ACCOUNT | cut -d " " -f 2 | awk '{print substr($0,2,length($0)-2)}'`   


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
    "gasLimit" : "0x4000000",
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
echo $GENESISFILE > /root/genesis.json


}


#Build Genesis File

createGenesisFile
echo $ACCOUNT
echo $GENESISFILE

$GETH_HOME/build/bin/geth --datadir $DATADIR init /root/genesis.json


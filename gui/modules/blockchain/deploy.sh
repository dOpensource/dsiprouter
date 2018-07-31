#!/bin/sh
set -x
#. ./gui/modules/blockchain/shared.sh

#Check if Soldity is installed
#TODO

DAPPS=$(pwd)/dapps
TARGET=$(pwd)/gethDataDir
#TARGET=$(pwd)/target
APP=$1
APP_BASENAME=$(basename $APP .sol)

compile() {

	solc -o $TARGET --bin --abi --overwrite $DAPPS/$APP
}

createDeployScript() {


APP_ABI=$(cat $TARGET/$APP_BASENAME.abi)
APP_BYTECODE=$(cat $TARGET/$APP_BASENAME.bin)

echo "var $APP_BASENAME=eth.contract($APP_ABI);\n" > $TARGET/$APP_BASENAME.js
echo "var ${APP_BASENAME}Bytecode=\"0x$APP_BYTECODE\";\n" >>$TARGET/$APP_BASENAME.js 


echo "//Unlock acccount using password\n"  >>$TARGET/$APP_BASENAME.js 
echo "personal.unlockAccount(web3.eth.accounts[0], \"$(cat ./password.txt)\")\n"  >>$TARGET/$APP_BASENAME.js
echo "var ${APP_BASENAME}Gas = eth.estimateGas({data: ${APP_BASENAME}Bytecode});\n" >>$TARGET/$APP_BASENAME.js
echo "var ${APP_BASENAME}Deploy = {from:eth.coinbase, data:${APP_BASENAME}Bytecode, gas:${APP_BASENAME}Gas};\n" >>$TARGET/$APP_BASENAME.js
echo "var ${APP_BASENAME}PartialInstance = ${APP_BASENAME}.new(${APP_BASENAME}Deploy);\n" >>$TARGET/$APP_BASENAME.js

echo "miner.start()\n" >>$TARGET/$APP_BASENAME.js

}


deploy() {
	echo "Deploy Function"
	#deploy, mind the contract and spit out the address info

	docker exec $NETWORKID geth --exec "loadScript('/root/.ethereum/$APP_BASENAME.js')" attach
}


if [ "$#" -ne "2" ]; then

	echo "Usage: $0 <filename of solidity app> <networkid>\n"
	echo "No need to provide the directory.  The app must reside in $DAPPS\n"
else
	
	APP=$1
	NETWORKID=$2
	#By default compile and deploy on to blockchain
	compile
	createDeployScript
	deploy

fi


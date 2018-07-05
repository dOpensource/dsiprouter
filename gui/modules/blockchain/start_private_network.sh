DATADIR=/root/gethDataDir
cd go-ethereum
./build/bin/geth --fast --cache 512 --ipcpath /root/Library/Ethereum/geth.ipc --networkid 12345 --datadir $DATADIR --targetgaslimit '9000000000000' console

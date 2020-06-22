## Instructions

###  Assumption

- You have dSIPRouter installed


### Clone kam branch v5.3:

```
git clone https://github.com/kamailio/kamailio.git -b 5.3 /usr/local/src/kamailio
```

copy to src dir and compile:

```
mkdir /usr/local/src/kamailio/src/modules/dsiprouter
cp -rf ./ /usr/local/src/kamailio/src/modules/dsiprouter
cd /usr/local/src/kamailio/src/modules/dsiprouter
make
```

### copy to deployment location:

```
scp /usr/local/src/kamailio/src/modules/dsiprouter/dsiprouter.so root@somewhere.com:/usr/lib/x86_64-linux-gnu/kamailio/modules/dsiprouter.so 
```

load module in kamailio (/etc/kamailio/kamailio.cfg):

```
loadmodule "dsiprouter.so"
```

restart kamailio

```
systemctl restart kamailio
```


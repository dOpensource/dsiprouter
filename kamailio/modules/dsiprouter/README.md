## Instructions

### assumptions

- You have dSIPRouter and Kamailio installed


### clone your kamailio version's branch:

```
KAM_VERSION_FULL=$(kamailio -v 2>/dev/null | grep '^version:' | awk '{print $3}' | sed -e  's/\([0-9]\.[0-9]\)\.[0-9]/\1/')
rm -rf /tmp/kamailio 2>/dev/null
git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git /tmp/kamailio
```

### copy to src dir and compile:

```
DSIP_PROJECT_DIR=/opt/dsiprouter
cp -rf ${DSIP_PROJECT_DIR}/kamailio/modules/dsiprouter/ /tmp/kamailio/src/modules/
cd /tmp/kamailio/src/modules/dsiprouter
make
```

### copy to deployment location:

```
MPATH=$(grep mpath /etc/kamailio/kamailio.cfg | awk 'NR==2' | awk '{print $3}')
cp /tmp/kamailio/src/modules/dsiprouter/*.so $MPATH
```

### load module in kamailio (/etc/kamailio/kamailio.cfg):

```
loadmodule "dsiprouter.so"
```

### restart kamailio

```
systemctl restart kamailio
```

## Notes

- Anytime Kamailio is upgraded (even patch releases) you must recompile this module.

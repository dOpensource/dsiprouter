### dsiprouter.sh

- Do not put platform specific commands in this file.  Use the component/OS distribution/version.sh file to place those commands.

For example, if we need to install the Letsencrypt OS package so that it can be used for Kamailio on debian, then you would
place it in the kamailio/debian/9.sh and kamailio/debian/10.sh file

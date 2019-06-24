#!/usr/bin/env bash
#
# Summary: clean up / harden system before creating an image
#

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
getDisto() {
    cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2
}

# make sure all security updates are installed
if cmdExists 'apt'; then
    # grub updates adhere to ucf not debconf
    # make sure ucf defaults to unattended upgrade
    unset UCF_FORCE_CONFFOLD
    export UCF_FORCE_CONFFNEW=YES
    ucf --purge /boot/grub/menu.lst

    apt-get -y install perl
    apt-get -y update
    apt-get -y upgrade
    apt-get -y autoremove
    apt-get -y autoclean
elif cmdExists 'yum'; then
    yum -y install perl
    yum -y update
    yum -y upgrade
    yum -y autoremove
    yum -y clean all
fi

# harden sshd server configs
(cat <<'EOF'
# |== SSHD Server Settings ==|
Port 22
Protocol 2

# |== Log Settings ==|
SyslogFacility AUTH
LogLevel INFO

# |== Authentication Settings ==|
# we only allow pubkey auth using ssh protocol v2
PermitRootLogin no
StrictModes yes
# enable protocol v2 auth
PubkeyAuthentication yes
# disable protocol v1 auth
RSAAuthentication no
ChallengeResponseAuthentication no
PasswordAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
PermitEmptyPasswords no
# HostKeys for protocol v2
# see: man sshd_config for more details
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# |== Security Settings ==|
# Process is unprivileged until auth is complete
UsePrivilegeSeparation yes
# Make brute force attempts much harder
# NOTE: if you have many identity keys (>5) each one causes an auth attempt and this may cause auth failure
# clients with this issue need to specify the key explicitly for that host (on cmdline or in ~/.ssh/ssh_config)
# ex) ssh -o IdentitiesOnly=yes -i ~/.ssh/<your key>.pem <user>@<host>
MaxAuthTries 5
LoginGraceTime 60
# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# Don't allow remote host auth protocol v1
RhostsRSAAuthentication no
# Don't allow remote host auth protocol v2
HostbasedAuthentication no
# PAM is needed for some 2-factor auth solutions
UsePAM yes
# Some exploits have been published using X11 offsets
# so we disable it just in case
X11Forwarding no

# |== General sSettings ==|
PrintMotd yes
TCPKeepAlive yes
ClientAliveInterval 240
# Allow client to pass locale environment variable
AcceptEnv LANG LC_*
# Allow sftp over ssh
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
) > /etc/ssh/sshd_config

# don't aalow cloud-init's initial ssh module to overwrite our settings
perl -0777 -i -pe 's|(cloud_init_modules:.*?)\s-\sssh\s*\n(\n)|\1\2|gs' /etc/cloud/cloud.cfg

# remove logs and any information from build process
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.*history
unset HISTFILE
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
dd if=/dev/zero of=/zerofile 2> /dev/null; sync; rm -f /zerofile; sync
cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp

# ensure address space layout randomization (ASLR) is enabled
echo '2' > /proc/sys/kernel/randomize_va_space

# some debian-based systems may not regenerate host keys
# debian9 specifically has issues with this
dpkg-reconfigure -f noninteractive openssh-server

exit 0
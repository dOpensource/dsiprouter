#!/usr/bin/env bash
#
# Summary: find the correct hosts template for the current environment
#

case "$(cloud-init query distro)" in
alpine)
    echo '/etc/cloud/templates/hosts.alpine.tmpl'
    ;;
arch)
    echo '/etc/cloud/templates/hosts.arch.tmpl'
    ;;
debian|ubuntu)
    echo '/etc/cloud/templates/hosts.debian.tmpl'
    ;;
freebsd|dragonfly)
    echo '/etc/cloud/templates/hosts.freebsd.tmpl'
    ;;
gentoo|cos)
    echo '/etc/cloud/templates/hosts.gentoo.tmpl'
    ;;
netbsd)
    echo '/etc/cloud/templates/hosts.netbsd.tmpl'
    ;;
openbsd)
    echo '/etc/cloud/templates/hosts.openbsd.tmpl'
    ;;
almalinux|amazon|centos|cloudlinux|eurolinux|fedora|mariner|miraclelinux|openmandriva|photon|rhel|rocky|virtuozzo)
    echo '/etc/cloud/templates/hosts.redhat.tmpl'
    ;;
opensuse|opensuse-leap|opensuse-microos|opensuse-tumbleweed|sle_hpc|sle-micro|sles|suse)
    echo '/etc/cloud/templates/hosts.suse.tmpl'
    ;;
openeuler)
    echo '/etc/cloud/templates/hosts.openeuler.tmpl'
    ;;
OpenCloudOS|TencentOS)
    echo '/etc/cloud/templates/hosts.OpenCloudOS.tmpl'
    ;;
*)
    echo '/etc/cloud/templates/hosts.tmpl'
    ;;
esac

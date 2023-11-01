#!/usr/bin/env bash

#####################################
# dsiprouter command completion
#####################################

_dsiprouter() {
    COMPREPLY=( )
    local cur="${COMP_WORDS[$COMP_CWORD]}"
    local prev="${COMP_WORDS[$((COMP_CWORD-1))]}"
    local cmd="${COMP_WORDS[1]}"

    # available commands for dsiprouter <cmd>
    declare -a cmds=(
        install
        uninstall
        clusterinstall
        upgrade
        start
        stop
        restart
        chown
        configurekam
        configuredsip
        renewsslcert
	    configuresslcert
        installmodules
        resetpassword
        setcredentials
        help
        -h
        --help
        version
        -v
        --version
    )
    # available long options (with value) for each cmd
    declare -A llopts=(
        [install]='--database= --dsip-clusterid= --database-admin= --dsip-clustersync= --dsip-privkey= --with_lcr= --with_dev= --dmz= --network-mode='
        [uninstall]=''
        [clusterinstall]=''
        [upgrade]='--dsip-clusterid= --release= --repo-url='
        [start]=''
        [stop]=''
        [restart]=''
        [chown]=''
        [configurekam]=''
        [configuredsip]=''
        [renewsslcert]=''
        [configuresslcert]=''
        [installmodules]=''
        [resetpassword]=''
        [setcredentials]='--dsip-creds= --api-creds= --kam-creds= --mail-creds= --ipc-creds= --db-admin-creds= --session-creds='
        [help]=''
        [-h]=''
        [--help]=''
        [version]=''
        [-v]=''
        [--version]=''
    )
    # available long options (without value) for each cmd
    declare -A lopts=(
        [install]='--all --kamailio --dsiprouter --rtpengine'
        [uninstall]='--all --kamailio --dsiprouter --rtpengine'
        [clusterinstall]='--'
        [upgrade]=''
        [start]='--all --kamailio --dsiprouter --rtpengine'
        [stop]='--all --kamailio --dsiprouter --rtpengine'
        [restart]='--all --kamailio --dsiprouter --rtpengine'
        [chown]=''
        [configurekam]=''
        [configuredsip]=''
        [renewsslcert]=''
        [configuresslcert]='--force'
        [installmodules]=''
        [resetpassword]='--all --dsip-creds --api-creds --kam-creds --ipc-creds --force-instance-id'
        [setcredentials]=''
        [help]=''
        [-h]=''
        [--help]=''
        [version]=''
        [-v]=''
        [--version]=''
    )
    # available short options (with or without value) for each cmd
    declare -A sopts=(
        [install]='-debug -all -kam -dsip -rtp -db -dsipcid -dbadmin -dsipcsync -dsipkey -with_lcr -with_dev -dmz -netm -homer'
        [uninstall]='-debug -all -kam -dsip -rtp'
        [clusterinstall]='-debug -i'
        [upgrade]='-debug -dsipcid -rel -url'
        [start]='-debug -all -kam -dsip -rtp'
        [stop]='-debug -all -kam -dsip -rtp'
        [restart]='-debug -all -kam -dsip -rtp'
        [chown]='-debug -certs -dnsmasq -nginx -kamailio -dsiprouter -rtpengine'
        [configurekam]='-debug'
        [configuredsip]='-debug'
        [renewsslcert]='-debug'
        [configuresslcert]='-debug -f'
        [installmodules]='-debug'
        [resetpassword]='-debug -q -all -dc -ac -kc -ic -fid'
        [setcredentials]='-debug --dc -ac -kc -mc -ic -dac -sc'
        [help]=''
        [-h]=''
        [--help]=''
        [version]=''
        [-v]=''
        [--version]=''
    )

    # determine command being completed and generate possible values
    if [[ $({ for x in ${cmds[*]}; do [[ "$x" == "$cmd" ]] && echo "yes"; done; }) == "yes" ]]; then
        # special use cases
        if [[ "${cmd}" == "clusterinstall" && "${prev}" == "--" ]]; then
            cmd="install"
        fi

        # normal opt matching
        case "$cur" in
            --*)
                COMPREPLY=( $(compgen -W "${lopts[$cmd]}" -- ${cur}) $(compgen -o nospace -W "${llopts[$cmd]}" -- ${cur}) )
                ;;
            -*)
                COMPREPLY=( $(compgen -W "${sopts[$cmd]}" -- ${cur}) )
                ;;
        esac
    else
        COMPREPLY=( $(compgen -W "${cmds[*]}" -- ${cur}) )
    fi

    return 0
}
complete -F _dsiprouter dsiprouter

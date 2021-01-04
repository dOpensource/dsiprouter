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
        upgrade
        clusterinstall
        start
        stop
        restart
        configurekam
        renewsslcert
	    configuresslcert
        installmodules
        enableservernat
        disableservernat
        resetpassword
        setcredentials
        generatekamconfig
        updatekamconfig
        updatertpconfig
        updatednsconfig
        help
        -h
        --help
        version
        -v
        --version
    )
    # available long options (with value) for each cmd
    declare -A llopts=(
        [install]='--external-ip= --database= --dsip-clusterid= --database-admin= --dsip-clustersync= --dsip-privkey= --with_lcr= --with_dev='
        [uninstall]=''
        [upgrade]='--release='
        [clusterinstall]=''
        [start]=''
        [stop]=''
        [restart]=''
        [configurekam]=''
        [renewsslcert]=''
        [configuresslcert]=''
        [installmodules]=''
        [enableservernat]=''
        [disableservernat]=''
        [resetpassword]=''
        [setcredentials]='--dsip-creds= --api-creds= --kam-creds= --mail-creds= --ipc-creds= --db-admin-creds='
        [generatekamconfig]=''
        [updatekamconfig]=''
        [updatertpconfig]=''
        [updatednsconfig]=''
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
        [upgrade]=''
        [clusterinstall]='--'
        [start]='--all --kamailio --dsiprouter --rtpengine'
        [stop]='--all --kamailio --dsiprouter --rtpengine'
        [restart]='--all --kamailio --dsiprouter --rtpengine'
        [configurekam]=''
        [renewsslcert]=''
        [configuresslcert]='--force'
        [installmodules]=''
        [enableservernat]=''
        [disableservernat]=''
        [resetpassword]='--all --dsip-creds --api-creds --kam-creds --ipc-creds --force-instance-id'
        [setcredentials]=''
        [generatekamconfig]=''
        [updatekamconfig]=''
        [updatertpconfig]=''
        [updatednsconfig]=''
        [help]=''
        [-h]=''
        [--help]=''
        [version]=''
        [-v]=''
        [--version]=''
    )
    # available short options (without value) for each cmd
    declare -A sopts=(
        [install]='-debug -servernat -all -kam -dsip -rtp -exip -db -dsipcid -dbadmin -dsipcsync -dsipkey -with_lcr -with_dev'
        [uninstall]='-debug -all -kam -dsip -rtp'
        [upgrade]='-debug'
        [clusterinstall]='-debug'
        [start]='-debug -all -kam -dsip -rtp'
        [stop]='-debug -all -kam -dsip -rtp'
        [restart]='-debug -all -kam -dsip -rtp'
        [configurekam]='-debug -servernat'
        [renewsslcert]='-debug'
        [configuresslcert]='-debug -f'
        [installmodules]='-debug'
        [enableservernat]='-debug'
        [disableservernat]='-debug'
        [resetpassword]='-debug -all -dc -ac -kc -ic -fid'
        [setcredentials]='-debug --dc -ac -kc -mc -ic -dac'
        [generatekamconfig]='-debug'
        [updatekamconfig]='-debug'
        [updatertpconfig]='-debug -servernat'
        [updatednsconfig]='-debug'
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

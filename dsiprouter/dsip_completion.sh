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
        start
        stop
        restart
        configurekam
        renewsslcert
        installmodules
        enableservernat
        disableservernat
        resetpassword
        setcredentials
        setkamdbconfig
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
        [install]='--external-ip= --database= --dsip-clusterid= --dsip-clustersync= --dsip-privkey= --with_lcr= --with_dev='
        [uninstall]=''
        [clusterinstall]=''
        [start]=''
        [stop]=''
        [restart]=''
        [configurekam]=''
        [renewsslcert]=''
        [installmodules]=''
        [enableservernat]=''
        [disableservernat]=''
        [resetpassword]=''
        [setcredentials]='--dsip-user= --dsip-creds= --api-creds= --kam-user= --kam-creds= --mail-user= --mail-creds= --ipc-creds='
        [setkamdbconfig]=''
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
        [clusterinstall]='--'
        [start]=''
        [stop]=''
        [restart]=''
        [configurekam]=''
        [renewsslcert]=''
        [installmodules]=''
        [enableservernat]=''
        [disableservernat]=''
        [resetpassword]='--all --dsip-creds --api-creds --kam-creds --ipc-creds --force-instance-id'
        [setcredentials]=''
        [setkamdbconfig]=''
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
        [install]='-debug -servernat -all -kam -dsip -rtp -exip -db -dsipcid -dsipcsync -dsipkey -with_lcr -with_dev'
        [uninstall]='-debug -all -kam -dsip -rtp'
        [clusterinstall]='-debug'
        [start]='-debug'
        [stop]='-debug'
        [restart]='-debug'
        [configurekam]='-debug -servernat'
        [renewsslcert]='-debug'
        [installmodules]='-debug'
        [enableservernat]='-debug'
        [disableservernat]='-debug'
        [resetpassword]='-debug -all -dc -ac -kc -ic -fid'
        [setcredentials]='-debug -du -dc -ac -ku -kc -mu -mc -ic'
        [setkamdbconfig]='-debug'
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

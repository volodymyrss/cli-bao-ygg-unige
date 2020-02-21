#!/bin/bash

action=${1:-bao-login}

shift
args=$@

function bao-get-config() {
    path=${1:?}
    v=$(< $HOME/.local/etc/bao/bao.yaml yq -r $path)
    eval echo $v
}


function bao-store-fact() {
    fact=${1:?}

    fn=$HOME/.local/state/bao/$fact

    mkdir -pv $(dirname $fn)

    date > $fn
}

function bao-ask-fact() {
    fact=${1:?}

    fn=$HOME/.local/state/bao/$fact

    [ -s $fn ]
}



function bao-mount() {
    mountpoint=$(bao-get-config .sshfs_mountpoint)
    echo "mounting as $mountpoint"
    fusermount -u $mountpoint || echo 'can not unmount'
    mkdir -pv $mountpoint
    sshfs baobab2.unige.ch:/ $mountpoint -o ssh_command='sshpass -f '<(keyring get unige savchenk)' ssh';
}

function bao-login() {
    sshpass -f <(keyring get unige savchenk) ssh -Y baobab2.unige.ch $@;
}


function bao-update-env() { 
    bao_env_version=$(find $HOME/.local/share/bao -type f -exec md5sum {} \; | md5sum | cut -c1-8)

    fact=remote-env-installed/$bao_env_version

    if bao-ask-fact $fact; then
        echo "bao remotely available $fact"
    else
        echo "bao not remotely available $fact, installing"
        bao mkdir -pv env
        (cd $HOME/.local/share/bao; ls -ltor; tar cvf - init.sh sync.sh ssh-config | bao "tar xvf - -C env")
        bao 'mv env/ssh-config ~/.ssh/config'
        bao-store-fact $fact
    fi
}

function bao-upload-image() {
    bao-upload-image.sh
}

function bao-sync-data-rev() {
    bao bash env/sync.sh sync-rev $REVNUM $DATALEVEL
}


function bao-sync-ic() {
    bao bash env/sync.sh sync-ic 
}


function bao-pull() {
    pattern=${1:?}

    bao tar cvzf - scratch/data/reduced/ddcache/$pattern | tar xvzf - -C $(bao-get-config .local_ddcache) --strip-components=4
}

function bao-list-functions() {
    ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    < $ABSOLUTE_PATH awk -F'[ (]' '/function bao-/ {print $2}'
}


if echo $action | grep ^bao-; then
    $action $args
    #${action//bao-/} $args
else
    bao-login $action $args
fi

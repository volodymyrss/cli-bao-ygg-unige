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


function bao-upload-dir() {
    local_dir=${1:?}
    remote_dir=${2:?}

    bao mkdir -pv $remote_dir
    (cd $local_dir; ls -ltor; tar cvf - * | bao "tar xvf - -C $remote_dir")
}

function bao-download-dir() {
    remote_dir=${1:?}
    local_dir=${2:?}

    bao tar cvzf - $remote_dir | tar xvzf - -C $local_dir --strip-components=4
}

function bao-update-env() { 
    bao_env_version=$(find $HOME/.local/share/bao -type f -exec md5sum {} \; | md5sum | cut -c1-8)

    fact=remote-env-installed/$bao_env_version

    if bao-ask-fact $fact; then
        echo "bao remotely available $fact"
    else
        echo "bao not remotely available $fact, installing"
        bao mkdir -pv env
        bao-upload-dir $HOME/.local/share/bao env
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

    bao-download-dir scratch/data/reduced/ddcache/$pattern  $(bao-get-config .local_ddcache)
}

function bao-list-functions() {
    ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    < $ABSOLUTE_PATH awk -F'[ (]' '/function bao-/ {print $2}'
}

function bao-upload-workflow() {
    workflow_dir=${1:?}
    workflow_dir=$(realpath $workflow_dir)

    workflow_version=$(find $workflow_dir -type f -exec md5sum {} \; | md5sum | cut -c1-8)

    workflow_remote_path=workflows/$(basename $workflow_dir)/$workflow_version

    fact=uploaded/$workflow_remote_path

    if bao-ask-fact $fact; then
        echo "already uploaded"
    else
        echo "workflow $workflow_dir version/hash $workflow_version to $workflow_remote_path"

        bao-upload-dir $workflow_dir $workflow_remote_path
        bao-store-fact $fact
    fi

    #for t0 in $(cat utc-gbm.json | shuf -n 10); do t0=$t0 bash submit.sh ; done
}


function bao-submit-array() {
    arglist=${1:?}

    for t0 in $(cat utc-gbm.json | shuf -n 10); do t0=$t0 bash submit.sh ; done
}


if echo $action | grep ^bao-; then
    $action $args
    #${action//bao-/} $args
else
    bao-login $action $args
fi

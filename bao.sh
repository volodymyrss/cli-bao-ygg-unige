#!/bin/bash

action=${1:-login}

shift
args=$@

function get-config() {
    path=${1:?}
    v=$(< $HOME/.local/etc/bao/bao.yaml yq -r $path)
    eval echo $v
}



function mount() {
    mountpoint=$(get-config .sshfs_mountpoint)
    echo "mounting as $mountpoint"
    fusermount -u $mountpoint || echo 'can not unmount'
    mkdir -pv $mountpoint
    sshfs baobab2.unige.ch:/ $mountpoint -o ssh_command='sshpass -f '<(keyring get unige savchenk)' ssh';
}

function login() {
    sshpass -f <(keyring get unige savchenk) ssh -Y baobab2.unige.ch $@;
}

$action $args

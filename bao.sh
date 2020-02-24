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
    sshfs baobab2.unige.ch:/ $mountpoint -o ssh_command='sshpass -f '<(keyring get unige $(whoami))' ssh';
}

function bao-login() {
    sshpass -f <(keyring get unige $(whoami)) ssh -Y baobab2.unige.ch $@;
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
    bao bash env/sync.sh sync-rev ${1:?} ${2:-cons}
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

    bao-update-env

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
        
    echo "$ workflow_remote_path: $workflow_remote_path" 


    #for t0 in $(cat utc-gbm.json | shuf -n 10); do t0=$t0 bash submit.sh ; done
}

function bao-run-workflow() {
    workflow_dir=${1:?}
    setenv=${2:-}

    bao-upload-workflow $workflow_dir 
    workflow_remote_path=$(bao-upload-workflow $workflow_dir | awk '/^\$/ {print substr($0,2,length($0))}' | yq -r .workflow_remote_path)
    workflow_cmd=$(< $workflow_dir/oda.yaml yq -r .entrypoint)

    echo "export $setenv; $workflow_cmd" | bao "cat -> $workflow_remote_path/auto-entrypoint.sh"
    bao "cat $workflow_remote_path/auto-entrypoint.sh"
    bao "cd $workflow_remote_path; bash auto-entrypoint.sh" 
}

function bao-submit-array() {
    workflow_dir=${1:?}
    argvar=${2:?}
    arglist=${3:?}

    echo "submitting to ${partition:=mono-shared-EL7}"

    workflow_remote_path=$(bao-upload-workflow $workflow_dir | awk '/^\$/ {print substr($0,2,length($0))}' | yq -r .workflow_remote_path)

    taskid=${taskid:-$(date +%s)}
    taskdir=$workflow_remote_path/arrays/$taskid

    bao mkdir -pv $taskdir/logs

    < $arglist awk '{print "export '$argvar'="$1}' | bao "cat -> $taskdir/envlist.sh"

    
    echo "
        export JOB_DIR=\$HOME/$workflow_remote_path
        cd $taskdir
        i=0
        while IFS="" read -r p;  do (
            echo \$p
            sp=\$(echo \$p | awk '{print \$2}' | sed 's/[^a-zA-Z0-9 -]/_/g')
            dgst=\$(echo \$p | md5sum | cut -c 1-8)
            echo "job \$sp, \$dgst"

            eval \$p

            export logfile=\$HOME/$taskdir/logs/\${dgst}-\${sp}

            sbatch --mem-per-cpu 16000  --partition ${partition} --export=ALL --output \$logfile \$HOME/$workflow_remote_path/submit.sh
        ); let 'i++'; done < envlist.sh 
    " | bao "cat -> $taskdir/submit-array.sh"

    bao cat $taskdir/submit-array.sh
    bao cat $taskdir/envlist.sh

    bao bash $taskdir/submit-array.sh
}


function bao-upload-images() {
    pattern=${1:?}

    bao mkdir -pv scratch/singularity

    for fn in /data/singularity/*/$pattern; do
        cat $fn | pv  | bao "cat - > scratch/singularity/$(basename $fn)"
    done
}

function bao-tail-last-job() {
    bao 'tail -n 100 -f $(ls -tr workflows/*/*/*/*/*/* | tail -1) '
}

function bao-less-last-job() {
    bao 'cat  $(ls -tr workflows/*/*/*/*/*/* | tail -1) ' | less -R
}

function bao-last-logs() {
    patt=${1:?}
    bao 'find workflows -name \*'"${patt}"'\*  | xargs ls -ltro'
}

function bao-get-logs() {
    patt=${1:?}
    log=$(bao 'find workflows -name \*'"${patt}"'\*  | xargs ls -tr | tail -1')
    echo "found $log"
    bao "cat $log" 
}

function bao-squeue() {
    bao squeue -u $(whoami)
}


if echo $action | grep ^bao-; then
    $action $args
    #${action//bao-/} $args
else
    bao-login $action $args
fi

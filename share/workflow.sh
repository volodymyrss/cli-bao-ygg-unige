#!/bin/bash

source $HOME/env/init.sh

function report-action() {
    action=${1:-}
    extra_json=${2:-}

    echo "extra_json $extra_json"

    jwt=$(cat $HOME/.dataapi-jwt)
    curl  https://data.odahub.io/secure/log --cookie "rampartjwt=${jwt}" --data '
{
    '"$extra_json"'
    "source": "'${workflow_source}'", 
    "action":"'$action'", 
    "jobid": "'$JOB_ID'",
    "hostname": "'$(hostname)'"
}
' -H 'Content-Type: application/json'
}



function run() {
    workflow_dir=${1:?}

    echo "workflow engine args: $@"

    (cd $workflow_dir && bash auto-entrypoint.sh)
}

function run-action() {
    action_name=${1:?}
    shift 1
    action_cmd=$@

    echo "running $action_name as $action_cmd"

    $action_cmd
}

$@

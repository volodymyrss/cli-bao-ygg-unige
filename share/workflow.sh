#!/bin/bash

source $HOME/env/init.sh

function report-action() {
    action=${1:-}
    event=${2:-}
    extra_json=${3:-}

    echo "extra_json $extra_json"

    jwt=$(cat $HOME/.dataapi-jwt)

    #TODO: recover
    echo curl  https://data.odahub.io/secure/log --cookie "rampartjwt=${jwt}" --data '
{
    '"$extra_json"'
    "source": "'${workflow_source}'", 
    "event": "'${event}'",
    "action":"'$action'", 
    "jobid": "'$JOB_ID'",
    "hostname": "'$(hostname)'"
}
' -H 'Content-Type: application/json'
}



function run() {
    cmd=$@
    

#    workflow_dir=${1:?}

    echo "workflow engine args: $cmd"

    ($cmd)

#    (cd $workflow_dir && bash auto-entrypoint.sh)
}


function action-version() {
    code=${1:?}
    name=${2:?}

    < $code awk -F= '/^'$name'_version=/ {print $2}' | head -1
}

function run-action() {
    action_name=${1:?name}
    action_version=${2:?version}
    shift 2
    action_cmd=$@

    export ODA_ACTION_OUTPUT_PATH="$DDCACHE_ROOT/$(bash ${ODA_WORKFLOW_PATH}/oda-cache.sh $action_name/$action_version)"
    echo "action output path: $ODA_ACTION_OUTPUT_PATH"

    report-action $action_name starting

    tstart=$(date +%s)

    ! [ -z $WORKFLOW_OUTPUT ] || echo "WORKFLOW_OUTPUT not set"
    [ -s $ODA_ACTION_OUTPUT_PATH/$WORKFLOW_OUTPUT ] || echo "missing cache in $ODA_ACTION_OUTPUT_PATH/$WORKFLOW_OUTPUT"

    if ! [ -z $WORKFLOW_OUTPUT ] && [ -s $ODA_ACTION_OUTPUT_PATH/$WORKFLOW_OUTPUT ]; then
        echo "output already exists in $ODA_ACTION_OUTPUT_PATH/$WORKFLOW_OUTPUT, no need to run"
    else
        echo "no output yet. will run"

        echo -e "\e[36mrunning $action_name as \"$action_cmd\"\e[0m"

        ($action_cmd)

        exitcode=$?

        tstop=$(date +%s)

        let 'tspent_s=tstop-tstart'

        echo "action exited with code $exitcode in $tspent_s"

        tspent_json='"tspent_s":'$tspent_s','




        if [ "$exitcode" == "0" ]; then
            cache=""

            if [ -z $WORKFLOW_OUTPUT ]; then
                echo "no output required"
            else
                if [ -s $WORKFLOW_OUTPUT ]; then
                    echo "found output in $WORKFLOW_OUTPUT"
                    CP=${ODA_ACTION_OUTPUT_PATH}/$WORKFLOW_OUTPUT
                    echo "storing to $CP"
                    mkdir -pv ${ODA_ACTION_OUTPUT_PATH}
                    cat $WORKFLOW_OUTPUT > $CP
                    ls -l $CP

                    cache=$CP
                    output_size=$(stat -c "%s" $CP)
                else
                    echo "no output found in $WORKFLOW_OUTPUT"
                fi
            fi

            report-action $action_name finished $tspent_json' "cache":"'$cache'", "output_size":'$output_size','

        else
            report-action $action_name failed $tspent_json
        fi
    fi
    
    # store stats, inputs, cachc
}

$@

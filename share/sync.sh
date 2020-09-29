source $HOME/env/init.sh

function sync-rev-cons() {
    orbit=${1:?}
    mkdir -pv $REP_BASE_PROD/scw/$orbit
    mkdir -pv $REP_BASE_PROD/aux/adp/$orbit.001

    rsync -avu login01.astro.unige.ch:/isdc/arc/rev_3/scw/$orbit/ $REP_BASE_PROD/scw/$orbit/
    rsync -avu login01.astro.unige.ch:/isdc/arc/rev_3/aux/adp/$orbit.001/ $REP_BASE_PROD/aux/adp/$orbit.001/
    rsync -avu login01.astro.unige.ch:/isdc/arc/rev_3/aux/adp/ref/ $REP_BASE_PROD/aux/adp/ref/
}

function sync-rev-nrt() {
    orbit=${1:?}
    mkdir -pv $REP_BASE_PROD_NRT/scw/$orbit
    mkdir -pv $REP_BASE_PROD_NRT/aux/adp/$orbit.000
    mkdir -pv $REP_BASE_PROD_NRT/aux/adp/$orbit.001

    rsync -avu isdc-in01:/isdc/pvphase/nrt/ops/scw/$orbit/ $REP_BASE_PROD_NRT/scw/$orbit/
    rsync -avu isdc-in01:/isdc/pvphase/nrt/ops/aux/adp/$orbit.000/ $REP_BASE_PROD_NRT/aux/adp/$orbit.000
    rsync -avu login01.astro.unige.ch:/isdc/arc/rev_3/aux/adp/ref/ $REP_BASE_PROD_NRT/aux/adp/ref/
}

function sync-rev() {
    orbit=${1:?}
    datalevel=${2:?}
    
    if [ "$datalevel" == "nrt" ]; then
        sync-rev-nrt $orbit
    elif [ "$datalevel" == "cons" ]; then
        sync-rev-cons $orbit
    fi
}

function sync-ic() {
    rsync -Lzrtv isdcarc.unige.ch::arc/FTP/arc_distr/ic_tree/prod/ $REP_BASE_PROD
}

$@

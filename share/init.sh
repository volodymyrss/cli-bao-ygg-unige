module load GCCcore/8.2.0 Singularity/3.4.0-Go-1.12

export SINGULARITY_LOCAL_REPO=/srv/beegfs/scratch/users/s/savchenk/singularity/
export SINGULARITY_SHARED_REPO=/srv/beegfs/scratch/shares/astro/integral/singulariy/

export DATA_ROOT=/srv/beegfs/scratch/shares/astro/integral/data/

export REP_BASE_PROD=$DATA_ROOT/rev_3
export REP_BASE_PROD_NRT=$DATA_ROOT/nrt

export DDCACHE_ROOT=$DATA_ROOT/reduced/ddcache

chmod +x $HOME/env/workflow.sh
(cd $HOME/env; cp -f workflow.sh workflow)

export PATH=$HOME/env:$PATH



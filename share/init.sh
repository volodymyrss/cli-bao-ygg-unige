module load GCCcore/8.2.0 Singularity/3.4.0-Go-1.12

export REP_BASE_PROD=$HOME/scratch/data/integral
export REP_BASE_PROD_NRT=$HOME/scratch/data/integral-nrt

export SINGULARITY_LOCAL_REPO=/srv/beegfs/scratch/users/s/savchenk/singularity/
#export SINGULARITY_LOCAL_REPO=$HOME/scratch/singularity/
export DATA_ROOT=/srv/beegfs/scratch/users/s/savchenk/data/

export DDCACHE_ROOT=$DATA_ROOT/reduced/ddcache

chmod +x $HOME/env/workflow.sh
(cd $HOME/env; ln -fs workflow.sh workflow)

export PATH=$HOME/env:$PATH



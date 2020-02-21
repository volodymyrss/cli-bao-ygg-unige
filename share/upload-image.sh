set -x

bao mkdir -pv scratch/singularity

for fn in /data/singularity/spiacs-detection/*; do
    cat $fn | pv  | bao "cat - > scratch/singularity/$(basename $fn)"
done

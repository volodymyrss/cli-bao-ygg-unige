echo "updating env"

bao mkdir -pv env
tar cvf - init.sh sync.sh | bao "tar xvf - -C env"

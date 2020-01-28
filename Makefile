VERSION=$(shell git describe --tags)

install: bao.sh
	install -m +x -v bao.sh $$HOME/.local/bin/bao

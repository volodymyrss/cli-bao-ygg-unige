VERSION=$(shell git describe --tags)

install: bao.sh bao.yaml
	install -m 755 -v bao.sh $$HOME/.local/bin/bao
	install -v -d $$HOME/.local/etc/bao/
	install -m 400 -v bao.yaml $$HOME/.local/etc/bao/bao.yaml
	for f in $(shell ls share); do \
            install -m 400 -v share/$$f $$HOME/.local/share/bao/$$f; \
	done
    

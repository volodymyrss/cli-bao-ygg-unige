VERSION=$(shell git describe --tags)

install: bao.sh bao.yaml
	mkdir -p $$HOME/.local/bin $$HOME/.local/etc/bao $$HOME/.local/share/bao
	rm -v $$HOME/.local/bin/bao-* || true
	install -m 755 -v bao.sh $$HOME/.local/bin/bao
	install -m 755 -v gentoken.py $$HOME/.local/bin/bao-gentoken
	install -v -d $$HOME/.local/etc/bao/
	install -m 400 -v bao.yaml $$HOME/.local/etc/bao/bao.yaml
	for f in $(shell ls share); do \
            install -m 400 -v share/$$f $$HOME/.local/share/bao/$$f; \
	done
	echo "export BAOBAB_LOGIN_NODE=login1.yggdrasil.hpc.unige.ch; bao "'$$@' > $$HOME/.local/bin/ygg
	chmod +x $$HOME/.local/bin/ygg
	for fn in $(shell bash bao.sh bao-list-functions | sort -u | grep ^bao); do \
            echo "bao $$fn "'$$@' > $$HOME/.local/bin/$$fn; \
	    chmod +x $$HOME/.local/bin/$$fn; \
        done
	for fn in $(shell bash bao.sh bao-list-functions | sort -u | grep ^bao | sed 's/bao/ygg/'); do \
            echo "bao $$fn "'$$@' > $$HOME/.local/bin/$$fn; \
	    chmod +x $$HOME/.local/bin/$$fn; \
        done

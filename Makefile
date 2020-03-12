VERSION=$(shell git describe --tags)

install: bao.sh bao.yaml
	rm -v $$HOME/.local/bin/bao-* || true
	install -m 755 -v bao.sh $$HOME/.local/bin/bao
	install -m 755 -v gentoken.py $$HOME/.local/bin/bao-gentoken
	install -v -d $$HOME/.local/etc/bao/
	install -m 400 -v bao.yaml $$HOME/.local/etc/bao/bao.yaml
	for f in $(shell ls share); do \
            install -m 400 -v share/$$f $$HOME/.local/share/bao/$$f; \
	done
	for fn in $(shell bash bao.sh bao-list-functions | sort -u | grep ^bao); do \
            echo "bao $$fn "'$$@' > $$HOME/.local/bin/$$fn; \
	    chmod +x $$HOME/.local/bin/$$fn; \
        done
    

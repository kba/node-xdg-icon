VERSION = $(shell cat .version)
PKGNAME = $(shell grep name package.json |/bin/grep -o '[^"]*",'|/bin/grep -o '[^",]*')

PANDOC = pandoc -s -t man 
NPM = npm
COFFEE_COMPILE = coffee -c

MKDIR = mkdir -p
MKTEMP = mktemp -d --tmpdir "make-$(PKGNAME)-XXXXXXX"
RM = rm -rf
LN = ln -fsrv
CP = cp -r

BIN_TARGETS = $(shell find src/bin -type f -name "*.*" |sed 's,src/,,'|sed 's,\.[^\.]\+$$,,')
MAN_TARGETS = $(shell find src/man -type f -name "*.md"|sed 's,src/,,'|sed 's,\.md$$,.gz,')
COFFEE_TARGETS = $(shell find src/lib -type f -name "*.coffee"|sed 's,src/,,'|sed 's,\.coffee,\.js,')

.PHONY: clean

lib: ${COFFEE_TARGETS}

lib/%.js: src/lib/%.coffee
	@$(MKDIR) $(dir $@)
	$(COFFEE_COMPILE) -p -b $^ > $@

clean:
	$(RM) lib

bin: $(BIN_TARGETS)

bin/%: src/bin/%.*
	@$(MKDIR) bin
	$(CP) $< $@
	chmod a+x $@

man: ${MAN_TARGETS}

man/%.gz : src/man/%.md
	@$(MKDIR) man
	$(PANDOC) $< |gzip > $@

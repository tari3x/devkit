
VERSION=$(shell git describe --always --long)

ifndef VERSION
VERSION=v0.5.2
endif

.PHONY: build lib top doc clean install uninstall test gen

INSTALL_FILES=$(filter-out \
  _build/myocamlbuild% _build/test.cm%, \
  $(wildcard _build/*.cmx* _build/*.cmi _build/*.mli _build/*.ml _build/*.cma _build/*.cmt* \
						 _build/*.lib _build/*.a _build/*.dll _build/*.so))

OCAMLBUILD=ocamlbuild -use-ocamlfind -no-links -j 0

target: build

gen: devkit_ragel.ml

%.ml: %.ml.rl
		ragel -O -F1 $< -o $@

build: lib top build-test

EXTRA_TARGETS := $(shell ocamlfind query gperftools -format "devkit_gperftools.cma devkit_gperftools.cmxa" 2> /dev/null)
EXTRA_TARGETS += $(shell ocamlfind query jemalloc_ctl -format "devkit_jemalloc.cma devkit_jemalloc.cmxa" 2> /dev/null)

lib:
		$(OCAMLBUILD) $(BUILDFLAGS) devkit.cma devkit.cmxa $(EXTRA_TARGETS)

top:
		$(OCAMLBUILD) $(BUILDFLAGS) devkit.top

build-test:
		$(OCAMLBUILD) $(BUILDFLAGS) test.byte test.native

test: build-test
		_build/test.native

doc:
		$(OCAMLBUILD) devkit.docdir/index.html

install: lib
		ocamlfind install -patch-version "$(VERSION:v%=%)" devkit META $(sort $(INSTALL_FILES))

uninstall:
		ocamlfind remove devkit

reinstall:
		$(MAKE) uninstall
		$(MAKE) install

clean:
		ocamlbuild -clean

distclean: clean

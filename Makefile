MODULES=schedule classRoster command main
OBJECTS=$(MODULES:=.cmo)
MLS=$(MODULES:=.ml)
MLIS=$(MODULES:=.mli)
MAIN=main.byte
OCAMLBUILD=ocamlbuild -use-ocamlfind -plugin-tag 'package(bisect_ppx-ocamlbuild)'
PKGS=unix,oUnit,str,qcheck,curl,ansiterminal

default: build
	utop

build:
	$(OCAMLBUILD) $(OBJECTS)

check:
	bash checkenv.sh

run: build
	$(OCAMLBUILD) $(MAIN) && ./$(MAIN)
	
clean:
	ocamlbuild -clean
	rm -rf doc.public doc.private report scheduler_src.zip bisect*.out

PONYC ?= ponyc

build/maybe: build maybe/*.pony
	stable env $(PONYC) maybe -o build --debug

build:
	mkdir build

test: build/maybe
	build/maybe

clean:
	rm -rf build

.PHONY: clean test

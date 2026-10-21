.PHONY: all dev

all:
	sitegen

dev:
	sitegen deploy leaf@leafo.net www/moonscript.org/dev/

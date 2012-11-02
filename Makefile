
all:
	sitegen

%.js: %.coffee
	coffee -c $+

js:
	coffee -o www -w -c *.coffee

static: www/reference/index.html
	mkdir -p static
	./pack_html.js $+ > moonscript/docs/reference_manual.html

dev:
	sitegen deploy leaf@leafo.net www/moonscript.org/dev/

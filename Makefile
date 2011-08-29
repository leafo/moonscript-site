
all: highlight.js client.js
	moon site.moon

%.js: %.coffee
	coffee -c $+

js:
	coffee -o www -w -c *.coffee

static: www/reference/index.html
	mkdir -p static
	./pack_html.js $+ > moonscript/docs/reference_manual.html

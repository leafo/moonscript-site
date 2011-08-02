
all: highlight.js client.js
	moon site.moon

%.js: %.coffee
	coffee -c $+

js:
	coffee -o www -w -c *.coffee

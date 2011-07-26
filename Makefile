
all: highlight.js
	moon site.moon

highlight.js: highlight.coffee
	coffee -c $+

js:
	coffee -o www -w -c *.coffee

#!/usr/bin/env phantomjs

var page = new WebPage();

page.onConsoleMessage = function(msg) {
	console.log(msg);
}

if (phantom.args.length == 0) {
	console.log("Usage: ./pack_html.js input.html > packed.html")
	phantom.exit();
}

var url = phantom.args[0];
page.open(url, function(status) {
	if (status != "success") {
		console.error("Failed to open["+status+"]: " + url);
		phantom.exit()
	}

	var html = page.evaluate(function() {
		function remove(node) {
			node.parentElement.removeChild(node);
		}

		function get_content(url, response) {
			r = new XMLHttpRequest();
			r.open("GET", url, false);
			r.send();
			return r.responseText;
		}

		var scripts = document.getElementsByTagName("script");
		while (scripts.length > 0) {
			remove(scripts[0]);
		}

		var styles = document.getElementsByTagName("link");
		var to_remove = [];
		for (var i = 0; i < styles.length; i++) {
			var s = styles[i];
			if (s.getAttribute('rel') == "stylesheet") {
				var href = s.getAttribute('href');
				to_remove.push([styles[i], get_content(s.getAttribute('href'))]);
			}
		}

 		for (var i = 0; i < to_remove.length; i++) {
 			var node = to_remove[i][0], css = to_remove[i][1];
 			var style = document.createElement("style");
 			style.setAttribute("type", "text/css");
 			style.innerHTML = css;
 			node.parentElement.insertBefore(style, node);
 			remove(node);
 		}
 
		return document.documentElement.innerHTML;
	});

	html = '<!DOCTYPE HTML>\n<html lang="en">\n' + html + "\n</html>"
	console.log(html);
	phantom.exit();
});


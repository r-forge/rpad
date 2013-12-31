// Rpad_head.js: to be included in head section of an Rpad HTML document
// This loads Dojo in the HTML head so that all modules are available by the time Rpad_body.js is loaded

// Dojo configuration
// async: true is suggested for Dojo > 1.7 (http://dojotoolkit.org/documentation/tutorials/1.8/hello_dojo/)
// parseOnLoad: true enables declarative instantiation of widgets - absolutely needed in our case!
// (http://dojotoolkit.org/reference-guide/1.8/dojo/parser.html)

// load Dojo
document.write('<script src="dojo.js" data-dojo-config="async: true, parseOnLoad: true"></script>');

// also a good time to load Rpad CSS
document.write('<style type="text/css" rpadIgnore="true">@import url(Rpad.css);</style>');

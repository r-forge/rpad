/**
 * Basic application build profile to make a Dojo layer with specified modules
 */

var profile = {
	basePath: 'src/',
        releaseDir: '../dist/',
	action: 'release',
	cssOptimize: 'comments',
	mini: true,
        // only for modules that aren't part of a layer (none here)
	optimize: false,
        // for distribution, set to 'closure'; for easier debugging, set to false
	//layerOptimize: false,
	layerOptimize: 'closure',
	stripConsole: 'all',
	selectorEngine: 'acme',
        packages: [ 'dojo', 'dijit' ],
	layers: {
		'dojo/dojo': {
                        // this is customized to include all the dependencies of Rpad
			include: [ // modules recommended by the Dojo boilerplate
                                   // https://github.com/csnover/dojo-boilerplate
                                   'dojo/i18n', 'dojo/domReady',
                                   // widget-defining stuff
                                   'dojo/_base/declare', 'dojo/dom-construct', 'dojo/parser', 'dojo/ready',
                                   'dijit/_WidgetBase', 'dojo/_base/window', 'dijit/_TemplatedMixin',
                                   // network stuff
                                   'dojo/request',
                                   // widget-finding stuff
                                   'dijit/registry',
                                   // not Rpad-specific ... but good fun
                                   'dojo/fx', 'dojo/fx/Toggler'
                        ],
			boot: true,
                        // we might not want customBase since it can possibly take out too much
                        // http://dojotoolkit.org/reference-guide/1.9/build/customBase.html
			customBase: true
		},
	},

	staticHasFeatures: {
		'dojo-trace-api': 0,
		'dojo-log-api': 0,
		'dojo-publish-privates': 0,
		'dojo-sync-loader': 0,
		'dojo-xhr-factory': 0,
		'dojo-test-sniff': 0,
                // some others found in build --check that seem ok to turn off
                'dojo-config-require': 0,
                'dojo-fast-sync-require': 0,
                'dojo-modulePaths': 0,
                'dojo-moduleUrl': 0,
                'dojo-timeout-api': 0
	}
};

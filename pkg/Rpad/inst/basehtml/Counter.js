/////////////////
// a test widget to see if dojo is working
// https://dojotoolkit.org/reference-guide/1.8/quickstart/writingWidgets.html

require([
    "dojo/_base/declare", "dojo/dom-construct", "dojo/parser", "dojo/ready",
    "dijit/_WidgetBase"
], function(declare, domConstruct, parser, ready, _WidgetBase){

    declare("Counter", [_WidgetBase], {
        // counter
        _i: 0,

        buildRendering: function(){
            // create the DOM for this widget
            this.domNode = domConstruct.create("button", {innerHTML: this._i});
        },

        postCreate: function(){
            // every time the user clicks the button, increment the counter
            this.connect(this.domNode, "onclick", "increment");
        },

        increment: function(){
            this.domNode.innerHTML = ++this._i;
        }
    });
    
    ready(function(){
        // Call the parser manually so it runs after our widget is defined, and page has finished loading
        parser.parse();
    });

});


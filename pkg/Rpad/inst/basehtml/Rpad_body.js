/*
    Rpad.js  --  Rpad client-side functionality

    by Tom Short, EPRI, tshort@epri.com

    (c) Copyright 2005 - 2006. by EPRI

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    ITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*/

// with modifications by Jeffrey Dick:
// January 2013 start migration from Dojo 0.4.1 to 1.8.3
// December 2013 further development with Dojo 1.9.2



////////////////////////////
// Rpad configuration options
// 
//

// configure default options for Rpad widgets:
var _config = {
    // options are "normal", "init", "none", "all"
    rpadRun: "normal",
    rpadHideSource: false,
    // options are "normal", "none", "javascript"
    rpadOutput: "normal",
}
// use defaults, or merge with existing configuration options
if (typeof rpadConfig == "undefined") { 
    rpadConfig = _config; 
} else {
    for (var _option in _config) {
        if (typeof rpadConfig[_option] == "undefined") {
            rpadConfig[_option] = _config[_option];
        }
    }
}


////////////////////////////
// The main namespace for Rpad

var rpad = {};


////////////////////////////
// Get the text content of a node 
// (used to get R commands from Rpad_input, i.e. containerNode of Rpad widgets)

rpad.getTextContent = function(node) {
  // text node
  if (node.nodeType == 3) {
    // really should see if the style has "white-space: pre"
    if (node.parentNode.nodeName == "PRE") {
      return node.nodeValue;
    } else {
      return node.nodeValue.replace(/\n/g," ");
    }
  }
  // element node
  if (node.nodeType == 1) {
    if (node.nodeName == "BR") return "\n";
    if (node.nodeName == "TEXTAREA") return node.value;
    // the R command for input fields: assign the value to a variable
    if (node.nodeName == "INPUT") {
      var name = node.getAttribute("name");
      var command = name + " = " + node.value;
      return command;
    }
    var text = [];
    for (var chld = node.firstChild;chld;chld=chld.nextSibling) {
        text.push(rpad.getTextContent(chld));
    } return text.join("");
  // some other node, won't contain text nodes.
  } return "";
}  



////////////////////////////
// This provides the basic Rpad widget, with input (DOM node rpadInput)
// and output (DOM node rpadResults)
// It's public methods are:
//    initialize(): get it ready
//    toggleVisibility(): hide and unhide source
//    show(): show source
//    hide(): hide source
//    calculate(): calculate it
// The main CSS classes available for modification are:
//    Rpad_input
//    Rpad_output
   
require([
    "dojo/_base/declare", "dojo/dom-construct", "dojo/parser", "dojo/ready",
    "dijit/_WidgetBase", "dojo/_base/window", "dijit/_TemplatedMixin"
], function(declare, domConstruct, parser, ready, _WidgetBase, win, _TemplatedMixin){

    // for the Rpad widget we need TemplatedMixin in order to define a template
    declare("Rpad", [_WidgetBase, _TemplatedMixin], {

      // R code in declarative instantiation (markup e.g. preformatted or input)
      // is appended to the "containerNode" attach point
      // https://dojotoolkit.org/documentation/tutorials/1.9/templated/
      // class attributes are used for CSS formatting
      // div with style=clear:both is needed to separate the results (style=float:left) from the next line
      templateString:
          '<div data-dojo-attach-point="rpadWrapper">                                                    '+
          '    <div class="Rpad_input" data-dojo-attach-point="containerNode"></div>                     '+
          '    <div class="Rpad_results" data-dojo-attach-point="rpadResults"></div>                     '+
          '    <div style="clear:both;"></div>                                                           '+
          '</div>                                                                                         ',
    
      rpadOutput: rpadConfig.rpadOutput,
      rpadRun: rpadConfig.rpadRun,
      rpadHideSource: rpadConfig.rpadHideSource,
      visible: true,
     
      // note: we may want to use startup() method here, not postCreate()
      // http://stackoverflow.com/questions/13514450/dojo-widget-not-appearing-correctly-on-first-instance
      postCreate: function(){
          // this.rpadInput refers to declaration of the widget with some R code
          this.rpadInput = this.containerNode;
          //this.rpadInputWrapper.appendChild(this.rpadInput);
          if (this.rpadHideSource) this.hide();
      },

      // set the DOM attributes - this flag is needed for rpad.calculateNode
      // http://dojotoolkit.org/reference-guide/1.9/quickstart/writingWidgets.html#attributes
      _setRpadRunAttr: "rpadWrapper",

      show: function() {
          this.rpadInput.style.display = "";
          this.visible = true;
      },

      hide: function() {
          this.rpadInput.style.display = "none";
          this.visible = false;
      },

      toggleVisibility: function() {
          if (this.visible) {
              this.hide();
          } else {
              this.show();
          }
      },

      calculate: function() {
//alert("in calculate, rpadInput text is"+rpad.getTextContent(this.rpadInput));
          var rpadResults = this.rpadResults;
          if (this.rpadOutput == "javascript") {
              // use for JSON or other server-side javascript
              rpadResults = "javascript";
          } else if (this.rpadOutput == "none") {
              rpadResults = null;
          }
          rpad.send(rpad.getTextContent(this.rpadInput), 
                    rpadResults, this.rpadInput);
      }, 

      onReceive: function() { // stub available for attaching
      }

    });

    ready(function(){
        // Call the parser manually so it runs after our widget is defined, and page has finished loading
        // parser.parse();
    });

 });


   
////////////////////////////
// This provides the base Rpad class (it's not R specific)
// Its public methods are:
//    send(commands, rpadResults, node): send for processing
//    receive(rpadResults, data, startNode): receive processed results
//    updateResults(rpadResults, data, rpadOutputStyle): update results received
   
rpad.dir = "";

rpad.send = function(commands, rpadResults, rpadInput) {    
  // Send "commands" for processing. 
  // Put results received in the DOM node "rpadResults".
  // Send along the originating DOM node "rpadInput" in case it's needed.
//alert("in rpad.send, commands = "+commands);
  require(["dojo/request"], function(request){
      // The target URL on your webserver:
      request.get("server/R_process.pl", {
      // the query string to use
      query: {
        ID: rpad.dir,
        command: "R_commands",
        R_commands: commands
      },
      // The used data format.
      handleAs: "text"
    }).then(function(response){
      // Event handler on successful call:
      rpad.receive(rpadResults, response, rpadInput);
    }, function(err){
      // Event handler on errors:
      alert("Error in rpad.send. Did R stop running?\n"+err);
    });
  });
}

   
rpad.receive = function(rpadResults, data, rpadInput) {
// Receive the processed commands "data" (text/html).
// Put results received in the DOM node "rpadResults".
// Send along the originating DOM node "rpadInput" in case it's needed.
// if rpadResults == "javascript", exec the javascript instead of inserting results in the DOM
//alert("in rpad.receive, data="+data);

    if (rpadInput.onReceive) rpadInput.onReceive(); // fire an event inputs can attach to
    if (rpadInput.rpadWidget) {
        rpadInput.rpadWidget.onReceive(); // fire an event Rpad widgets can attach to
        var rpadOutputStyle = rpadInput.rpadWidget.rpadOutput;
    }
    if (rpadResults == "javascript") {
        dj_eval(data);
    } else if (rpadResults != null) {
        rpadResults.style.display = "";
        rpad.updateResults(rpadResults, data, rpadOutputStyle);       
    }
//    if (rpad._doKeepGoing) { // this would be better separated, but connect was acting funny
        rpad.calculateNextNode(rpadInput);
//    }

}  


rpad.updateResults = function(rpadResults, data, rpadOutputStyle) {
// Insert the processed commands "data" (text/html)
// in the DOM node "rpadResults".
// Decode the text/html and handle the switching between
// html mode and text mode (done with <htmlon/> and <htmloff/>.

    function fixhtmlencodings(str) {  
      str = str.replace(/&/g,"&amp;");  
      str = str.replace(/</g,"&lt;");  
      str = str.replace(/>/g,"&gt;");  
      str = str.replace(/\n/g,"\n<BR/>");
      str = str.replace(/ /g,"&#160;"); // replace spaces with nonbreaking spaces
      return(str);
    }
    
    function fixformat(str, type) {
    // <htmlon/> turns html mode on
    // <htmloff/> turns html mode off
    // s='aasdf asdf asdf <htmlon/>asdf asdf <htmloff/>asdf asdf'
      var resultstr = "";
      var ishtml = type == 'html';
      var s = "";
    
      do {
        if (ishtml) {
          var s1 = str.split('<htmloff\/>');
          s1[0] = s1[0].replace(/<htmlon\/>/gi,""); // get rid of redundant tags
          s = s1[0];
          s1[0] = "";
          str = s1.join('<htmloff\/>').replace('<htmloff\/>','') // rejoin all but the first with <htmloff/>
          resultstr += s;
          ishtml = false;
        } else {
          var s1 = str.split('<htmlon\/>');
          s1[0] = s1[0].replace(/<htmloff\/>/gi,""); // get rid of redundant tags
          s = s1[0];
          s1[0] = "";
          str = s1.join('<htmlon\/>').replace('<htmlon\/>','')
          resultstr += fixhtmlencodings(s);
          ishtml = true;
        }
      } while (str != "");
      return(resultstr);
    }
    // apply the format
    rpadResults.innerHTML = fixformat(data, rpadOutputStyle);  
}  


////////////////////////////
// install an R form handler
   
rpad.processRForm = function(nodes) {
// Sweep through the elements of the DOM form "node" and
// generate a list of assignment commands for R.
// Then send the commands to R.
    var commands = "";
    if (!nodes.length || (nodes.nodeName && nodes.nodeName.toLowerCase() == "select")) 
        nodes = [nodes]; // make individual nodes into an array
    for (var i=0; i < nodes.length; i++) {
        var node = nodes[i];
        var name = node.getAttribute("name");
        if (name == "") continue;
        var command = "";
        if (node.type == "checkbox") {
          if (node.checked)
            command = name + " = TRUE";
          else
            command = name + " = FALSE";
        } else if (node.type == "radio") {
          if (node.checked) 
            command = name + " = '" + node.value + "'";
        } else if (node.nodeName.toLowerCase() == "select" && node.selectedIndex >= 0)
          command = name + " = '" + node[node.selectedIndex].text.replace(/'/g,"\\\'") + "'"
        else if (node.type == "text" || node.type == "hidden") {
          if (node.getAttribute("rpadType") == "Rvariable" && node.value != "") {
            command = name + " = " + node.value; 
          }
          else if (node.getAttribute("rpadType") == "Rstring" && node.value != "") {
            command = name + " = '" + node.value.replace(/'/g,"\\\'") + "'";
          }
        }
        commands = commands + command + "\n";
    }
//alert("processRForm node.type="+node.type+" commands="+commands);
    if (commands != "" && commands != "\n") {
        rpad.send(commands, null, nodes[0]);
    } else if (commands == "\n") {
        // the \n by itself, caused by an input field in an Rpad widget (not Rvariable or Rstring)
        // results in a spurious R command that breaks R communication in the CGI implementation,
        // but we do need to keep going to calculate the next nodes
        rpad.calculateNextNode(nodes[0]);
    }
}  
   

   
////////////////////////////
// Rpad calculation routines, providing the following methods that the user
// could call:
//   - calculatePage(): Calculates the whole page.
// The following are used internally but may be "connected to" to change functionality:
//   - calculateNextNode(node): Calculates the first Rpad widget after the given DOM node 
//   - calculateNode(node): Calculates the given DOM node (Rpad widget or form element)
// The page also keeps track of the internal state of the page with the following:
//   - _runState: "init" initially and "normal" after the first pass through the page

rpad._runState = "init";  
   
rpad.calculatePage = function(){
  rpad.base = document.body;
  rpad.calculateTree(rpad.base);  
}  

rpad.calculateTree = function(node) {
  // turn on page traversal

  // since this is our major entry point for interactive events
  // (button presses), make it possible to call this function with
  // either the DOM node reference or with a DOM ID
  require(["dojo/dom"], function(dom) {
    // https://dojotoolkit.org/reference-guide/1.7/dojo/byId.html
    // If you pass byId a domNode reference, the same node is returned:
    var mynode = dom.byId(node);
    if(mynode) {
      // remember the starting point
      rpad._startingNode = mynode;
      rpad.calculateNextNode(mynode);  
    } else {
      console.log("no node with id="+node+"found!");
    }
  });
}  

rpad.calculateNextNode = function(node) { // non-recursive
// Calculate the next Rpad element after or below the DOM node "node".
// Traverses the DOM tree starting at the DOM node "node".
// Keeps going until it finds and calculates a "calculatable" DOM node.
  while (typeof(node) != "undefined" && node != null) {
    if (node.firstChild != null) { // try children
      if (rpad.calculateNode(node.firstChild)) {
        return;
      }
      node = node.firstChild;
    }
    else { // try siblings and parent's siblings
    while (node.nextSibling == null && (node.nodeType != 1 || node.nodeName != 'BODY') && node != rpad._startingNode) { 
        node = node.parentNode;
      }   
      if (node.nodeName == 'BODY' || node == rpad._startingNode) { // the end of the tree traversal
        rpad._runState = "normal";
        return;
      } else { // found a way to keep traversing the tree
        if (rpad.calculateNode(node.nextSibling)) {
          return;
        }
        node = node.nextSibling;
      }
    }
  }
}  

rpad._hasNoFormParent = function(node) {
    // returns true if the DOM "node" does not have a FORM-element parent
    while (node.nodeName != "FORM" && node.nodeName != "BODY")
        node = node.parentNode;
    return node.nodeName == "BODY";
}

   
rpad.calculateNode = function(node) {
    // Calculates the DOM node "node" - either a widget, a form, or input node
    // Returns true if it found a node to calculate, false if not.
    if (node.nodeType != 1) return false;
    // get the rpadRun attribute (if it exists) of the node
    var rrun = node.getAttribute("rpadRun");
    // check if we are ready to calculate, based on runState (state of page) and rpadRun (type of node)
    var isReady =  (rpad._runState == "init" && rrun == "init") || 
                   (rpad._runState == "normal" && (rrun == null || rrun == "" || rrun == "normal")) ||
                   (rrun == "all");
    if (isReady) {      
// alert("in rpad.calculateNode/isReady. nodeName="+node.nodeName+" rrun="+rrun);
        // to get the widget given the node
        // http://dojotoolkit.org/reference-guide/1.8/dijit/registry.html
        var widget = false;
        require(["dijit/registry"], function(registry){
            widget = registry.byNode(node);
        });
        if(widget) {
            // we found a widget!
            if (widget.calculate != null) {
//alert("in rpad.calculateNode/isReady. widget="+widget);
                widget.calculate();
                return true;
            }
        } else {
            // the node is not a widget, so maybe it's a form or input node
            // for forms, process the whole form at once
            if (node.nodeName == "FORM") {
                rpad.processRForm(node.elements);
                return true;
            }
            // process standalone input fields (but not buttons) individually
            if ((node.nodeName == "INPUT" || node.nodeName == "SELECT") &&
                node.getAttribute("name") != "" &&
                node.type != "button" &&
                rpad._hasNoFormParent(node)) {
                    rpad.processRForm(node);
                    return true;
            }
        }
    }
    return false;
}  


////////////////////////////
// Key handling
//   just the basics here - F9 for calculatePage
   
require(["dojo/on", "dojo/keys", "dojo/domReady!"], function(on, keys) {
    on(document, "keyup", function(event) {
        if (event.keyCode == keys.F9) {
            rpad.calculatePage();
        }
    });
});



////////////////////////////
// Throbber to show a page (or tree) calculation in progress
rpad.addPageThrobber = function() {
    rpad.throbber = document.createElement('div');
    rpad.throbber.innerHTML = "<img src='gui/wait.gif'>";
    rpad.throbber.id = "rpadPageThrobber"
    document.body.appendChild(rpad.throbber);
}   
rpad.hidePageThrobber = function() {
    if (rpad.throbber)
        rpad.throbber.style.display = "none";
}   
rpad.showPageThrobber = function() {
    if (rpad.throbber)
        rpad.throbber.style.display = "";
}



////////////////////////////
// Initialization
//   * log in right away   
//   * set up keyboard and login events
// ... will not be called until DOM is ready
require(["dojo/domReady!"], function(){
  //    rpad.addPageThrobber();
  // Rpad login: send a login command to the server and update the appropriate working directory.
  // translated from Rpad 1.3.0
  // dojo.io.bind -> dojo.xhrGet    http://livedocs.dojotoolkit.org/dojo/xhr (deprecated)
  // dojo.xhrGet -> dojo/request     http://dojotoolkit.org/documentation/tutorials/1.8/modern_dojo/
  require(["dojo/request"], function(request){
    
      // The target URL on your webserver:
      // initialize Rpad
      request.get("server/Rpad_process.pl?command=login", {
      // The used data format.
      handleAs: "text"

    }).then(function(response){
      // Event handler on successful call:
      // Save the location of the rpad temporary directory and start an R process
      rpad.dir = response;
      request.get("server/R_process.pl?ID="+response+"&command=login", {
        handleAs: "text"
      }).then(function(response){
        // this is where we want to be! let's calculate the page
        if(rpad._runState == "init") rpad.calculatePage();
      }, function(err){
        // (The missingness of Statistics::R might cause this error on the server version of Rpad, not the local version)
        alert("Error in rpad.login step 2/2. Is the Statistics::R Perl module installed? Error:\n"+err);
      });

    }, function(err){

      // Event handler on errors:
      // (The missingness of Rpad_process.pl will cause this error on the server version of Rpad, not the local version)
      alert("Error in rpad.login step 1/2. Is the Rpad/server/Rpad_process.pl file present on the HTTP server?");

    });
  });
});


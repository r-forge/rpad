# Rpad utility functions for running Rpad locally.

# Here we use a local Tcl httpd server to receive Rpad commands.
# this is an internal function, but is exported to the package namespace
# so that it can be evaluated from within the Tcl scripts
"processRpadCommands" <-
function() {
  require("tcltk")
  commands <- tclvalue(.Tcl("set user(R_commands)"))
  textcommands <- textConnection(commands)
  results <- tryCatch({
    tc <- textConnection("textfromconnection",open="w")
    sink(file=tc)
    source(textcommands, print.eval=TRUE)
    sink()
    close(tc)
    # the result is R result text
    get("textfromconnection")
  }, error=function(e) {
    sink()
    close(tc)
    cat('ERROR1:')
    print(e)
    # the result is an error message
    etext <- paste(paste(get("textfromconnection"), "\n", collapse=""), '\n', e)
    etext
  }, finally=close(textcommands))
  formattedresults <- paste(results,"\n",sep="",collapse="")
  escapeBrackets <- function(x) gsub("(\\{|\\})", "\\\\\\1", x)
  .Tcl(paste("set RpadTclResults {", escapeBrackets(formattedresults), "}", sep=""))
}

"Rpad" <-
function(file = "", port = 8079, type="Rpng") {
  # stop the local server if it's running
  if(RpadIsLocal()) {
    stopRpadServer()
    WasRunning <- TRUE
  } else WasRunning <- FALSE
  # start the local server, set the graph type and browse to the default page
  graphoptions(type=type)
  startRpadServer(port=port)
  if(!WasRunning) browseURL(paste("http://127.0.0.1:", port, "/", file, sep = ""))
}

"startRpadServer" <-
function(file = "index.html", port = 8079) {
    # This is the main function that starts the server
    if (!require("tcltk")) stop("package tcltk required for the local Rpad http server")
    assign("RpadLocal", TRUE, envir = .RpadEnv)
    assign("RpadDir",   ".",  envir = .RpadEnv)
    # This implements a basic http server on 'port', written in Tcl.
    # This way it is not blocking the R command-line!
    tclfile <- file.path(find.package(package = "Rpad"), "tcl", "mini1.1.tcl")
    htmlroot <- file.path(find.package(package = "Rpad"), "basehtml")
    tcl("source", tclfile)
    tcl("Httpd_Server", htmlroot, port, file)
    # this initializes the png device for Rpad
    newgraph()
    return(TRUE)
}

"stopRpadServer" <-
function() {
    require("tcltk")
    assign("RpadLocal",    FALSE, envir = .RpadEnv)
    .Tcl("close $Httpd(listen)")
    .Tcl("unset Httpd")
}

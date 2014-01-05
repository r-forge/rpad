# Rpad graphing functions 

######################
# internal functions #
######################

"newRpadPlotName" <- function(name = "") {
  # Create a new Rpad plot name
  # Updates the plot counter and name
  if (name == "") {
    Counter <- get("plot.counter", envir = .RpadEnv)
    assign("plot.counter", Counter + 1, envir = .RpadEnv)
    name <- sprintf("Rpad_plot%03d", Counter)
  } 
  assign("plot.name", name, envir = .RpadEnv)
  name
}

GScmd <- function(name, invisible=FALSE, infile=paste(name, ".eps", sep = "")) {
  # generate a ghostscript command
  # set invisible=TRUE for windows
  # set infile="" for output piped to command (see ?postscript)
  GO <- graphoptions()
  gsexe <- Sys.getenv("R_GSCMD")
  if (is.null(gsexe) || nchar(gsexe) == 0) 
  gsexe <- ifelse(.Platform$OS.type == "windows", "gswin32c.exe", "gs")
  if(invisible) gshelp <- system(paste(gsexe, "-help"), intern = TRUE, invisible = TRUE)
  else gshelp <- system(paste(gsexe, "-help"), intern = TRUE)
  st <- grep("^Available", gshelp)
  en <- grep("^Search", gshelp)
  gsdevs <- gshelp[(st + 1):(en - 1)]
  devs <- c(strsplit(gsdevs, " "), recursive = TRUE)
  if (match(GO$type, devs, 0) == 0) 
    stop(paste(paste("Device ", GO$type, "is not available"), 
               "Available devices are", paste(gsdevs, collapse = "\n"), 
               sep = "\n"))
  cmd <- paste(gsexe, " -dNOPAUSE -dBATCH -q -sDEVICE=", GO$type, 
               " -r", GO$res, " -g", ceiling(GO$res * GO$width), "x",
               ceiling(GO$res * GO$height), " -sOutputFile=", name,
               ".", GO$extension, " ", infile, sep = "")
}

"newDevice" <- function(name) {
  # Open a new device.
  # If it's an R graphics device, initiate it.
  # If it's a ghostscript-based device, set up the ghostscript handling.
  name <- newRpadPlotName(name)
  GO <- graphoptions()
  if (GO$type == "Rpng") {
    # for builtin png support
    png(filename = paste(name, ".png", sep=""), width = GO$width*GO$res, height = GO$height*GO$res)
  } else if (GO$type == "pngalpha") {
    # for a ghostscript device using bitmap
    if (.Platform$OS.type == "windows") {
      cmd <- NULL
    } else {
      cmd <- GScmd(name, infile="")
    }
    postscript(file = paste(name, ".eps", sep=""), width = GO$width, height = GO$height,
               pointsize = GO$pointsize, 
               paper = "special", horizontal = FALSE, print.it = !is.null(cmd), 
               command = cmd)
  }
}
 
"closeCurrentDevice" <- function() {
  # Closes the current device and if the current device is postscript,
  # process the output with ghostscript to generate the desired output.
  if (.Device == "postscript") {
    dev.off()
    if (.Platform$OS.type == "windows") {
      cmd <- GScmd(get("plot.name", envir = .RpadEnv), invisible=TRUE)
      system(cmd, intern = TRUE, invisible = TRUE)
    }
  } else if (.Device != "null device") {
    dev.off()
  }
}


##########################
# user-visible functions #
##########################

"graphoptions" <- function (..., reset = FALSE, override.check = TRUE) {
  # set various Rpad graph options
  # modified based on code from ps.options
  l... <- length(new <- list(...))
  old <- check.options(new = new, envir = .RpadEnv, name.opt = "GraphOptions", 
      reset = as.logical(reset), assign.opt = l... > 0, override.check = override.check)
  if (reset || l... > 0) 
      invisible(old)
  else old
}

"newgraph" <- function(name = "") {
  # Start a new Rpad graph.
  closeCurrentDevice()
  newDevice(name)
  GO <- graphoptions()
  par(lwd = GO$lwd, mgp = c(2.5, 0.6, 0),
      mar = c(3 + GO$sublines + 0.25 * (GO$sublines > 0) + 
        0.5, 3 + GO$leftlines + 0.5, GO$toplines+.4,  1) + 0.1,
      cex.main=1, font.main=1, las=1)
  invisible()
}

# Start a new Rpad graph, and show the existing graph(s).
"showgraph" <- function(name = get("plot.name", envir = .RpadEnv), link = FALSE, ...) {
  name
  newgraph()
  for (n in dir(pattern = paste(name, graphoptions()$extension, sep="."))) 
    print(HTMLimg(n))
  # show a link to an EPS file if specified and if using the ghostscript graphics
  if (link && graphoptions()$type == "pngalpha")
    cat("<span contentEditable='false'>",
        "<sub><a href='", RpadURL(name), ".eps'>[EPS]</a></sub>",
        "</span>\n",
        sep="")
  invisible()
}

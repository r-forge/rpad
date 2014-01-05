.RpadEnv <- new.env()

".onLoad" <-
function(lib, pkg) {
    # create the RpadEnv environment
    #attach(NULL, name=".RpadEnv")
    # look for R2HTML package
    isR2HMTLAvailable <- length(find.package("R2HTML", quiet = TRUE)) != 0
    if (isR2HMTLAvailable) { 
      options(R2HTML.sortableDF = TRUE)
      options(R2HTML.format.digits = 3)
      options(R2HTML.format.nsmall = 0)
      options(R2HTML.format.big.mark = "")
      options(R2HTML.format.big.interval = 3)
      options(R2HTML.format.decimal.mark = Sys.localeconv()[["decimal_point"]])
      .HTML.file <<- ""
    }
    # The following uses the environment variable DOCUMENT_ROOT with apache to find
    # the directory of the R process. Change may be required for another server.
    if (Sys.getenv("DOCUMENT_ROOT") != "") {
      # for Apache 1.3 linux & win
      # strip off the document root
      RpadDir <- gsub(Sys.getenv("DOCUMENT_ROOT"), "", getwd(),  ignore.case = TRUE)
    } else if (Sys.getenv("SCRIPT_NAME") != "") {
      # for Apache 2.0
      RpadDir <- paste(gsub("R_process.pl", "", Sys.getenv("SCRIPT_NAME"), ignore.case = TRUE),
                       gsub(".*/", "", getwd()), sep="")
    } else if (Sys.getenv("PATH_INFO") != "") {
      # for microsoft IIS
      RpadDir <- paste(gsub("R_process.pl", "", Sys.getenv("PATH_INFO"), ignore.case = TRUE),
                       gsub(".*/", "", getwd()), sep="")
    } else {
            .rootdir = ifelse(.Platform$OS.type == "windows", "C:/www", "/var/www")
            RpadDir <- gsub(.rootdir, "", getwd(),  ignore.case = TRUE)
    }


    assign("GraphOptions",
       list(type = "pngalpha", extension = "png",
            res = 120, width = 4, height = 3, deviceUsesPixels = TRUE, pointsize = 10,
            sublines = 0, toplines = 0.6, leftlines = 0, lwd = 0.6),
       envir = .RpadEnv)
    assign("RpadLocal", FALSE, envir = .RpadEnv)
    assign("RpadDir", RpadDir, envir = .RpadEnv)
    assign("plot.counter",  0, envir = .RpadEnv)
}

".onUnload" <-
function(libpath) {
 	if (interactive()) stopRpadServer()
}

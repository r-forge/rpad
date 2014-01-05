# Rpad utility functions.

# for debugging, it's nice to have the .RpadEnv environment accessible
RpadEnv <- function() .RpadEnv

"RpadURL" <- function(filename = "") {
  # returns the URL for the given filename
  #   "./filename" for the local version
  #   "/Rpad/server/dd????????/filename" for the server version
  # use this to output HTML links for the user
  paste(get("RpadDir", envir = .RpadEnv), "/", filename, sep="")
}

"RpadBaseURL" <- function(filename = "") {
  # returns the base URL
  #   "filename" for the local version
  #   "/Rpad/filename" for the server version
  # use this to read in data files or save data files somewhere permanent
  if ( RpadIsLocal() )
    filename
  else
    paste("../../", filename, sep="")
}

"RpadBaseFile" <- function(filename = "") {
  # returns the file name relative to the base R directory
  #   "filename" for the local version
  #   "../../filename" for the server version
  # use this to read in data files or save data files somewhere permanent
  if ( RpadIsLocal() )
    paste("./", filename, sep="")
  else
    paste("../../", filename, sep="")
}

"RpadIsLocal" <- function() 
  get("RpadLocal", envir = .RpadEnv)    


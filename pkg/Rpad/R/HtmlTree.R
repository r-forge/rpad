"Html" <- function(x,...) { 
  UseMethod("Html") 
}

"Html.default" <- function(x, ...) as.character(x)

"Html.integer" <- "Html.numeric" <- function(x, ...) paste(format(x), collapse = ", ")


"HtmlTree" <- function(tagName, ...) {  
  UseMethod("HtmlTree") 
}

"H" <- HtmlTree

"HtmlTree.HtmlTree" <- function(tagName, ..., standaloneTag = FALSE, collapseContents = TRUE) tagName

"jsQuote" <- function(string) {
  # uses code from shQuote
  # wraps strings in quotes, with priority to single quotes
  # cat(jsQuote("asdf")) -> 'asdf'
  # cat(jsQuote('asdf')) -> 'asdf'
  # cat(jsQuote('alert("hello")')) #-> 'alert("hello")'
  # cat(jsQuote("alert('hello')")) #-> "alert('hello')"
  # cat(jsQuote("alert(\"he\'l'lo\")")) #-> 'alert("he\'l\'lo")'
  has_single_quote <- grep("'", string)
  if (!length(has_single_quote)) 
    return(paste("'", string, "'", sep = ""))
  has_double_quote <- grep('"', string)
  if (!length(has_double_quote)) 
    return(paste('"', string, '"', sep = ""))
  # default - single-quote emphasis
  paste("'", gsub("'", "\\\\\'", string), "'", sep = "")
}

"HTMLargs" <- function(x) {
  # returns a string with the arguments as a="arg1", b="arg2", and so on
  names <- names(x)
  if (length(x) > 0) str <- " " else str <- ""
  for (i in seq(along = x))
    str <- paste(str, names[i], "=", jsQuote(x[[i]]), " ", sep = "")
  return(str)
}

"print.HtmlTree" <- function(x, file = "", ...)
  cat(file=file, x, "\n")

"HtmlTree.default" <- function(tagName, ..., standaloneTag = FALSE, collapseContents = TRUE) {
  # named arguments are attributes; unnamed are content
  args <- list(...)
  methodsOfHtml <- setdiff(c(gsub("^Html.","",(methods("Html"))), "HtmlTree"), "character")
  # if we can apply "html" to tagName, and it's by itself, do it (for non-character classes)
  if (length(args) == 0 && !is.character(tagName) && class(tagName) %in% methodsOfHtml)
    return(Html(tagName))
  if (length(names(args)) > 0) {
    tagContents <- args[names(args) == ""]    # unnamed arguments
    tagAttributes <- args[names(args) != ""]  # named arguments
  } else {
    tagContents <- args
    tagAttributes <- NULL
  }
  pasteList <- function(x) {
    str <- ""
    for (i in seq(along=x)) {
        str <- paste(str, Html(x[[i]]), sep = " ")
    }
    str
  }
  if (is.null(tagName)) {
    startTag <- ""
    contents <- pasteList(tagContents)
    endTag <- ""
  } else if (standaloneTag) {
    startTag <- paste("<", tagName, HTMLargs(tagAttributes), "/>", sep = "")
    contents <- ""
    endTag <- ""
  } else { # default case:
    startTag <- paste("<", tagName, HTMLargs(tagAttributes), ">", sep = "")
    contents <- paste(" ",pasteList(tagContents), "")
    endTag <- paste("</", tagName, ">", sep = "")
  }
  str <- paste(startTag, contents, endTag,
               sep = "", collapse = if (collapseContents) "" else NULL)
  class(str) <- "HtmlTree"
  str
}

"Html.data.frame" <- "Html.matrix" <- function(x, ...) {
## 
## Make an HtmlTree out of a data frame.
## First "format" then convert to a matrix.
## "..." arguments are passed directly to format.
## 
  
  x.formatted <- as.matrix(format(x, ...))
  x.formatted[is.na(x)] <- " "
  x.formatted[grep("^ *(NA|NaN) *$", x.formatted)] <- " "

  H("div", class = "RpadTableHolder",
    H("table",
      H("tbody",
        H("tr",                           # HEADER ROW
          H("th", 
            H("div", class = "tableheaderrow", 
              colnames(x), collapseContents = FALSE))), # collapseContents keeps the <th><div></div></th><th><div></div></th> nested pair
        H(NULL, # NULL groups consecutive tags together
          apply(x.formatted, MARGIN = 1,    # MAIN BODY - sweep the rows
            FUN = function (x)
              H("tr", 
                H("td", x)))))))
}


"HTMLbutton" <- function(label = "Calculate", js = "rpad.calculatePage()", ...) 
  # Other useful js parameters:
  #   js = "rpad.calculateNext(this)"  # calculate the next Rpad block
  #   js = "rpad.send('put commands here')"
  H("input", onclick = paste("javascript:", js, sep=""),
          value = label, type = "button", ...)

"HTMLradio" <- function(variableName, commonName = "radio", text = "", ...) 
  # outputs an HTML radio button wrapped in a contentEditable=false 
  H("span", contentEditable="false",
    H("input", type = 'radio', name = commonName, value = variableName, id = variableName, ...),
    H("label", "for" = variableName,
      text))

"HTMLcheckbox" <- function(name, text = "", ...)
  H("span", contentEditable="false",
    H("input", type = 'checkbox', name = name, id = name, ...),
    H("label", "for" = name,
      text))

"HTMLinput" <- function(name, value = "", rpadType = "Rvariable", contenteditablewrapper = TRUE, ...) {
  res <- H("input", name = name, value = value, rpadType = rpadType, standaloneTag = TRUE, ...)
  if (contenteditablewrapper)
    H("span", contentEditable = "false", 
      res)
  else
    res
}

"HTMLselect" <- function(name, text, default=1, size=1, id=name, contenteditablewrapper=TRUE,
                         optionvalue=text, ...) {
# generate a select box

  options =
    H("option", value = optionvalue,
      text, collapseContents = FALSE)
  
  if (default > 1 & default <= length(text)) 
    options[default] =
      H("option", value = optionvalue[default], selected = "selected",
        text[default])

  res =
    H("select", name = name, size = size, id = id, ...,
      H(NULL, options))

  if (contenteditablewrapper)
    H("span", contentEditable = "false",
      res)
  else
    res
}

"HTMLlink" <- function(url, text, ...) 
  H("span", contentEditable="false",
    H("a", href = url, ...,
      text))

"HTMLimg" <- function(filename = get("plot.name", envir = .RpadEnv), ...) 
  H("img", src = RpadURL(filename), ...)

"HTMLembed" <- function(filename, width = 600, height = 600, ...) 
  H("embed", src = filename, width = width, height = height, ...)

"HTMLjs" <- function(js)
  # Runs a javascript snippet. HTML must be enabled.
  # doesn't work because scripts won't get executed when inserted via innerHTML
  H("script", type="text/javascript",
    js)

"HTMLjs" <- function(js)
  # Runs a javascript snippet by attaching it to an error handler for an image.
  # HTML must be enabled.
  # see also: # http://24ways.org/advent/have-your-dom-and-script-it-too
  #   <img src="g.gif?randomnum" alt="" 
  #        onload="alert('Now that I have your attention...');this.parentNode.removeChild(this);" />
  H("img", src = "", alt = "", style = "display:none",
    onerror = paste(js, ";this.parentNode.removeChild(this);"))

"HTMLSetInnerHtml" <- function(id, html) 
  # Sets the innerHTML of the element "id" to "html".
  # Runs a bit of javascript to do it. HTML must be enabled.
  # It's probably better to do this sort of thing on the javascript side.
  HTMLjs(paste("dojo.byId('", id, "').innerHTML = '", html, "'", sep=""))

"BR" = function()
  H("br", standaloneTag = TRUE) # <br/>

"HTMLon" <- function()
  H("htmlon", standaloneTag = TRUE)

"HTMLoff" <- function()
  H("htmloff", standaloneTag = TRUE)

"HTMLtag" <- function(tagName, ...) {
  # outputs the given HTML tagName with arguments supplied in ...
  str <- paste("<", tagName, HTMLargs(list(...)), ">", sep = "", collapse = "")
  class(str) <- "HtmlTree"
  str
}

"HTMLetag" <- function(tagName) {
  str <- paste("</", tagName, ">\n", sep = "")
  class(str) <- "HtmlTree"
  str
}

"print.condition" <- function (x, ...) {
	# redefine this to get rid of the <> brackets around error messages

	msg <- conditionMessage(x)
    call <- conditionCall(x)
    cl <- class(x)[1]
    if (!is.null(call)) {
        cat("** ", cl, " in ", deparse(call), ": ", msg, " **\n", sep = "")
    } else {
		cat("** ", cl, ": ", msg, " **\n", sep = "")
	}
}

"HfromHTML" <- function(x) {
  if(require("R2HTML")) {
    res <- capture.output({HTML(x);cat("\n")}) # the \n makes sure to get a complete line
    class(res) <- "HtmlTree"
    res
  } else {
    Html(x)
  }
}

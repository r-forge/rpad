\name{RpadGraphing}
\alias{graphoptions}   
\alias{newgraph}   
\alias{showgraph}
                   
\title{ Rpad graphing utilities }

\description{
  Utilities to make graphing in Rpad R scripts easier.
}

\usage{
  graphoptions(..., reset = FALSE, override.check = TRUE)
  newgraph(name = "")
  showgraph(name = get("plot.name", envir = .RpadEnv), link = FALSE, ...)
}

\arguments{
  \item{reset, override.check}{ logical arguments passed to \code{check.options}.  }
  \item{name}{ is the name of the graph with the extension left OFF.}
  \item{link}{ is a logical specifying whether to show a link to allow
    the user to download an EPS file of the graph (not available when
    using R's png driver.}
  \item{...}{ named arguments assigned as defaults for \code{newgraph}.}
}
\details{
      
The \code{graphoptions}, \code{newgraph}, and \code{showgraph} set of functions allows quick setup and display of web-friendly graphics.
In an Rpad page, the user can normally just use any of the plot commands followed by \code{showgraph}.
\code{newgraph} sets up the graphics device, and it's called when the Rpad package starts.
\code{showgraph} generates the HTML to show the graph and runs \code{newgraph} to advance to the next graphics file.
Graphics files are by default named Rpad\_plot1, Rpad\_plot2, and so on.
Named graphs can also be used, but there's more of a chance that if the user has caching set wrong (or the server's caching is set wrong) that graphs won't update properly in the user's browser.
With the default sequential numbering of files, caching problems are less likely.

Internally, \code{newgraph} uses one of two devices to generate the bitmap for the browser.
Specifying \code{type="Rpng"} directs \code{newgraph} to use R's \code{\link{png}} device directly.
The \code{type="pngalpha"} option outputs to a \code{\link{postscript}} device, followed by ghostscript conversion to PNG with anti-aliasing.
This approach has the side-effect of creating an EPS file for each graph, so it's easy to add a link to allow the user to download the EPS file.

\code{graphoptions} is available to change the parameters from their defaults.
It can be called interactively (before running \code{\link{Rpad}()}) or in the server version (in RpadStartup.R).

\itemize{
  \item{\code{extension}}{ is the file extension of the device (typically '.png').}
  \item{\code{type}}{ is the graphics device, either a ghostscript device as a
    character string, or "Rpng" for R's builtin png device.
    For a ghostscript device, common
    possibilities are "png256", "pngalpha" (the default), or "pdf".}
  \item{\code{res}}{ is the resolution of the bitmap in dots per inch.}
  \item{\code{width}, \code{height}}{ are the dimensions of the graph in inches.}
  \item{\code{deviceUsesPixels}}{ is a logical specifying whether the R
    graphics driver uses pixels. This only applies if \code{type} is
    used to specify an R graphics driver. It defaults to TRUE.}
  \item{\code{ratio}}{ specifies the ratio of the graph if either the width or
    height is not specified.}
  \item{\code{pointsize}}{ is the font point size passed to the postscript
    device.}
  \item{\code{sublines}, \code{toplines}, \code{leftlines}}{ specify the dimension of
    the graph along with the outside border. It defaults to fairly tight
    outside dimensions.}
  \item{\code{lwd}}{ is the line width set with \code{par}.}
}


}

\section{Side Effects}{
\code{newgraph} opens a new graphics device, saving files with the pattern Rpad_plot.*.png (and Rpad_plot.*.eps for pngalpha) in the working directory.
}

\value{
None of the routines returns a value: all are run for their side effects. 
}

\author{ Tom Short, EPRI, (\email{tshort@epri.com}) }

\seealso{ See also \code{bitmap}, \code{png}, and \code{pdf}. }

\examples{
# make some graphs (a default graphics device is already available)
  x <- 1:10
  y <- x^2
  y2 <- x^3
  if (capabilities("png")) graphoptions(type="Rpng")
  newgraph()
  plot(x, y)  # does the plot
  plot(x, y2) # does the second plot
  HTMLon()    # sets Rpad to HTML output
  showgraph() # closes the device, outputs the HTML for the both
              # images, and creates the next device
  plot(x, y2)
  showgraph()

# graphs with named files:
  newgraph("graph_A")
  plot(x, y)
  showgraph("graph_A")
# also adjust the width and height
  graphoptions(width = 4, height = 6)
  newgraph("graph_B")
  plot(x, y2)
  showgraph("graph_B")

}

\keyword{ math }

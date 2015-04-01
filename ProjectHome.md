![http://geben-on-emacs.googlecode.com/svn/materials/logo/logo.gif](http://geben-on-emacs.googlecode.com/svn/materials/logo/logo.gif) (beta version)

## SUMMARY ##

GEBEN is a software package that interfaces [Emacs](http://www.gnu.org/software/emacs/emacs.html) to [DBGp](http://xdebug.org/docs-dbgp.php) protocol with which you can debug running scripts interactively.
At this present DBGp protocol are supported in several script languages with help of custom extensions.

  * [PHP](http://php.net/) with [Xdebug](http://xdebug.org/)
  * [Perl](http://www.perl.org/), [Python](http://www.python.org/), [Tcl](http://www.tcl.tk/) and [Ruby](http://www.ruby-lang.org/en/) with [Komodo Debugger Extensions](http://aspn.activestate.com/ASPN/Downloads/Komodo/RemoteDebugging)

NewsOnReleases »

## REQUIREMENTS ##

### server side ###
  * (To debug PHP scripts) PHP + [Xdebug extension](http://xdebug.org/) 2.0.3 or later
  * (To debug Python, Perl or Ruby scripts) Script engine + [Komodo Debugger Extension](http://aspn.activestate.com/ASPN/Downloads/Komodo/RemoteDebugging)

### client side ###
  * Emacs22.1 or later

## FEATURES ##

Currently GEBEN implements the following features.

  * continuation commands: run/stop/step-in/step-over/step-out
  * set/unset/listing breakpoints
  * expression evaluation
  * STDOUT/STDERR redirection
  * backtrace listing
  * variable Inspection

ScreenShots »

## RELEASES ##

  * 2010-03-30 [version 0.26](http://geben-on-emacs.googlecode.com/files/geben-0.26.tar.gz)

## TODO ##

  * Variable watch
  * More documentation
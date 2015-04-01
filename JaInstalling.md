# GEBENのインストール #

## 必要な環境 ##

[Emacs](http://www.gnu.org/software/emacs/emacs.html) Version 22.1以上

## インストール手順 ##

### Linux ###

  1. [GEBENのダウンロードページ](http://code.google.com/p/geben-on-emacs/downloads/list)から最新版をダウンロードします。
  1. `~/src> tar xfz geben-x.xx.tar.gz`
  1. `~/src> cd geben-x.xx`
  1. `~/src/geben-x.xx> make`
  1. `~/src/geben-x.xx> sudo make install`<br />(管理者権限がない場合またはインストール先を指定したい場合)<br />`~/src/geben-x.xx> make SITELISP=/path/to/install install`
  1. .Emacsの初期化ファイル(`site-start.el` or `.emacs` or `.emacs.el`)にautoloadフックを追加します。<br />` (autoload 'geben "geben" "DBGp protocol front-end" t)`
  1. Emacsを再起動します。

### その他環境 ###
  1. [GEBENのダウンロードページ](http://code.google.com/p/geben-on-emacs/downloads/list)から最新版をダウンロードし、任意の作業ディレクトリに展開(解凍)します。
  1. 展開されたディレクトリに移動します。
  1. `dbgp.el` をバイトコンパイルします。
  1. `geben.el` をバイトコンパイルします。
  1. `dbgp.elc`, `geben.elc` と `tree-widget` ディレクトリ全体をEmacsの`site-lisp` もしくはEmacsの変数 `load-path` に示されたディレクトリにコピーします。
  1. .Emacsの初期化ファイル(`site-start.el` or `.emacs` or `.emacs.el`)にautoloadフックを追加します。<br />` (autoload 'geben "geben" "DBGp protocol front-end" t)`
  1. Emacsを再起動します。
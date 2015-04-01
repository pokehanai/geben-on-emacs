# GEBENとは #

[GEBEN](http://code.google.com/p/geben-on-emacs/)は[Emacs](http://www.gnu.org/software/emacs/emacs.html)用のスクリプトデバッガパッケージです。<br />Emacs上でPHPやPerl,Rubyなど様々なスクリプトをデバッグできるようになります。

## 詳細 ##
GEBENは[DBGpプロトコル](http://xdebug.org/docs-dbgp.php)で対話するためのパッケージです。<br />
DBGpはデバッギング用途の汎用プロトコルで、ステップ実行やブレークポイントの設定、変数の読み出しなどのデバッグコマンドが定義されています。<br />
GEBENはDBGpプロトコルを介してスクリプトエンジンを制御し、各種のデバッグ動作を行えるようにします。

PHPなど各種スクリプトエンジンは通常、デフォルトではDBGpプロトコルに対応していませんが、DBGpプロトコル対話機能を追加する拡張が有志によって開発されています。<br />
# proxy.sh プロキシ自動設定スクリプトの使い方
まずは、proxy.shをLinux内のエディターで開き、プロキシ情報を設定します。  
基本的にproxy.sh内の4行目から7行目までを変更するだけで良い。(下記に示している部分)
```
# プロキシ情報を変数に設定 (それぞれの""内を適宜書き換えること)
PROXY_USER="User_ID"        		# ユーザー名
PROXY_PASS="Password"       		# パスワード
PROXY_HOST="ProxyServer_HostName"   # プロキシサーバー ([http://]以降のみでよい)
PROXY_PORT="ProxyPort"              # プロキシサーバーのポート (最近では8080がよく使われる)
```
ここでは、vimというエディターを例に解説します。  
下記をターミナルに入力すると、vimというエディターでproxy.shが開かれます。
```
vim ~/proxy.sh
```
Iキーを押して-INSERT-モードにし、4行目から6行目を適宜変更してください。  
※User_IDとPasswordについては、プロキシに接続するためのものを使用してください。プロキシサーバーとポートについては、pacファイルやdatファイル等、プロキシ自動設定ファイルから確認することも可能です。基本的に[http://]以降の情報をそのまま入力するだけでOK。

入力が終わりましたら、[esc]キーを押下後「:wq」を入力し、保存して退出します。  
続けて下記をターミナルに入力して実行してください。
```
bash ~/proxy.sh
```
プロキシを登録、プロキシを削除という選択画面が現れるので、1を入力してEnterを押す。

自動でプロキシ情報が登録されます。

最後に、下記のコマンドを実行して反映させたら終了となります。お疲れさまでした。
```
source ~/.bashrc
```

## 使い方（プロキシの削除）
下記コマンドをターミナルに入力・実行します。
```
bash ~/proxy.sh
```
プロキシを登録、プロキシを削除という選択画面が現れるので、2を入力してEnterを押す。

プロキシが自動で削除されます。

プロキシ情報が変更されたり、繋がらなくて再度設定を見直す時にお使いください。
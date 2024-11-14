#!/bin/bash

# プロキシ情報を変数に設定 (それぞれの""内を適宜書き換えること)
PROXY_USER="User_ID"        		# ユーザー名
PROXY_PASS="Password"       		# パスワード
PROXY_HOST="ProxyServer_HostName"   # プロキシサーバー ([http://]以降のみでよい)
PROXY_PORT="ProxyPort"              # プロキシサーバーのポート (最近では8080がよく使われる)

# 書き込む内容
HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"
HTTPS_PROXY="https://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"

# メニューの表示
echo "[注意] 実行する前にユーザー名やパスワード、プロキシサーバーのホストを設定しましたか？"
echo "       このファイルをエディタで開き、4 ~ 7行目の項目を編集してください。"
echo "[プロキシ設定スクリプト]"

while true; do
    echo "1. プロキシを登録"
    echo "2. プロキシを削除"
    echo "0. プロキシ設定の終了"
    read -p "選択してください (1 または 2 | 0 で終了) : " choice

    if [ "$choice" -eq 1 ]; then
        # プロキシ設定を登録
        echo "プロキシを登録します..."

        # .bashrcにプロキシ設定を追加 (重複チェック)
        if ! grep -q "export HTTP_PROXY=${HTTP_PROXY}" ~/.bashrc; then
            cat <<EOF >> ~/.bashrc
# HTTP/HTTPSプロキシ設定
export HTTP_PROXY=${HTTP_PROXY}
export HTTPS_PROXY=${HTTPS_PROXY}

# Gitプロキシ設定
git config --global http.proxy ${HTTP_PROXY}
git config --global https.proxy ${HTTPS_PROXY}
git config --global url."https://".insteadOf git://
EOF
        fi

        # aptのプロキシ設定 (重複チェック)
        if ! grep -q "Acquire::http::proxy \"${HTTP_PROXY}\";" /etc/apt/apt.conf; then
            echo "Acquire::http::proxy \"${HTTP_PROXY}\";" | sudo tee /etc/apt/apt.conf > /dev/null
            echo "Acquire::https::proxy \"${HTTP_PROXY}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
        fi

        # wgetのプロキシ設定 (重複チェック)
        if ! grep -q "https_proxy = ${HTTP_PROXY}" /etc/wgetrc; then
            echo -e "# wgetプロキシ設定" | sudo tee -a /etc/wgetrc > /dev/null
            echo "https_proxy = ${HTTP_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
            echo "http_proxy = ${HTTP_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
            echo "ftp_proxy = ${HTTP_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
        fi

        echo "プロキシの登録が完了しました。"

    elif [ "$choice" -eq 2 ]; then
        # プロキシ設定を削除
        echo "プロキシを削除します..."

        # .bashrcからプロキシ設定を削除
        sed -i '/# HTTP\/HTTPSプロキシ設定/,/git config --global url."https:\/\/"\.insteadOf git:\/\//d' ~/.bashrc

        # Gitのプロキシ設定を削除
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        git config --global --unset url."https://".insteadOf

        # aptのプロキシ設定を削除
        ESCAPED_PROXY=$(echo "${HTTP_PROXY}" | sed 's/[\/&]/\\&/g')
        sudo sed -i "s|Acquire::http::proxy \"${ESCAPED_PROXY}\";||g" /etc/apt/apt.conf
        sudo sed -i "s|Acquire::https::proxy \"${ESCAPED_PROXY}\";||g" /etc/apt/apt.conf

        # wgetのプロキシ設定を削除
        sudo sed -i '/# wgetプロキシ設定/,/ftp_proxy =/d' /etc/wgetrc

        echo "プロキシの削除が完了しました。"

    elif [ "$choice" -eq 0 ]; then
        # プロキシ設定の終了
        echo "終了しています..."
        break;

    else
        echo "無効な選択です。1 または 2 、0 を選んでください。"
    fi
done

# ユーザーへの催促
echo "変更を反映するには、以下のコマンドを実行してください。: "
echo "source ~/.bashrc"

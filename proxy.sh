#!/bin/sh

# プロキシ情報を変数に設定 (それぞれの""内を適宜書き換えること)
PROXY_USER="User_ID"        		# ユーザー名
PROXY_PASS="Password"       		# パスワード
PROXY_HOST="ProxyServer_HostName"   # プロキシサーバー ([http://]以降のみでよい)
PROXY_PORT="ProxyPort"              # プロキシサーバーのポート (最近では8080がよく使われる)

# 書き込む内容
HTTPS_PROXY="https://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"
HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"
FTP_PROXY="ftp://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"

# シェルの確認と設定ファイルの指定
if [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    SHELL_CONFIG_FILE="$HOME/.bashrc"
fi

# メニューの表示
echo "[注意] 実行する前にユーザー名やパスワード、プロキシサーバーを設定しましたか？"
echo "       このファイルをエディタで開き、4 ~ 7行目の項目を編集してください。"
echo "[プロキシ設定スクリプト]"

while true; do
    echo "1. プロキシを登録"
    echo "2. プロキシを削除"
    echo "0. プロキシ設定の終了"
    read -p "選択してください (1 または 2 | 0 で終了) : " choice

    if [ "$choice" = "1" ]; then
        # プロキシ設定を登録
        echo "プロキシを登録します..."

        # シェル設定ファイルにプロキシ設定を追加 (重複チェック)
        if ! grep -q "export HTTP_PROXY=${HTTP_PROXY}" "$SHELL_CONFIG_FILE"; then
            cat <<EOF >> "$SHELL_CONFIG_FILE"
# HTTP/HTTPSプロキシ設定
export HTTPS_PROXY=${HTTPS_PROXY}
export HTTP_PROXY=${HTTP_PROXY}
export FTP_PROXY=${FTP_PROXY}

# Gitプロキシ設定
git config --global https.proxy ${HTTPS_PROXY}
git config --global http.proxy ${HTTP_PROXY}
git config --global ftp.proxy ${FTP_PROXY}
git config --global url.https://github.com/.insteadOf git://github.com/
EOF
        fi

        # システム全体のプロキシ設定 (/etc/environment)
        if [ -f /etc/environment ]; then
            # 既存の設定を確認し、なければ追加
            if ! grep -q "^http_proxy=" /etc/environment; then
                sudo bash -c "cat << 'EOF' >> /etc/environment
https_proxy=${HTTPS_PROXY}
http_proxy=${HTTP_PROXY}
ftp_proxy=${FTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
HTTP_PROXY=${HTTP_PROXY}
FTP_PROXY=${FTP_PROXY}
EOF"
            fi
        fi

        # curlの設定
        if [ ! -f "$HOME/.curlrc" ]; then
            touch "$HOME/.curlrc"
        fi

        # 既存の設定を確認し、なければ追加
        if ! grep -q "^proxy =" "$HOME/.curlrc"; then
            echo "proxy = \"http://${PROXY_HOST}:${PROXY_PORT}\"" >> "$HOME/.curlrc"
            echo "proxy-user = \"${PROXY_USER}:${PROXY_PASS}\"" >> "$HOME/.curlrc"
        fi

        # Linux環境のみ実行する処理
        if [[ "$(uname)" == "Linux" ]]; then
            # aptのプロキシ設定
            if [ -f /etc/apt/apt.conf ] || [ -d /etc/apt ]; then
                # apt.confファイルが存在しない場合は作成
                if [ ! -f /etc/apt/apt.conf ]; then
                    sudo touch /etc/apt/apt.conf
                fi
                
                # 既存の設定を確認
                if ! grep -q "Acquire::https::proxy" /etc/apt/apt.conf; then
                    echo "Acquire::https::proxy \"${HTTPS_PROXY}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
                    echo "Acquire::http::proxy \"${HTTP_PROXY}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
                    echo "Acquire::ftp::proxy \"${FTP_PROXY}\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
                fi
            fi

            # wgetのプロキシ設定
            if [ -f /etc/wgetrc ] || [ -d /etc ]; then
                # wgetrcファイルが存在しない場合は作成
                if [ ! -f /etc/wgetrc ]; then
                    sudo touch /etc/wgetrc
                fi
                
                # 既存の設定を確認
                if ! grep -q "^https_proxy" /etc/wgetrc; then
                    echo -e "# wgetプロキシ設定" | sudo tee -a /etc/wgetrc > /dev/null
                    echo "https_proxy = ${HTTPS_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
                    echo "http_proxy = ${HTTP_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
                    echo "ftp_proxy = ${FTP_PROXY}" | sudo tee -a /etc/wgetrc > /dev/null
                fi
            fi
        fi

        echo "プロキシの登録が完了しました。"

    elif [ "$choice" = "2" ]; then
        # プロキシ設定を削除
        echo "プロキシを削除します..."

        # シェル設定ファイルからプロキシ設定を削除
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/# HTTP\/HTTPSプロキシ設定/,/git config --global url.https:\/\/github.com\/.insteadOf git:\/\/github.com\//d' "$SHELL_CONFIG_FILE"
        else
            sed -i '/# HTTP\/HTTPSプロキシ設定/,/git config --global url.https:\/\/github.com\/.insteadOf git:\/\/github.com\//d' "$SHELL_CONFIG_FILE"
        fi

        # システム全体のプロキシ設定の削除 (/etc/environment)
        if [ -f /etc/environment ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sudo sed -i '' '/^https_proxy=/d' /etc/environment
                sudo sed -i '' '/^http_proxy=/d' /etc/environment
                sudo sed -i '' '/^ftp_proxy=/d' /etc/environment
                sudo sed -i '' '/^HTTPS_PROXY=/d' /etc/environment
                sudo sed -i '' '/^HTTP_PROXY=/d' /etc/environment
                sudo sed -i '' '/^FTP_PROXY=/d' /etc/environment
            else
                sudo sed -i '/^https_proxy=/d' /etc/environment
                sudo sed -i '/^http_proxy=/d' /etc/environment
                sudo sed -i '/^ftp_proxy=/d' /etc/environment
                sudo sed -i '/^HTTPS_PROXY=/d' /etc/environment
                sudo sed -i '/^HTTP_PROXY=/d' /etc/environment
                sudo sed -i '/^FTP_PROXY=/d' /etc/environment
            fi
        fi

        # Gitのプロキシ設定を削除
        git config --global --unset https.proxy
        git config --global --unset http.proxy
        git config --global --unset ftp.proxy
        git config --global --unset url.https://github.com/.insteadOf git://github.com/

        # curl設定ファイルからプロキシ設定を削除
        if [ -f "$HOME/.curlrc" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/^proxy =/d' "$HOME/.curlrc"
                sed -i '' '/^proxy-user/d' "$HOME/.curlrc"
            else
                sed -i '/^proxy =/d' "$HOME/.curlrc"
                sed -i '/^proxy-user/d' "$HOME/.curlrc"
            fi
        fi

        # Linux環境のみ実行する処理
        if [[ "$(uname)" == "Linux" ]]; then
            # aptのプロキシ設定を削除
            if [ -f /etc/apt/apt.conf ]; then
                sudo sed -i '/^Acquire::https::proxy/d' /etc/apt/apt.conf
                sudo sed -i '/^Acquire::http::proxy/d' /etc/apt/apt.conf
                sudo sed -i '/^Acquire::ftp::proxy/d' /etc/apt/apt.conf
            fi

            # wgetのプロキシ設定を削除
            if [ -f /etc/wgetrc ]; then
                sudo sed -i '/^# wgetプロキシ設定/d' /etc/wgetrc
                sudo sed -i '/^https_proxy/d' /etc/wgetrc
                sudo sed -i '/^http_proxy/d' /etc/wgetrc
                sudo sed -i '/^ftp_proxy/d' /etc/wgetrc
            fi
        fi

        echo "プロキシの削除が完了しました。"

    elif [ "$choice" = "0" ]; then
        # プロキシ設定の終了
        echo "終了しています..."
        echo "変更を反映するには、以下のコマンドを実行してください。: "
        echo "source $SHELL_CONFIG_FILE"
        break
    else
        echo "無効な選択です。1 または 2 、0 を選んでください。"
    fi
done
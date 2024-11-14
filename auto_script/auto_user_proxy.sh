#!/bin/bash

# プロキシ情報を変数に設定
PROXY_USER="User_ID"
PROXY_PASS="Password"
PROXY_HOST="ProxyServer_HostName"
PROXY_PORT="ProxyPort"
PROXY_DNS="proxy.dns.example.com"

# プロキシURLの設定（ダブルクォートをエスケープ）
HTTPS_PROXY="https://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"
HTTP_PROXY="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"
FTP_PROXY="ftp://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}/"

# シェルの確認と設定ファイルの指定
if [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    SHELL_CONFIG_FILE="$HOME/.bashrc"
fi

# プロキシ環境検出関数
check_proxy_environment() {
    local current_dns=""
    current_dns=$(grep "search" /etc/resolv.conf | head -n 1 | awk '{print $2}')
    
    if [ "$current_dns" = "$PROXY_DNS" ]; then
        return 0  # DNSが一致 -> プロキシ設定を有効化
    else
        return 1  # DNSが不一致 -> プロキシ設定を無効化
    fi
}

# プロキシ設定を適用する関数
set_proxy(){
    # 環境変数の設定
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
    
    # curlの設定
    if [ ! -f "$HOME/.curlrc" ]; then
        touch "$HOME/.curlrc"
    fi

    # 既存の設定を確認し、なければ追加
    if ! grep -q "^proxy =" "$HOME/.curlrc"; then
        echo "proxy = \"http://${PROXY_HOST}:${PROXY_PORT}\"" >> "$HOME/.curlrc"
        echo "proxy-user = \"${PROXY_USER}:${PROXY_PASS}\"" >> "$HOME/.curlrc"
    fi
}

# プロキシ設定を削除する関数
unset_proxy(){
    # シェル設定ファイルからプロキシ設定を削除
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/# HTTP\/HTTPSプロキシ設定/,/git config --global url.https:\/\/github.com\/.insteadOf git:\/\/github.com\//d' "$SHELL_CONFIG_FILE"
    else
        sed -i '/# HTTP\/HTTPSプロキシ設定/,/git config --global url.https:\/\/github.com\/.insteadOf git:\/\/github.com\//d' "$SHELL_CONFIG_FILE"
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
}

# メイン処理
check_proxy_environment
_dns_state=$?

if [ $_dns_state -eq 0 ]; then
    echo -e '\e[31mSet user proxy settings\e[m' 1>&2
    set_proxy
else
    echo -e '\e[36mUnset user proxy settings\e[m' 1>&2
    unset_proxy
fi
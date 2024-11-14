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
set_proxy() {
    # 環境変数の設定
    PROXY_SETTINGS_FILE=$(mktemp)
    cat << EOF > "$PROXY_SETTINGS_FILE"
export HTTPS_PROXY=${HTTPS_PROXY}
export HTTP_PROXY=${HTTP_PROXY}
export FTP_PROXY=${FTP_PROXY}
export https_proxy=${HTTPS_PROXY}
export http_proxy=${HTTP_PROXY}
export ftp_proxy=${FTP_PROXY}
EOF

    # 設定を現在のシェルに適用
    source "$PROXY_SETTINGS_FILE"

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

    # 一時ファイルを削除
    rm -f "$PROXY_SETTINGS_FILE"
}

# プロキシ設定を削除する関数
unset_proxy() {
    # 環境変数の削除
    unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY no_proxy NO_PROXY
    
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
}

# メイン処理
check_proxy_environment
_dns_state=$?

if [ $_dns_state -eq 0 ]; then
    echo -e '\e[31mSet system proxy settings\e[m' 1>&2
    set_proxy
else
    echo -e '\e[36mUnset system proxy settings\e[m' 1>&2
    unset_proxy
fi
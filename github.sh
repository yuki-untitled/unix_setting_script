#!/bin/sh

# GitHub情報を変数に設定 (それぞれの""内を適宜書き換えること)
GIT_USER="User_ID"              # ユーザー名
GIT_PASS="Password"             # アプリパスワード | https://github.com/settings/tokens でClassicのTokenを作成 repoにチェックを入れる
GIT_MAIL="MailAdress"           # GitHubアカウントのメールアドレス

# シェルの確認と設定ファイルの指定
if [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    SHELL_CONFIG_FILE="$HOME/.bashrc"
fi

# メニューの表示
echo "[注意] 実行する前にユーザー名やアプリパスワード、メールアドレスを設定しましたか？"
echo "       このファイルをエディタで開き、4 ~ 6行目の項目を編集してください。"
echo "[GitHub設定スクリプト]"

while true; do
    echo "1. GitHub情報を登録"
    echo "2. GitHub情報を削除"
    echo "0. GitHub設定を終了"
    read -p "選択してください (1 または 2 | 0 で終了) : " choice

    if [ "$choice" = "1" ]; then
        # GitHub情報を登録
        echo "GitHub情報を登録します..."

        # シェル設定ファイルにGitHub情報を追加 (重複チェック)
        if ! grep -q "git config --global user.name ${GIT_USER}" "$SHELL_CONFIG_FILE"; then
            cat <<EOF >> "$SHELL_CONFIG_FILE"
# GitHubユーザ名の設定
git config --global user.name ${GIT_USER}
# GitHubメールアドレスの設定
git config --global user.email ${GIT_MAIL}
EOF
        fi

        # .netrcにGitHub情報を追加 (重複チェック)
        if [ ! -f ~/.netrc ]; then
            touch ~/.netrc
            chmod 600 ~/.netrc  # .netrcファイルのパーミッションを設定
        fi
        if ! grep -q "machine github.com" ~/.netrc; then
            cat <<EOF >> ~/.netrc
# GitHub情報
machine github.com
login ${GIT_USER}
password ${GIT_PASS}
EOF
        fi

        echo "GitHub情報の登録が完了しました。"

    elif [ "$choice" = "2" ]; then
        # GitHub情報を削除
        echo "GitHub情報を削除します..."

        # シェル設定ファイルからGitHub情報を削除
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/# GitHubユーザ名の設定/,/git config --global user.email/d' "$SHELL_CONFIG_FILE"
        else
            sed -i '/# GitHubユーザ名の設定/,/git config --global user.email/d' "$SHELL_CONFIG_FILE"
        fi

        # Gitの設定を削除
        git config --global --unset user.name
        git config --global --unset user.email

        # .netrcからGitHub情報を削除
        if [ -f ~/.netrc ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/# GitHub情報/,/password/d' ~/.netrc
            else
                sed -i '/# GitHub情報/,/password/d' ~/.netrc
            fi
        fi

        echo "GitHub情報の削除が完了しました。"

    elif [ "$choice" = "0" ]; then
        # GitHub情報の設定終了
        echo "終了しています..."
        # ユーザーへの催促
        echo "変更を反映するには、以下のコマンドを実行してください。: "
        echo "source $SHELL_CONFIG_FILE"
        break;

    else
        echo "無効な選択です。1 または 2 、0 を選んでください。"
    fi
done
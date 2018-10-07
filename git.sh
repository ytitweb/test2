#!/bin/bash
# GitHub リポジトリ作成
#   $1 Githubユーザ名
#   $2 アカウントDBパス

IsSameConfig () {
     # ローカル・リポジトリ名を取得する
    reponame=$(basename "${repo_path}")
    if [ -f "${repo_path}/.git/config" ]; then
        local gitconfig_user=`git config --get user.name`
          # リモート・リポジトリ名を取得する https://code-examples.net/ja/q/efcdf1
        # basename -s .git `git config --get remote.origin.url`
        local gitconfig_remote_url=`git config --get remote.origin.url`
        local gitconfig_repo=`basename -s .git "${gitconfig_remote_url}"`

          # 起動引数と.git/configが一致するか
        [ 0 -lt $# ] && [ "$1" != "$gitconfig_user" ] && { echo -e ".git/configのユーザ名と起動引数のユーザ名が一致しません。\n  .git/configのユーザ名: ${gitconfig_user}\n  起動引数のユーザ名: ${1}"; exit 1; }
        [ "${reponame}" != "${gitconfig_repo}" ] && { echo -e ".git/configのリポジトリ名とカレントディレクトリ名が一致しません。他所からコピペした.gitを間違って使い回していませんか？\n  .git/configリポジトリ名: ${gitconfig_repo}\n  カレントディレクトリ名 : ${reponame}"; exit 1; }

        username=${gitconfig_user}
    fi
}
ExistReadMe () {
    for name in README ReadMe readme Readme; do
        for ext in "" .md .txt; do
            [ -f "${repo_path}/${name}${ext}" ] && return 0
        done
    done
    echo "カレントディレクトリに ReadMe.md が存在しません。作成してください。: "${repo_path}
    exit 1
}
QuerySqlite () {
    local sql=$1
    [ $# -lt 2 ] && local db_file=~/root/script/py/GitHub.Uploader.Pi3.Https.201802210700/res/db/GitHub.Accounts.sqlite3
    [ 2 -le $# ] && local db_file=$2
    local sql_file=/tmp/tmp.sql
    echo $sql > $sql_file
    local select=`sqlite3 $db_file < $sql_file`
    rm $sql_file
    echo $select
}
SelectUser () {
    # IsSameConfig で .git/config が存在していればその値を使う
    #[ -n $username ] && return
    [ ! -z "$username" ] || [ ! "${username:-A}" = "${username-A}" ] && return
    local sql="select Username from Accounts order by Username asc;"
    local select=`QuerySqlite "$sql"`
    echo "ユーザを選択してください。"
    select i in $select; do [ -n "$i" ] && { username=$i; break; }; done
}
IsRegistedUser () {
    local sql="select COUNT(*) as count from Accounts where Username='$1';"
    local select=`QuerySqlite "$sql"`
    [ "0" == "$select" ] && { echo "指定されたユーザ名はDBに登録されていません。: '$1' $db_file"; exit 1; }
    username=$1
}
GetPassMail () {
    local sql="select Password, MailAddress from Accounts where Username='$username';"
    local select=`QuerySqlite "$sql"`
    # "|"→"\n"→改行
    local value=`echo $select | sed -e "s/|/\\\\n/g"`
    local pass_mail=(`echo -e "$value"`)
    password=${pass_mail[0]}
    mailaddr=${pass_mail[1]}
    [ -z "$password" ] && { echo "パスワードが見つかりませんでした。DBを確認してください。"; exit 1; }
    [ -z "$mailaddr" ] && { echo "メールアドレスが見つかりませんでした。DBを確認してください。"; exit 1; }
}
OverwriteConfig () {
    # セキュリティ的に危険 https://qiita.com/azusanakano/items/8dc1d7e384b00239d4d9
    git config remote.origin.url "https://${username}:${password}@github.com/${username}/${reponame}"
}
CreateRepository () {
    if [ ! -d ".git" ]; then
        CreateLocalRepository
        CreateRemoteRepository
    fi
}
CreateLocalRepository () {
    echo "ローカル・リポジトリを作成します。"
    git init

    # リポジトリごとにユーザ名とメアドを設定する
    git config --global user.useConfigOnly true
    git config --global --unset user.name
    git config --global --unset user.email
    git config user.name "$username"
    git config user.email "$mailaddr"
    if [ -z "`git config --local user.name`" ]; then
        echo "git user.name がセットされていません。終了します。"
　　　　　rm -rf "${repo_path}/.git"
        exit 1
    fi
    if [ -z "`git config --local user.email`" ]; then
        echo "git user.email がセットされていません。終了します。"
　　　　　rm -rf "${repo_path}/.git"
        exit 1
    fi
}
CreateRemoteRepository () {
    echo "リモート・リポジトリを作成します。"
    #json='{"name":"'${REPO_NAME}'","description":"'${REPO_DESC}'","homepage":"'${REPO_HOME}'"}'it
    json='{"name":"'${reponame}'"}'
    echo $json | curl -u "${username}:${password}" https://api.github.com/user/repos -d @-
    git remote add origin https://${username}:${password}@github.com/${username}/${reponame}.git
}
CheckView () {
    git status -s
    echo "--------------------"
    git add -n .
    echo "--------------------"
    echo commit message入力するとPush。未入力のままEnterキー押下で終了。
    read answer
}
AddCommitPush () {
    if [ -n "$answer" ]; then
        git add .
        git commit -m "$answer"
        OverwriteConfig
        # stderrにパスワード付URLが見えてしまうので隠す
        git push origin master 2>&1 | grep -v http
    fi
}

repo_path=`pwd`
IsSameConfig "$@"
ExistReadMe
[ 0 -eq $# ] && SelectUser
[ 0 -lt $# ] && IsRegistedUser $1

GetPassMail
CreateRepository

echo "$username/$reponame"
#echo "username: "`git config --get user.name`
#echo "email: "`git config --get user.email`

# Add, Commit, Push
CheckView
AddCommitPush

unset username
unset reponame
unset password
unset mailaddr

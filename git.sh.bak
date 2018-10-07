#!/bin/bash
IsSameConfig_OLD () {
    if [ -f "${repo_path}/.git/config" ]; then
        #local gitconfig_reponame=$(python3 "$HOME/root/script/py/tool/git/config/GetRepoName.py" "${repo_path}")
        #local gitconfig_userrepo=($(python3 "/tmp/work/RaspberryPi.Home.Root.20180318143826/src/script/py/tool/git/config/Reader.py" "${repo_path}"))
        # 2018/08/11 複数アカウント使っていると違うアカウントでcommitされることがあった。~/.gitconfigの値が使われていた。どうすればいいか不明。とりあえず初回時にコミットせず一旦終了し、再度実行してコミットすると正しいアカウントでコミットできる。
        local gitconfig_userrepo=($(python3 "$HOME/root/script/py/tool/git/config/Reader.py" "${repo_path}"))
#        local gitconfig_userrepo=($(python3 "$HOME/root/script/py/tool/git/config/Reader.py" "${repo_path}/.git/config"))
        local gitconfig_user=${gitconfig_userrepo[0]}
        local gitconfig_repo=${gitconfig_userrepo[1]}
        echo ".git/config filepath: ${repo_path}/.git/config"
        echo ".git/config:[remote "origin"]Url user: ${gitconfig_user}"
        echo ".git/config:[remote "origin"]Url repo: ${gitconfig_repo}"
        [ 0 -lt $# ] && [ "$1" != "$gitconfig_user" ] && { echo -e ".git/configのユーザ名と起動引数のユーザ名が一致しません。\n  .git/configのユーザ名: ${gitconfig_user}\n  起動引数のユーザ名: ${1}"; exit 1; }
        [ "${cd_name}" != "${gitconfig_repo}" ] && { echo -e ".git/configのリポジトリ名とカレントディレクトリ名が一致しません。他所からコピペした.gitを間違って使い回していませんか？\n  .git/configリポジトリ名: ${gitconfig_repo}\n  カレントディレクトリ名 : ${cd_name}"; exit 1; }
        username=$gitconfig_user
        #.git/configのユーザ名が空値でなければセットする
#        [ ! -z "$gitconfig_user" ] || [ ! "${gitconfig_user:-A}" = "${gitconfig_user-A}" ] && username=$gitconfig_user
    fi
}
IsSameConfig () {
     # ローカル・リポジトリ名を取得する
    reponame=$(basename "${repo_path}")
    if [ -f "${repo_path}/.git/config" ]; then
        local gitconfig_user=`git config --get user.name`
          # リモート・リポジトリ名を取得する https://code-examples.net/ja/q/efcdf1
        # basename -s .git `git config --get remote.origin.url`
        local gitconfig_remote_url=`git config --get remote.origin.url`
        local gitconfig_repo=`basename -s .git "${gitconfig_remote_url}"`
        echo "gitconfig_remote_url: ${gitconfig_remote_url}"
        echo "gitconfig_repo: ${gitconfig_repo}"

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
#QuerySqlite () {
#    local sql=$1
#    [ $# -lt 2 ] && local db_file=~/root/script/py/GitHub.Uploader.Pi3.Https.201802210700/res/db/GitHub.Accounts.sqlite3
#    [ 2 -le $# ] && local db_file=$2
#    local this_dir=`dirname $repo_path`
#    local sql_file=${this_dir}/tmp.sql
#    echo $sql > $sql_file
#    local select=`sqlite3 $db_file < $sql_file`
#    rm $sql_file
#    echo $select
#}
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
#OverwriteConfig () {
    # セキュリティ的にどうよ
#    local before="	url = https://github.com/"
#    local after="	url = https://${username}:${password}@github.com/"
#    local config=".git/config"
#    cp "$config" "$config.BAK"
#    sed -e "s%$before%$after%" "$config.BAK" > "$config"
#    rm "$config.BAK"
#}
OverwriteConfig () {
    # セキュリティ的にどうよ https://qiita.com/azusanakano/items/8dc1d7e384b00239d4d9
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
#    git config --local user.name "$username"
#    git config --local user.email "$mailaddr"
    git config user.name "$username"
    git config user.email "$mailaddr"
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

# $1 Githubユーザ名
repo_path=`pwd`
IsSameConfig "$@"
ExistReadMe
[ 0 -eq $# ] && SelectUser
[ 0 -lt $# ] && IsRegistedUser $1

# パスワード取得と設定
GetPassMail
# 2018-10-07 https://qiita.com/uasi/items/a340bb487ec07caac799
#git config --global user.useConfigOnly true
# 2018-10-07 http://klabgames.tech.blog.jp.klab.com/archives/1033121546.html
#git config --local user.name "$username"
#git config --local user.email "$mailaddr"
# 2018/08/11 複数アカウント使っていると違うアカウントでcommitされることがあった。~/.gitconfigの値が使われていた。どうすればいいか不明。とりあえず初回時にコミットせず一旦終了し、再度実行してコミットすると正しいアカウントでコミットできる。
#echo "username:${username}"
#echo "email:${mailaddr}"

CreateRepository

echo "username:${username}"
echo "email:${mailaddr}"
echo "username: "`git config --get user.name`
echo "email: "`git config --get user.email`
if [ -z "`git config --local user.name`" ]; then
    echo "git user.name がセットされていません。終了します。"
    exit 1
fi
if [ -z "`git config --local user.email`" ]; then
    echo "git user.email がセットされていません。終了します。"
    exit 1
fi

# Add, Commit, Push
#repo_name=$(basename $repo_path)
echo "$username/$reponame"
CheckView
AddCommitPush

unset username
unset reponame
unset password
unset mailaddr

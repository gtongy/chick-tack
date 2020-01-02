---
date: 2020-01-01T16:50:14+09:00
linktitle: '黒い画面嫌いにおさらば！gitコマンドを使いこなしてterminalと仲良くなろうや'
title: '黒い画面嫌いにおさらば！gitコマンドを使いこなしてterminalと仲良くなろうや'
tags: ['git', 'cheetsheet']
weight: 16
---

![often-use-git-cheetsheet-header](/images/2020/often-use-git-cheetsheet/often-use-git-cheetsheet-header.png)

## はじめに

あなたは黒い画面は好きですか？  
どんなプログラムの勉強をしていても、どこかで必ずつまづくのってやっぱり黒い画面との接触かなと。  
まず git は出来ないとそもそも業務もまともに進められなくて、エンジニアの難易度をあげてる一つだよなぁとも思うのです。  
ただ、git ってかなり便利なコマンドなんですよ！とも伝えたい。git って他のコマンドと組み合わせて使うことで、さらに真価を発揮するので。  
この便利さを是非伝えたい！と思ったので、記事にしました。

## コマンド間の連結

[こちらの記事](https://qiita.com/greymd/items/32d4dcb6fff4832f1fc5)がかなり分かりやすくまとまっていて見やすいので一読するといいかなぁと思います。
個人的に普段使いでいうと

```
- pipe
  - commandA | commandB
- pipe + xargs
  - commandA | xargs -I{} commandB {}
- コマンド置換
  - commandA $(commandB)
- 入力対象としてのプロセス置換
  - commandA <(commandB)
- 制御演算子(&&)
  - commandA && commandB
    - commandAの終了コードがtrueの時にcommandBを実行
```

が頻出の連結方法でした。これを覚えておくと後々効いてくる場面が必ずあるので、覚えておくと良きかなというところ。

## 何はともあれ fzf(or peco)は必須！

fzf(or peco)等の command line fuzzy finder は絶対に必須です！  
これがあるかないかで作業効率は天と地ほど違います。まじで。  
fzf は pipe からリスト形式で標準入力を受け取り、インタラクティブに結果を絞り込み、標準出力として吐き出すコマンドです。  
簡単な例を出すと、以下のようなコマンドを実行して、

```
$ seq 10 | fzf | xargs -I{} echo {}
```

出力される結果を以下のように絞り込むことが出来ます。
![fzf](https://gyazo.com/8ab76e14418bb7159d0fd02f88d97105/raw)

fzf のいいところとして、ユーザーの入力を pipe の途中に埋め込んでユーザー任意の値が入力出来る点と、速度面に違和感なく操作出来るところかなと思います。  
割と基本のコマンドですが、もし知らなかったら今すぐ取っておきましょう！

## 普段使いの git コマンド + tips

普段使いの git コマンドとそれを使った tips の説明です。

- [git init](#git-init)
- [git clone](#git-clone)
- [git merge](#git-clone)
- [git fetch](#git-fetch)
- [git push](#git-push)
- [git status](#git-status)
- [git add](#git-add)
- [git checkout](#git-checkout)
- [git commit](#git-commit)
- [git rm](#git-rm)
- [git grep](#git-grep)
- [git log](#git-log)
- [git branch](#git-branch)
- [git diff](#git-diff)

<!--adsense-->

## git init

```sh
# gitの初期化
git init "{directory name}"
```

新規で空のリポジトリを作成する or 既存のディレクトリにリポジトリを作成することが出来ます。  
既存の作成済みのリポジトリに対して git init を実行した場合には既存のリポジトリの上書きは行いません。

### tips

git hooks 等を git 管理していて、そのテンプレートを初期設定として使いたい

```sh
# https://git-template.readthedocs.io/en/latest/ をサンプルとして使用
# home dir配下に共通で使いたいtemplateを作成
$ git clone https://github.com/greg0ire/git_template ~/.git_template
# init時にtemplateの指定
$ git init --template='/path/to/.git_template'
# init時に毎回指定しなくても、git configで指定することも可能
$ git config --global init.templatedir '~/.git_template'
```

## git clone

```sh
$ git clone "{remote repository path}"
```

リポジトリをローカルのディレクトリ内に複製。リモートに置かれたリポジトリ等をローカルに置くのが主な使い方です。  
ssh, https 等のプロトコルを経由して取得出来ます。

### tips

local に置かれたリポジトリでも複製。ただあんまり活用箇所はないかな？(local の方が速度は気持ち早い)

```sh
# リモートのリポジトリを複製
$ git clone "local repository name"
```

## git merge

```sh
# 現在のブランチにdevelopブランチの最新の状態を取り込み(merge時はmerge commitを作成)
$ git merge --no-ff develop
```

別 branch の変更分を取り込みます。

### tips

merge した時に conflict した時には以下コマンド。

```sh
# conflict時にmergeを中止
$ git merge --abort
# conflict時に変更差分をaddし終わった後にmergeを続行
$ git merge --continue
```

## git fetch

```sh
# リモートリポジトリのmaster branch変更差分を全て取得
$ git fetch remote_name master
# リモートリポジトリの変更差分一括取得
$ git fetch --all
```

リモートリポジトリの変更差分をローカルに落とし込みます。

### tips

現在のブランチの変更差分を取り込み。

```sh
 $ CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD) && git fetch origin $CURRENT_BRANCH && git merge --no-ff "origin/$CURRENT_BRANCH"
```

## git push

```sh
# ローカルのdevelopブランチをリモートへ反映
$ git push remote_name develop
```

ローカルのブランチの変更差分をリモートへ反映させます。

### tips

現在のブランチの push(master 直 push はさせない)。

```sh
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD); if [ $CURRENT_BRANCH != "master" ]; then git push origin $CURRENT_BRANCH; else echo "current branch is master"; fi
```

## git status

```sh
# リポジトリ全体の状態確認
$ git status
# フォルダ指定も可能
$ git status test/
```

ワークツリー, インデックス内のファイル, ディレクトリの状態を確認することが出来ます。(インデックスについての説明は[こちら](https://backlog.com/ja/git-tutorial/intro/04/))  
実際作業しているファイルと既に編集済の差分を確認する時に使用します。

### tips

`git status -s`で git status の short mode で必要な情報だけに絞り込み。  
実行時にはファイルのパスと、左に以下のような記号が表示されます。

```sh
$ git status -s
M a.txt
?? b.txt
```

記号は以下のような意味を持ちます。

```
 o   ' ' = unmodified
 o   M = modified
 o   A = added
 o   D = deleted
 o   R = renamed
 o   C = copied
 o   U = updated but unmerged
```

## git add

```sh
# ファイルをインデックスに追加
git add filename
# ファイルを一括で追加したい。個人的にはなんでも追加されてしまうのでtipsの方法で追加を推奨
git add -A
```

ワークツリーで見つかった現在のコンテンツを使用してインデックスを更新します。  
git commit でスナップショット的に保存する対象のファイルを決定するために使用します。

### tips

ファイルの差分を確認しながら add したい時は以下コマンドを実行します。

```sh
git add -p $(git status -s -uno | awk '{print $2}' | fzf | tr '\n' ' ')
```

使用例はこんな感じです。tab 選択で add したいファイルを絞り込むことが出来ます。

![git add -p](https://gyazo.com/02062d8f9ae5d1af1b7f6d8372694b87/raw)

## git checkout

```sh
# developブランチへ移動
$ git checkout develop
# 現在のブランチから新しいfeatureブランチを作成
$ git checkout -b feature/new_branch
# インデックス未登録のファイルの変更差分を削除
$ git checkout filename
```

ブランチの切替だったり、インデックス未登録のファイルの変更の削除だったりを実行するコマンドです。

### tips

ローカルのブランチ一覧から目的のブランチへの移動は以下コマンドで行えます。

```sh
$ git branch | fzf | xargs git checkout
```

## git commit

```sh
# index登録済のファイルに対してcommit(変更差分のsnapshot)を作成(vi mode)
$ git commit
# vi modeなしでcommitの作成
$ git commit -m "message name"
# 直前のコミットの取り消し
# 既にindexに登録済の変更差分は前回のcommitに取り込まれる(commit messageも編集可能)
$ git commit --amend
```

変更差分をリポジトリへ登録します。

### tips

これは git commit の副次的な話ですが、[husky](https://github.com/typicode/husky), [lint-staged](https://github.com/okonet/lint-staged)等を入れると git commit 時の hooks を利用して linter の実行だったりを組み込めて便利なので是非入れて欲しいところです。  
package.json に以下を追加して commit する直前だったり、push する直前に npm scripts だったり lint の実行だったりが出来ます。

![husky, lint-staged exec](https://gyazo.com/915406a6791b9ed5ffab145871c806c8/raw)

以下コードを package.json に記述して関連ライブラリを追加すれば実行できます。

```
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "pre-push": "npm run lint-fix"
    }
  },
  "lint-staged": {
    "*.{js,jsx}": [
      "eslint --fix",
      "git add"
    ],
    "*.{ts,tsx}": [
      "tslint --fix",
      "git add"
    ]
  }
}
```

## git rm

```sh
# ファイルを削除
$ git rm filename
# フォルダを強制削除
$ git rm -rf test/
# インデックス内から削除(ファイルは残った状態)
$ git rm --cached filename
```

ワークツリー, インデックスからファイルを削除します。

### tips

git で既に登録済みのファイルから絞り込んで、インデックスから削除します(ファイルは残った状態)。

```sh
git rm --cached $(git ls-files | fzf | tr '\n' ' ')
```

## git reset

```sh
# 直前のコミットの取り消し
$ git reset --hard HEAD^
# add取り消し
$ git reset HEAD
```

現在の状態を指定の状態にリセットします。
何かをやらかして、直前の行動を取り消したりする行動でよく出会うコマンドです。

### tips

git reset はやらかした時に出会うコマンドだと思います。  
この辺は自分が解説するよりも良記事はゴロゴロ転がっているため、いいなぁと思った記事をピックアップさせていただきます。

- [[git reset (--hard/--soft)]ワーキングツリー、インデックス、HEAD を使いこなす方法](https://qiita.com/shuntaro_tamura/items/db1aef9cf9d78db50ffe)
- [Git でやらかした時に使える 19 個の奥義](https://qiita.com/muran001/items/dea2bbbaea1260098051)

## git grep

git-grep に関しては、以下記事の方に詳細をまとめているのでこちらを参照ください。

[git grep のすゝめ](https://chick-tack.blog/posts/2018/git-grep/)

## git log

```sh
# 全てのcommit logを表示
$ git log
# 表示数の制限
$ git log -n 10
```

リポジトリ内の commit log を表示します。

### tips

ここ最近で自分の作業分でスタイルの修正をした変更差分を抜き出して差分確認([gitmoji](https://gitmoji.carloscuesta.me/)を使用)

![git log grep](https://gyazo.com/aa88775d4e1845eda941984c3361f620/raw)

```sh
$ git log --pretty=oneline --author="ここに作業者のusernameを入力" --no-merges --grep=":lipstick:" -n 10 | fzf | head -n 1 | awk '{print $1}' | xargs -I{} git diff {}
```

git の log を見た目を tree 形式で表示

![git log tree](https://gyazo.com/ebf69fc93d1d44cb3356723625aff3de/raw)

```
git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
```

## git branch

```sh
# ブランチの作成
$ git branch branch_name
# リポジトリ内のbranchを表示
$ git branch -a
# ブランチの削除
$ git branch -d branch_name
# ブランチの削除(強制)
$ git branch -D branch_name
# ブランチのrename
$ git branch -m old_branch_name new_branch_name
```

リポジトリ内に登録された branch に対する CRUD(作成/読み取り/更新/削除) を実行出来るコマンドです。

### tips

git branch -a は他のコマンドと噛み合わせて使うことが多いので、git diff の tips の方で利用します。

## git diff

```sh
# git add前の変更差分の確認
$ git diff
# commit同士の差分の確認
$ git diff before_commit_hash..after_commit_hash
# branch同士の差分の確認
$ git diff before_branch_name..after_branch_name
```

コミットや、作業ツリー間の変更やその他ファイルの差分を確認するコマンドです。

### tips

リモート/ローカルのブランチ差分があるかどうかを確認。(左が差分なし、右が差分あり)

![remote/local branch](https://gyazo.com/77256ac1aed99506e0a269eb0530c9a4/raw)

```sh
REMOTE_BRANCH=$(git branch -a | grep remotes | grep -v "*" | fzf | xargs) && git fetch && git diff "${REMOTE_BRANCH##*/}" "origin/${REMOTE_BRANCH##*/}"
```

## まとめ

git でよく使う tips をまとめました。  
このあたりは結構普段使いでよく使うコマンドなので、覚えておくといつか便利な場面が来ると思います！  
是非 git のコマンド群をたくさん応用して使って、terminal と仲良くなってもらえると幸いです。

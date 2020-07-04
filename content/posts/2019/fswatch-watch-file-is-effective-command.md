---
date: 2019-11-24T00:38:39+09:00
linktitle: 'swaggerのfile-mergeだったりgolangのorm自動生成のフォルダ監視にfswatchはいいぞ'
title: 'swaggerのfile-mergeだったりgolangのorm自動生成のフォルダ監視にfswatchはいいぞ'
tags: ['fswatch', 'swagger', 'go-xorm/cmd', 'swagger-merger']
weight: 16
---

![fswatch header](/images/2019/fswatch-watch-file-is-effective-command/fswatch-header.png)

最近、コード自動化を諸々整備している中で、ファイルの変更だったり DB の変更が発生したタイミングで色々コマンドを叩く必要があるんですよね。  
これ結構しんどくて、特に swagger とかだと stoplight studio で yaml 修正して、mock サーバの疎通確認するぞって時に、動いてないことに気付いたり。  
よくよく確認してみると swagger-merger 実行してないじゃん...みたいなことがよくあります。  
こういう時にファイル変更した時にコマンド実行してくれる方法あったらなーと調べたら fswatch がどうやら良さそうなので使ってみました。

## swagger の file merge

swagger のファイルの merge コマンド。swagger-merger は[こちら](https://www.npmjs.com/package/swagger-merger)を参考ください。

```sh
fswatch -0 path/to | xargs -0 -I {} swagger-merger -i path/to/openapi.yaml -o openapi.yaml
```

## 解説

fswatch で path/to 配下を watch。その後 xargs で該当のコマンドを実行。  
今回は swagger-merger で merge を実行。基本的にはこれだけ。

<!--adsense-->

## ちょっと応用してみて golang の ORM 自動生成

fswatch の可能性をかなり感じたため、他にもちょっと試してみました。  
golang の ORM で [xorm](https://github.com/go-xorm/xorm) という package があるのですが、この xorm には [cli](https://github.com/go-xorm/cmd) が存在していて 、mysql の table 定義から golang の orm を自動生成してくれる優れものです。  
自分は mysql は docker で container を立ち上げて使っているのですが、ここで table の永続化のために data を mount してます。  
ここで mount した data は table が作成されるタイミングで作成した table と同名のファイルを作成します。

「あれ？これ fswatch + xorm cli 組み合わせてみたら table 作成したら自動で ORM のコード生成されることないか？」

ということで shell を組んでみました。

まず、xorm の template。

```go:path/to/template/struct.go.tpl
package {{.Models}}

{{$ilen := len .Imports}}
{{if gt $ilen 0}}
import (
	{{range .Imports}}"{{.}}"{{end}}
)
{{end}}

{{range .Tables}}
type {{Mapper .Name}} struct {
{{$table := .}}
{{range .ColumnsSeq}}{{$col := $table.GetColumn .}}	{{Mapper $col.Name}}	{{Type $col}}
{{end}}
}
{{end}}
```

```json:path/to/template/config
lang=go
genJson=1
```

このあたりは xorm においてある[サンプル](https://github.com/go-xorm/cmd/tree/master/xorm/templates/go)を参考に template を作成しています。そして以下コマンドをコマンドライン上で実行します。

```sh
fswatch -e --event Created --event Updated -e '.*\.ibd$' mysql/data/dbname | xargs -n 1 -I{} basename -s '.frm' {} | xargs -n 1 -I{} xorm reverse mysql "user:pass@tcp(127.0.0.1:3306)/dbname?charset=utf8" ./path/to/template path/to/output {}
```

その後、CREATE TABLE を実行してみます。

![golang autogen orm](/images/2019/fswatch-watch-file-is-effective-command/golang-autogen-orm.gif)

```go:accounts.go
package example

import (
	"time"
)

type Accounts struct {
	Id            int64
	FirstName     string
	FirstNameKana string
	LastName      string
	LastNameKana  string
	Email         string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}
```

自動生成されたファイルはこちらです。うまく生成されていますね！

## まとめ

ファイル監視を行う fswatch とその周辺の自動化ツールの説明をしていました。  
今回紹介した swagger と xorm ですが、swagger は言わずもがな、openapi-generator と組み合わせて自動でソースコードを生成したりとか(api client, model 等)、xorm の cli ツールとかの ORM を自動生成するツールだったりとかでかなり便利なツール群です。  
このあたりのコマンド実行を仕組み化するとなるとタスクランナー(grunt, gulp)とかもあるとは思うのですが、自分は shell とか黒い画面でさくっと実行したり、 npm scripts 書いたり、 make 書いた方が楽だと思うので shell は覚えて損ないなと感じました。

このファイル自動生成とか好きだったり興味がある人は是非 fswatch だったりコードの自動化の周辺ツールを試してみてください！面白いですよ。

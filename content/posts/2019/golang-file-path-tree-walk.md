---
date: 2019-06-23T14:09:50+09:00
linktitle: '[golang]複数のファイルパスから多階層のjson文字列を作成したい'
title: '[golang]複数のファイルパスから多階層のjson文字列を作成したい'
tags: ['golang']
weight: 16
---

## 始めに

golang で json 文字列を出力する時に、構造体内で json タグを利用すれば多階層の json 文字列を表現できます。  
これを利用すれば、ファイルのパスのスライスが渡された時にシュッと木構造の json 文字列 が作れるので、その技の紹介します。

## 一番最終的に吐き出される json のサンプル

先に、与える slice と最後に吐き出される json 文字列のサンプルをあげます。

- slice

```go
paths := []string{"image/hoge/hoge.jpg", "image/hoge/fuga.jpg", "image/hoge/piyo.jpg"}
```

- json 文字列

```json
{
  "name": "root folder",
  "children": [
    {
      "name": "image",
      "children": [
        {
          "name": "hoge",
          "children": null,
          "files": [
            {
              "name": "hoge.jpg"
            },
            {
              "name": "fuga.jpg"
            },
            {
              "name": "piyo.jpg"
            }
          ]
        }
      ],
      "files": null
    }
  ],
  "files": null
}
```

## 木構造の作成

まずフォルダ, ファイルの構造体を作成します。

```go
package main

import (
	"path/filepath"
	"strings"
)

type Folder struct {
	Name    string    `json:"name"`
	Folders []*Folder `json:"children"`
	Files   []*File   `json:"files"`
}

type File struct {
	Name string `json:"name"`
}
```

ルートフォルダに対してフォルダ, ファイルが紐づいている構造を考えます。
問題はシンプルに考えたいので、基本的にファイル, フォルダの属性は name のみとしています。  
最終的に`json.Marshal`で json に変換を行うため、あらかじめ json タグを付与しておきます。

## 各ポインタの作成、ファイル,フォルダの検索,追加

```go
func NewFolder(name string) *Folder {
	return &Folder{
		Name: name,
	}
}

func (f *Folder) FindFolder(ff *Folder) *Folder {
	for _, folder := range f.Folders {
		if folder.Name == ff.Name {
			return folder
		}
	}
	return nil
}

func (f *Folder) AppendFolder(ff *Folder) {
	f.Folders = append(f.Folders, ff)
}

func (f *Folder) AppendFile(fl *File) {
	f.Files = append(f.Files, fl)
}

type File struct {
	Name string `json:"name"`
}

func NewFile(name string) *File {
	return &File{
		Name: name,
	}
}
```

各ポインタの作成、ファイル,フォルダの検索,追加の処理の追加箇所です。
特段特別なことはしていなくて、

- 各ポインタの作成
  - 受け取った引数からポインタを返却
- ファイル, フォルダの検索
  - for range で愚直にフォルダ内を検索
- ファイル, フォルダの検索
  - append を利用して動的に内部プロパティにポインタを格納

ちょっと癖がある部分で言えば、Folder 自身も Folder 群を保持していて、同じ構造体を使っているけど、作成されるポインタに多階層的に違うポインタとして表現されているところくらいかな？というところです。

<!--adsense-->

## 処理の実行箇所

```go
import (
	"path/filepath"
	"strings"
)

const (
	pathSepalate    = "/"
	isFirstDirIndex = 0
)

func (f *Folder) Walk(path string) {
	currentFolder := &Folder{}
	for i, dirname := range strings.Split(filepath.Dir(path), pathSepalate) {
		newFolder := NewFolder(dirname)
		if i == isFirstDirIndex {
			foundFolder := f.FindFolder(newFolder)
			if foundFolder == nil {
				f.AppendFolder(newFolder)
				currentFolder = newFolder
			} else {
				currentFolder = foundFolder
			}
		} else {
			foundFolder := currentFolder.FindFolder(newFolder)
			if foundFolder == nil {
				currentFolder.AppendFolder(newFolder)
				currentFolder = newFolder
			} else {
				currentFolder = foundFolder
			}
		}
	}
	file := NewFile(filepath.Base(path))
	currentFolder.AppendFile(file)
}
```

要となる実際にフォルダ, ファイルを追加する箇所です。
folder のポインタ内で Walk を実装しているところで、この呼び出し側ではこんな感じの実装になっています。

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	paths := []string{"image/hoge/hoge.jpg", "image/hoge/fuga.jpg", "image/hoge/piyo.jpg"}
	root := NewFolder("root folder")
	for _, path := range paths {
		root.Walk(path)
	}
	b, err := json.Marshal(root)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(string(b))
}
```

呼び出しの Walk に着目すると、root は Folder のポインタを新規で作成し、そのポインタの Walk を呼び出しています。  
呼び出される度に、内部では各パスに対してフォルダの検索を行って、同じフォルダが存在するかどうかを確認しながら、currentFolder を用いて現在のポインタの位置をずらして、上記でいうところの root を作成して行きます。  
フォルダパスは単一方向の directory の path を保持しているため、複雑な実装もなくシンプルにディレクトリの separator を用いてフォルダを分割して、重複を確認しながら、内部の root を更新して行くことで、root をもりもり成長されて行きます。  
処理の最後に、json.Marshal で構造体に対して json への変換を行います。
この処理の実行結果を確認して見ると

```sh
$ go build . && ./tree-walk | jq .

{
  "name": "root folder",
  "children": [
    {
      "name": "image",
      "children": [
        {
          "name": "hoge",
          "children": null,
          "files": [
            {
              "name": "hoge.jpg"
            },
            {
              "name": "fuga.jpg"
            },
            {
              "name": "piyo.jpg"
            }
          ]
        }
      ],
      "files": null
    }
  ],
  "files": null
}
```

となります。うまく実行されていますね！

## まとめ

golang を使って、複数のファイルパスから多階層の json 文字列を作成しました。  
json.Marshal が多階層の構造体に対しても綺麗に json ファイルを作成してくれるので、こういった多階層の json の表現力は、golang はしやすくていいですね！
問題自体はデータ構造とアルゴリズムにあるシンプルな木構造の例でしたが、実際に使われるところだと、こんな感じになるのかな？と。  
どうしても業務だと普段なかなか木構造に触れる機会も少ないところも多いと思うので、手触り改めて確認するきっかけになれば幸いです。

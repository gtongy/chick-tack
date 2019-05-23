---
date: 2019-05-23T19:18:21+09:00
linktitle: "golangのif err != nil {}面倒だと言ったな？"
title: "golangのif err != nil {}面倒だと言ったな？"
tags: ["golang", "karabiner element"]
weight: 16
---

## はじめに

任せろ！華麗に解決してやるぞ！

こんにちは、GTO です。
今回問題となる

```
if err != nil {

}
```

このイディオム、なかなかタイプ数多くて大変ですよね。
始めは自分もこれを見て、毎回これをタイプするのか....と思っていたのですがそんな過去の自分、そして記事を読んでくださっているそこのあなたへ。

**<font style="font-size:38px;">キー 1 つタイプするだけで打てるぞ</font>**

## ちょっと注意

この記事はネタ要素強めです。ただあなたの golang 漬けの生活をちょっと豊かに出来るかも？と思ったので記事にしました。

## きっかけ

きっかけは以下の tweet。

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Problem solved. <a href="https://twitter.com/hashtag/golang?src=hash&amp;ref_src=twsrc%5Etfw">#golang</a> <a href="https://t.co/GRueLZAwgY">pic.twitter.com/GRueLZAwgY</a></p>&mdash; Nate Finch (@NateTheFinch) <a href="https://twitter.com/NateTheFinch/status/899730215957561344?ref_src=twsrc%5Etfw">August 21, 2017</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

**<font style="font-size:38px;">So Cool...</font>**

何年前の記事を引っ張って来てんねんって感じですが、昔々自分はこの tweet をみて、これがしたくてタッチバー付きの Macbook Pro が欲しくなったくらいに興奮したのを今でも覚えています。  
同時に、Macbook Pro(タッチバーなし)を買ってちょうどすぐのタイミングで流れて来たために同時に非常に悔しい思いをしたことも覚えています。  
ただ、あの頃の俺とは違うんだ...。絶対に解決してやる...!!!

## そこで Karabiner Elements ですよ

そこで閃いたのが、Karabiner Elements で key_code の設定作ればいいんじゃね？ということですよ。  
Karabiner Elements?って人に簡単に説明すると、Karabiner Elements は簡単に Mac のキーバインドを変えられるツールです。  
マウスの操作をキーボードで操作したり、矢印キーを vim のキーバインドに変更出来たりといろんな場面で使える万能なツールです。  
また、この Karabiner Elements は、一つのキータイプに対して複数のキータイプを入力することが出来ます。

## あれ？ってことはつまり...

そう、つまり一つのキータイプに if err != nil {}の設定を記述してあげればいいのです。  
ということで、~/.config/karabiner/karabiner.json の rules の記述の中に、

```
{
  "description": "enter if err != nil {}",
  "manipulators": [
    {
      "from": {
        "key_code": "right_shift"
      },
      "to": [
        { "key_code": "i" },
        { "key_code": "f" },
        { "key_code": "spacebar" },
        { "key_code": "e" },
        { "key_code": "r" },
        { "key_code": "r" },
        { "key_code": "spacebar" },
        {
          "key_code": "1",
          "modifiers": [
            "shift"
          ]
        },
        {
          "key_code": "hyphen",
          "modifiers": [
            "shift"
          ]
        },
        { "key_code": "spacebar" },
        { "key_code": "n" },
        { "key_code": "i" },
        { "key_code": "l" },
        { "key_code": "spacebar" },
        {
          "key_code": "close_bracket",
          "modifiers": [
            "shift"
          ]
        },
        { "key_code": "return_or_enter" }
      ],
      "type": "basic"
    }
  ]
}
```

を追加してあげます。中を見てもらえると分かると思いますが、愚直に 1 文字ずつ文字をタイプしています。  
冗長なのでは？と思ったそこのあなた。はい、その指摘間違っていません。他に方法が思いつかなかったんや.....。許してくれ....。

追加して保存すると、Karabiner Elements に以下のように設定が追加されていれば成功です。

![karabiner-elements-preferences](/images/2019/auto-insert-golang-error-handling/karabiner-elements-preferences.png)

小ネタですが、Karabiner-EventViewer を見れば、どの key_code で登録されているのか見れるから困ったらおすすめです。

![karabiner-event-viewer](/images/2019/auto-insert-golang-error-handling/karabiner-event-viewer.png)

この name のカラムに表示されるのが key_code に入力する値です。

## それでは if err != nil {} を入力してみる。

さあ、行くぞ。

![go-error-handling-auto-insert](/images/2019/auto-insert-golang-error-handling/go-error-handling-auto-insert.gif)

🎉🎉🎉🎉🎉 出来たぞ〜〜〜 🎉🎉🎉🎉🎉

## 終わりに

今回は golang のちょっとしたネタを投下してみました。  
実はこのネタ自体はもう何番煎じだよって感じですが、自分の中で解決出来たので大満足です。  
今回はうまく技術を無駄使い出来たのでこの辺で〜 👏

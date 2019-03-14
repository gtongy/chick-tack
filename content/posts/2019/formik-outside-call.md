---
date: 2019-03-09T23:53:41+09:00
linktitle: "FormikのComponents外からメソッドを呼び出したい"
title: "FormikのComponents外からメソッドを呼び出したい"
tags: ["react", "react native", "formik"]
weight: 16
---

## はじめに

React とか、React Native で実装するときに Form の実装がやたらと辛い。state で form 内全ての要素を state で管理しなきゃいけないのはぶっちゃけ初見殺しだった。
なんかいい感じの外部ライブラリないかなーと探してみると

- redux form
- formik

辺りが有名なライブラリとして見つかる。
個人的な意見としては、redux の処理って必要以上に記述しすぎると Component が持つべき責任を飛び越えすぎて処理が追いづらくなってくるんじゃないかという懸念があって、store には全体の状態を管理するものまでに留められるのなら、出来るだけ小さく留めたい。  
特に form とかはその Component 内で完結出来るものなような気がしていたので、そう言う意味では formik って結構ドンピシャに使いやすい。  
しかし、Component の内部でなんとか出来る素晴らしさはもちろんいいが、要件によっては逆に外部から値をとってくるとかの処理があったりすると小技が必要だったりする。  
React Native で QR コード読み取り等で他の画面に遷移したりして別のコンポーネントに移動して Form の内容を reset したい時に今回ハマりました。  
今回はそんな時に有用な小技の紹介です。

## TL;DR

React の Refs を使って、Formik の Component を外部から参照する

## そもそも React の Refs とは？

公式の記述をそのまま引用して

> Refs provide a way to access DOM nodes or React elements created in the render method
> https://reactjs.org/docs/refs-and-the-dom.html

と言うことらしいです。Refs は render メソッド内の定義された React elements もしくは DOM 要素へアクセスするための API です。
正直、上記のリンクに記述された内容をみる限り今回の要件にバッチリあってそうなのでこれを使って実装しました。

## 実装

下記の Formik の Component に対して`React.createRef()`で参照用のオブジェクトを実装する必要があるので

```jsx
import SampleForm from './SampleForm';
import { View } from 'react-native';

class ParentComponent extends Component {
  constructor(props) {
   super(props);
   this.formRef = React.createRef();
  }
  render() {
    return (
      <View>
        <SampleForm name="hoge" ref={this.formRef}>
      </View>
    );
  }
}
```

```jsx
import { Button, View, Text } from 'react-native';

class SampleForm extends Component {
  render() {
    const { ref, name } = this.props;
    return (
      <Formik
        ref={ref}
        initialValues={{ name: name }}
      >
        {({ values, handleSubmit, handleChange }) => {
          return (
            <View>
              <View>
                <TextInput
                  onChangeText={handleChange("name")}
                  value={values.name}
                  name="name"
                />
              </View>
              <Button onPress={handleSubmit}>
                <Text>register</Text>
              </Button>
            </Form>
          );
        }}
      </Formik>
    );
  }
}
```

のように親から props で refs を渡してあげれば解決です。

## ただし注意点

なんとなく想像はつきますが、refs を多様すれば何処からでも呼び出せる訳なので汚コードになりやすいです。

- フォーカス、テキスト選択、またはメディア再生の管理
- アニメーションの起動
- サードパーティの DOM ライブラリとの統合

等の場合に限って使うべきとドキュメントにも記述があるので、今回で言えばサードパーティの DOM ライブラリとの統合で利用しているのでまあ回避策としてはありなのかな？と思います。

## 終わりに

Formik、React だとどうしても苦しい Form の扱いやすくかつ簡素にかけるのでおすすめです。

https://jaredpalmer.com/formik/

Form 系のライブラリの一つの選択肢としていじってみるのも楽しいので是非。

---
date: 2019-05-08T21:12:57+09:00
linktitle: 'go-playground/validatorでエラーField名だけ英語にするのはやめて'
title: 'go-playground/validatorでエラーField名だけ英語にするのはやめて'
tags: ['go', 'go-playground/validator']
weight: 16
---

## 始めに

go の validation でよくお世話になっている[go-playground/validator](https://github.com/go-playground/validator)があるのですが、構造体の Field ごとに validation をかけられて便利ですが、エラーが起きた時にユーザー側で表示するメッセージの Field 名は構造体のまま取ってきてしまいます。  
さあ困った...。  
そんな時の小技と内部の実装を追ってみたのでその紹介。

## TL;DR

RegisterTagNameFunc で独自の tag を作成しそこから field 名を取得出来るようにする

## Validation を行うパッケージの実装内部

```go
package main

import (
	"fmt"
	"reflect"

	"github.com/go-playground/locales/ja"
	ut "github.com/go-playground/universal-translator"
	"gopkg.in/go-playground/validator.v9"
	ja_translations "gopkg.in/go-playground/validator.v9/translations/ja"
)

var (
	uni      *ut.UniversalTranslator
	validate *validator.Validate
	trans    ut.Translator
)

type User struct {
	ID   int    `jaFieldName:"ユーザーid" validate:"max=11"`
	Name string `jaFieldName:"名前" validate:"oneof=taro takashi"`
}

func main() {
	Init()
	user := User{
		ID:   123456789012,
		Name: "Samu",
	}
	err := Validate(user)
	fmt.Println(GetErrorMessages(err))
}

// Init 初期化処理
func Init() {
	ja := ja.New()
	uni = ut.New(ja, ja)
	t, _ := uni.GetTranslator("ja")
	trans = t
	validate = validator.New()
	validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		fieldName := fld.Tag.Get("jaFieldName")
		if fieldName == "-" {
			return ""
		}
		return fieldName
	})
	ja_translations.RegisterDefaultTranslations(validate, trans)
}

// Validate バリデーションの実行
func Validate(i interface{}) error {
	return validate.Struct(i)
}

// GetErrorMessages エラーメッセージ群の取得
func GetErrorMessages(err error) []string {
	if err == nil {
		return []string{}
	}
	var messages []string
	for _, m := range err.(validator.ValidationErrors).Translate(trans) {
		messages = append(messages, m)
	}
	return messages
}
```

```shell
$ go run main.go
[ユーザーidは11かより小さくなければなりません 名前は[taro takashi]のうちのいずれかでなければなりません]
```

<!--adsense-->

## 処理内部を追ってみた

さすがにこれだとなんか出来ちゃった感が半端ないので、実際どういう経路で処理が実行されるのかソースを潜って実装を追ってみた。

バリデーションのエラー文の日本語の translation は`go-playground/universal-translator`でエラー文自体を翻訳するインスタンス自体を定義して、RegisterDefaultTranslations で translation の定義を取得。
`validate.Struct(i)`でバリデーションを実行したのちに、エラーが発生していたら、そのメッセージを`ValidationErrors.Translate()`で translation している。

まず universal-translator の初期化から処理からスタート。

```go
// New returns a new UniversalTranslator instance set with
// the fallback locale and locales it should support
func New(fallback locales.Translator, supportedLocales ...locales.Translator) *UniversalTranslator {

	t := &UniversalTranslator{
		translators: make(map[string]Translator),
	}

	for _, v := range supportedLocales {

		trans := newTranslator(v)
		t.translators[strings.ToLower(trans.Locale())] = trans

		if fallback.Locale() == v.Locale() {
			t.fallback = trans
		}
	}

	if t.fallback == nil && fallback != nil {
		t.fallback = newTranslator(fallback)
	}

	return t
}

// GetTranslator returns the specified translator for the given locale,
// or fallback if not found
func (t *UniversalTranslator) GetTranslator(locale string) (trans Translator, found bool) {

	if trans, found = t.translators[strings.ToLower(locale)]; found {
		return
	}

	return t.fallback, false
}
```

ロケールごとの fallback を GetTranslator で locale を指定して取得している。

```go
ja_translations.RegisterDefaultTranslations(validate, trans)
```

の RegisterDefaultTranslations の内部実装は長いので端折ると`translations`と呼ばれる

```go
[]struct {
		tag             string
		translation     string
		override        bool
		customRegisFunc validator.RegisterTranslationsFunc
		customTransFunc validator.TranslationFunc
}
```

上記のような構造体に対して

```go
v.RegisterTranslation(t.tag, trans, t.customRegisFunc, t.customTransFunc)
```

を実行し、`validator.Validate`の`RegisterTranslation`を呼び出す。ここで`go-playground/universal-translator`に対してバリデーションを追加してる。  
今度はエラー文を取得するところから、最終的に表示されるエラーの内容がどうやって生成されるのかを調べたい。

```go
func GetErrorMessages(err error) []string {
	for _, m := range err.(validator.ValidationErrors).Translate(trans) {
		messages = append(messages, m)
	}
}
```

`(validator.ValidationErrors).Translate(trans)`では

```go
func (ve ValidationErrors) Translate(ut ut.Translator) ValidationErrorsTranslations {
	trans := make(ValidationErrorsTranslations)
	var fe *fieldError
	for i := 0; i < len(ve); i++ {
		fe = ve[i].(*fieldError)
		trans[fe.ns] = fe.Translate(ut)
	}
	return trans
}
```

`fieldError.Translate(ut)`を実行。この内部が

```go
func (fe *fieldError) Translate(ut ut.Translator) string {

	m, ok := fe.v.transTagFunc[ut]
	if !ok {
		return fe.Error()
	}

	fn, ok := m[fe.tag]
	if !ok {
		return fe.Error()
	}

	return fn(ut, fe)
}
```

locale ごとの`fieldError.v.transTagFunc`を実行。この transTagFunc の実行でタグごとで処理を切り分けて translation を実行している。  
そして、`translations/ja`に記述された`customTransFunc`がこの transTagFunc にあたる処理になっていて、内部では universal-translator の

```go
T(key interface{}, params ...string) (string, error)
C(key interface{}, num float64, digits uint64, param string) (string, error)
O(key interface{}, num float64, digits uint64, param string) (string, error)
R(key interface{}, num1 float64, digits1 uint64, num2 float64, digits2 uint64, param1, param2 string) (string, error)
```

上のメソッドを呼び出していた。こいつらが実際のエラー文の文字列の正体で、ここの params に入力される string の値から第一引数の値だったりをカスタム出来るって話。ゴールが見えてきた。
例えば max の場合には

```go
func(ut ut.Translator, fe validator.FieldError) string {
	//...
	switch kind {
	default:
		t, err = ut.T("max-number", fe.Field(), ut.FmtNumber(f64, digits))
	}

	return t
},
```

のように、`ut.T()`を呼び出していて、第一引数に`fe.Field()`を渡している。`ut.T()`は

```go
// T creates the translation for the locale given the 'key' and params passed in
func (t *translator) T(key interface{}, params ...string) (string, error) {

	trans, ok := t.translations[key]
	if !ok {
		return unknownTranslation, ErrUnknowTranslation
	}

	b := make([]byte, 0, 64)

	var start, end, count int

	for i := 0; i < len(trans.indexes); i++ {
		end = trans.indexes[i]
		b = append(b, trans.text[start:end]...)
		b = append(b, params[count]...)
		i++
		start = trans.indexes[i]
		count++
	}

	b = append(b, trans.text[start:]...)

	return string(b), nil
}
```

このようにテキストの変換を実行している。ここで、param に設定された値に関してもここで変換が行われる。
第一引数として渡す`Field()`に関しては

```go
func (fe *fieldError) Field() string {
	return fe.ns[len(fe.ns)-int(fe.fieldLen):]
}
```

`fieldError`の`Namespace`(fe.ns で表現されている箇所)から field 名までを slice で切り取って取得しているのが分かる。
`fe.ns`は`validate.RegisterTagNameFunc`で返ってきた値に対してそのまま namespace として使えるので、最初に説明した

```go
validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		fieldName := fld.Tag.Get("jaFieldName")
		if fieldName == "-" {
			return ""
		}
		return fieldName
	}
)
```

を行うことによって、自身が設定した構造体のタグに対してフィールド名を自由に決めることが出来る。
これで解決！！スッキリしました。

## まとめ

構造体の Field 名から独自に Tag を設定し、日本語のエラー文を表示する実装をしてみました。  
ただ、多言語に対応という訳ではなく、日本語にのみ対応となっているのでちょっとどうかな...構造体から Field 名も決められるしまあ使い所によっては便利だと感じました。  
ただ、json で記述してそれを読み込むみたいな i18n のやり方が自分はしっくり来るので、ちょっとその辺りなんとかならないかなとは思うところ。

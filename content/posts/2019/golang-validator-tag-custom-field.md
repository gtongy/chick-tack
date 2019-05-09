---
date: 2019-05-08T21:12:57+09:00
linktitle: "go-playground/validatorでField名だけ英語にするのはやめて"
title: "go-playground/validatorでField名だけ英語にするのはやめて"
tags: ["go", "go-playground/validator"]
weight: 16
---

## 始めに

goのvalidationでよくお世話になっている[go-playground/validator](https://github.com/go-playground/validator)があるのですが、構造体のFieldごとにvalidationをかけられて便利ですが、エラーが起きた時にユーザー側で表示するメッセージのField名は構造体のまま取ってきてしまいます。  
さあ困った...。  
そんな時の小技と内部の実装を追ってみたのでその紹介。

## TL;DR

RegisterTagNameFuncで独自のtagを作成しそこからfield名を取得出来るようにする

## Validationを行うパッケージの実装内部

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

## 処理内部を追ってみた

さすがにこれだとなんか出来ちゃった感が半端ないので、実際どういう経路で処理が実行されるのか、潜ってみた。

バリデーションのエラー文の日本語翻訳は``go-playground/universal-translator``でエラー文自体を翻訳するインスタンス自体を定義して、RegisterDefaultTranslationsで翻訳を定義を取得。
``validate.Struct(i)``でバリデーションを実行したのちに、エラーが発生していたら、そのメッセージをValidationErrors.Translateで翻訳している。

まずuniversal-translatorの初期化から処理からスタート。

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

ロケールごとのfallbackを定義してそれをGetTranslatorでlocaleを指定して取得している。
この時に、universal-translatorのTranslator構造体を一緒に取得している。
RegisterDefaultTranslationsは長いが、

```
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

でvalidator.ValidateのRegisterTranslationを呼び出す。ここでuniversal-translatorに対してバリデーションを追加してるみたい。
今度はエラー文を取得するところから、最終的に表示されるエラーの内容がどうやって生成されるのかを調べたい。

```go
func GetErrorMessages(err error) []string {
	for _, m := range err.(validator.ValidationErrors).Translate(trans) {
		messages = append(messages, m)
	}
}
```

ValidationErrorsのTranslate(ut ut.Translator)では

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

fieldError.Translate(ut)を実行。この内部が

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

で、transTagFuncの処理を実行。このtransTagFuncの実行の中身が実際にTranslationを実行している処理の内部っぽい。
そして、translations/jaに記述されたcustomTransFuncってのがこのtransTagFuncにあたる処理になっていて、内部ではuniversal-translatorの

```go
T(key interface{}, params ...string) (string, error)
C(key interface{}, num float64, digits uint64, param string) (string, error)
O(key interface{}, num float64, digits uint64, param string) (string, error)
R(key interface{}, num1 float64, digits1 uint64, num2 float64, digits2 uint64, param1, param2 string) (string, error)
```

上のメソッドを呼び出していた。こいつらが実際のエラー文の文字列の正体で、ここのparamsに入力されるstringの値から第一引数の値だったりをカスタム出来るって話。ゴールが見えてきた。
例えばmaxの場合には

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

のように、ut.T()の呼び出し時に第一引数にfe.Field()を渡している。この内部は

```go
func (fe *fieldError) Field() string {
	return fe.ns[len(fe.ns)-int(fe.fieldLen):]
}
```

でfieldErrorのNamespaceからfield名までをsliceで切り取って取得しているのが分かる。
fe.nsはvalidate.RegisterTagNameFuncで帰ってきた値に対してそのままnamespaceとして使えるので、最初に説明した

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
これで解決！！

## まとめ

構造体のField名から独自にTagを設定し、日本語のエラー文を表示する実装をしてみました。  
ただ、多言語に対応という訳ではなく、日本語にのみ対応となっているので使い所は考えそうですが、構造体からField名も決められるしまあ使い所によっては便利だと感じました。  
ただ、jsonで記述してそれを読み込むみたいなi18nのやり方が自分はしっくり来るので、ちょっとその辺りなんとかならないかな....。  
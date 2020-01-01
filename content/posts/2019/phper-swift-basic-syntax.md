---
date: 2019-03-29T20:05:30+09:00
linktitle: '業務PHPerだがSwiftに入門した。基本構文編'
title: '業務PHPerだがSwiftに入門した。基本構文編'
tags: ['PHP', 'Swift']
weight: 16
---

## はじめに

個人でアプリがたくさん作りたい。  
業務では PHP とか JS とか, 個人では Go とかを触ることが多く Web 開発が多かったが、アプリを初めて作って AppStore と Google Play にあげた時、妙な高揚感があった。  
自分のアイデアとかを共有したりするために、アプリって一番手軽だなぁと感じた。  
Baas の発展もあって、個人で作るくらいだったら Firebase でいい感じのもの作れてしまうし。  
個人では React を触っていたこともあって、React Native(Expo)を使って初めてアプリを作ったが(また今度紹介させてください！)、なにぶん実装に不安を抱えながら実装を進めることになる。  
アプリ開発したことないから、もしハマった箇所がネイティブ依存だった場合にソースを追えないから。  
それだと、もし自分が考えたアイデアを形にしようとした時に言語が分からないから....ってなるのはめっちゃもったいないなと思った。  
なので、Swift を勉強をやっていきたい。  
PHPer だろうが、なんだろうが割と作ろうと思えばアプリでもなんでも作れるんやでってこともついでに証明したい。  
エモさたっぷりの冒頭ですが、今回は基本構文編をお送りします。

## 環境

- Xcode
  - 10.1
- Swift
  - 4.2.1
- PHP
  - 7.0

## とにもかくにも困った時にはどこ見ればいいのか

ともかく先にも後にも、PHP でいう php.net, JS でいう Mozilla のようなリファレンスはまあ欲しい。  
探してみると、どうやら Xcode 内に埋め込まれているらしい。  
Xcode > Help > Developer Documentation から開ける。以下画像は Logging を参照。

![Xcode Developer Documentation](/images/2019/phper-swift-basic-syntax/xcode-developer-documentation.png)

困ったらここを見ればいいのかな？実際に実装して行く時に振り返ってみるとする。

## Swift は静的型付け, 型推論あり

Swift は 静的型付け、型推論ありの言語。  
型ありはいい。型推論もあるみたいだし、言語として記述のし易さも整ってそう。

## Swift の対話モード

いわゆる`$ php -a`みたいなこと。Swift の場合は`$ swift`でいける。
自分が実行した時には、したのエラーが出て焦った。

```sh
Traceback (most recent call last):
  File "<input>", line 1, in <module>
  File "/usr/local/Cellar/python@2/2.7.15_1/Frameworks/Python.framework/Versions/2.7/lib/python2.7/copy.py", line 52, in <module>
    import weakref
  File "/usr/local/Cellar/python@2/2.7.15_1/Frameworks/Python.framework/Versions/2.7/lib/python2.7/weakref.py", line 14, in <module>
    from _weakref import (
ImportError: cannot import name _remove_dead_weakref
```

どうやら、swift が原因なのではなく、brew の python が原因らしい。当分 python は使わないだろうから`$ brew remove python@2 --ignore-dependencies`で削除。

```sh
$ swift
Welcome to Apple Swift version 4.2.1 (swiftlang-1000.11.42 clang-1000.11.45.1). Type :help for assistance.
  1>
```

うん、行けた。
Swift は Xcode を使って Playground で画面上でもデバッグができるらしい。まあ、とりあえず 動作確認するくらいなら、使い慣れた黒い画面で大丈夫そう。

## 標準出力への吐き出しとか

var_dump 的な？のは Swift では`print()`でいける。以下から基本構文を PHP と比較していく。

## 基本構文

### 変数定義

- Swift

```swift
// mutable
var intVal: Int = 1
// immutable
let intValImmutable: Int = 2
```

- PHP

```php
<?php
$intVal = 1;
```

var, let で mutable, immutable の定義を選べる。なので、再代入すると

```swift
 intValImmutable = 2
error: repl.swift:2:17: error: cannot assign to value: 'intValImmutable' is a 'let' constant
intValImmutable = 2
```

でエラーで弾かれる。

### 配列定義

- Swift

```swift
var stringArray: [String] = ["foo", "bar", "baz"]
var intArray: [Int] = [1,2,3]
```

- PHP

```php
<?php
$stringArray = ["foo", "bar", "baz"]
```

似たような感じ。PHP でいう連想配列も Swift にも存在していて Dictionary という名前でつけられる。

- Swift

```swift
var dictionary: [String: String] = [
  "foo": "FOO",
  "bar": "BAR",
  "baz": "BAZ"
]
```

- PHP

```php
<?php
$associativeArray = [
  "foo": "FOO",
  "bar": "BAR",
  "baz": "BAZ"
]
```

でほぼ違和感なし。  
PHP だと引数の型とかつけられなくて、入ってくる添字とか値が結構カオスになることあるけど、こうやって型ついてると安全でいいなと思った。

### for とか if とかの定義

- Swift

```swift
// for
for val in 0..<5 {
    print(val)
}
// if
let isValid = true
if isValid {
   print("isValid")
}
```

- PHP

```php
<?php
// for
foreach(range(1,4) as $val) {
    var_dump($val);
}
// if
$is_valid = true;
if ($is_valid) {
    var_dump("isValid");
}
```

range の記述が少し特殊な印象。swift4.1 からこの Range を表す型に[変更があった](https://qiita.com/koher/items/4ae98d71b8eb06ab1b79#range)らしい。Float とか Int とか String の Range に型をつける訳だからこの複雑性にはなるほどとはなったが、まあ多い。慣れなのかな。
あと、かっこはない。

### 関数定義

- Swift

```swift
func add(a: Int, b: Int) -> Int {
  return a + b
}
add(a: 1, b: 2)
```

- PHP

```php
function add($a: int, $b: int) int {
    return $a + $b;
}
add(1,2)
```

ここは PHP の方が書きやすいかなと思った。  
定義時の変数名わざわざ書かなくてもコードジャンプすれば可読性も高いから、まあ個人的にはわざわざ引数の命名書くんか...と思った。  
ただ、Swift がいいなと思うのは、クロージャが使えるのが JS っぽくていいなと思った。第一引数に無名関数を渡せるのも良い。  
クロージャーの基本は

```
{ (引数) -> 戻り値の型 in 式 }
```

で記述でき、以下のような記法も使えるということになる。

```swift
var targets = [1,2,3,4]
// map
targets.map({ (number: Int) -> Int in return number * 2 })  // => [2,4,6,8]

// filter
target.filter({ (number: Int) -> Bool in return number % 2 == 1 })  // => [3, 7, 9, 5]

// reduce
numbers.reduce(0, { (total: Int, number: Int) -> Int in
  return total + number
})
```

あれ、js と似とる...  
for 文はあんまり書かなくてもストレスなくかけそう。

### 例外

- Swift

```swift
do {
    try login(url: "")
} catch LoginError.invalid {
    print("invalid")
} //...
```

- PHP

```php
try {} catch (LoginInvalidException $e) {
    echo $e->getMessage();
}
```

do catch で例外を細くする処理に対して明示的に try を記述する必要がある。
また、エラーを持つメソッドに対して

```swift
func login() throws -> Void {
    if self.isNotConnectNetwork() {
        throw LoginError.netWork
    }
}
```

のように、throws で例外を宣言できる。

### クラス定義

- Swift

```swift
class User {
    public private(set) var id: Int
    public private(set) var name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
let taro = User(id: 1, name: "taro")
print(taro.name)
```

- PHP

```php
<?php
class User {
    private $id;
    private $name;
    public function __construct(int $id, string $name) {
        $this->id = $id;
        $this->name = $name;
    }
    public function getName(): string {
        return $this->name;
    }
}
$taro = new User(1, "taro");
var_dump($taro->getName()); // "taro
```

Swift だと、`public private(set) var (プロパティ名): 型名`で、setter は private, getter は public のようなアクセス権の切り分けができるみたい。
基本に記述だけならまあとっつきにくさはない。ただ、namespace とかのファイル分割は、Swift と PHP では違うみたい。またファイル分割で困った時に。

<!--adsense-->

### Struct

これは Swift 特有のもの。
Struct は Class と似たような処理を記述はできるが、Class とは性質がまったく異なる。
そもそも Struct とは値型であり、参照型ではない。
どういうことかというと、以下を参照。

```swift
struct CardStruct {
    public var number: Int
    init(number: Int) {
        self.number = number
    }
}
class CardClass {
    public var number: Int
    init(number: Int) {
        self.number = number
    }
}
var cardStruct1 = CardStruct(number: 1)
var cardStruct2 = cardStruct1
cardStruct1.number = 2
print("cardStruct1: \(cardStruct1.number), cardStruct2: \(cardStruct2.number)") // cardStruct1: 2, cardStruct2: 1
var cardClass1 = CardClass(number: 1)
var cardClass2 = cardClass1
cardClass1.number = 2
print("cardClass1: \(cardClass1.number), cardClass2: \(cardClass2.number)") // cardClass1: 2, cardClass2: 2
```

struct の場合、変数宣言時に毎回インスタンスを作成するため、変数を宣言する度に毎回新しいオブジェクトのコピーを行っている。  
class の場合、参照型であるため、変数にインスタンスを渡しても、同じインスタンスを参照する。  
また、struct では継承を使うことができない。  
まあでも、継承を使えなくても、interface のようなものを定義して(Swift では protocol というものがあるらしい。後述)、メソッドだけ定義したものを引数に渡してダックタイピングすればよくね？とか思うので、思い切って struct を使った方がソースが綺麗になりそうな直感的な印象。

### Enum

これも Swift 特有のもの。というか PHP にはないっていうのが適切？いわゆる列挙型。Java とか馴染みがある人にはすっと入る。  
ただ、値を列挙する、以下の値型 Enum から

```swift
enum CardSuit: String {
    case spade = "spade"
    case heart = "heart"
    case diamond = "diamond"
    case club = "club"
}
```

関連する値をもつこともできる。

```swift
enum Response {
    case Result(String, String)
    case Error(String)
}
```

他にも、struct 内に定義できたり、プロパティとして宣言できたり、使われ方は幅広いので使いどころにさじ加減はありそう。

### Protocol

これは interface と似た感じと考えて良さそう。ただ、大きな違いはプロパティもかけるところ。

- Swift

```swift
protocol Animal {
    var name: String {get}
    func bark() -> String
}

struct Cat: Animal {
    let name: String
    init(name: String) {
        self.name = name
    }
    func bark() -> String {
        return "にゃー"
    }
}

struct Owner {
    func ote(animal: Animal) {
        print("\(animal.name)、お手")
        print(animal.bark())
    }
}

var taro = Owner()
var mike = Cat(name: "mike")
// mike、お手
// にゃー
taro.ote(animal: mike)
```

- PHP

```php
interface Animal {
    public function bark(): string;
}

class Cat implements Animal {
    private $name;
    public function __construct(string $name) {
        $this->name = $name;
    }
    public function getName() {
        return $this->name;
    }
    public function bark(): string {
        return "にゃー";
    }
}

class Owner {
    public function ote(Animal $animal) {
        var_dump("{$animal->getName()}、お手");
        var_dump($animal->bark());
    }
}

$taro = new Owner();
$mike = new Cat("mike");
// mike、お手
// にゃー
$taro->ote($mike);
```

struct を使う時に、メソッドをいい感じに委譲させて使うのが一番利用回数が増えそう。

### Optional

- Swift

```swift
struct User {
    var id: Int
    var name: String
    var age: Int? // nilが入るプロパティ
    init(id: Int, name: String, age: Int?) {
        self.id = id
        self.name = name
        self.age = age
    }
}
var taro = User(id: 1, name: "taro", age: nil)
print(taro.age) // nil
```

- PHP

```php
class User {
    private $id;
    private $name;
    private $age; // nullableなプロパティ
    public function __construct(int $id, string $name, ?int $age) {
        $this->id = $id;
        $this->name = $name;
        $this->age = $age;
    }
    public function getAge() {
        return $this->age;
    }
}

$taro = new User(1, "taro", null);
var_dump($taro->getAge()); // null
```

nullable な値の宣言に利用可能。入力するフォームの値によっては存在しない可能性があるものによっては使える。

## 終わりに

基本構文をあらかたやってみました。
PHP でいうところの〜の部分 + α でざっくりと基本は抑えられたかな？とは思います。
基本構文はあらかた抑えた上で今後 Swift を使ってアプリを作っていこう。

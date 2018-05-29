---
date: 2018-05-25T01:06:25+09:00
linktitle: "LaravelのCollectionについてソースを少しかじってみた"
title: "LaravelのCollectionについてソースを少しかじってみた"
tags: ["PHP"]
weight: 16
---

## LaravelのCollectionについてソースを少しかじってみた

最近本家のコードを追ってみていて、laravelのcollectionから学べることが多くて面白かった。

### そもそもCollectionってどんなことができるか？

データ配列を操作するためのラッパークラス。
標準クラスでは表現しきれないようなかゆい部分に手が届いているのがこのクラスの良いところです。

### メソッドの内部を追ってみる

例えば``avg``メソッドを例に出して見ると
```php
/**
 * collect()でCollectionインスタンスを新規作成
 * @see framework/src/Illuminate/Support/helpers.php: L421
 */
$average = collect([['foo' => 10], ['foo' => 10], ['foo' => 20], ['foo' => 40]])->avg('foo'); // 20
```
のように、配列のオブジェクトを生成し、指定したキーをの平均値を弾き出すようなメソッドです。
このメソッドを追って見ると、
```php
public function avg($callback = null)
{
  if ($count = $this->count()) {
    return $this->sum($callback) / $count;
  }
}
```
のように、内部でsum()の呼び出しを行っていて、このsum()は
```php
public function sum($callback = null)
{
	if (is_null($callback)) {
    	return array_sum($this->items);
    }

    $callback = $this->valueRetriever($callback);

    return $this->reduce(function ($result, $item) use ($callback) {
        return $result + $callback($item);
    }, 0);
}
```
のように、callbackで受け取った値を使って、再帰的に合計したものを返却するメソッドになっています。
そして、そのcallbackで受けとるvalueRetrieverは
```php
protected function valueRetriever($value)
{
	if ($this->useAsCallable($value)) {
		return $value;
	}

	return function ($item) use ($value) {
		return data_get($item, $value);
	};
}
```
のようなメソッドになっていて、useAsCallableメソッドは渡されてきた値がstring, もしくは関数としてコール可能な形式以外で渡された場合にその値をそのまま返却します。
そして、そのブロック文を通過した$valueは内部のコールバックでdata_getに渡され、
```php
function data_get($target, $key, $default = null)
{
  // process...
	while (! is_null($segment = array_shift($key))) {
    // process...
		if (Arr::accessible($target) && Arr::exists($target, $segment)) {
			$target = $target[$segment];
		}
    // process...
    return $target;
}
```
このdata_getの内部でcallbackで受けとった値を変換し、dataのみを取得させるcallbackを返却しています。
こうすることで初期に渡した配列に対してcallbackで受け取り、配列内でavgに定義した引数の値のみを抽出した値に対してreduceメソッド内でarray_reduceの呼び出しを行い合計値を取り出し、あとはこの取り出したsum()に対して配列の合計数をcountを割ればavgメソッドとしてCollectionを使って配列の平均値を弾き出すことができる...といった流れになっています。

### まとめ

Collectionクラスは単純に配列の操作をリッチにさせるラッパーにすぎないが、その内部の処理を追って見ることで

 - メソッド毎の責任のうまい分散方法
 - callbackを使った処理の簡素化

を追って確認ができた。
callbackを使って配列の操作を使うことで、内部の処理をうまいこと切り分けることができるのもいい点だなと感じた。
PHP連想配列の操作はいい意味でも悪い意味でも扱いやすいため、内部が複雑な構造になりやすいが、配列のラッパーオブジェクト一つ使って見ると複雑な処理が少しでも簡素になっていいかも。
単純な処理の内部でもCollectionの内部の処理は簡素に綺麗に書かれてるから読んで勉強になるので是非追ってみてください。


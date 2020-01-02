---
date: 2019-07-07T17:22:02+09:00
linktitle: 'ソースコードリーディングで理解する、AWS X-Ray SDK Go'
title: 'ソースコードリーディングで理解する、AWS X-Ray SDK Go'
tags: ['golang', 'AWS', 'AWS X-Ray']
weight: 16
---

## はじめに

業務内でサーバーレス構成の実装を進めて行く過程で、リリース後のボトルネック調査だったり、障害点の特定だったりをなるべく高速で回して行きたいなという思いがありました。
その際に AWS X-Ray がどうやら良さそう？というところがあったため、AWS X-Ray を導入してみたのですが、

- 各サービスの受け渡しのインターフェースがシンプルだが内部実装がかなりブラックボックス感
- 各サービスに渡す context.Context は内部でどう使われてるのかな
- 開発者が内部実装を意識しない設計になっているのかなりすごいな。複数のコンポーネントをまたいでどうやって処理を追加してるんだろう

という、疑問もあり内部の処理がかなり気になったので、せっかくなのでソースコードリーディングしながら内部の実装を追っていきたいなと思います。

## そもそも AWS X-Ray とは

とにもかくにも[ドキュメント](https://docs.aws.amazon.com/ja_jp/xray/latest/devguide/aws-xray.html)は一読必須です。  
AWS X-Ray はアプリケーションが処理するリクエストに関するデータを収集するサービスです。
AWS X-Ray が提供するものとして、

- リクエスト内の各処理をトレース
- 他 AWS サービスの呼び出しにしようする AWS SDK クライアントを計測
- 内外の HTTPWeb サービスの呼び出しを計測

等が出来ます。
X-Ray を使用することで、下記にあげたような利点があげられれます。

- 収集した実行トレースから実行時間軸のグラフを表示可能

![trace](/images/2019/aws-xray-sdk-go-source-reading/trace.png)

- サービスグラフと呼ばれるグラフに対して、開始地点からどのサービスで死んだのか等を一目で確認可能

![searvice-graph](/images/2019/aws-xray-sdk-go-source-reading/searvice-graph.png)

呼び出しは、X-Ray SDK を利用して X-Ray daemon と呼ばれる UDP ポート 2000 番を解放しているサーバー経由で AWS X-Ray API を呼び出す方法と、直接 AWS X-Ray API の呼び出しを行う 2 通りの方法があります。

![overview](/images/2019/aws-xray-sdk-go-source-reading/overview.png)

今回のコードリーディングでは X-Ray SDK から X-Ray daemon の呼び出し箇所を追っていければなと思います。  
実際、daemon が送られてきたパケットを一括で HTTP Request で結果を送信する箇所は今回省きます。

## 処理内部リーディング対象リポジトリ

- [AWS X-Ray SDK for Go](https://github.com/aws/aws-xray-sdk-go)
- [AWS SDK for Go](https://github.com/aws/aws-sdk-go)

## Lambda で実行する際の AWS X-Ray daemon の起動タイミング

Lambda 内で AWS X-Ray SDK を利用して X-Ray への Trace を行う際に Lambda 内で daemon の起動はどうなっているのかというと、設定を一つ追加することで、Lambda の実行時に自動的に起動することができます。

[Lambda 環境の AWS X-Ray daemon](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-x-ray-daemon.html)

daemon には最大で 16MB〜Lambda の使用メモリの 3%が使用されるようです。もし並列に goroutine を起動してギリギリまでメモリを使っていたりすると、このあたりで障害が起こる可能性もあるので注意が必要ですね。
SAM の定義上から Tracing をオンにするためには、yaml の Properties 内に

```sh
Tracing: Active
```

を追加すると、CloudFormation でいうところの[TracingConfig](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-lambda-function-tracingconfig.html)の設定を追加することができ、トレースモードを ON にすることができます。

## 実行の起点

Lambda 内でまずはじめに

```go
xray.Configure(xray.Config{
	LogLevel:  "error",
	LogFormat: "[%Level] [%Time] %Msg%n",
})
```

のように、xray の config の設定を追加します。
この箇所のソースは global に定義された config の変数に対して設定の追加を行っています。
また、global な変数に対して race condition が発生しないように、sync.RWMutex を利用して

```go
globalCfg.Lock()
defer globalCfg.Unlock()
```

のように、グローバルに定義された設定変数の書き換えを行っています。

## xray.AWS の呼び出しによる Handler の追加

golang で各 AWS のサービスに対して設定を追加する時に、

```go
svc := s3.New(s3Session)
xray.AWS(svc.Client)
```

のように、各サービスに対して作成した Client を引数としています。
ここでの svc は以下のような構造体を返却します。

```go
type Client struct {
	request.Retryer
	metadata.ClientInfo

	Config   aws.Config
	Handlers request.Handlers
}
```

ここでの Handlers に当たる箇所は aws のリクエスト処理のライフサイクルを扱う際の中核となる処理で、SDK 内の各サービスで各処理はこの handler 内の各処理を委譲して実装されています。
以下記事はこの handler を利用した custom handler を作成する例です。

- [Using Custom Request Handlers](https://aws.amazon.com/jp/blogs/developer/using-custom-request-handlers/)

各ステップの Handler に対して、無名関数が list の形で定義されていて、先頭や末尾に新しい関数を追加することで、実行前後での処理を追加することができます。

これを利用して、AWS X-Ray では独自の Handler を各ステップの実行前後に登録しています。
具体的には、

```go
func AWS(c *client.Client) {
	// ...
	// handlerの登録
	pushHandlers(&c.Handlers, "")
}

// 各フェーズの前後にHandlerを追加
func pushHandlers(handlers *request.Handlers, completionWhitelistFilename string) {
	handlers.Validate.PushFrontNamed(xRayBeforeValidateHandler)
	handlers.Build.PushBackNamed(xRayAfterBuildHandler)
	handlers.Sign.PushFrontNamed(xRayBeforeSignHandler)
	handlers.Send.PushBackNamed(xRayAfterSendHandler)
	handlers.Unmarshal.PushFrontNamed(xRayBeforeUnmarshalHandler)
	handlers.Unmarshal.PushBackNamed(xRayAfterUnmarshalHandler)
	handlers.Retry.PushFrontNamed(xRayBeforeRetryHandler)
	handlers.AfterRetry.PushBackNamed(xRayAfterRetryHandler)
	handlers.Complete.PushFrontNamed(xrayCompleteHandler(completionWhitelistFilename))
}
```

のような形で、Handler を登録しています。
PushFrontNamed, PushBackNamed は、以下のようなコードになっていて

```go
// 前にhandlerを登録
func (l *HandlerList) PushFrontNamed(n NamedHandler) {
	if cap(l.list) == len(l.list) {
		l.list = append([]NamedHandler{n}, l.list...)
	} else {
		l.list = append(l.list, NamedHandler{})
		copy(l.list[1:], l.list)
		l.list[0] = n
	}
}

// 後にhandlerを登録
func (l *HandlerList) PushBackNamed(n NamedHandler) {
	if cap(l.list) == 0 {
		l.list = make([]NamedHandler, 0, 5)
	}
	l.list = append(l.list, n)
}
```

各 handler 内の List の前後に対して append で handler 追加しています。次に各 NamedHandler の詳細を追っていきます。

## Handler 内の実装詳細

segment 作成の一連の流れを追うため、部分的に xRayBeforeValidateHandler, xRayAfterBuildHandler の処理を見てみます。
他の処理も同様に subsegment の開始と終了時の流れは似ているので、切り取って追っていきます。

```go
var xRayBeforeValidateHandler = request.NamedHandler{
	Name: "XRayBeforeValidateHandler",
	Fn: func(r *request.Request) {
		// 初回のsubsegmentの登録。初回は新規作成したルートとなる親segmentを作成した後、
		// AWSのサービス名の開始を記録するsegmentを作成する
		ctx, opseg := BeginSubsegment(r.HTTPRequest.Context(), r.ClientInfo.ServiceName)
		opseg.Namespace = "aws"
		// 上記のctxを使って新しいmarshal用のctxを作成。はじめはこちらが参照される。
		marshalctx, _ := BeginSubsegment(ctx, "marshal")

		r.HTTPRequest = r.HTTPRequest.WithContext(marshalctx)
		r.HTTPRequest.Header.Set("x-amzn-trace-id", opseg.DownstreamHeader().String())
	},
}
```

ここで、`r.HTTPRequest.Context()` を指定しているのですが、これは実装時 AWS SDK を利用時に Context 付きの Request を使って API に叩くときに HTTPRequest を作成していてそれを利用しています。

`aws/aws-sdk-go/aws/request/request_context.go` の `setRequestContext` の処理がその処理に当たる箇所です。WithContext で後から Request のポインタに対して Context を追加しています。  
初回の BeginSubsegument では、`r.HTTPRequest.Context()` を利用して新しい ctx を作成しています。
この BeginSubsegument を追ってみます。

```go
func BeginSubsegment(ctx context.Context, name string) (context.Context, *Segment) {
	var parent *Segment
	// 親となるsegmentの作成または取得
	if getTraceHeaderFromContext(ctx) != nil && GetSegment(ctx) == nil {
		_, parent = newFacadeSegment(ctx)
	} else {
		parent = GetSegment(ctx)
		// ...
	}
}
```

まず親となる segment を作成, もしくはすでに Context 内に入力された segment が存在する場合はそちらを参照し取得します。  
そして

```go
func BeginSubsegment(ctx context.Context, name string) (context.Context, *Segment) {
	// ...
	// 親として上記コードで作成または取得した親となるsegmentを使って新しいsegmentを追加
	seg := &Segment{parent: parent}
	// ...
	// 親のsegmentの子segmentとして追加
	parent.rawSubsegments = append(parent.rawSubsegments, seg)
	parent.openSegments++

	// segmentの値を更新
	seg.ID = NewSegmentID()
	seg.Name = name
	seg.StartTime = float64(time.Now().UnixNano()) / float64(time.Second)
	seg.InProgress = true

	// 新しいcontextを作成し返却
	return context.WithValue(ctx, ContextKey, seg), seg
}
```

のように、先ほど作成した Segment を親とする新しい Segment を作成した後、この segment を埋め込んだ Context を生成し return で返却しています。
こうすることで、木構造も持った Segment を Context 内に作成していきます。
ここで作成した木構造を利用して segment の情報を daemon へ送信しています。

次に xRayAfterBuildHandler を追っていきます。

```go
var xRayAfterBuildHandler = request.NamedHandler{
	Name: "XRayAfterBuildHandler",
	Fn: func(r *request.Request) {
		endSubsegment(r)
	},
}
```

この処理は単純に、endSubsegment を 実行しています。

```go
func endSubsegment(r *request.Request) {
	seg := GetSegment(r.HTTPRequest.Context())
	if seg == nil {
		return
	}
	seg.Close(r.Error)
	r.HTTPRequest = r.HTTPRequest.WithContext(context.WithValue(r.HTTPRequest.Context(), ContextKey, seg.parent))
}
```

Request から Context を取得し、その中から segment を取得し、`seg.Close()`の呼び出しを行なっています。  
ここで取得した Context 内の segment は前回作成した segment になります。  
この処理の前に作成された Context は name が marshal の segment が取得できます。  
さらにこの`Close`を追ってみると、

```go
func (seg *Segment) Close(err error) {
	// ...
	seg.EndTime = float64(time.Now().UnixNano()) / float64(time.Second)
	seg.InProgress = false
	seg.flush()
}

func (seg *Segment) flush(decrement bool) {
	// 親元のfacadeで作成されたsegmentが終了されるまで、処理は通過し、Emitは実行されない
	shouldFlush := (seg.openSegments == 0 && seg.EndTime > 0) || seg.ContextDone
	if shouldFlush {
		if seg.parent == nil {
			seg.Lock()
			seg.Emitted = true
			seg.Unlock()
			Emit(seg)
		} else if seg.parent != nil && seg.parent.Facade {
			seg.Lock()
			seg.Emitted = true
			seg.Unlock()
			Emit(seg)
		} else {
			// 条件に引っかからない場合は再帰的に親を確認
			seg.parent.flush(true)
		}
	}
}
```

のように、`Close` を実行した segment に対して EndTime を設定した後、親元の処理が実行完了しているかを確認しにいきます。
xRayAfterBuildHandler 時点で終了しているのは marshal の実行のみのため、marshal の終了時間のみが記載されて、処理が継続して実行されます。
この要領で handler 内の各ステップで Context 内に処理開始と処理終了時間を計測した Context が生成されていきます。

<!--adsense-->

## 最終的に Context が送信される処理

上記の handler の処理を実行していき、最終的に root に到達した時点で今まで構築した Context を使って UDP 経由で daemon にパケットが送信されます。

```go
func Emit(seg *Segment) {
	for _, p := range packSegments(seg, nil) {
		if logLevel == "trace" {
			b := &bytes.Buffer{}
			json.Indent(b, p, "", " ")
			log.Trace(b.String())
		}
		e.Lock()
		// Marshal後のSegmentに対してUDP経由でパケットを送信
		_, err := e.conn.Write(append(Header, p...))
		if err != nil {
			log.Error(err)
		}
		e.Unlock()
	}
}

func packSegments(seg *Segment, outSegments [][]byte) [][]byte {
	trimSubsegment := func(s *Segment) []byte {
		// ...
		b, _ := json.Marshal(s)
		return b
	}
	for _, s := range seg.rawSubsegments {
		// 再帰的に、葉の末端まで走査
		outSegments = packSegments(s, outSegments)
		// trimされたsubsegmentを大元のsegmentに追加
		if b := trimSubsegment(s); b != nil {
			seg.Subsegments = append(seg.Subsegments, b)
		}
	}
	if seg.parent == nil {
		if b := trimSubsegment(seg); b != nil {
			outSegments = append(outSegments, b)
		}
	}
	return outSegments
}

```

上記の`packSegments`から、再帰的に大元の segment から始まった木構造全ての segment を `json.Marshal` で byte 配列を作成します。

ここで作成されるパケットの最小構成は、以下のような構造の json で、

```json
{
  "name": "Scorekeep",
  "id": "70de5b6f19ff9a0a",
  "start_time": 1.478293361271e9,
  "trace_id": "1-581cf771-a006649127e371903a2de979",
  "end_time": 1.478293361449e9
}
```

上記の json 構造の byte 配列を`e.conn.Write(append(Header, p...))`で UDP 経由でパケットを送信することで daemon にトレースの結果を送信します。

## まとめ

AWS X-Ray SDK for Go を流れを追っていく中で、内部構造のブラックボックスだった内部構造が大分明らかになりました。  
実装を追っていく中で、AWS SDK そのものの handler の仕組みだったり、Context の実用的な使用例が追っていけたので、勉強にもなりました。  
業務内でサーバーレス構成での運用テクニックみたいなものはまだがっつり実践では使いきれていないですが、分散トレーシングを利用して Context 経由で実装の流れをサクッと導入できるのは、AWS-X-Ray 特有の旨味ですね。  
ただ、追ってみてさらにわかったことですが、内部では context.Context をガリガリに引き回して使っている以上 context.Context は必須になるので、その辺りの対応は golang で実装する以上、なる早でやっておいた方が身のためだなと感じました。  
こういうツールを試せる一手にもなるので、はじめから実装を着手するなら context.Context は処理の下まで引き回せるライブラリとかは考えた方が良さそうですね。

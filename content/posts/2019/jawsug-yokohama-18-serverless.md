---
date: 2019-09-29T20:26:31+09:00
linktitle: 'Jawsug Yokohama 18 Serverless'
title: 'JAWS-UG横浜 #18 サーバーレスに参加してきました'
tags: ['AWS', 'JAWS-UG']
weight: 16
---

![jaws-ug_yokohama3](/images/2019/jawsug-yokohama-18-serverless/jaws-ug_yokohama3.jpg)

## はじめに

先日、JAWS-UG 横浜 #18 サーバーレスに参加してきました。

https://jawsug-yokohama.connpass.com/event/140266/

その、発表のまとめと感想を拙いながらもまとめさせていただきました。

## Lambda@Edge 実例に基づくユースケース

Lambda@Edge で実装 + 検証まで行ったユースケースの紹介。
そもそも Lambda@Edge とは？ + Lambda@Edge で実現できること

> CloudFront へのアクセス、または応答時に、機能制限された Lambda function を実行することが出来る機能
>
> https://techblog.kayac.com/lambda-edge

なぜ、Lambda@Edge を採用したのか？

- Lambda でサクッと採用して検証まで見てみたかった
- API Gateway も検討したが Payload Limit が気になった
  - https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/limits.html
    - メッセージのペイロードサイズ: 128 KB
- 面白そうだったから

Lambda@Edge でいろんな企業どんなケースで使ってるんだろう？

- https://techlife.cookpad.com/entry/2018-05-25-lambda-edge
- https://qiita.com/hareku/items/3c49e5f60a7cf0989cd0
- https://engineers.weddingpark.co.jp/?p=2446

リアルタイム画像リサイズで使ってる事例が多い？
他にも

- https://techblog.kayac.com/lambda-edge
- https://github.com/nzoschke/gofaas/blob/master/docs/lambda-at-edge-oauth.md

静的コンテンツに対して認証を噛ませられるのが手軽なので、そういう用途で使われることも多いみたい。

実際に実装してみて得られたこと

- CloudFront と Lambda@Edge は同期的に実行
  - レイテンシとか同時実行数も意識する必要あり
- Lambda は各リージョンで実行
  - なので、ログは実行リージョン内の CloudWatchLogs に保存される
- コンソールからのテストの挙動に若干高となる点がある
  - リクエストパラメーターに対する URL Encode の有無等
- デプロイ(レプリケーション)に時間がかかる
- 削除の順番
  - CloudFront からアンデプロイ => Lambda@Edge の削除の順に削除する必要あり

途中からになってしまったので、もう一度資料があがったら追ってみたいです...

## サーバーレスについてみんなで考えよう

サーバーレスについて、6~8 人でグループを作って、ディスカッションするセッションでした。
セッション内容として、色々挙げられた中で、自分たちのチームは以下のような議論をしました

- サーバーレスにする時どうやって導入 & 運用した？

  - 導入する時に上の偉い人たちにどう説得するのか
    - API の call 数だったり、ファイルのサイズだったり、serverless の pros/cons を出してお金の面で安くなることを説明してみたりしたら良さそう
  - インフラとバックエンドの境界が曖昧でどっちが実装 & 監視するべき？ - 会社によりけり。監視するチームがある人たちはそこで監視してるところもあれば、人が少なければアプリ側が全部やってたり
    サーバーレスの運用や監視はどうやってる？
    の内容で話ました。
    サーバーの監視は CloudWatch Logs を使ったり、AWS X-Ray を使ったり

サーバーレス自体がまだ導入してまもない & まだ試したことがない人が結構多かったので、全体を通してみても初めてサーバーレスに挑戦する！見たいなチームが多かったです。
システム設計のポイントの踏み入った話もあって面白かったです！以下が発表メモです。

```
- サーバーレスにいろんな課題がある
  - 開発のライフサイクルは変わるの?
  - テストしづらそう
- 初めてサーバーレスに挑戦
  - アプリケーションと役割が分かれてたけど、そこを分けない
  - アプリチームがどうとか分けたくない
  - サーバーレスならではの監視、運用が必要
  - 標準出力を全て出さないといけないとか
  - 監視は大事な項目
  - 周りの説得(啓蒙)むずい。pro/con 説明どうやる？
  - 勉強するためにはどうする
  - システム設計のポイント
    - 1 つの lambda は simple
    - 15min time out
    - 1lambda 1APIのイメージ
    - Lambda or ECS かどうかがむずい。まずサーバーレスで考えてみると良さそう？
```

## [サーバレスで DynamoDB レスな IoT アプリの開発](https://speakerdeck.com/kojiisd/sabaresudedynamodbresunaiotapurikai-fa)

サーバーレスで DynamoDB レスな IoT アプリを開発しているお話でした。
サーバーレスで実装する時に Data の保存先の候補として

- S3
- DynamoDB

が基本的に候補としてあげられる中で、 [No SQL for Amazon DynamoDB](https://aws.amazon.com/jp/blogs/news/nosql-workbench-for-amazon-dynamodb-available-in-preview/)とかが出てきたのもあいまって DynamoDB が便利。
ただ、追加要件で

- 生データが見たい
- データを再コンバートしたい
- サマリ情報を見たい

等の要件が複雑に入り組んで来た時に、気づいたら AWS の関連するコンポーネントが増えていって管理が複雑になっていく。
そこで、IoT Analytics を使うとその辺りをシュッと解決してくれる。
IoT Analytics は

- Channel
  - データの受付窓口。生データをアーカイブ
- pipeline
  - チャネルから message を受け取り、filter を実施。Lambda も実行できる
- Data store

  - Athena 相当の message を保持できる Data Store

上記の機能をうまく使いこなせば要件をこなせる！ただ、以下のような落とし穴もあるから気をつけたほうがいい。

- Channel の受付容量には制限ある。
- Pipeline 内 Lambda を VPC 内に配置して同一 VPC の何かにアクセスしようとしてもできない
- Dataset の S3 への出力ははならず 1 つの CSV になってしまう。分割できない。
  - センサごと、農家ごとに分けるとかはできない

気をつけるべきところを抑えた上で、要件によっては複雑にサービスを組み合わせなくても１つのサービスでうまく実装できることもある。

## 最近の AWS Lambda についてなんやかんや話します

去年の re:Invent ~ Lambda の変化を振り返る

- 去年
  - Custom Runtime
  - Lamnbda Layers
  - ALB
- 今年から
  - GetLayerVersionByArn API
  - CloudWatch Logs Insights の統合
  - Node.js の v10 サポート
  - Amazon Linux 2018.03
  - VPC コールドスタートの改善

VPC のコールドスタートの改善はだいぶ大幅な改善を遂げた。([資料](https://aws.amazon.com/jp/blogs/compute/announcing-improved-vpc-networking-for-aws-lambda-functions/))
RDBMS, RDS との相性は、VPC レイテンシコストと Lambda の同時接続数(default で 1000 とか)が多い + 毎回コンテナを作成 + 破棄を行うためにコネクションプールを使えない等の理由で相性が悪い。が、VPC のコールドスタートの改善によって問題はコネクションの問題のみになった。
ただ、RDBMS, RDS との相性は完全に解消した！という訳ではないので、使うときには注意が必要そう。
この辺りの説明で、発表者様の資料でこのあたりがかなり読みやすい記事があったので引用させていただきます

- [なぜ AWS Lambda と RDBMS の相性が悪いかを簡単に説明する](https://www.keisuke69.net/entry/2017/06/21/121501)

それと、java の Lambda のコールドスタートが遅いので、GraalVM と Quarkus で早くする事例の紹介。
早いとのことだったので、

- golang との比較ないかなーと思って、ちょっと調べてみた。
  - https://dzone.com/articles/java-vs-go-multiple-users-load-test-1
  - 銀行のサンプルアプリを作って比べてみると 2 倍以上のユーザーを同時に扱えるらしい。
  - がケースバイケースで、割と遅くなるケースも多いらしく実際に試してみて...とのこと。

最後に話の中で興味深かったのは、AWS Step Functions

- AWS Step Functions っていうのがサーバーレスであるらしい
  - https://dev.classmethod.jp/cloud/aws/relay_looking_back_step-functions/#toc-step-functions
  - https://qiita.com/ketancho/items/147a141c9f8a6de86c97
  - 複数の lambda を経由する処理を１つの状態遷移図を記述することで一連の処理を書くことができる。
  - ただエラーハンドリングだったり、context 内の id の受け渡し等はまだできない？
    - この辺り、SQS の受け渡し独自実装が今の所は良さそうかなって記事が各所に見られた。
    - 時間あったら触ってみたい

## AWS AppSync でフルサーバーレスアプリケーションを作ってみた

AWS AppSync でフルサーバーレスアプリケーションを作ってみたお話。

- AppSync でできること
  - Managed な GraphQL サービス。以下サービスと紐づけられる
    - DynamoDB
    - Cognito
    - Elasticsearch
    - Lambda Function
    - RDB
    - HTTP
  - オフラインデータ同期
  - データ更新のリアルタイム通知

AppSync について、以下の記事で概要を掴めそう

- https://scrapbox.io/tasuwo/AWS_AppSync

認証とかは Cognito を使えばできる。AWS Like なデータ更新のリアルタイム通知とか実装できるのはありそうだなぁ
GraphQL という点を除くと、Firebase で同等の機能を開発ができそう？

- 料金
  - クエリおよびデータ変更操作 100 万回につき 4 USD
  - リアルタイム更新 100 万回につき 2 USD
  - AWS AppSync サービスへの接続 100 万分につき 0.08 USD

ちょっとお金かかる...
AWS である程度構成されているサービスに対して取り込むと、full managed で GraphQL のサービスをサーバーレス構成で作れるのが良さげ。
Terraform との組み合わせで、サービスの構成を CI/CD で自動生成可能。
ただ、ちょっと運用金額がかかりそうなところが気になる。
同機能があって、初回無料な firebase を選ばれることが多そう？
Backend API をコーディングレスでかけるのが幸せ。
GraphQL で受け渡されるスキーマをはじめに決めてそれを管理も少なく運用出来るので、AWS でサーバーレスの構成でとなると候補として選んでみると幸せになるのかな？

## ServerlessDays Belgrade

[ServerlessDays Belgrade](https://serverlessbelgrade.com/)を写真で振り返す発表でした。

サーバーレスはビジュアライズしないとわからない。複数 component の関係をコードだけでは理解不能であるので。
なので、サーバーレスに限らずだが、一瞬で理解できるように visualize は必要。[stackery](https://www.stackery.io/)が良さそう？
運用をしていく中で、安定して稼働するシステムを作るために、カオスエンジニアリングをやっていこう。

- カオスエンジニアリング について
  - https://qiita.com/naokiiiii/items/de20997a70922c01f754

サーバーレスは運用が大変。ツールも使って運用を楽にしていきたい。serverless の運用楽にするツールもある見たい。

- https://lumigo.io/

- 継続デリバリのお話。人間はポカをするから早い段階で CI/CD は作っていこうねってお話。

  - [継続デリバリ](https://books.google.co.jp/books/about/%E7%B6%99%E7%B6%9A%E7%9A%84%E3%83%87%E3%83%AA%E3%83%90%E3%83%AA%E3%83%BC_%E4%BF%A1%E9%A0%BC%E3%81%A7%E3%81%8D%E3%82%8B.html?id=-HcuDwAAQBAJ&printsec=frontcover&source=kp_read_button&redir_esc=y#v=onepage&q&f=false)を書いた方の発表だったらしい

10/22 に[serverlessTokyo](https://tokyo.serverlessdays.io/)もあるみたい。 記事を追いたい。

## まとめ

サーバーレス自体がまだ初めてって人も結構多くて、グループディスカッション形式でいろんな角度からサーバーレスを覗けてすごく面白かったです！！！
アプリケーション、インフラ、SIer 等の様々な方面の方々がいらっしゃっていて、こういった多角的な仕事の人が AWS を触っているのはサーバーレスに限らずですが、フルマネージドなサービス構築が各所で求められているんだなぁとしみじみと実感した会でした。
発表の方々もかなりレベルが高くて非常に刺激になりました。まだまだ知らないこと多いなぁと実感。
AWS もっとたくさんのユースケースを触って体験していきたいです！

最後にこのイベントを開催してくださったスタッフのみなさま、最高に刺激になる会を提供 & 開催ありがとうございます！
本当に楽しかったです！

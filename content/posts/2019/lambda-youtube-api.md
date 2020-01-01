---
date: 2019-04-08T20:24:35+09:00
linktitle: 'Lambda+SAMでYoutubeのコメントを定期的にぶっこ抜く'
title: 'Lambda+SAMでYoutubeのコメントを定期的にぶっこ抜く'
tags: ['AWS', 'Lambda', 'CloudWatch Events', 'golang', 'SAM']
weight: 16
---

## はじめに

Youtube に入力されたデータ、面白いです。  
何が面白いかって、配信者が伝えたい情報の生のデータを google が公開してる API を使えばまるっと持ってこれるし、再生回数から興味を持ってるユーザー数の概算はチラ見出来るから、考えたアイデアを使ってくれる人はどれだけいるのか見えるのがいいです。  
ただ、毎回 shell 叩くのはメンドくさい！それに家で触るんだから、ガンガン新しい技術を触っていきたい。  
定期実行でかつコスト安い組み合わせ何だろうなと考えたところ、AWS Lambda(稼働時間分の課金) + Amazon CloudWatch Events(cron の形式で定期実行) + golang(速度早い、あと単純に好き)が自分の中では多分最適解だろうなと思ったので作ってみました。

## 最終的に出来上がったもの

[https://github.com/gtongy/youtube-comments-crawler](https://github.com/gtongy/youtube-comments-crawler)

## 事前準備

事前に以下のツールが必要となります。今回以下のインストール方法等は今回の話とはまた別の話なので、説明はスキップします。

- aws-sam-cli
  - 0.14.2
- go
  - 1.12.1
- docker
  - 18.09.2
- docker-compose
  - 1.23.2
- aws-cli
  - 1.16.130

## 主な構成

AWS の構成は以下のような構成にしました。

![構成図](https://github.com/gtongy/youtube-comments-crawler/raw/master/images/aws-youtube-comments-crawler.png)

利用する AWS のサービスとして

- Lambda
- DynamoDB
- CloudWatch
- S3
- CloudFormation

を利用しています。  
CloudFormation はこの構成を SAM で定義しているため、その構成 stack の作成のために使用しました。

処理の内部としては、

```
CloudWatch Events で定期的に Event を発火
-> S3 から google の認証情報を取得し、Lambda による Crawling の開始
-> youtubeのchannel情報からビデオを取得しDynamoDBへ保存
-> ビデオからコメントを取得しDynamoDBへ保存
```

の流れで Crawling を行なっています。

## SAM の定義

```
AWSTemplateFormatVersion: "2010-09-09"
Transform: "AWS::Serverless-2016-10-31"
Description: "This application use youtube comments crawler"
Resources:
  YoutubeCommentCrawler:
    Type: "AWS::Serverless::Function"
    Properties:
      Handler: "main"
      Runtime: "go1.x"
      CodeUri: "../../main.zip"
      FunctionName: "youtube-comments-crawler"
      MemorySize: 256
      Timeout: 30
      Events:
        ScheduleEvent:
          Type: Schedule
          Properties:
            Schedule: cron(0 12 * * ? *)
      Environment:
        Variables:
          ENV: ""
          ACCESS_KEY: ""
          SECRET_KEY: ""
          SERVICE_ACCOUNT_KEY: ""
          SERVICE_ACCOUNT_FILE_NAME: ""
          SERVICE_BUCKET: ""
```

SAM の定義内では複雑なことはせず、主に Lambda の定義を主に記述しています。  
大事なのは、Events の箇所で、Type に Schedule を指定して、Properties の Schedule に cron のような形式で実行時間の記述をすることが出来ます。  
ルールの記述形式に関しては、以下のドキュメントを見ればあらかた検討はつくと思うので、一読必須です。

[ルールのスケジュール式](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/events/ScheduledEvents.html)

実行の時間は UTC であるため、日本の時刻との時差には注意してください。(今だと 9 時間程度日本と時差がある)  
SAM はこのように、yml 形式でデプロイの方式を Code で記述することが出来ます。  
SAM 使うか使わないかで、デプロイの楽さが段違いに変わるので使ってみるとかなり便利ですよー

<!--adsense-->

## 処理の詳細

```
func Handler(ctx context.Context, event events.CloudWatchEvent) (string, error) {
	filename := serviceAccountFileDownload()
	b, err := ioutil.ReadFile(filename)

	if err != nil {
		log.Fatalf("Unable to read client secret file: %v", err)
		return "", err
	}

	db := dynamo.New(session.New(), dynamodb.Config(region, dynamodbEndpoint))

	youtubeClient := youtube.NewClient(b)

	videoRepository := repository.Video{Table: db.Table(videosTableName)}
	commentRepository := repository.Comment{Table: db.Table(commentsTableName)}
	youtuberRepository := repository.Youtuber{Table: db.Table(youtubersTableName)}

	for _, youtuber := range youtuberRepository.ScanAll() {

		videos := youtubeClient.GetVideosIDsByChannelID(youtuber.ChannelID, maxVideosCount)
		savedVideos := videoRepository.SaveAndGetVideos(videos)

		for _, savedVideo := range savedVideos {
			comments := youtubeClient.GetCommentsByVideoID(savedVideo.ID, maxCommentsCount)
			commentRepository.Save(comments)
		}
	}
	return "success", nil
}
```

主な処理は handler.go あたりに記述してあります。

```
youtubeClient := youtube.NewClient(b)
```

ここで、Youtube Data API へ問い合わせを行うクライアントオブジェクトを初期化していて、
Client の内部では

```
package youtube

import (
	"context"
	"log"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/youtube/v3"
)

// Client is youtube api wrapper
type Client struct {
	service *youtube.Service
}

// handleError is api call error handling
func handleError(err error, message string) {
	if message == "" {
		message = "Error making API call"
	}
	if err != nil {
		log.Fatalf(message+": %v", err.Error())
	}
}

// NewClient is get client. this client is youtube client wrapper
func NewClient(secretFile []byte) Client {
	cfg, err := google.JWTConfigFromJSON(secretFile, youtube.YoutubeForceSslScope)
	if err != nil {
		log.Fatalf("Unable to parse client secret file to config: %v", err)
	}
	client := cfg.Client(context.Background())
	service, err := youtube.New(client)
	handleError(err, "Error creating YouTube client")
	return Client{service: service}
}
```

のように、`google.JWTConfigFromJSON`を使って、設定ファイルを読み取ったのちに、youtube の client を新規で作成し、wrapper として、新しい構造体を定義しているという処理内容です。

それと、

```
videoRepository := repository.Video{Table: db.Table(videosTableName)}
commentRepository := repository.Comment{Table: db.Table(commentsTableName)}
youtuberRepository := repository.Youtuber{Table: db.Table(youtubersTableName)}
```

は、db(今回で言うと DynamoDB)への接続を行う Repository を定義しています。
ここで Repository は、主に DB への接続だったり、上層から渡ってくる処理の間に入れ込む処理系統をまとめています。  
いわゆる Usecase 的な扱いです。

その Repository に対して

```
for _, youtuber := range youtuberRepository.ScanAll() {
	videos := youtubeClient.GetVideosIDsByChannelID(youtuber.ChannelID, maxVideosCount)
	savedVideos := videoRepository.SaveAndGetVideos(videos)
	for _, savedVideo := range savedVideos {
		comments := youtubeClient.GetCommentsByVideoID(savedVideo.ID, maxCommentsCount)
		commentRepository.Save(comments)
	}
}
```

のように、格納された youtuber の情報を抜き取ったのちに、ビデオを保存し、コメントを保存することで、コメントを Crawling しています。

## 開発環境

開発環境内では、aws-sam-cli を利用して開発を行なっています。
また、開発環境内で**本物の AWS のサービスっぽく振る舞うもの**が欲しかったので

- DynamoDB
  - amazon/dynamodb-local
- S3
  - minio/minio

を使っています。これを同一ネットワーク内で実行することで、擬似的に無料で周辺サービスを扱うことが出来ます。
他にも全部入り pack の LocalStack などもあったのですが、実際に試してみた時に取得がすごく遅かったので、採用を見送っています。
この辺りは docker で作るのがやりやすかったので、docker で作成しています。

## ということでいざ実行！

事前に、event.json と、env.json を作成しておきます。
sample があるので、それを参考に。その後

container を立ち上げて

```
$ cd /path/to/youtube-comments-crawler
$ make create-network && docker-compose up -d
```

dummy のテーブルを作って

```
 $ make create-table TABLE_NAME="YoutubeCommentsCrawlerVideos"
 $ make create-table TABLE_NAME="YoutubeCommentsCrawlerComments"
 $ make create-table TABLE_NAME="YoutubeCommentsCrawlerYoutubers
```

item の追加し

```
$  make put-item TABLE_NAME='YoutubeCommentsCrawlerYoutubers' ITEM='{ "id": { "S": "unique xid insert" }, "name": { "S": "Please Input Youtuber Name" }, "channel_id": { "S": "Please Input Youtuber Channel ID" }}'
```

バイナリの作成したのちに

```
$ make main-zip
```

Local での実行！

```
$ make local-exec FUNCTION_NAME="YoutubeCommentCrawler"
```

![Pipeline exec result](/images/2019/lambda-youtube-api/sam-local-exec.gif)

動きました!
また、実行結果を取得してみます。

![Youtube Exec Result](/images/2019/lambda-youtube-api/youtube-comments-local-exec.png)

うまく取得出来ていますね。

## まとめ

Yotube Data API を使って実行結果を取得してみました。
今回、SAM + Lambda + サーバーレス構成で定期的に Youtube API を使ってコメントを引っこ抜いてきましたが、個人開発で小さい機能を高速で作ろうと思った時に、お金って気になるんですよね。
ただ、Lambda は起動分の金額課金になるので、現状意識するのは DynamoDB の稼働分金額だけで、マシンの稼働時間の金額を節約できていいです。
今回はローカルでの実行を説明しましたが、AWS CodePipeline である程度自動化できるところはありそうなので、積極的に今後採用して行きたい。

---
date: 2019-03-27T21:55:59+09:00
linktitle: 'AWS CodePipelineのCapabilityでCAPABILITY_AUTO_EXPANDがなくてハマった'
title: 'AWS CodePipelineのCapabilityでCAPABILITY_AUTO_EXPANDがなくてハマった'
tags: ['aws', 'CodePipeline']
weight: 16
---

## はじめに

業務で案件のデプロイ環境を整える必要が出てきて、Lambda を使うので、SAM を使って AWS Codepipeline でデプロイをいい感じに構築したいなと思って家でなんとなく試してみた。
CodeDeploy の Action を記述している時に、アクションプロバイダーで AWS CloudFormation, アクションモードでスタックを作成または更新するを選択し、CodePipeline を実行した時に

```
Requires capabilities : [CAPABILITY_AUTO_EXPAND] (Service: AmazonCloudFormation; Status Code: 400; Error Code: InsufficientCapabilitiesException; Request ID: XXXXX)
```

のエラーが出て困ったのでその解決方法の紹介。

## TL;DR

新しい画面上だと、「能力 - オプショナル」から選択。aws cli を使って json からも更新可能。

## エラーの画面

![Pipeline exec result](/images/2019/pipeline-exec-result.png)

## そもそも capabilities でなんでエラーが出るのよ

SAM の定義自体はそもそも AWS CloudFormation で記述されているのですが、AWS CloudFormation がスタックを作成する前にまずテンプレートが検証されます。

[AWS CloudFormation テンプレートでの IAM リソースの承認](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-iam-template.html#using-iam-capabilities)

> スタックを作成する前に、AWS CloudFormation に指定された機能を付与して、テンプレートにそれらのリソースを含めることを承認する必要があります。

上記の引用通りで、あらかじめリソースに IAM リソースを承認する必要があって、それを指定しないとエラーになるようです。
また、今回みたいな SAM の定義の定義で複数のネストされているアプリケーションに対して CAPABILITY_AUTO_EXPAND を指定する必要があるのですが、旧 CodePipeline の管理画面だと

![Capability old view](/images/2019/capability-old-view.png)

のような感じで CAPABILITY_AUTO_EXPAND が存在しないのです。辛い。

<!--adsense-->

## 解決方法 1: 新管理画面からの設定方法

新しい管理画面だと、スタックの作成または更新の選択欄のうち、「能力 - オプショナル」から CAPABILITY_AUTO_EXPAND を選択することが出来ます。  
おそらくこれが一番手っ取り早いかなと思います。

![Capability old view](/images/2019/capability-new-view.png)

## 解決方法 2: aws cli からの設定方法

この capability に限らずの話ですが、CodePipeline の設定は aws cli を使っても出来ます。

```sh
aws codepipeline get-pipeline --name "CodePipeline名を入力" --region "Regionを入力" >> current.json
```

上記コマンドを実行することで現在の Codepipeline の設定が取得出来ます。

```
{
    "pipeline": {
        "name": "image-uploader-stg",
        "stages": [
            {
                "name": "XXXXX",
                "actions": [
                    {
                        "configuration": {
                            "ActionMode": "CREATE_UPDATE",
                            "Capabilities": "ここを変更する",
                            "RoleArn": "YYYYY",
                            "StackName": "image-upload-stg",
                            "TemplatePath": "SampleArtifact::/go/src/github.com/gtongy/repository/template.yml"
                        },
                    }
                ]
            },
        ],
        "version": 14
    },
}
```

必要な箇所以外は省略するのですが、設定が pipeline 内の Action ごとに stages が作られていて、該当の actions の configureration に対して Capabilities の項目が存在する(なければ追加)ので、そこを CAPABILITY_AUTO_EXPAND に変更します。  
あとは、変更を加えたのちに、pipeline 以下の json の構造を copy して新しくファイルを作り、

```
aws codepipeline update-pipeline --region "Regionを入力" --pipeline file://changed.json
```

を実行することで設定を変更することができます。

## 終わりに

今回は aws cli と画面からの設定の二つを紹介したのも、なぜか CloudFormation の stack が存在しない場合の時に新規管理画面でこの項目が選択できずどうしようかと思ったために cli からの解決法を探したらこれが最適そうだったのでこれを試したという感じです。  
AWS CodeDeploy を使うと、AWS Lambda へのカナリアデプロイを行えて、段階的にリリースを行えるため、安心感も大きいのと、Code Pipeline で各ステージごとに定義を決められて自由度高いなと思いました。
Lambda を使って複数サービスをまたがったリソースのリリースを考えている方は是非一度触ってみてください！

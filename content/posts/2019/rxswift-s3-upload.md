---
date: 2019-05-11T23:43:40+09:00
linktitle: 'RxSwiftでS3へのアップロードを実装してみる'
title: 'RxSwiftでS3へのアップロード機能を実装してみる'
tags: ['swift', 'RxSwift', 'AWS', 'S3', 'Congnito']
weight: 16
---

![post header](/images/2019/rxswift-s3-upload/post-header.png)

## はじめに

いざ Swift に入門！...となったのはいいのですが、他の言語でも一般的に必須だろって機能は触っておきたいよねと思ってました。  
ということで、S3 への直接アップロードはやっておきたかった事の一つでもあったのと、RxSwift を軽く触るにはちょうどいいボリューム感だったので合わせて実装してみました。

## 使用ライブラリ

- RxSwift
- RxCocoa
- AWSS3
- AWSCognito

## RxSwift で実装したサンプル

以下に gist を載せておきました。詳細はこっちを参照していただけると分かると思います。

[RxSwift S3 Upload Sample](https://gist.github.com/gtongy/842c25548a6c264f107aa762a7807830)

ツリー構造はこんな感じです。

```sh
.
├── AppDelegate.swift
├── Assets.xcassets
│   ├── AppIcon.appiconset
│   │   └── Contents.json
│   └── Contents.json
├── Base.lproj
│   └── LaunchScreen.storyboard
├── Controllers # ViewController群
│   └── ViewController.swift
├── Extensions # 機能の拡張が必要な場合に追加
│   ├── RxImagePickerDelegateProxy.swift
│   ├── UIImagePickerController+Rx.swift
│   └── UIImagePickerController+RxCreate.swift
├── Info.plist
├── Storyboards # Storyboard群
│   └── Base.lproj
│       └── Main.storyboard
├── ViewModels # Actionが発生した時の処理をまとめたGroup
│   ├── SelectPhotoViewModel.swift
│   └── UploadPhotoViewModel.swift
├── Views # 画面描画に関連する動的なUI関連をまとめたGroup
│   ├── PreviewImage.swift
│   └── PrimaryActionButton.swift
└── droppo.xcdatamodeld
    └── droppo.xcdatamodel
        └── contents

11 directories, 15 files
```

## そもそもなんで RxSwift 使ったの？

正直このくらいの規模感ならわざわざ使わなくてもいいかな...とも思いましたが、これくらいの規模感だからこそ試してみれるよねという事もあるよなと思い実装してみた感じです。  
実際に簡単に実装してみて思うのが、ViewController にロジックが寄らないので、あるべき責任が分散して実装出来て良さそうだけど、学習コストは高いなとは思いました。  
簡単な tap 等のサンプルはあるけど、個人開発で一から作ろうと思って実装をやってみよう！ってなって初めから構文を追うには初めは時間がどうしてもかかるかも....。  
自分がまだ知らないだけだからっていうのもあるのですが。

## RxSwift を利用してどこを分離したのか

主に

- 画像をライブラリから選択してくる処理を行う箇所(UIImagePickerControllerDelegate, UIImagePickerController)
- 単純なボタンクリックによるアクションの制御(UIButton, UIImageView)

を分離しています。

<!--adsense-->

## UIImagePickerController を RxSwift から呼び出す

公式の Sample から以下 3 ファイルをコピー

- [RxImagePickerDelegateProxy.swift](https://github.com/ReactiveX/RxSwift/blob/master/RxExample/Extensions/RxImagePickerDelegateProxy.swift)
- [UIImagePickerController+Rx.swift](https://github.com/ReactiveX/RxSwift/blob/master/RxExample/Extensions/UIImagePickerController%2BRx.swift)
- [UIImagePickerController+RxCreate.swift](https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/ImagePicker/UIImagePickerController%2BRxCreate.swift)

上記を取り込んで、UIImagePickerController を Observable なものとして扱えるように拡張を行います。
上記を保存したあと、`AppDelegate.swift`に

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // ...
    RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }
    return true
}
```

を追加します。そうすれば

```swift
UIImagePickerController.rx.createWithParent(input.targetController) { picker in
    picker.sourceType = .photoLibrary
    picker.allowsEditing = false
}
.flatMap {
    $0.rx.didFinishPickingMediaWithInfo
}
.take(1)
.map { info in
    return info[UIImagePickerController.InfoKey.originalImage] as? UIImage
}
.bind(to: input.previewImage.rx.image)
.disposed(by: self.disposeBag)
```

のように、UIImagePickerController を Observable な Object として扱うことが出来ます。

## UIImagePickerController で選択したファイルの bind

選択するボタンを

```swift
selectPhotoButton.rx.tap.asObservable()
```

のように、tap に対して Observable なものへ変換し、ViewController 側で ViewModel を宣言します。その後、

```swift
func setup(input: SelectPhotoViewModelInput) {
    input.selectPhotoButton
        .subscribe({ [unowned self] _ in
            UIImagePickerController.rx.createWithParent(input.targetController) { picker in
                picker.sourceType = .photoLibrary
                picker.allowsEditing = false
            }
            .flatMap {
                $0.rx.didFinishPickingMediaWithInfo
            }
            .take(1)
            .map { info in
                return info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            }
            .bind(to: input.previewImage.rx.image)
            .disposed(by: self.disposeBag)
        })
        .disposed(by: self.disposeBag)
}
```

のように、photoLibrary から選択されたものから 1 つ取り出し、それを UIImageView へ bind する処理を行います。  
処理の流れが見やすいのが RxSwift いいですね。

## Cognito を利用して、S3 へのアップロードを行う権限を付与

iphone から AWS を利用するために、Cognito から Identity Pool Id を作成する必要があります。
Cognito から Identity Pool Id の取得方法は[こちらの](https://dev.classmethod.jp/cloud/aws/aws-cli-credentials-using-amazon-cognito/)記事が分かりやすくまとまっています。

Cognito の Identity Pool Id を作成したのちに、この IAM に対して、対象の S3 バケットに対して書き込み(PutObject)の権限を追加します。

```json
{
  "Effect": "Allow",
  "Action": ["s3:PutObject"],
  "Resource": ["arn:aws:s3:::save-bucket-name/*"]
}
```

取得後の Identity Pool Id を.env の AWS_IDENTITY_POOL_ID へ書き込み、環境変数は[こちらの](https://qiita.com/nnsnodnb/items/9344a1955c5cf50e61af)記事を参考させていただいて、`AppDelegate.swift`に以下コードを追加します。

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    self.initEnv()
    let env = ProcessInfo.processInfo.environment
    let credentialsProvider = AWSCognitoCredentialsProvider(
        regionType:.APNortheast1,
        identityPoolId: env["AWS_IDENTITY_POOL_ID"]!
    )
    let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider:credentialsProvider)
    AWSServiceManager.default().defaultServiceConfiguration = configuration
    return true
}

// 環境変数の初期化
private func initEnv() {
    guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
        fatalError("Not found: '/path/to/.env'.\nPlease create .env file reference from .env.sample")
    }
    let url = URL(fileURLWithPath: path)
    do {
        let data = try Data(contentsOf: url)
        let str = String(data: data, encoding: .utf8) ?? "Empty File"
        let clean = str.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
        let envVars = clean.components(separatedBy:"\n")
        for envVar in envVars {
            let keyVal = envVar.components(separatedBy:"=")
            if keyVal.count == 2 {
                setenv(keyVal[0], keyVal[1], 1)
            }
        }
    } catch {
        fatalError(error.localizedDescription)
    }
}
```

これで、Cognito の認証を設定することができます。

## 選択されたファイルを tmp ファイルへ書き込み S3 へアップロード

アップロードボタンがクリックされた時のイベントを追加するために新しい ViewModel を作成し、

```swift
func setup(input: UploadPhotoViewModelInput) {
    input.uploadPhotoButton
        .subscribe({ [unowned self] _ in
            let tmpPath:String =  NSTemporaryDirectory() + "image.png"
            let localFilePath:URL = self.savePNGImage(to: tmpPath, image: input.previewImage.image!) as URL
            let transfer: AWSS3TransferUtility = AWSS3TransferUtility.default()
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = {(task, progress) in
                DispatchQueue.main.async {
                    print("uploading...")
                }
            }
            let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
            completionHandler = { (task, error) -> Void in
                DispatchQueue.main.async {
                    if error != nil {
                        print("error")
                    } else {
                        print("success")
                    }
                }
            }
            transfer.uploadFile(localFilePath, bucket: "droppo-save-images", key: "key/image.png", contentType: "image/png", expression: expression, completionHandler: completionHandler)
        })
        .disposed(by: self.disposeBag)
}

private func savePNGImage(to filePath: String, image: UIImage) -> NSURL {
    let imageData:NSData = image.pngData()! as NSData
    imageData.write(toFile: filePath, atomically: true)
    return NSURL(fileURLWithPath: filePath)
}
```

のように、選択した画像に対して、`imageData.write(toFile: filePath, atomically: true)`で一度ファイルを tmp 領域に保存を行い、AWSS3TransferUtilityUploadExpression(アップロード中の処理), AWSS3TransferUtilityUploadCompletionHandlerBlock(アップロード完了時の処理)を AWSS3TransferUtility を利用してクロージャーとして宣言したのちに uploadFile を利用してアップロードを実行します。

実際に実行した結果して、S3 を確認すると

![s3 uploaded file](/images/2019/rxswift-s3-upload/s3-uploaded-file.png)

うまくアップロードされていますね！

## 終わりに

RxSwift で S3 へのアップロード機能を実装してみました。  
実装して思いましたが、RxSwift を利用する利点として分離した時のイベントの流れが見やすくなるのは本当にいいなーと思いました。  
ただ、途中でも述べた通り、実際の実務への導入となると Observable の知識だったり、自分でイベントを拡張する必要も出てきたりするのかなと思うと、そこで以外に時間を取られたり....なんて事もあるんだろうなと思いました。  
いろんなコストと鑑みて導入は考えるものだと感じました。ただコードが読みやすくなるのは正義なので自分はもう少し追ってみようかなと思います。

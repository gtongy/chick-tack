---
date: 2019-05-27T20:48:59+09:00
linktitle: '【RxSwift】MapKitを使って現在地を表示させる'
title: '【RxSwift】MapKitを使って現在地を表示させる'
tags: ['swift', 'MapKit']
weight: 16
---

## はじめに

アプリでマップを使った実装がしたい！
自分もマップを使ったアプリを作ろうと思ったのですが、日本語の情報が意外に少なくて探すのに一苦労ですよね...  
そこで今回は MapKit を使って、現在地から目的の場所までのルートを表示する実装をやってみようと思います。  
まだ swift を触り始めて間もないですが、躓いてしまった方へ読んでいただけると幸いです。  
ボタンのタップ部分だけ RxSwift を利用してます。今のところちょろっとしか使ってないですが。
そのあたりも気になった人の参考になると幸いです。

## 開発環境

```
 - swift
   - 5.0.1
 - Xcode
   - 10.2.1
 - RxSwift
   - 5.0
 - RxCocoa
   - 5.0
 - FontAwesome.swift
```

## よく記事に目にする Frameworks の追加は?

MapKit 系によく見る、

> Linked Frameworks and Libraries に MapKit, CoreLocation を追加してください

という箇所がありますが、現在の Xcode はそのような設定を行わなくても import を呼び出すだけで自動的に Link する設定が追加されているため、特出設定を行う必要はないようです。

[When do you have to link Frameworks and Libraries to an XCode project?](https://stackoverflow.com/questions/33728359/when-do-you-have-to-link-frameworks-and-libraries-to-an-xcode-project)

## mapView.setCenter を使って現在値を中心にしてマップを表示

現在値を取得するために info.plint に以下の設定を追加します。

```
<key>NSLocationWhenInUseUsageDescription</key>
<string>このアプリでは、ルート案内のために現在地の取得を行います</string>
```

また、mapView.setCenter を利用してマップの中心にマーカーを合わせます。

```swift
import UIKit
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.goBackCenter()
    }

    private func goBackCenter() {
        self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: false)
        self.mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: false)
    }
}
```

## Storyboard に MapKit の追加

`cmd + shift + L`もしくは、下の画像の箇所から

![ui library](/images/2019/ios-mapkit-current-to-target/ui-library.png)

MapKit の埋め込みを行います。
Auto Layout は制約として各方向に 0 を設定し、Contain to margins のチェックを外せばいい感じに整形してくれます。

一度ここで実行してみます。

![follow with heading](/images/2019/ios-mapkit-current-to-target/follow-with-heading.png)

上のような自分の向いている方向に対してマーカーがつくようになります。
`MKMapView.setCenter` は、対象の現在のユーザーの位置を中心にするようにするインターフェースで、`mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: false)` で自分の現在の向いている方向にマーカーを合わせることが出来ます。

## IBDesignable を使って現在値に戻るボタンの設置

このままだと、Map を別の箇所へ Swipe した状態だと現在値に戻る術がなくなってしまいます。
そこで現在値へ戻るボタンを設置します。
以下のクラスを追加しボタンのデザインを作成します。

```swift
import UIKit
import FontAwesome_swift

@IBDesignable
public final class BackToCurrentButton: UIButton {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = #colorLiteral(red: 0, green: 0.6730770469, blue: 1, alpha: 1)
        layer.cornerRadius = 40
        titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        setTitle(String.fontAwesomeIcon(name: .locationArrow), for: .normal)
        setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        frame.size.width = 80
        frame.size.height = 80
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 4
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
    }
}
```

作成後、再度 storyboard からボタンをライブラリから選択し、適宜位置を指定して AutoLayout を設定後、Custom Class に今回作成した BackToCurrentButton を設定します。

![custom class](/images/2019/ios-mapkit-current-to-target/custom-class.png)

これでボタンの設置が完了です。ここからボタンクリック後に現在値に戻る実装を行います。

<!--adsense-->

## RxSwift を使って tap 後のアクションの追加

最後にボタンタップ後に現在値に戻る実装の追加を行います。
MapViewController にボタンの View を追加し、tap 時のイベントを追加します。

```swift
import UIKit
import MapKit
import RxSwift
import RxCocoa

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    // ボタンの追加
    @IBOutlet weak var backToCurrentButton: BackToCurrentButton!
    // イベント購読後の解放を行うObjectの追加
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.goBackCenter()

        // タップ時のイベントを追加
        self.backToCurrentButton.rx.tap.subscribe(onNext: {_ in
            self.goBackCenter()
        }).disposed(by: disposeBag)
    }

    private func goBackCenter() {
        self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: false)
        self.mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: false)
    }
}
```

これでボタンタップ時に現在値に戻るボタンの設置完了です。

## まとめ

簡易的ではありますが、現在値に戻るボタンの設置までの実装を行いました。
わかればかなり簡単ですが、MapKit を触り始めの初心者には記事が色々とあってどれを使ったらいいのか迷ったので記事にしました。
今後も MapKit を一緒に弄っていきましょう 🎉🎉

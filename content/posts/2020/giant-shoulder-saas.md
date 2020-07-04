---
date: 2020-06-23T21:44:54+09:00
linktitle: '巨人の肩に乗り、SaaSの開発を眺める'
title: '巨人の肩に乗り、SaaSの開発を眺める'
tags: ['海外SaaS']
weight: 16
---

## はじめに

最近ユーザーへのヒアリングを積み重ねていく中で、この課題を解決するための最適解になるのは何かを機能単位に落とし込む際に、自分の手持ちの体験の少なさが露見することが多かった。  
顧客の課題が大きく解決が必要だったとしても、その解に対するアプローチが悪ければそもそも使ってもユーザーへの価値を最大化することは難しく既存のオペレーション(自分たちだと紙)に敗北する未来は最もたやすく形成されてしまう。  
このオペレーションを解決するための最適な意思決定は何かを知るためには、他の SaaS を探訪することによって巨人の肩にのり、ストーリーを知りたいなと思った。  
何故このプロダクトは生まれたのか、そしてこのプロダクトが解決したいことは何か。この時に得る学びにはどの様なものがあるのか。  
成長速度の早い SaaS はどの様な戦略を取ってきたのかを潜る。

### Airtable (Series C, 資金調達額: $170.6M)

![airtable lp](https://gyazo.com/190908712e38be293b079e3f3b5a8b87/raw)

進化型の Spreadsheet SaaS。
Airtable は従来の Spreadsheet と比較すると、テンプレートとセルのフィールドがかなり柔軟に設定できる。
テンプレートの設定で、CRM, ユーザーリサーチ, バグトラック, 不動産取引管理, 採用管理等の複数のユースケースに対してテンプレートを管理することができ、
セルのフィールドの設定で、画像つきの form 作成, カレンダーでの予定の TODO 管理, かんばん形式によるプロジェクト管理等を NoCode で実現できるところが強み。

![convert](https://gyazo.com/11869f57aaeca465bfdefbd8ea644dd6/raw)

今までだと、Google Form とか、Google Calendar とかを使って管理をしていたであろう部分を汎用的な設定により、より複雑な要件に対しても柔軟に耐えうるような進化型の Spreadsheet。  
そんなAirtable が、どの経緯で生まれ、そしてそのサービスは何故この様な使われ方をされる様になったのかを探る。    

Airtable の創設者である Howie Liu は、2010 年にはメール連絡先管理の CRM の開発を行っていた。これが Etacts。

> Etacts was a lightweight personal relationship manager (PRM) that allowed users to keep in contact with people. After a user signed up with Etacts, the service would crawl through the user's email headers and obtain statistics (of contact frequency, last contacted date, importance metric, recent conversations) of each user's contacts. The service allowed users to store additional notes for each contact. Etacts also worked with social networking services such as LinkedIn (product), Facebook (product) and Twitter (product) to show profile pictures and other relevant data of the contacts from those services.

Etacts は、各ユーザーの連絡先の統計（連絡頻度、最終連絡日、重要度メトリック、最近の会話）を取得。またサービスにより、ユーザーは連絡先ごとに追加のメモを行うことも出来る。  
後に、Salesforce によって買収することになり、LiuはSalesforceでのプロダクトマネージャーとして1年過ごし違和感を感じる。

> “Spreadsheets are really optimized for numerical analysis and financial calculations. But almost 90% of spreadsheets don’t have formulas. Most are used for organizing purposes.” — Howie Liu, founder, Airtable

**スプレッドシートは数値分析や財務計算に最適化されていたが、スプレッドシートのほぼ9割は数式を持っておらずほとんどが整理目的で使われてることだった。  そこでLiu氏が開発するAirtable は、ユーザーが使い慣れた状態で本質的な組織的なツールを開発することを出発点としてサービス開発が行われた。** 

以下の2つの例から Airtable 成長の一端を見る。  

**1. Powering legislative advocacy using Airtable: Andrew Cates**

https://airtable.news/powering-legislative-advocacy-using-airtable-andrew-cates-ae66d5385200

2015 年 9 月まで、病院で仕事中に怪我をしたテキサス州の看護師は、限られた救済手段しかなかった。  
それはなぜかと言うと、テキサス州法があいまいな言葉で書かれたものしかない。  
テキサス州法が曖昧なのは、2003 年の医療過誤および不法行為改革法は、病院の雇用主に対するこれらの看護師の主張を医療過誤訴訟と同じカテゴリーにまとめたことが原因としてあげられていた。  
ここでケイツ氏が求めていたことは、看護師が仕事中に怪我をした場合に補償を求めることができるようにする法案の可決を支援することだった。  
この法案を擁護するために、以前は Excel を使って各議員の参謀長の連絡先リストを使っていた。  
これに対して Airtable を使うことで、顔と名前が画面で一目でわかることに良さがある。

![](https://gyazo.com/fe83060551e479c4153bb2de668f5f4f/raw)

これによって、人と顔の一致が即座に認識出来ることに良さを感じてはじめにAirtableを利用している。  
また、ケイツ氏はこの法案擁護に対しての情熱で本を実費出版を行う。  
この際に、顧客のプリセールス、出荷、在庫を整理する必要が出てきた時に、Airtable を使う。

この例から、**最初はケイツ氏の議員の連絡リストから始まり、その議員に対するリレーションからその議員が所属する看護関連の議会委員会へのリンクを作りこみ、最終的に本の出版に対する入出庫管理の側面まで課題も解決。汎用的なツールをノーコードで複数作成することに成功している。**

**2. Students, meet your match: how ScholarMatch made Airtable work for them**

https://airtable.news/students-meet-your-match-how-scholarmatch-made-airtable-work-for-them-part-1-7a1d77a2bf51  
https://airtable.news/students-meet-your-match-how-scholarmatch-made-airtable-work-for-them-part-2-cf980ea8f691

ScholarMatchは、クラウドファンディングの大学奨学金を提供している小さな非営利団体で、寄付者や寄付を管理するための安価で柔軟なソフトウェアを探していた。
ScholarMatch は、さまざまな種類の情報を簡単に収容して相互参照できるシステムが必要であり、これを実装するための従来のデータベースシステムだと数万ドルかかる様なものだった。    
各情報をデータベース化させ、さらに寄付時にデータベースの状態をリアルタイムで管理する様な場面も出現し、システムの複雑度が増す。
この複雑なユースケースに対しても Airtable は解決する。  

![](https://gyazo.com/c729c4bf539123d854ecddc29efc6c61/raw)

zapier を介して Stripe と統合することが出来る Airtable は、Stripe 上から寄付される金額情報を Airtable 上に格納し管理を行う。  
さらに、寄付テーブルのフィールドのうち、寄付の日付と金額を連結させ、各寄付レコードに対してコードを付与させる。  
また、ScholarMatch は寄付の旅に寄付者への感謝状を送る。ここでの住所の絞り込みを行う際にも、ルックアップフィールドを利用し、寄付テーブル内から絞り込みを行うことが出来る。  
各テーブルを抽象化しその抽象化したテーブルに対しての絞り込みだったりはまさに SQL を記述するのと同じ様な感覚で利用出来る。  
このようにScholarMatchでは**決済管理ツールを起点としてとして、クラウドファウンディングの管理ツールとしてノーコードでかつコスト自体も抑えた状態で作ることを可能とした。**

このようにAirtableは、**自社内で作られるであろうシステムを汎化させ、スプレットシートを利用した他の様々な組織的なツールを作ることが出来ること自体に価値を見出し、非エンジニアでもスプレットシートを利用したツールを汎用的に作れることが出来る**点が他のサービスと画一していることがわかる。

### Front (Series C, 資金調達額: $138.3M)

![front lp](https://gyazo.com/61bd4daef3d0d6f2ac44f741cc203401/raw)

チーム間でのメールコミュニケーションを効率化する SaaS。  
例えば email に.cc をつけて運用をもししていた場合に、メールそのものが埋もれてしまったり、そのメールに対してどのくらい重要なメールなのかがわかりづらくなる。この痛みを解決する。

![](https://gyazo.com/bf791eb3b44c86ca1bfce6de8c5bc892/raw)

現在、拡張できるアプリ数も 50 件以上あるため、個人で手持ちのタスクが大量に持ち始めて誰がどの情報を持っているのかが乱立するような場合にチーム間で流れやすいコンテキストの共有をemailを超えて一元で管理できることに超特化。

Front が解決したいことは何か、またどんなアプローチを取ってきたのか。またそれはなぜか

https://medium.com/@collinmathilde/predicting-the-future-of-email-c934bdc1583d

> - CCs and BCCs should disappear and give way to a “share” feature.
> - Forwarding a mail will be replaced by a “comment” function.
> - Reply-all will give way to subscribe/follow mechanisms.

**Front がそもそも解決したい課題は email をなくすことではなく、既存の email を再定義すること。email での体験を一部新しい価値に変換し、Front にしかない体験の提供を行う。**  
CC, BCC, 返信の体験を根本から価値を変えて、共有だったりメールにコメントと言うレイヤーを追加している。

https://techcrunch.com/2014/06/18/front-is-a-shared-inbox-app-that-makes-email-suck-lessfront-is-a-shared-inbox-app-to-make-email-suck-less/

当時競合として Zendesk が出現していたが、この比較において **Front は顧客をタスクとして捉えずに、シームレスにチームメンバー間でメールをタスクとして共有資産に出来る。**  
ここに根本的な提供価値に差分を出す。既存の email の自体を死滅させることはなく顧客間のコミュニケーションを最大化させるためのツールの立ち位置を維持する。

https://medium.com/@collinmathilde/email-will-last-forever-eaf3ea6e2196

> - There are over 2.4 billion email users and 3.9 billion email accounts today
> - People spend on average 2.5 hours per day on their emails
> - Workers check their emails an average of 74 times a day

> email is a platform that still has room for innovation, and better yet, without changing the basic premise of how email works.

> email is being replaced for some types of communication (personal and professional). It’s nothing to be worried about. We have more choices for how to communicate today, and can cherry-pick the best tool for every situation . It doesn’t mean email is dying. It simply means that the communication ecosystem has expanded.

**1. email を利用する人数、頻度、痛みの強さ全てが高い状態にあり、email はこの大きな課題に対してのアプローチを行っているためそもそも消えることがそうそうないということ。**  
**2. まだ email 自体がイノベーションの途中であり仕組みの大前提を変えることが求められているということ。**  
**3. email そのものが死滅するのではなく、単にコミュニケーションのエコシステムの発達が求められてきている状態が今の状態であるということ。**

これが、Front が email そのものの価値を否定するものではなく、email を通じて行われるコミュニケーションの拡張だったり、価値の再定義を行っていることがわかる。

では、このFrontが使われる興味のある領域と領域での使われ方はどう使われているのか。また、この領域内で改善していったものにはどんなものがあるのか。

https://frontapp.com/blog/5-ways-logistics-teams-use-front

> Oftentimes, it’s such a competitive industry that the first to respond gets the shipment.

物流業界において、業務内の速度そのものが価値となりそれが売り上げへと直結するような大事な事項である。
このうちで出荷の業務内でFrontを活用。ここでFrontの自動化の機能を利用して、ルールを作成する。  

> For example, if an email has been sitting without a reply for 10 minutes, LDI uses automated rules in Front to automatically escalate that message into a High Priority inbox, with a “urgent” label, so someone can jump on it immediately.

出荷におけるメールでのやりとりの時間で無駄が発生しうる事項に対して、**自動アクションを設定しラベルでの管理を行うことでチーム感でオペレーションの漏れがないことや、速度が遅れている作業がないかどうかをリアルタイムに進捗管理を行うことができる。**   

https://help.frontapp.com/t/h42v6y/automate-actions-with-rules

他の例だと、以下の物流関連のIT企業。  

https://frontapp.com/customer-stories/boxton

各輸送業者単位でのやりとりの管理等をApple Mailのフォルダを作成していて、これが250通/日のメールを管理する。  
この管理方法だと、フォルダで各輸送業者単位でどの輸送業者からの連絡かと言う単位は理解できるが、そこからそのメールの重要度が把握できない。  
そこで、**タグを利用して各輸送業者単位の管理、また割り当て機能を用いて各ユーザー間でのやりとりを知ることができるようにさせた。**  
この効率化により、会社全体でのリモートでのやりとりを可能にさせている。  

このように、**チーム間でのメールコミュニケーションを効率化させる。そこから発展してかつタグや自動化アクション等を利用することによりフォルダ管理では実現出来なかったメールの進捗管理等の側面も取り入れ、emailそのものの機能では網羅しきれないニーズも獲得した点**がサービスとしてレベルが一つ上だと感じる。  

## 終わりに

今回は2つの大型調達を行っているSaaSの肩からサービスの成長を眺めながら、両方のSaaSの成長の過程でどんなユーザーのニーズが発生したのか、またどんな機能が発生したのかを眺めた。  
どちらのサービスも、既存の価値のサービス内で解決がなかなか難しいであろうユーザーのニーズを汲み取り新しい価値へ変換させていることがひしひしと感じる。  
ユーザーのニーズの価値を見誤らずサービスの価値を最大化させていきたいと身が引き締まったそんな気持ちである。  

## 参考文献

- https://usefyi.com/airtable-history/
- https://www.quora.com/What-does-Etacts-do
- https://airtable.news/powering-legislative-advocacy-using-airtable-andrew-cates-ae66d5385200
- https://techcrunch.com/2014/06/18/front-is-a-shared-inbox-app-that-makes-email-suck-lessfront-is-a-shared-inbox-app-to-make-email-suck-less/

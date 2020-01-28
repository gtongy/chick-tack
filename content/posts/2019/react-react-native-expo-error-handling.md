---
date: 2020-01-23T22:55:32+09:00
linktitle: 'react + react native(Expo)でエラーハンドリングどうやる？'
title: 'react + react native(Expo)でエラーハンドリングどうやる？'
tags: ['react', 'react native', 'redux', 'error handling']
weight: 16
---

![react react native expo error handling header](/images/2019/react-react-native-expo-error-handling/react-react-native-expo-error-handling-header.png)

## はじめに

最近業務内で、サーバーサイド 側のエラーハンドリングを以下記事を参考にさせていただきながらエラーメッセージを統一化しました。

https://techdo.mediado.jp/entry/2019/02/15/120257

サーバーサイド側はエラー周りの整備が進んでいく中で、 client 側非同期処理のエラー周りがまだ未整備だったこともあってどこかで直したいなぁと薄々思っていて。

業務で認証の有効期限周りの実装を行うタイミングがあったので、ちょうどいいタイミングだなということで色々試行錯誤しながら試してみました。  
どのパターンが今の自分にあっているのかを探して今はこれに落ち着いてるというところを紹介できたらなと思います。  
まだこれから他の形に変わっていくかもですが現在までの思考整理も含めて。

## 全体の方針。error tracking は何を使う？

monorepo 構成で実装をしているところもあって、React + React Native(Expo)を使うことを前提とした時に、

- Sentry
- Firebase Crashlytics
- TrackJS
- Loggly

等が候補かなぁというところでしたが、ドキュメント(Expo, sentry)の豊富さだったり、React Native のサポートだったり、そもそもの使いやすさの面 + 価格が 5000/month が free ということで、相性の良さそうな Sentry を選びました。

今回は Sentry を使って Error Tracking を行おうかなと思います。

## React のエラーハンドリング

React 16 以降から Uncaught Error 時の画面の挙動が変わっていて、React 16 以降になるとエラー発生時に component が unmount されて画面が真っ白になってしまう仕様に変わりました。  
これだと、ユーザビリティが低い。なので、React 16 以降では componentDidCatch のライフサイクルメソッドが提供されているため、これを使ってコンポーネントで発生したエラーに対してエラーハンドリングを行う必要があります。

```jsx
import React, { Component } from 'react'
import * as Sentry from '@sentry/browser'

interface Props {}

interface State {
  eventId?: string
  hasError: boolean
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { eventId: '', hasError: false }
  }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  componentDidCatch(error: Error, errorInfo: {}) {
    Sentry.withScope(scope => {
      scope.setExtras(errorInfo)
      const eventId = Sentry.captureException(error)
      this.setState({ eventId })
    })
  }

  render() {
    if (this.state.hasError) {
      return (
        <div>エラー発生した旨をここに記述<div/>
      )
    }
    return this.props.children
  }
}

export default ErrorBoundary
```

具体的には上記の class component ベースの Component を作成し、

```jsx
import React from 'react';
import { Provider } from 'react-redux';
import configureStore from '../state/store';
import Routes from './Routes';
import ErrorBoundary from '../libraries/ErrorBoundary';
import * as Sentry from '@sentry/browser';

const store = configureStore();
Sentry.init({ dsn: process.env.REACT_APP_SENTRY_DSN });

const App: React.FC = () => {
  return (
    <ErrorBoundary>
      <Provider store={store}>
        <Routes />
      </Provider>
    </ErrorBoundary>
  );
};
```

最上位の App.tsx で Comonent を wrap します。これで子 Component 以下で発生するエラーを補足して componentDidCatch 内の

```ts
Sentry.withScope(scope => {
  scope.setExtras(errorInfo);
  const eventId = Sentry.captureException(error);
  this.setState({ eventId });
});
```

の箇所でエラーを Sentry に送るような実装になります。  
エラーを送ると以下のように画面内でエラーを確認することができます。  
これは React, React Native で同様の画面を確認出来る感じです。

![sentry view](https://gyazo.com/61a7b3cf71b0d5ce87cb87511db384bd/raw)

React Hooks は対応はされておらず、Error の観測は tree 構造であることが望ましいとされているため、Hooks の対応はまだされていないという感じでした。  
この処理だけは長い間 class component で使われるのかなという感覚です。

https://github.com/facebook/react/issues/14347

## React Native(Expo) のエラーハンドリング

このあたりは Expo への導入の方は、Expo の document 通りにやったら特に詰まることないです。  
気をつけるとしたら auth token の project:write の権限を忘れないこととくらいですかね？

https://docs.expo.io/versions/latest/guides/using-sentry/

ただ、別々の env で管理する時にどうするのかがわからないのでその辺りは少し工夫が必要なのかなという感じです。

https://wheatandcat.hatenablog.com/entry/2019/09/25/091029

実装はこの記事の jq の実装を参考にさせてもらって実装しました。

```
{
  "expo": {
    "hooks": {
      "postPublish": [
        {
          "file": "sentry-expo/upload-sourcemaps",
          "config": {
            "organization": "organizationName",
            "project": "projectName",
            "authToken": $authToken
          }
        }
      ]
    },
    "extra": {
      "sentryDSN":  $sentryDSN
    }
  }
}
```

のように、appBase.jq を作成して、

```
jq -n --arg authToken $authToken --arg sentryDSN $sentryDSN -f appBase.jq | tee app.json
```

を実行することで環境ごとに別々の app.json を作成出来ます。  
そうすると各環境ごとのファイルを git 管理しなくて済むのと、app.json の extra に設定した sentryDSN を利用して、

```ts
import Constants from 'expo-constants';

Sentry.setRelease(Constants.manifest.revisionId || 'development');
Sentry.init({
  dsn: Constants.manifest.extra.sentryDSN,
  enableInExpoDevelopment: true,
  debug: true
});
```

のように環境変数を expo でも切り出すことが出来るので便利だなという感じです！これは jq 様様です。

<!--adsense-->

## Redux のエラーハンドリング

React, React Native(Expo)の画面内で発生するようなエラーは上記で概ねエラートラッキング出来るかなと思うのですが、非同期処理のエラーもエラーハンドリングしたいとなった時、所謂画面を離れた時の処理をどうするのかは少し悩ましいところかなと思います。  
こういうエラーを各所で書くのもいいですが、認証エラーだったりの各コンポーネント単位ではない共通で同様のエラーハンドリングを毎回書くのは億劫だなぁという感じです。  
はじめにで軽く触れましたが、幸い、サーバーサイド側の処理は以下記事の実装を行ってすぐだということもあり、ある程度整形された json が渡って来る形式にはなっていたので、尚更に共通化することが出来そうだな？という気持ちでした。

具体的にはエラーが返却される時には

```
{"status", 500, "code", 5, "errors": ["error1", "error2"]}
```

のような json が返却されるようになっています。  
こういうエラーを snackbar のような形で通知するとなった時に各所で dispatch を書くのではなく、1 つ reducer を作成することで解決しようかなという設計で実装してみました。

```ts
import { ErrorInterceptionAction, SuccessInterceptionAction } from './actions';

interface HTTPError {
  // status code
  status: number;
  // エラーコードごとにエラーのタイプが別れる。内部エラーと外部エラーの定義をここで判別する
  code: ErrorCodeEnum;
  // error messages
  errors: Array<string>;
}

const handleHttpError = (error: HTTPError) => {
  return {
    type: ActionTypes.HANDLE_HTTP_ERROR,
    error
  };
};

const authFailure = (error: HTTPError) => {
  return {
    type: ActionTypes.AUTH_FAILURE,
    error
  };
};

const authExpired = () => {
  return {
    type: ActionTypes.AUTH_EXPIRED
  };
};
const internalServerError = (error: HTTPError) => {
  return {
    type: ActionTypes.INTERNAL_SERVER_ERROR,
    error
  };
};

type ErrorInterceptionAction = ReturnType<typeof handleHttpError> &
  ReturnType<typeof authFailure> &
  ReturnType<typeof authExpired> &
  ReturnType<typeof internalServerError> &
  ReturnType<typeof resetError>;

interface HttpErrorInterceptionState {
  error: Error | null;
}

const initialHttpErrorInterceptionState: HttpErrorInterceptionState = {
  error: null
};

const errorInterception = (
  state: HttpErrorInterceptionState = initialHttpErrorInterceptionState,
  action: ErrorInterceptionAction
): HttpErrorInterceptionState => {
  switch (action.type) {
    case ActionTypes.AUTH_FAILURE: {
      return {
        ...state,
        error: new Error(action.error.errors.join('\n'))
      };
    }
    case ActionTypes.INTERNAL_SERVER_ERROR: {
      return {
        ...state,
        error: new Error(action.error.errors.join('\n'))
      };
    }
    case ActionTypes.AUTH_EXPIRED: {
      return { ...state, error: new Error(action.error.errors.join('\n')) };
    }
    case ActionTypes.RESET_ERROR: {
      return { ...state, error: null };
    }
    // ...
    default: {
      return { ...state };
    }
  }
};
```

のように、error の reducer を作成します。ここで redux で error 専用の reducer を作成します。  
この各アクションを発行するタイミングは redux-saga で定義します。  
以下のような generator を作成します。

```ts
import { put, takeEvery } from 'redux-saga/effects';
import { default as actions, ErrorInterceptionAction } from './actions';
import { ErrorCodeEnum } from 'api';
import { ActionTypes } from './types';

function* handleHttpError(action: ErrorInterceptionAction) {
  switch (action.error.code) {
    case ErrorCodeEnum.AuthenticationFailure: {
      yield put(actions.authFailure(action.error));
      yield put(actions.resetError());
      return;
    }
    case ErrorCodeEnum.InternalServerError: {
      yield put(actions.internalServerError(action.error));
      yield put(actions.resetError());
      return;
    }
    case ErrorCodeEnum.AuthenticationExpired: {
      yield put(actions.authExpired());
      yield put(actions.resetError());
      return;
    }
  }
}
const sagas = [takeEvery(ActionTypes.HANDLE_HTTP_ERROR, handleHttpError)];
export default sagas;
```

これを作成することで、エラー補足時の action(ActionTypes.HANDLE_HTTP_ERROR) を発火するタイミングで、内部の error のコードを判別し、エラーの状態によってそれぞれのエラーを表示することが出来ます。  
これを、各 api の呼び出し後の try-catch で補足した catch 文内で呼び出します。

```ts
function* getTodo(action: TodoAction) {
  try {
    const todo = yield call(getTodoRequest, {
      todoId: action.todoId
    });
    yield put(actions.getSuccessTask(task));
  } catch (error) {
    yield put(interceptionsActions.handleHttpError(error));
  }
}
```

これを各所で定義することで非同期処理に対するエラーハンドリングを行うことが出来るようになり、エラー発生時は global state で管理している内部の error の値を更新することで、snackbar 等で通知を行うことも出来るようになります。

具体的に通知する箇所は以下のような実装を差し込んでいます。

- presentational component

```jsx
import React, { useEffect } from 'react';
import { notification, Modal } from 'antd';

const { info } = Modal;

interface OwnProps {
  error: Error | null;
}

const ErrorNotification: React.FC<OwnProps> = (props: OwnProps) => {
  useEffect(() => {
    if (props.error !== null) {
      notification['error']({ message: props.error.message });
    }
  }, [props.error, props.isShowAuthExpired]);
  return null;
};

export default ErrorNotification;
```

- container component

```jsx
import React from 'react';
import ErrorNotification from '../../views/components/interceptions/ErrorNotification';
import { useSelector, shallowEqual } from 'react-redux';

interface State {
  interceptionsState: {
    errorInterception: {
      error: Error
    }
  };
}

const useStateProps = () => {
  return {
    error: useSelector((state: State) => state.interceptionsState.errorInterception.error, shallowEqual)
  };
};

const ErrorNotificationContainer: React.FC = () => {
  const stateProps = useStateProps();
  return <ErrorNotification {...stateProps} />;
};

export default ErrorNotificationContainer;
```

これで、発生したエラーを補足してエラーを表示することが出来るようになります。

## まとめ

エラーハンドリングがまだ未整備の状態だったので、api - web - mobile を一気通貫で整備したいなぁということで一連の流れの説明をしてみました。  
実際各所でまだ至らない箇所もあるなと感じている部分はあって(各 component 単位, 各 state 単位で発生するエラーで正しくハンドリング出来てるか？とか)、ここは徐々に改善させていくしかないかなという気持ちです。  
エラーハンドリングは後々に回すとコード量が増えてなかなか触られなくなってくると辛いので、ガッと一気にやるのが個人的なおすすめです。  
是非試してみてください！

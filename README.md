# myDiary

`myDiary` は、個人の日記を長期保存・閲覧するための macOS 用日記アプリです。

SwiftUI と SQLite（GRDB）で作成しています。

Facebook など特定のサービスに依存せず、日記本文・画像・リンク情報をローカル環境で管理することを目的としています。

## 特徴

- macOS ネイティブアプリ
- SwiftUI によるタイムライン表示
- SQLite（GRDB）による投稿管理
- 複数画像の表示
- 画像の original / display / thumbnail 管理
- YouTube サムネイル表示
- Webリンク画像の表示
- 投稿間リンク
- コメントと親投稿の関連付け
- Diary Package のインポート
- インポート後はオフラインで閲覧可能

## Diary Package

`myDiary` は、次のような Diary Package を読み込みます。

```text
MyDiaryPackage/
├── diary.json
└── pictures/
    ├── photo/
    ├── youtube/
    └── link/
```

`diary.json` には投稿本文、日時、メディア情報、投稿間リンク、コメントの親投稿情報などを記録します。

画像やサムネイルは Package 内の `pictures/` 以下に保存します。

myDiary の Import 処理は、Package 内のファイルだけをローカルストレージへコピーします。Import 時にインターネットから画像やサムネイルを取得することはありません。

## facebook2tex との関係

Facebook のアーカイブデータから Diary Package を生成するために、別プロジェクトの `facebook2tex` Version 3 を使用します。

処理の流れは次のようになります。

```text
Facebook Archive
        ↓
facebook2tex Version 3
        ↓
Diary Package
  ├── diary.json
  └── pictures/
        ↓
myDiary
        ↓
SQLite + local pictures
```

Facebook 固有のデータ構造の解析や、YouTube サムネイル・Webリンク画像の取得は `facebook2tex` 側で行います。

`myDiary` は完成した Diary Package を読み込むだけです。

## データ保存

投稿データは SQLite に保存します。

画像はデータベース内には保存せず、ファイルとして管理します。

```text
pictures/
├── original/
├── display/
└── thumbnail/
```

データベースには画像ファイルへの相対パスを保存します。

このため、画像の表示サイズを変更しても元画像を保持できます。

## 投稿

投稿は主に次の情報を持ちます。

- 本文
- 日記日時
- 作成日時
- 更新日時
- Package 内投稿ID
- 画像
- 投稿間リンク
- 親投稿ID

Diary Package の `parent_post_id` は、Import 時に myDiary 内部の SQLite ID に変換されます。

これにより、親投稿に関連付けられたコメントを投稿の下に表示できます。

## 重複Import

Diary Package の投稿IDは `packagePostID` として保存されます。

同じ Diary Package を再度Importした場合、既に登録済みの `packagePostID` を持つ投稿はスキップされます。

これにより、Importを途中で中断した場合でも、再度Importを実行できます。

## 開発環境

- macOS
- Xcode
- Swift
- SwiftUI
- GRDB.swift
- SQLite

## 現在の状態

現在は macOS 版を開発しています。

主な実装済み機能：

- 投稿の作成・編集・削除
- 画像の追加・表示
- 複数画像レイアウト
- 画像ビューア
- YouTube / Webリンク画像
- 投稿間リンク
- Diary Package Import
- `packagePostID` による重複Import防止
- コメントと親投稿の関連付け
- 親投稿下へのコメント表示

今後、Diary Package の Export 機能や、コメントと親投稿を手動で関連付ける編集機能などを追加する予定です。

## プライバシー

`myDiary` は個人の日記データをローカルで管理することを目的としています。

このGitHubリポジトリには、ユーザーの日記本文、SQLiteデータベース、写真、Diary Packageは含まれていません。

## License

ライセンスは未設定です。

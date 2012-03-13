This example application codes and documents for Japanese only.

## はじめに
iOS 5.0.1から導入された「Data Storage Guideline」に準拠していないという理由でリジェクトされたという事例が増えています。筆者自身も連続２回にわたりリジェクトされてしまったのですが、当初その理由が明確にわかりませんでした。しかし、曖昧な表現の多い「Data Storage Guideline」を何回も読み直して、オフラインデータ、つまり通信環境が利用できない場所でもアプリ内で利用するデータファイルに対して「do not backup」属性をセットする点に着目しました。

Cacheを除くAPP_DIR/Libraryにファイルを保存すればバックアップ対象にもなる訳で、たいしたサイズではないので、APP_DIR/Library/Private Documentsに単純に保存すれば良いと思ったのですが、オフラインデータについてはバックアップ対象にしてはいけないという事なのでしょうか？

その方針はアップルにしかわからない訳ですが、その理由不明なルールに従い、とにかくオフラインで閲覧できるデータについては「do not backup」属性をセットする事にしました。

とはいえ、作業する過程でいくつかはまった事がありましたので、少しでも皆様のお役に立てればいいなという事で情報を共有する事にしました。ブログに書けよという声が聞こえてきそうですが、筆者はブログにコード等を書きたくないという変な思い入れがありますので、ちゃんとしたコードとともに提供できるgithubで情報提供する事にしました。

ご質問、ご意見は直接githubからメッセージをいただくか、Twitter @naokitsまでご連絡ください。
ちなみに、最近はあまりTwitterを使用していないので、返信は遅れる可能性があります。

とりあえずソースコードも提供しました。
あいかわらずXcodeで共有したブレークポイント情報のみXcodeの個人設定情報として提供したいのですが、.gitignoreに指定する方法がわかりません。方法をご存知の方は是非ご教示ください。

<strong>
自動停止しないブレークポイントを使用してログを表示していますが、ソースを変更すると位置がずれてしまうようです、もしずれているだろうと思われるブレークポイントがありましたら、お手数ですがご自身で位置を調整してください。</strong>


コードの説明についてはコード内のコメントもご覧ください。

<br /><br />

## 注意事項
iOS5.1にはバックアップの対象としないファイルやディレクトリに対してマークするAPIが追加されています。
使い方としては、バックアップをさせないためのキー属性をNSURLオブジェクトにセットしますが、具体的なことはアップルとのNDAの関係上、現在は詳細を書けませんのでiOS5.1が正式リリースされた後に、改めてご紹介します。

なお、iOS5.1以上では、「com.apple.MobileBackup」属性を直接追加してはいけないとされています。つまりAPIを使えということです。

よってこの現在のサンプルコードと動作確認方法はiOS5.0.1のみで使用できる（使用しなくてはならない）内容となりますので、ご注意ください。iOS5.0.0やiOS5.1以降では使用できません。

<br /><br />

## 動作環境
筆者の動作環境を次に示します。

* Mac OSX 10.7.2 (Build 11C74)
* Xcode 4.2 (Build 4D199)
* 対象iOSのバージョン <strong>5.0.1</strong>のみ
* ARC ON
<br /><br />

## 関連情報
* [iOS Data Storage Guidelines - Apple Developer](https://developer.apple.com/icloud/documentation/data-storage/)
* [Technical Q&A QA1719: Technical Q&A QA1719](https://developer.apple.com/library/ios/#qa/qa1719/_index.html)

<br />

## サンプルアプリケーションの説明
このサンプルプログラムでは、起動直後にファイルを保存するディレクトリを作成し、即座に「do not backup」属性をセットしています。その直後に、アップルの公式日本語ドキュメント（Blocks.pdf）をダウンロードし属性をセットしたディレクトリ内に保存しています。

また明示的にBlocks.pdfにも属性をセットしています。

SKRMasterViewController.mファイルの130行付近の属性をセットしている部分をコメントアウトすれば、Blocks.pdfに対して「do not backup」属性をセットしません。

<br /><br />



## 動作確認方法

### 方法１
#### xattrコマンドを使用する

サンプルプログラムのアプリケーションディレクトリの構成は次のようになります。
<pre>
<code>
.
├── DoNotBackupExample.app
├── Documents
├── Library
│   ├── Caches
│   ├── Preferences
│   │   └── com.apple.PeoplePicker.plist
│   └── Private\ Documents
│       └── MyDocuments      <-- 「do not backup」属性をセットする
│           └── Blocks.pdf
└── tmp

</code>
</pre>

<br /><br />

アプリケーションディレクトリに移動します。

    % cd /Users/USERNAME/Library/Application Support/iPhone Simulator/User/Applications/GUID/

念のために説明しますと、USERNAME はユーザアカウント名、GUIDは「Global Unique ID」と呼ばれるもので、次のような形式で表わされます。「D1E5F588-B3B2-4A12-9D91-00EEE64FEF64」

アプリケーションの場所を具体的な例を示すと次のようになります。

    /Users/hoge/Library/Application Support/iPhone Simulator/5.0/Applications/D1E5F588-B3B2-4A12-9D91-00EEE64FEF64/

以降、このアプリケーションディレクトリを**APP_DIR**と示します。
<br /><br /><br />

**APP_DIR**に移動したら、次のように**xattr**コマンドを実行し結果を確認します。
<br /><br />

    % xattr -plxv com.apple.MobileBackup Library/
    Library/: com.apple.MobileBackup:
    xattr: Library/: No such xattr: com.apple.MobileBackup

サンプルプログラムでは、APP_DIR/Library/Private Documents/MyDocumentsディレクトリと、そのディレクトリに保存したファイルにのみ「do not backup」属性をセットしていますので、上のように属性名であるcom.apple.MobileBackupがないと表示されます。
<br /><br />

    % xattr -plxv com.apple.MobileBackup Library/Private\ Documents/
    Library/Private Documents/: com.apple.MobileBackup:
    xattr: Library/Private Documents/: No such xattr: com.apple.MobileBackup

Private Documentsディレクトリには属性をセットしていませんので、属性名であるcom.apple.MobileBackupがないと表示されます。
<br /><br />

    % xattr -plxv com.apple.MobileBackup Library/Private\ Documents/MyDocuments/
    Library/Private Documents/MyDocuments/: com.apple.MobileBackup:
    00000000  01                                               |.|
    00000001

サンプルプログラムでは、このMyDocumentsディレクトリに対して明示的に「do not backup」属性をセットしています。よって、正常に属性がセットされていれば上記のような表示になります。
<br /><br />

    % xattr -plxv com.apple.MobileBackup Library/Private\ Documents/MyDocuments/Blocks.pdf
    Library/Private Documents/MyDocuments/Blocks.pdf: com.apple.MobileBackup:
    00000000  01                                               |.|
    00000001

サンプルプログラムではBlocks.pdfをアップルの日本語公式ドキュメントサイトからダウンロードし、上記のように属性をセットしたAPP_DIR/Library/Private Documents/MyDocumentsディレクトリに保存しています。
サンプルプログラムを書き換えず、デフォルトのまま動作させた場合は保存したPDFファイルに対しても明示的に属性をセットしています。そのため、上記のように属性がセットされていることを確認できます。

Blocks.pdfに対して明示的に属性をセットしなくても、MyDocumentsディレクトリに属性がセットされていますので、アップルのバックアップエンジンはMyDocuments以下のファイルをスキップし、バックアップ対象としません。

過去の本ドキュメントでは、MyDocuments以下のファイルやディレクトリに対しても自動的に属性がセットされると書きましたが誤りです。明示的に属性をセットしない限りは属性はセットされません。単純にバックアップ対象外として無視されるだけです。

つまり、**属性をディレクトリにセットすれば、そのディレクトリ以下のファイルに対して個別に属性をセットしなくても自動的にバックアップ対象外として認識される**という事です。

サンプルプログラムのデフォルトの動作は、ダウンロードしたファイルに対しても明示的に属性をセットしています。
必要がない／動作を確認してみたい場合は、属性をセットする部分をコメントアウトしてください。
そして上記のコマンドを実行して、結果がどのように変化したか確認してみてください。

バックアップ対象外としたファイルが実際にバックアップされていないか確認するためには、実機とiTunesを使用してテストを行う必要があります。その方法については「方法２」を参照してください。

<br /><br />

### 方法２

次の方法は、アップルからの非公開情報ですが、あまり公開しないでほしいと言われている内容が含まれます。重要な部分に関しては説明を省略していますので、詳しい内容が知りたい方は個別に連絡をください。

なお、この方法は面倒で慎重な作業を要求されます。なので、上記の方法１で確認したにもかかわらずリジェクトされたという場合にのみ実施された方が良いと思います。

まずは徹底的にシミュレータでアプリをテストして、"do not backup"属性が正しくマークされていることを確認してください。（方法１を使用してください）

方法１でも同じ事ですが、属性をセットする前に、必ずファイルまたはフォルダが存在する事を確認します。アプリを初めて起動する場合（再インストールを含む）は特に注意してください。

複数回ファイルを保存する場合には、正常に見えてしまう事があります。

- 前述の注意事項に注意し、確実にファイルに対して属性をセットしたという前提で次のテストを行う事ができます。

2つの方法を使用してバックアップを検査することができます。

次のコマンドを使用します。

    /System/Library/PrivateFrameworks/MobileDevice.framework/Versions/A/AppleMobileDeviceHelper.app/Contents/Resources/AppleMobileBackup --list

このコマンドを実行すると、バックアップされているデバイスの一覧が表示されます。表示形式はデバイス名 (UDID）

    1. NKiPad (12b2d88e14e89ac5480ce0acab74e91a53ebe33e)
    2. NKiPodTouch (8ebb0c41aa582831c5705aac6689ad32257e3ea4)
    3. NKiPhone3GS01 (b3b908b748fe7be68d10cad7cd6f0a2ef0b9ac95)

    Please select a backup (1-3):



このコマンドはモバイルバックアップの内容の一覧を表示します。
アプリは、「 AppDomain-<bundle ID> 」のドメイン名でリストされます。

注）この方法はかなり面倒で不確実ですので、現時点では説明をやめます。

<br />


さらに、次の手順でモバイルバックアップのログを有効にすることができます。

1. 次のコマンドをターミナルで実行すると、デバッグログが有効になります。
defaultsコマンドを使用して、com.apple.MobileBackupにあるパラメータをセットしますが、「.....」の部分は公にできないので個別に聞いてください

    % defaults write com.apple.MobileBackup Session.....

2. iTunesでiOSデバイスをバックアップします。

3. 次の場所に書かれたログを調べます。

    ~/Library/Application Support/MobileSync/Backup/Logs/MobileBackup-**UDID**-**DATE**-**time**-Backup-Device.log

    注）デバッグログを有効にし、iTunesでデバイスをバックアップを行うまでは次のデバッグログディレクトリは存在しません。

    ~/Library/Application Support/MobileSync/Backup/Logs

4. 次のコマンドをターミナルで実行すると、デバッグログを無効にできます。

    % defaults delete com.apple.MobileBackup

注）デバッグログを無効にしてもデバッグログディレクトリは自動で削除されず、残ったままになっています。
<br /><br /><br />



関連するログの内容は次のようになります。（重要な部分だけ抜粋）

<pre>
<code>
2011-12-30 02:31:09.794 WARNING: Starting backup
...
2011-12-30 02:31:17.044 DEBUG: Scanning domains
    ...
2011-12-30 02:31:17.045 DEBUG: Scanning domain AppDomain-[APP_ID] at /var/mobile/        Applications/<UUID>
2011-12-30 02:31:17.051 DEBUG: Unmodified directory: /var/mobile/Applications/[UUID]
...
2011-12-30 02:31:17.172 DEBUG: Not backed up (blacklist): /var/mobile/Applications/<UUID>/Library/Caches
...
2011-12-30 02:31:19.611 DEBUG: Unmodified directory: /var/mobile/Applications/[UUID]/Library/Private Documents
....
2011-12-30 02:31:23.131 DEBUG: Not backed up (attribute): /var/mobile/Applications/[UUID]/Library/Private Documents/MyDocuments
</code>
</pre>

「do not backup」属性をマークした全てのファイルまたはフォルダについて、上記のデバッグログのように表示されます。

### 共通項目

アプリを削除し、再度インストールし、そして１度だけ実行し、全ての機能をテストしてください。
その後で、バックアップを確認します。データが確実に保存されることが確認できるまで、２回以上連続で実行しないでください。属性を正しくセットしていないというバグを発見できない原因となります。
<br /><br />


## ライセンス
現時点ではめんどうなので特に明記していませんが、ソースコードの全てをご自由にご利用ください。
<br /><br />


## 改訂履歴
* 2012/03/13: iOS5.0.2という誤った表記を訂正

* 2012/02/01:  iOS5.1リリース後に関する注意事項を追加

* 2012/01/06: ディレクトリに対して属性をセットした場合の振る舞いについての説明を修正、その他不適切な表現を修正

* 2011/12/30: 初版】とりあえず最低限必要な内容は網羅したつもり。


<br /><br />


## サンプルプログラムのログ

ディレクトリにのみ「do not backup」属性をセットした場合のログ
ブレークポイントを有効にしていないと表示されない項目があります。ご存知だとは思いますが、実行停止しないブレークポイントを利用し、かつそのブレークポイントを共有設定しています。

<pre>
<code>
2011-12-30 02:18:41.928 DoNotBackupExample[31844:707] -- SKRMasterViewController/viewDidLoad
2011-12-30 02:18:41.934 DoNotBackupExample[31844:707] -- DocumentStore/myDocumentsPath
2011-12-30 02:18:41.939 DoNotBackupExample[31844:707] -- DocumentStore/makeDirForAppContents
2011-12-30 02:18:41.944 DoNotBackupExample[31844:707] -- DocumentStore/myDocumentsPath
-viewDidLoad "file://localhost/var/mobile/Applications/42EEE509-7754-4491-9863-8DEAFC212AF4/Library/Private%20Documents/MyDocuments/"
2011-12-30 02:18:45.605 DoNotBackupExample[31844:707] -- DocumentStore/addSkipBackupAttributeToItemAtURL:
2011-12-30 02:18:45.615 DoNotBackupExample[31844:707] :/var/mobile/Applications/42EEE509-7754-4491-9863-8DEAFC212AF4/Library/Private Documents/MyDocuments
+addSkipBackupAttributeToItemAtURL: 「do not backup」属性のマーク成功
"/var/mobile/Applications/42EEE509-7754-4491-9863-8DEAFC212AF4/Library/Private Documents/MyDocuments"
2011-12-30 02:18:47.141 DoNotBackupExample[31844:707] -- DocumentStore/fetchPDF
+fetchPDF PDFファイルのダウンロード開始
[Switching to process 8963 thread 0x2303]
[Switching to process 8963 thread 0x2303]
ダウンロード完了
2011-12-30 02:20:01.611 DoNotBackupExample[31844:510b] -- DocumentStore/saveFileWithName:fileData:
2011-12-30 02:20:01.624 DoNotBackupExample[31844:510b] -- DocumentStore/myDocumentsPath
-saveFileWithName:fileData: ダウンロード成功
ファイルの保存先:"/var/mobile/Applications/42EEE509-7754-4491-9863-8DEAFC212AF4/Library/Private Documents/MyDocuments/Blocks.pdf"
-saveFileWithName:fileData: ファイル保存成功
</code>
</pre>



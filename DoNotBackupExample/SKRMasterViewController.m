//
//  SKRMasterViewController.m
//  DoNotBackupExample
//
//  Created by Naoki TSUTSUI on 11/12/21.
//

#import "SKRMasterViewController.h"
#include <sys/xattr.h>

/// <Application_Home>/Library/Private Documentsディレクトリに追加するデータ保存用ディレクトリ
#define kPaperStandDocumentsBaseName @"MyDocuments"

/// ダウンロードするPDFのURI
#define kContentsURL @"http://developer.apple.com/jp/devcenter/ios/library/documentation/Blocks.pdf"


@interface SKRMasterViewController (Private)
- (void)startExample;

- (NSString *)applicationSupportDirectory; // 未使用
- (NSString *)privateDocumentsDirectory;
- (NSString *)myDocumentsPath;
- (BOOL)makeDirForAppContents;
- (BOOL)saveFileWithName:(NSString *)filename fileData:(NSData *)fileData;
- (NSString *)savedFilePathByFilename:(NSString *)fileName; // 未使用
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;
@end

@implementation SKRMasterViewController

// MARK: ここからサンプルの実行開始
//=============================================================================
// # はじめに
// iOS 5.0.1より導入された「Data Storage Guideline」に従うために、オフラインデータとして
// 使用するファイルは特定の場所に保存し、「do not backup」属性をセットしなくてはいけません。
// 「do not backup」属性をセットすることでiCloudやiTunesのバックアップ対象外とします。
//
// アップルの意図はよくわかりませんが、オフラインで閲覧できるデータはサイズが小さくても
// バックアップ対象外にしろということなのでしょう。理由を考えても意味が無いので、従う事にします。
// 
// ガイドラインでは、オフラインデータの保存先は次のように決められています。
// 1. <Application_Home>/Library  （ただし、Cacheディレクトリを除く）
// 2. <Application_Home>/Documents
// 
// なおガイドラインでは次のディレクトリを作成し、その中に保存する事が推奨されています。
// <Application_Home>/Library/Private Documents
// 
// しかし、筆者の調べでは次のようなディレクトリ名でもよく、実はディレクトリ名自体は何でも良い
// のではないかと推測します。
// <Application_Home>/Library/Application Support
// 
// 
// # サンプルコードについて
// 上記ルールに従い、本サンプルコードでは
// <Application_Home>/Library/Private Documentsディレクトリ内にMyDocumentsディレクトリ
// を作成し、ダウンロードしたファイルを保存します。
// 
// 処理の流れとしては次のようになります。
// 1. ファイル保存用のディレクトリを保存
// 2. 上記ディレクトリに対して属性をセット
// 3. PDFファイルをアップルからダウンロードして保存
// 4. 上記PDFファイルに対して属性をセット
// 
// 作成済みのディレクトリの再作成や、保存済みのファイルの再保存は行いません。
// 
// 属性がセットされているかどうかの確認方法はドキュメント（README.md）をお読みください。
// 単純なテストしては、シミュレータで本サンプルアプリを動作させた後、
// % xattr -plxv com.apple.MobileBackup Library/Private\ Documents/MyDocuments/
// Library/Private Documents/MyDocuments/: com.apple.MobileBackup:
// 00000000  01                                               |.|
// 00000001
// 
// % xattr -plxv com.apple.MobileBackup Library/Private\ Documents/MyDocuments/Blocks.pdf 
// Library/Private Documents/MyDocuments/Blocks.pdf: com.apple.MobileBackup:
// 00000000  01                                               |.|
// 00000001
// 
// となっていればOKです。
// 
// # メモ
// ディレクトリに対して「do not backup」属性をセットすれば、属性がセットされた以後
// そのディレクトリ以下に保存した全てのディレクトリとファイルはアップルのバックアップエンジン
// によってバックアップ対象外として認識されます。
// しかし不安な場合には、全てのファイルそれぞれに対しても属性をセットすると良いかもしれません
// 
// # 注意点
// ファイルURLを取得するときには
// NSURLクラスの+fileURLWithPath:を使用し、+URLWithString:を使用しないでください。
//
// このサンプルアプリでは、ノンストップのブレークポイントでログメッセージを表示しています。
// ブレークポイントを有効にして動作させてください。
//=============================================================================
- (void)startExample
{
  // ファイルの保存先ディレクトリ <Application_Home>/Library/Private Documents/MyDocuments
  NSString *basePath = [self myDocumentsPath];

  
  // データ保存用のディレクトリを作成する
  if ([self makeDirForAppContents]) {
    // ディレクトリに対して「do not backup」属性をセット
    NSURL *dirUrl = [NSURL fileURLWithPath:basePath];
    [self addSkipBackupAttributeToItemAtURL:dirUrl]; // <------------
  }
  

  // PDFファイルをダウンロードし、保存が完了したら、ダウンドードしたファイルに対して「do not backup」属性をセット
  // ダウンロード自体は毎回行われます。途中で面倒になってファイルの存在チェックはしてません。

  NSURL *url = [NSURL URLWithString:kContentsURL];
  NSURLRequest *myRequest;
  myRequest = [NSURLRequest requestWithURL:url
                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                           timeoutInterval:30.0];
  
  // ネットワークインジケータを表示
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  
  [NSURLConnection sendAsynchronousRequest:myRequest 
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                           // ネットワークインジケータを非表示
                           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                           
                           if (data) {
                             // PDFの受信が完了したので保存する
                             NSString *pdfName = [kContentsURL lastPathComponent];
                             if ([self saveFileWithName:pdfName fileData:data]) {
                               NSString *downloadedPDFPath = [basePath stringByAppendingPathComponent:pdfName];
                               NSURL *fileUrl = [NSURL fileURLWithPath:downloadedPDFPath];
                               [self addSkipBackupAttributeToItemAtURL:fileUrl]; // <------------
                             }
                           } else {
                             NSLog(@"Error: %@", [error localizedDescription]);
                           }
                         }];
}



//=============================================================================
#pragma mark - Utility Methods
//=============================================================================
// <Application_Home>/Library/Application Supportディレクトリのパスを返す
// サンプルアプリでは使用していないが Private Documentsの代わりに使用したい場合の
// 為に残してあります。
//-----------------------------------------------------------------------------
- (NSString *)applicationSupportDirectory
{
  LOG_CURRENT_METHOD;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
                                                       NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
  return basePath;
}

//-----------------------------------------------------------------------------
//  <Application_Home>/Library/Private Documentsディレクトリのパスを返す
//-----------------------------------------------------------------------------
- (NSString *)privateDocumentsDirectory
{
  LOG_CURRENT_METHOD;
  NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
  NSString *privateDocumenstPath = [libraryPath stringByAppendingPathComponent:@"Private Documents"];
  return privateDocumenstPath;
}

//-----------------------------------------------------------------------------
//  <Application_Home>/Library/Private Documents/MyDocumentsディレクトリのパスを返す
//-----------------------------------------------------------------------------
- (NSString *)myDocumentsPath
{
  LOG_CURRENT_METHOD;
  NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
  NSString *privateDocumenstPath = [libraryPath stringByAppendingPathComponent:@"Private Documents"];
  NSString *path = [privateDocumenstPath stringByAppendingPathComponent:kPaperStandDocumentsBaseName];
  return path;
}

//=============================================================================
#pragma mark - Add Attribute
//=============================================================================
// 指定したファイルバスを「do not backup」属性にし、iOS 5.0.1以降ではバックアップされないようにする
//-----------------------------------------------------------------------------
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
  LOG_CURRENT_METHOD;
  if (URL == nil) {
    return NO;
  } else if (![URL isFileURL]) {
    NSLog(@"URLはファイルURLではない。");
    return NO;
  }
  
  const char *filePath = [[URL path] fileSystemRepresentation];
  const char *attrName = "com.apple.MobileBackup";
  u_int8_t attrValue = 1;
  
  int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
  
  if (result == 0) {
    NSLog(@":%@", [URL path]);
    return YES;
  } else {
    NSLog(@"「do not backup」属性のマーク失敗!! return:%d 対象パス:%@", result, [URL path]);
    return NO;
  }
}

//=============================================================================
#pragma mark - File Handle Methods
//=============================================================================
// アプリケーションのコンテンツ保存用のディレクトリを作成する
//-----------------------------------------------------------------------------
- (BOOL)makeDirForAppContents
{
  LOG_CURRENT_METHOD;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *baseDir = [self myDocumentsPath];
  
  BOOL exists = [fileManager fileExistsAtPath:baseDir];
  if (!exists) {
    NSError *error;
    BOOL created = [fileManager createDirectoryAtPath:baseDir
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&error];
    
    if (!created) {
      NSLog(@"ディレクトリが作成できませんでした:%@", [error localizedDescription]);
      return NO;
    }
  } else {
    // 作成済みの場合はNOを返す
    return NO;
  }
  
  return YES;
}

//-----------------------------------------------------------------------------
// ファイルの保存場所は<Application_Home>/Library/Private Documents/MyDocuments
//-----------------------------------------------------------------------------
- (BOOL)saveFileWithName:(NSString *)filename fileData:(NSData *)fileData
{
  LOG_CURRENT_METHOD;
  BOOL result = NO;
  NSString *myDocumentPath = [self myDocumentsPath];
  NSString *path = [myDocumentPath stringByAppendingPathComponent:filename];
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL existsDir = [fileManager fileExistsAtPath:myDocumentPath];
  
  if (existsDir) { // ディレクトリの存在チェック
    BOOL existsFile = [fileManager fileExistsAtPath:path isDirectory:NO];
    
    if(existsFile == NO ) { // ファイルの存在チェック
      if ([fileData writeToFile:path atomically:YES]) {
        result = YES;
      } else {
        NSLog(@"ファイルの保存失敗");
      }
    } else {
      NSLog(@"同名のファイルがすでに存在している");
    }
    
  } else {
    NSLog(@"ディレクトリは存在しない:%@", path);
  }
  return result;
}

//-----------------------------------------------------------------------------
// 指定したファイル名のファイルが保存されているフルパスを返す
// 存在しない場合はnilを返す
//-----------------------------------------------------------------------------
- (NSString *)savedFilePathByFilename:(NSString *)fileName
{
  LOG_CURRENT_METHOD;
  if (fileName != nil) {
    NSString *documentPath = [self myDocumentsPath];
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL exists = [fileManager fileExistsAtPath:filePath];
    if (exists) {
      return filePath;
    } else {
      return nil;      
    }
  } else {
    // 引数として渡されたfileNameは無効
    return nil;
  }
}


//=============================================================================
#pragma mark - ViewController Methods
//=============================================================================

- (void)awakeFromNib
{
  [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
  LOG_CURRENT_METHOD;
  [super viewDidLoad];

  [self startExample]; // サンプルの実行開始
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Synology NAS 管理';

  @override
  String get connecting => '接続中...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => '続行するにはサインイン';

  @override
  String get signInPrivacyNote =>
      'データはデバイスに保存されます。\nGoogle アカウントは認証と\nGoogle Drive への任意バックアップにのみ使用されます。';

  @override
  String get signInCancelled => 'サインインがキャンセルされました';

  @override
  String signInFailed(String error) {
    return 'サインイン失敗: $error';
  }

  @override
  String get signInWithGoogle => 'Google でサインイン';

  @override
  String get noDataStoredOnServers => 'サーバーにデータは保存されません';

  @override
  String get nasAddress => 'NAS アドレス';

  @override
  String get ipOrHostname => 'IP またはホスト名';

  @override
  String get port => 'ポート';

  @override
  String get protocol => 'プロトコル';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => 'すべての項目を入力してください';

  @override
  String get invalidPortNumber => '無効なポート番号';

  @override
  String get rememberMe => 'ログイン情報を保存';

  @override
  String get connect => '接続';

  @override
  String get myNas => 'マイ NAS';

  @override
  String get addNas => 'NAS を追加';

  @override
  String get online => 'オンライン';

  @override
  String get offline => 'オフライン';

  @override
  String get noNasTitle => 'NAS が未登録';

  @override
  String get noNasSubtitle => '「NAS を追加」をタップして\nSynology NAS を接続';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイス',
      one: '1 台のデバイス',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => 'Google Drive にバックアップ';

  @override
  String get restoreFromGoogleDrive => 'Google Drive から復元';

  @override
  String get signOut => 'サインアウト';

  @override
  String get backingUp => 'Google Drive にバックアップ中...';

  @override
  String get backupSuccessful => 'バックアップ成功';

  @override
  String backupFailed(String error) {
    return 'バックアップ失敗: $error';
  }

  @override
  String get restoringFromDrive => 'Google Drive から復元中...';

  @override
  String get restoreSuccessful => '復元成功';

  @override
  String restoreFailed(String error) {
    return '復元失敗: $error';
  }

  @override
  String get noBackupFound => 'Google Drive にバックアップが見つかりません';

  @override
  String get nameThisNas => 'NAS に名前を付ける';

  @override
  String get nasNicknameHint => '例: 自宅 NAS, オフィス NAS';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get ok => 'OK';

  @override
  String get rename => '名前変更';

  @override
  String get details => '詳細';

  @override
  String get remove => '削除';

  @override
  String get delete => '削除';

  @override
  String get retry => '再試行';

  @override
  String get host => 'ホスト';

  @override
  String get username => 'ユーザー名';

  @override
  String get model => 'モデル';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => '最終接続';

  @override
  String get removeNasTitle => 'NAS を削除';

  @override
  String removeNasMessage(String name) {
    return '「$name」をリストから削除しますか？';
  }

  @override
  String get nasRemoved => 'NAS を削除しました';

  @override
  String get language => '言語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageChinese => '中文';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get dashboard => 'ダッシュボード';

  @override
  String get files => 'ファイル';

  @override
  String get media => 'メディア';

  @override
  String get photos => '写真';

  @override
  String get healthy => '正常';

  @override
  String get dsmVersion => 'DSM バージョン';

  @override
  String get uptime => '稼働時間';

  @override
  String get lanIp => 'LAN IP';

  @override
  String get serial => 'シリアル';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => 'サービス';

  @override
  String get cpuTemp => 'CPU 温度';

  @override
  String get disks => 'ディスク';

  @override
  String get resourceMonitor => 'リソースモニター';

  @override
  String get storageAndVolumes => 'ストレージとボリューム';

  @override
  String get storageCapacity => 'ストレージ容量';

  @override
  String get diskHealth => 'ディスク健康状態';

  @override
  String bayN(int n) {
    return 'ベイ $n';
  }

  @override
  String get normal => '正常';

  @override
  String get installedPackages => 'インストール済みパッケージ';

  @override
  String get running => '実行中';

  @override
  String get stopped => '停止';

  @override
  String get quickActions => 'クイック操作';

  @override
  String get resourceMonitorAction => 'リソース\nモニター';

  @override
  String get storageManagerAction => 'ストレージ\nマネージャー';

  @override
  String get logCenterAction => 'ログ\nセンター';

  @override
  String get restart => '再起動';

  @override
  String get shutdown => 'シャットダウン';

  @override
  String get refresh => '更新';

  @override
  String confirmActionTitle(String action) {
    return 'NAS を$actionしますか？';
  }

  @override
  String confirmActionMessage(String action) {
    return 'NAS を$actionしてもよろしいですか？';
  }

  @override
  String get fileManager => 'ファイルマネージャー';

  @override
  String get notConnected => '未接続';

  @override
  String errorCode(String code) {
    return 'エラー $code';
  }

  @override
  String get newFolder => '新しいフォルダ';

  @override
  String get folderName => 'フォルダ名';

  @override
  String get newName => '新しい名前';

  @override
  String get failedToCreateFolder => 'フォルダの作成に失敗';

  @override
  String get failedToRename => '名前変更に失敗';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return '$count 件$suffixを削除しますか？';
  }

  @override
  String get cannotBeUndone => 'この操作は取り消せません。';

  @override
  String failedToDelete(String name) {
    return '削除失敗: $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return '$count 件$suffixを$actionしました';
  }

  @override
  String get copied => 'コピー済み';

  @override
  String get cut => 'カット';

  @override
  String failedToCopyMove(String action) {
    return '$actionに失敗';
  }

  @override
  String get shareLinkCopied => '共有リンクをコピーしました！';

  @override
  String get couldNotGenerateLink => 'リンクを生成できません';

  @override
  String get failedToCreateShareLink => '共有リンクの作成に失敗';

  @override
  String couldNotReadFile(String name) {
    return 'ファイルを読み取れません: $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return '$count ファイル$suffixをアップロード';
  }

  @override
  String failedError(String error) {
    return '失敗: $error';
  }

  @override
  String get copy => 'コピー';

  @override
  String get shareLink => 'リンクを共有';

  @override
  String get qrCode => 'QR コード';

  @override
  String nSelected(int count) {
    return '$count 件選択';
  }

  @override
  String get searchFiles => 'ファイルを検索...';

  @override
  String searchInFolder(String folder) {
    return '$folder 内を検索...';
  }

  @override
  String get searchFailed => '検索失敗';

  @override
  String get noResultsFound => '結果が見つかりません';

  @override
  String get emptyFolder => '空のフォルダ';

  @override
  String get sortByName => '名前';

  @override
  String get sortBySize => 'サイズ';

  @override
  String get sortByDate => '更新日';

  @override
  String get sortByType => '種類';

  @override
  String get listView => 'リスト表示';

  @override
  String get gridView => 'グリッド表示';

  @override
  String get root => 'ルート';

  @override
  String get clipboardMove => 'クリップボード: 移動';

  @override
  String get clipboardCopy => 'クリップボード: コピー';

  @override
  String get pasteHere => 'ここに貼り付け';

  @override
  String get linkCopied => 'リンクをコピーしました！';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get couldNotGenerateShareLink => '共有リンクを生成できません';

  @override
  String get sort => '並べ替え';

  @override
  String get mediaHub => 'メディアハブ';

  @override
  String get selectFolderDescription => 'NAS 上のフォルダを選択してメディアファイルをスキャン・閲覧';

  @override
  String get selectFolder => 'フォルダを選択';

  @override
  String get startingScan => 'スキャン開始中...';

  @override
  String scanningFolder(String name) {
    return 'スキャン中: $name';
  }

  @override
  String mediaFilesFound(int count) {
    return '$count 件のメディアファイルが見つかりました';
  }

  @override
  String get tmdbApiKey => 'TMDB API キー';

  @override
  String get tmdbApiKeyInstructions =>
      'TMDB アカウント設定の「API Key (v3 auth)」を使用してください — Read Access Token ではありません。';

  @override
  String get tmdbApiKeyHelp => 'themoviedb.org/settings/api で無料キーを取得';

  @override
  String get tmdbApiKeyHint => 'API Key (v3) を貼り付け';

  @override
  String get changeFolder => 'フォルダを変更';

  @override
  String get tmdbKeyConfigured => 'TMDB キー設定済み ✓';

  @override
  String get setTmdbApiKey => 'TMDB API キーを設定';

  @override
  String get rescanFolder => 'フォルダを再スキャン';

  @override
  String get chooseMediaFolder => 'メディアフォルダを選択';

  @override
  String get allMedia => 'すべてのメディア';

  @override
  String get recentlyAdded => '最近追加';

  @override
  String get filters => 'フィルター';

  @override
  String get allPhotos => 'すべての写真';

  @override
  String get favorites => 'お気に入り';

  @override
  String get recent => '最近';

  @override
  String get hidden => '非表示';

  @override
  String get recentlyAddedPhotos => '最近追加';

  @override
  String get viewAll => 'すべて表示';

  @override
  String get myAlbums => 'マイアルバム';

  @override
  String get family => '家族';

  @override
  String get travel => '旅行';

  @override
  String get workAndProjects => '仕事とプロジェクト';

  @override
  String itemsCount(String count) {
    return '$count 件';
  }

  @override
  String get logCenter => 'ログセンター';

  @override
  String get overview => '概要';

  @override
  String get logs => 'ログ';

  @override
  String get connections => '接続';

  @override
  String get totalLogs => 'ログ合計';

  @override
  String get info => '情報';

  @override
  String get warnings => '警告';

  @override
  String get errors => 'エラー';

  @override
  String lastNLogs(int count) {
    return '最新 $count 件のログ';
  }

  @override
  String get noLogsAvailable => 'ログがありません';

  @override
  String get systemLogs => 'システムログ';

  @override
  String nItems(int count) {
    return '$count 件';
  }

  @override
  String get level => 'レベル';

  @override
  String get time => '時間';

  @override
  String get user => 'ユーザー';

  @override
  String get event => 'イベント';

  @override
  String get noConnectionLogs => '接続ログなし';

  @override
  String get type => '種類';

  @override
  String get ip => 'IP';

  @override
  String get date => '日付';

  @override
  String get performance => 'パフォーマンス';

  @override
  String get details_tab => '詳細';

  @override
  String get utilization => '使用率 (%)';

  @override
  String get memory => 'メモリ';

  @override
  String get network => 'ネットワーク';

  @override
  String get diskIO => 'ディスク I/O';

  @override
  String get download => 'ダウンロード';

  @override
  String get upload => 'アップロード';

  @override
  String get read => '読み取り';

  @override
  String get write => '書き込み';

  @override
  String get activeConnections => 'アクティブ接続';

  @override
  String get processId => 'PID';

  @override
  String get process => 'プロセス';

  @override
  String get systemDetails => 'システム詳細';

  @override
  String get cpuModel => 'CPU モデル';

  @override
  String get cpuCores => 'CPU コア数';

  @override
  String get totalRam => '合計 RAM';

  @override
  String get temperature => '温度';

  @override
  String get systemTime => 'システム時刻';

  @override
  String get storageManager => 'ストレージマネージャー';

  @override
  String get storage => 'ストレージ';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => 'システム健康状態';

  @override
  String get totalStorage => '合計ストレージ';

  @override
  String get used => '使用済み';

  @override
  String get available => '利用可能';

  @override
  String get volumeUsage => 'ボリューム使用量';

  @override
  String get critical => '危険';

  @override
  String get usageExceedsThreshold => '使用率が 90% を超えています';

  @override
  String get storageHealthy => 'ストレージ正常';

  @override
  String get driveInformation => 'ドライブ情報';

  @override
  String get status => 'ステータス';

  @override
  String get capacity => '容量';

  @override
  String get diskTemperature => 'ディスク温度';

  @override
  String get userAndGroup => 'ユーザーとグループ';

  @override
  String get users => 'ユーザー';

  @override
  String get groups => 'グループ';

  @override
  String get allUsers => '全ユーザー';

  @override
  String nUsers(int count) {
    return '$count ユーザー';
  }

  @override
  String get admin => '管理者';

  @override
  String get active => 'アクティブ';

  @override
  String get disabled => '無効';

  @override
  String get allGroups => '全グループ';

  @override
  String nGroups(int count) {
    return '$count グループ';
  }

  @override
  String get members => 'メンバー';

  @override
  String get noUsers => 'ユーザーが見つかりません';

  @override
  String get noGroups => 'グループが見つかりません';

  @override
  String get loadingVideo => '動画を読み込み中...';

  @override
  String get failedToPlayVideo => '動画の再生に失敗';

  @override
  String get settings => '設定';

  @override
  String get nasConnection => 'NAS 接続';

  @override
  String get connection => '接続';

  @override
  String get appearance => '外観';

  @override
  String get themeAndColors => 'テーマと色';

  @override
  String get darkCyanAccent => 'ダーク • シアン';

  @override
  String get notifications => '通知';

  @override
  String get pushNotifications => 'プッシュ通知';

  @override
  String get systemAlerts => 'システムアラート';

  @override
  String get backupAlerts => 'バックアップアラート';

  @override
  String get storageWarnings => 'ストレージ警告';

  @override
  String get about => '情報';

  @override
  String get aboutSynoHub => 'SynoHub について';

  @override
  String get checkForUpdates => 'アップデートを確認';

  @override
  String get upToDate => '最新です';

  @override
  String get theme => 'テーマ';

  @override
  String get dark => 'ダーク';

  @override
  String get light => 'ライト';

  @override
  String get system => 'システム';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get cyan => 'シアン';

  @override
  String get teal => 'ティール';

  @override
  String get gold => 'ゴールド';

  @override
  String get purple => 'パープル';

  @override
  String get preview => 'プレビュー';

  @override
  String get accentColorPreview => 'アクセントカラーのプレビュー';

  @override
  String get connectionSettings => '接続';

  @override
  String get server => 'サーバー';

  @override
  String get nasAddressSetting => 'NAS アドレス';

  @override
  String get ipHostnameOrQuickConnect => 'IP、ホスト名、または QuickConnect ID';

  @override
  String get portLabel => 'ポート';

  @override
  String get protocolLabel => 'プロトコル';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => 'アカウント';

  @override
  String get password => 'パスワード';

  @override
  String get rememberLogin => 'ログイン情報を保存';

  @override
  String get logout => 'ログアウト';

  @override
  String versionN(String version) {
    return 'バージョン $version';
  }

  @override
  String get connectedNas => '接続中の NAS';

  @override
  String get dsmVersionLabel => 'DSM バージョン';

  @override
  String get serialNumber => 'シリアル番号';

  @override
  String get application => 'アプリケーション';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get madeWithFlutter => '❤ Flutter で作成';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => 'アクティブな接続なし';

  @override
  String get connectedUsers => '接続中のユーザー';

  @override
  String get memoryBreakdown => 'メモリ内訳';

  @override
  String get total => '合計';

  @override
  String get cached => 'キャッシュ';

  @override
  String get bufferLabel => 'バッファ';

  @override
  String get diskInformation => 'ディスク情報';

  @override
  String driveN(int n) {
    return 'ドライブ $n';
  }

  @override
  String get healthyStatus => '正常';

  @override
  String get degraded => '劣化';

  @override
  String get allStorageHealthy => 'すべてのストレージプールとボリュームは正常です。';

  @override
  String get storagePoolDegraded => 'ストレージプールに問題が発生しました。ストレージページで詳細を確認してください。';

  @override
  String get raidType => 'RAID タイプ';

  @override
  String get drives => 'ドライブ';

  @override
  String nDisks(int count) {
    return '$count ディスク';
  }

  @override
  String get device => 'デバイス';

  @override
  String get drive => 'ドライブ';

  @override
  String get size => 'サイズ';

  @override
  String get noStoragePoolData => 'ストレージプールデータなし';

  @override
  String get noDiskInfo => 'ディスク情報なし';

  @override
  String get systemGroup => 'システム';

  @override
  String get noMembers => 'メンバーなし';

  @override
  String membersCount(int count) {
    return 'メンバー ($count)';
  }

  @override
  String get manage => '管理';

  @override
  String get createUser => 'ユーザーを作成';

  @override
  String get email => 'メール';

  @override
  String get description => '説明';

  @override
  String get usernameAndPasswordRequired => 'ユーザー名とパスワードは必須です';

  @override
  String get userCreatedSuccessfully => 'ユーザーを作成しました';

  @override
  String editName(String name) {
    return '「$name」を編集';
  }

  @override
  String get userUpdated => 'ユーザーを更新しました';

  @override
  String changePasswordTitle(String name) {
    return 'パスワード変更 - $name';
  }

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get passwordCannotBeEmpty => 'パスワードを入力してください';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get passwordChanged => 'パスワードを変更しました';

  @override
  String userEnabled(String name) {
    return '$name を有効化しました';
  }

  @override
  String userDisabled(String name) {
    return '$name を無効化しました';
  }

  @override
  String get deleteUserTitle => 'ユーザーを削除しますか？';

  @override
  String deleteUserMessage(String name) {
    return 'ユーザー「$name」を削除しますか？この操作は取り消せません。';
  }

  @override
  String userDeleted(String name) {
    return 'ユーザー「$name」を削除しました';
  }

  @override
  String get createGroup => 'グループを作成';

  @override
  String get groupName => 'グループ名';

  @override
  String get groupNameRequired => 'グループ名は必須です';

  @override
  String get groupCreated => 'グループを作成しました';

  @override
  String get groupUpdated => 'グループを更新しました';

  @override
  String get deleteGroupTitle => 'グループを削除しますか？';

  @override
  String deleteGroupMessage(String name) {
    return 'グループ「$name」を削除しますか？';
  }

  @override
  String groupDeleted(String name) {
    return 'グループ「$name」を削除しました';
  }

  @override
  String membersOfGroup(String name) {
    return '「$name」のメンバー';
  }

  @override
  String get membersUpdated => 'メンバーを更新しました';

  @override
  String get edit => '編集';

  @override
  String get enable => '有効化';

  @override
  String get disable => '無効化';

  @override
  String get confirm => '確認';

  @override
  String get statusLabel => 'ステータス';

  @override
  String get connected => '接続中';

  @override
  String get nature => '自然';

  @override
  String get urban => '都市';

  @override
  String get chooseFolder => 'フォルダを選択';

  @override
  String get addTmdbKeyHint => '映画カバー用TMDBキーを追加';

  @override
  String get scanningMediaFiles => 'メディアファイルをスキャン中...';

  @override
  String get newestFilesSubtitle => 'ライブラリの最新ファイル';

  @override
  String get allVideos => 'すべての動画';

  @override
  String get videosLabel => '動画';

  @override
  String get imagesLabel => '画像';

  @override
  String get audioLabel => 'オーディオ';

  @override
  String get foldersLabel => 'フォルダ';

  @override
  String get latest => '最新';

  @override
  String get play => '再生';

  @override
  String get change => '変更';

  @override
  String get selectMediaFolder => 'メディアフォルダを選択';

  @override
  String get select => '選択';

  @override
  String get noSubfolders => 'サブフォルダなし';

  @override
  String get tapSelectHint => '\"選択\"をタップしてこのフォルダを使用';

  @override
  String nFiles(int count) {
    return '$count ファイル';
  }

  @override
  String nVideos(int count) {
    return '$count 本の動画';
  }

  @override
  String nImages(int count) {
    return '$count 枚の画像';
  }

  @override
  String nTracks(int count) {
    return '$count 曲';
  }

  @override
  String get sampleAlpineReflection => 'アルプスの映り込み';

  @override
  String get sampleEmeraldMorning => 'エメラルドの朝';

  @override
  String get sampleNeonPulse => 'ネオンパルス';

  @override
  String get connectionLogs => '接続ログ';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return 'ユーザー: $userPct%  ·  システム: $systemPct%';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '$usedMb MB 使用 / $totalMb MB  ·  キャッシュ: $cachedMb MB';
  }

  @override
  String driveHddDetail(int n, String size) {
    return 'ドライブ $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return 'ストレージプール $n';
  }

  @override
  String volumeN(int n) {
    return 'ボリューム $n';
  }

  @override
  String get unknown => '不明';

  @override
  String get insufficientPermission => '権限が不十分です。管理者権限が必要です。';

  @override
  String get invalidParameter => '無効なパラメータ';

  @override
  String get accountIsDisabled => 'アカウントは無効です';

  @override
  String get permissionDenied => 'アクセスが拒否されました';

  @override
  String get userGroupNotFound => 'ユーザー/グループが見つかりません';

  @override
  String get nameAlreadyExists => '名前は既に存在します';

  @override
  String operationFailedCode(int code) {
    return '操作に失敗しました（エラー $code）';
  }

  @override
  String get notAvailable => 'N/A';

  @override
  String get timeline => 'タイムライン';

  @override
  String get albumsTab => 'アルバム';

  @override
  String get backup => 'バックアップ';

  @override
  String get sharedSpace => '共有スペース';

  @override
  String get personalSpace => '個人スペース';

  @override
  String get searchPhotos => '写真を検索...';

  @override
  String get addToAlbum => 'アルバムに追加';

  @override
  String uploadingProgress(int current, int total) {
    return '$current/$total アップロード中...';
  }

  @override
  String deletePhotosTitle(int count) {
    return '$count件を削除しますか？';
  }

  @override
  String get deletePhotosMessage => 'これらのアイテムは完全に削除されます。元に戻すことはできません。';

  @override
  String addedToAlbumN(String name) {
    return '「$name」に追加しました';
  }

  @override
  String uploadedNPhotos(int count) {
    return '$count枚の写真をアップロードしました';
  }

  @override
  String get createAlbum => 'アルバムを作成';

  @override
  String get albumName => 'アルバム名';

  @override
  String get create => '作成';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String photoCount(int count) {
    return '$count枚の写真';
  }

  @override
  String get photosApiHint => 'Synology PhotosがNASにインストールされ、実行中であることを確認してください。';

  @override
  String get noPhotosTitle => '写真がありません';

  @override
  String get noPhotosSubtitle => 'NASに写真をアップロードするか、バックアップを有効にしてください。';

  @override
  String get uploadPhotos => '写真をアップロード';

  @override
  String get deleteAlbum => 'アルバムを削除';

  @override
  String deleteAlbumMessage(String name) {
    return 'アルバム「$name」を削除しますか？中の写真は削除されません。';
  }

  @override
  String get noAlbums => 'アルバムなし';

  @override
  String get createAlbumHint => 'アルバムを作成して写真を整理しましょう';

  @override
  String get backupPhotos => '写真バックアップ';

  @override
  String get backupPhotosDesc => 'デバイスの写真をNASにアップロードして安全に保管します。';

  @override
  String get manualUpload => '手動アップロード';

  @override
  String get selectPhotosToUpload => 'アップロードする写真を選択';

  @override
  String get uploadToNasPhotos => 'NASの/photo/Uploadにアップロード';

  @override
  String get backupInfoHint =>
      'アップロードされた写真はSynology Photosによって自動的にインデックスされ、タイムラインに表示されます。';

  @override
  String get noPhotosInAlbum => 'このアルバムに写真はありません';

  @override
  String get downloadLinkCopied => 'ダウンロードリンクをクリップボードにコピーしました';

  @override
  String get photoInfo => '写真情報';

  @override
  String get filenameLabel => 'ファイル名';

  @override
  String get takenOn => '撮影日';

  @override
  String get resolution => '解像度';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get video => '動画';

  @override
  String get photo => '写真';

  @override
  String downloadSavedTo(String path) {
    return '$path に保存しました';
  }

  @override
  String downloadFailed(String error) {
    return 'ダウンロード失敗: $error';
  }

  @override
  String get uploadDestination => 'アップロード先';

  @override
  String get selectUploadDest => 'アップロードフォルダを選択';

  @override
  String get selectMediaToUpload => '写真と動画を選択';

  @override
  String uploadToNasDest(String dest) {
    return 'NASの $dest にアップロード';
  }

  @override
  String lastUploadResult(int count) {
    return '前回のアップロード: $count ファイル成功';
  }

  @override
  String get renameAlbum => 'アルバム名を変更';

  @override
  String get limitedAccess => 'アクセス制限';

  @override
  String get limitedAccessDesc =>
      'システム監視には管理者権限が必要です。ファイルマネージャー、メディアハブ、フォトは完全に利用可能です。';

  @override
  String get quota => 'クォータ';

  @override
  String get quotaMB => 'クォータ (MB)';

  @override
  String get unlimited => '無制限';

  @override
  String get sharePermissions => '共有権限';

  @override
  String get readWrite => '読み取り/書き込み';

  @override
  String get readOnly => '読み取り専用';

  @override
  String get noAccess => 'アクセスなし';

  @override
  String get adminOnly => '管理者のみ';

  @override
  String get quotaUpdated => 'クォータを更新しました';

  @override
  String get permissionUpdated => '権限を更新しました';

  @override
  String get premiumFeature => 'プレミアム機能';

  @override
  String get premiumFeatureDesc =>
      'Media Hub と Photos は VIP メンバー限定のプレミアム機能です。アカウントのアップグレードについては開発者にお問い合わせください。';

  @override
  String get vipMember => 'VIPメンバー';

  @override
  String get freeUser => '無料ユーザー';

  @override
  String get otpDialogTitle => '二要素認証';

  @override
  String get otpDialogMessage => 'NASは確認コードを要求しています。認証アプリの6桁のコードを入力してください。';

  @override
  String get verify => '確認';

  @override
  String get quickConnectFailed => 'QuickConnectの解決に失敗しました';

  @override
  String get updateAvailable => 'アップデートがあります';

  @override
  String get whatsNew => '新機能';

  @override
  String get later => '後で';

  @override
  String get updateNow => '今すぐ更新';

  @override
  String get downloading => 'アップデートをダウンロード中...';

  @override
  String get updateFailed => 'アップデートに失敗しました';
}

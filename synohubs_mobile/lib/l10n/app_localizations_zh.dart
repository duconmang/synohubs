// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Synology NAS 管理';

  @override
  String get connecting => '连接中...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => '登录以继续';

  @override
  String get signInPrivacyNote =>
      '您的数据存储在设备上。\nGoogle 账户仅用于身份验证\n和可选的 Google Drive 备份。';

  @override
  String get signInCancelled => '登录已取消';

  @override
  String signInFailed(String error) {
    return '登录失败: $error';
  }

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get noDataStoredOnServers => '我们的服务器不存储任何数据';

  @override
  String get nasAddress => 'NAS 地址';

  @override
  String get ipOrHostname => 'IP 或主机名';

  @override
  String get port => '端口';

  @override
  String get protocol => '协议';

  @override
  String get usernameLabel => '用户名';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => '请填写所有字段';

  @override
  String get invalidPortNumber => '端口号无效';

  @override
  String get rememberMe => '记住我';

  @override
  String get connect => '连接';

  @override
  String get myNas => '我的 NAS';

  @override
  String get addNas => '添加 NAS';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get noNasTitle => '尚未添加 NAS';

  @override
  String get noNasSubtitle => '点击\"添加 NAS\"连接\n您的 Synology NAS';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
      one: '1 台设备',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => '备份到 Google Drive';

  @override
  String get restoreFromGoogleDrive => '从 Google Drive 恢复';

  @override
  String get signOut => '退出登录';

  @override
  String get backingUp => '正在备份到 Google Drive...';

  @override
  String get backupSuccessful => '备份成功';

  @override
  String backupFailed(String error) {
    return '备份失败: $error';
  }

  @override
  String get restoringFromDrive => '正在从 Google Drive 恢复...';

  @override
  String get restoreSuccessful => '恢复成功';

  @override
  String restoreFailed(String error) {
    return '恢复失败: $error';
  }

  @override
  String get noBackupFound => 'Google Drive 上未找到备份';

  @override
  String get nameThisNas => '为此 NAS 命名';

  @override
  String get nasNicknameHint => '例如: 家用 NAS, 办公 NAS';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get ok => '确定';

  @override
  String get rename => '重命名';

  @override
  String get details => '详情';

  @override
  String get remove => '移除';

  @override
  String get delete => '删除';

  @override
  String get retry => '重试';

  @override
  String get host => '主机';

  @override
  String get username => '用户名';

  @override
  String get model => '型号';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => '上次连接';

  @override
  String get removeNasTitle => '移除 NAS';

  @override
  String removeNasMessage(String name) {
    return '从列表中移除\"$name\"？';
  }

  @override
  String get nasRemoved => '已移除 NAS';

  @override
  String get language => '语言';

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
  String get dashboard => '仪表盘';

  @override
  String get files => '文件';

  @override
  String get media => '媒体';

  @override
  String get photos => '照片';

  @override
  String get healthy => '健康';

  @override
  String get dsmVersion => 'DSM 版本';

  @override
  String get uptime => '运行时间';

  @override
  String get lanIp => '局域网 IP';

  @override
  String get serial => '序列号';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => '服务';

  @override
  String get cpuTemp => 'CPU 温度';

  @override
  String get disks => '磁盘';

  @override
  String get resourceMonitor => '资源监控';

  @override
  String get storageAndVolumes => '存储与卷';

  @override
  String get storageCapacity => '存储容量';

  @override
  String get diskHealth => '磁盘健康';

  @override
  String bayN(int n) {
    return 'Bay $n';
  }

  @override
  String get normal => '正常';

  @override
  String get installedPackages => '已安装套件';

  @override
  String get running => '运行中';

  @override
  String get stopped => '已停止';

  @override
  String get quickActions => '快捷操作';

  @override
  String get resourceMonitorAction => '资源\n监控';

  @override
  String get storageManagerAction => '存储\n管理';

  @override
  String get logCenterAction => '日志\n中心';

  @override
  String get restart => '重启';

  @override
  String get shutdown => '关机';

  @override
  String get refresh => '刷新';

  @override
  String confirmActionTitle(String action) {
    return '$action NAS？';
  }

  @override
  String confirmActionMessage(String action) {
    return '确定要$action您的 NAS 吗？';
  }

  @override
  String get fileManager => '文件管理器';

  @override
  String get notConnected => '未连接';

  @override
  String errorCode(String code) {
    return '错误 $code';
  }

  @override
  String get newFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get newName => '新名称';

  @override
  String get failedToCreateFolder => '创建文件夹失败';

  @override
  String get failedToRename => '重命名失败';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return '删除 $count 个项目$suffix？';
  }

  @override
  String get cannotBeUndone => '此操作无法撤销。';

  @override
  String failedToDelete(String name) {
    return '删除失败: $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return '已$action $count 个项目$suffix';
  }

  @override
  String get copied => '已复制';

  @override
  String get cut => '剪切';

  @override
  String failedToCopyMove(String action) {
    return '$action失败';
  }

  @override
  String get shareLinkCopied => '分享链接已复制！';

  @override
  String get couldNotGenerateLink => '无法生成链接';

  @override
  String get failedToCreateShareLink => '创建分享链接失败';

  @override
  String couldNotReadFile(String name) {
    return '无法读取文件: $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return '已上传 $count 个文件$suffix';
  }

  @override
  String failedError(String error) {
    return '失败: $error';
  }

  @override
  String get copy => '复制';

  @override
  String get shareLink => '分享链接';

  @override
  String get qrCode => 'QR 码';

  @override
  String nSelected(int count) {
    return '已选 $count 项';
  }

  @override
  String get searchFiles => '搜索文件...';

  @override
  String searchInFolder(String folder) {
    return '在 $folder 中搜索...';
  }

  @override
  String get searchFailed => '搜索失败';

  @override
  String get noResultsFound => '未找到结果';

  @override
  String get emptyFolder => '空文件夹';

  @override
  String get sortByName => '名称';

  @override
  String get sortBySize => '大小';

  @override
  String get sortByDate => '修改日期';

  @override
  String get sortByType => '类型';

  @override
  String get listView => '列表视图';

  @override
  String get gridView => '网格视图';

  @override
  String get root => '根目录';

  @override
  String get clipboardMove => '剪贴板: 移动';

  @override
  String get clipboardCopy => '剪贴板: 复制';

  @override
  String get pasteHere => '粘贴到此处';

  @override
  String get linkCopied => '链接已复制！';

  @override
  String get copyLink => '复制链接';

  @override
  String get couldNotGenerateShareLink => '无法生成分享链接';

  @override
  String get sort => '排序';

  @override
  String get mediaHub => '媒体中心';

  @override
  String get selectFolderDescription => '选择 NAS 上的文件夹来扫描和浏览媒体文件';

  @override
  String get selectFolder => '选择文件夹';

  @override
  String get startingScan => '开始扫描...';

  @override
  String scanningFolder(String name) {
    return '正在扫描: $name';
  }

  @override
  String mediaFilesFound(int count) {
    return '找到 $count 个媒体文件';
  }

  @override
  String get tmdbApiKey => 'TMDB API 密钥';

  @override
  String get tmdbApiKeyInstructions =>
      '使用 TMDB 账户设置中的\"API Key (v3 auth)\"— 不是 Read Access Token。';

  @override
  String get tmdbApiKeyHelp => '在 themoviedb.org/settings/api 获取免费密钥';

  @override
  String get tmdbApiKeyHint => '在此粘贴 API Key (v3)';

  @override
  String get changeFolder => '更改文件夹';

  @override
  String get tmdbKeyConfigured => 'TMDB 密钥已配置 ✓';

  @override
  String get setTmdbApiKey => '设置 TMDB API 密钥';

  @override
  String get rescanFolder => '重新扫描文件夹';

  @override
  String get chooseMediaFolder => '选择媒体文件夹';

  @override
  String get allMedia => '全部媒体';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get filters => '筛选';

  @override
  String get allPhotos => '所有照片';

  @override
  String get favorites => '收藏';

  @override
  String get recent => '最近';

  @override
  String get hidden => '隐藏';

  @override
  String get recentlyAddedPhotos => '最近添加';

  @override
  String get viewAll => '查看全部';

  @override
  String get myAlbums => '我的相册';

  @override
  String get family => '家庭';

  @override
  String get travel => '旅行';

  @override
  String get workAndProjects => '工作与项目';

  @override
  String itemsCount(String count) {
    return '$count 项';
  }

  @override
  String get logCenter => '日志中心';

  @override
  String get overview => '概览';

  @override
  String get logs => '日志';

  @override
  String get connections => '连接';

  @override
  String get totalLogs => '日志总数';

  @override
  String get info => '信息';

  @override
  String get warnings => '警告';

  @override
  String get errors => '错误';

  @override
  String lastNLogs(int count) {
    return '最近 $count 条日志';
  }

  @override
  String get noLogsAvailable => '暂无日志';

  @override
  String get systemLogs => '系统日志';

  @override
  String nItems(int count) {
    return '$count 项';
  }

  @override
  String get level => '级别';

  @override
  String get time => '时间';

  @override
  String get user => '用户';

  @override
  String get event => '事件';

  @override
  String get noConnectionLogs => '无连接日志';

  @override
  String get type => '类型';

  @override
  String get ip => 'IP';

  @override
  String get date => '日期';

  @override
  String get performance => '性能';

  @override
  String get details_tab => '详情';

  @override
  String get utilization => '使用率 (%)';

  @override
  String get memory => '内存';

  @override
  String get network => '网络';

  @override
  String get diskIO => '磁盘 I/O';

  @override
  String get download => '下载';

  @override
  String get upload => '上传';

  @override
  String get read => '读取';

  @override
  String get write => '写入';

  @override
  String get activeConnections => '活跃连接';

  @override
  String get processId => 'PID';

  @override
  String get process => '进程';

  @override
  String get systemDetails => '系统详情';

  @override
  String get cpuModel => 'CPU 型号';

  @override
  String get cpuCores => 'CPU 核心数';

  @override
  String get totalRam => '总 RAM';

  @override
  String get temperature => '温度';

  @override
  String get systemTime => '系统时间';

  @override
  String get storageManager => '存储管理';

  @override
  String get storage => '存储';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => '系统健康';

  @override
  String get totalStorage => '总存储';

  @override
  String get used => '已用';

  @override
  String get available => '可用';

  @override
  String get volumeUsage => '卷使用情况';

  @override
  String get critical => '严重';

  @override
  String get usageExceedsThreshold => '使用率超过 90%';

  @override
  String get storageHealthy => '存储健康';

  @override
  String get driveInformation => '硬盘信息';

  @override
  String get status => '状态';

  @override
  String get capacity => '容量';

  @override
  String get diskTemperature => '磁盘温度';

  @override
  String get userAndGroup => '用户与群组';

  @override
  String get users => '用户';

  @override
  String get groups => '群组';

  @override
  String get allUsers => '所有用户';

  @override
  String nUsers(int count) {
    return '$count 个用户';
  }

  @override
  String get admin => '管理员';

  @override
  String get active => '活跃';

  @override
  String get disabled => '已禁用';

  @override
  String get allGroups => '所有群组';

  @override
  String nGroups(int count) {
    return '$count 个群组';
  }

  @override
  String get members => '成员';

  @override
  String get noUsers => '未找到用户';

  @override
  String get noGroups => '未找到群组';

  @override
  String get loadingVideo => '加载视频中...';

  @override
  String get failedToPlayVideo => '视频播放失败';

  @override
  String get settings => '设置';

  @override
  String get nasConnection => 'NAS 连接';

  @override
  String get connection => '连接';

  @override
  String get appearance => '外观';

  @override
  String get themeAndColors => '主题与颜色';

  @override
  String get darkCyanAccent => '深色 • 青色';

  @override
  String get notifications => '通知';

  @override
  String get pushNotifications => '推送通知';

  @override
  String get systemAlerts => '系统警报';

  @override
  String get backupAlerts => '备份警报';

  @override
  String get storageWarnings => '存储警告';

  @override
  String get about => '关于';

  @override
  String get aboutSynoHub => '关于 SynoHub';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get upToDate => '已是最新';

  @override
  String get theme => '主题';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get system => '系统';

  @override
  String get accentColor => '强调色';

  @override
  String get cyan => '青色';

  @override
  String get teal => '蓝绿';

  @override
  String get gold => '金色';

  @override
  String get purple => '紫色';

  @override
  String get preview => '预览';

  @override
  String get accentColorPreview => '强调色预览';

  @override
  String get connectionSettings => '连接';

  @override
  String get server => '服务器';

  @override
  String get nasAddressSetting => 'NAS 地址';

  @override
  String get ipHostnameOrQuickConnect => 'IP、主机名或 QuickConnect ID';

  @override
  String get portLabel => '端口';

  @override
  String get protocolLabel => '协议';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => '账户';

  @override
  String get password => '密码';

  @override
  String get rememberLogin => '记住登录';

  @override
  String get logout => '退出';

  @override
  String versionN(String version) {
    return '版本 $version';
  }

  @override
  String get connectedNas => '已连接 NAS';

  @override
  String get dsmVersionLabel => 'DSM 版本';

  @override
  String get serialNumber => '序列号';

  @override
  String get application => '应用';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get sourceCode => '源代码';

  @override
  String get madeWithFlutter => '使用 ❤ Flutter 制作';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => '无活跃连接';

  @override
  String get connectedUsers => '已连接用户';

  @override
  String get memoryBreakdown => '内存分析';

  @override
  String get total => '总计';

  @override
  String get cached => '缓存';

  @override
  String get bufferLabel => '缓冲';

  @override
  String get diskInformation => '磁盘信息';

  @override
  String driveN(int n) {
    return '硬盘 $n';
  }

  @override
  String get healthyStatus => '健康';

  @override
  String get degraded => '降级';

  @override
  String get allStorageHealthy => '所有存储池和卷均健康。';

  @override
  String get storagePoolDegraded => '存储池出现问题。请前往存储页面查看详情。';

  @override
  String get raidType => 'RAID 类型';

  @override
  String get drives => '硬盘';

  @override
  String nDisks(int count) {
    return '$count 块硬盘';
  }

  @override
  String get device => '设备';

  @override
  String get drive => '硬盘';

  @override
  String get size => '大小';

  @override
  String get noStoragePoolData => '无存储池数据';

  @override
  String get noDiskInfo => '无磁盘信息';

  @override
  String get systemGroup => '系统';

  @override
  String get noMembers => '无成员';

  @override
  String membersCount(int count) {
    return '成员 ($count)';
  }

  @override
  String get manage => '管理';

  @override
  String get createUser => '创建用户';

  @override
  String get email => '邮箱';

  @override
  String get description => '描述';

  @override
  String get usernameAndPasswordRequired => '用户名和密码为必填项';

  @override
  String get userCreatedSuccessfully => '用户创建成功';

  @override
  String editName(String name) {
    return '编辑\"$name\"';
  }

  @override
  String get userUpdated => '用户已更新';

  @override
  String changePasswordTitle(String name) {
    return '修改密码 - $name';
  }

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordCannotBeEmpty => '密码不能为空';

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String get passwordChanged => '密码已修改';

  @override
  String userEnabled(String name) {
    return '已启用 $name';
  }

  @override
  String userDisabled(String name) {
    return '已禁用 $name';
  }

  @override
  String get deleteUserTitle => '删除用户？';

  @override
  String deleteUserMessage(String name) {
    return '确定要删除用户\"$name\"吗？此操作无法撤销。';
  }

  @override
  String userDeleted(String name) {
    return '已删除用户\"$name\"';
  }

  @override
  String get createGroup => '创建群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupNameRequired => '群组名称为必填项';

  @override
  String get groupCreated => '群组已创建';

  @override
  String get groupUpdated => '群组已更新';

  @override
  String get deleteGroupTitle => '删除群组？';

  @override
  String deleteGroupMessage(String name) {
    return '确定要删除群组\"$name\"吗？';
  }

  @override
  String groupDeleted(String name) {
    return '已删除群组\"$name\"';
  }

  @override
  String membersOfGroup(String name) {
    return '\"$name\"的成员';
  }

  @override
  String get membersUpdated => '成员已更新';

  @override
  String get edit => '编辑';

  @override
  String get enable => '启用';

  @override
  String get disable => '禁用';

  @override
  String get confirm => '确认';

  @override
  String get statusLabel => '状态';

  @override
  String get connected => '已连接';

  @override
  String get nature => '自然';

  @override
  String get urban => '城市';

  @override
  String get chooseFolder => '选择文件夹';

  @override
  String get addTmdbKeyHint => '添加TMDB密钥以获取电影封面';

  @override
  String get scanningMediaFiles => '正在扫描媒体文件...';

  @override
  String get newestFilesSubtitle => '您媒体库中的最新文件';

  @override
  String get allVideos => '所有视频';

  @override
  String get videosLabel => '视频';

  @override
  String get imagesLabel => '图片';

  @override
  String get audioLabel => '音频';

  @override
  String get foldersLabel => '文件夹';

  @override
  String get latest => '最新';

  @override
  String get play => '播放';

  @override
  String get change => '更改';

  @override
  String get selectMediaFolder => '选择媒体文件夹';

  @override
  String get select => '选择';

  @override
  String get noSubfolders => '没有子文件夹';

  @override
  String get tapSelectHint => '点击\"选择\"使用此文件夹';

  @override
  String nFiles(int count) {
    return '$count 个文件';
  }

  @override
  String nVideos(int count) {
    return '$count 个视频';
  }

  @override
  String nImages(int count) {
    return '$count 张图片';
  }

  @override
  String nTracks(int count) {
    return '$count 首曲目';
  }

  @override
  String get sampleAlpineReflection => '高山倒影';

  @override
  String get sampleEmeraldMorning => '翡翠晨光';

  @override
  String get sampleNeonPulse => '霓虹脉动';

  @override
  String get connectionLogs => '连接日志';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return '用户: $userPct%  ·  系统: $systemPct%';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '已用 $usedMb MB / $totalMb MB  ·  缓存: $cachedMb MB';
  }

  @override
  String driveHddDetail(int n, String size) {
    return '硬盘 $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return '存储池 $n';
  }

  @override
  String volumeN(int n) {
    return '存储卷 $n';
  }

  @override
  String get unknown => '未知';

  @override
  String get insufficientPermission => '权限不足，需要管理员权限。';

  @override
  String get invalidParameter => '参数无效';

  @override
  String get accountIsDisabled => '帐户已停用';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get userGroupNotFound => '未找到用户/群组';

  @override
  String get nameAlreadyExists => '名称已存在';

  @override
  String operationFailedCode(int code) {
    return '操作失败（错误 $code）';
  }

  @override
  String get notAvailable => '不适用';

  @override
  String get timeline => '时间线';

  @override
  String get albumsTab => '相册';

  @override
  String get backup => '备份';

  @override
  String get sharedSpace => '共享空间';

  @override
  String get personalSpace => '个人空间';

  @override
  String get searchPhotos => '搜索照片...';

  @override
  String get addToAlbum => '添加到相册';

  @override
  String uploadingProgress(int current, int total) {
    return '正在上传 $current/$total...';
  }

  @override
  String deletePhotosTitle(int count) {
    return '删除 $count 个项目？';
  }

  @override
  String get deletePhotosMessage => '这些项目将被永久删除，此操作无法撤销。';

  @override
  String addedToAlbumN(String name) {
    return '已添加到「$name」';
  }

  @override
  String uploadedNPhotos(int count) {
    return '已上传 $count 张照片';
  }

  @override
  String get createAlbum => '创建相册';

  @override
  String get albumName => '相册名称';

  @override
  String get create => '创建';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String photoCount(int count) {
    return '$count 张照片';
  }

  @override
  String get photosApiHint => '请确保 Synology Photos 已安装并在 NAS 上运行。';

  @override
  String get noPhotosTitle => '暂无照片';

  @override
  String get noPhotosSubtitle => '上传照片到 NAS 或启用备份开始使用。';

  @override
  String get uploadPhotos => '上传照片';

  @override
  String get deleteAlbum => '删除相册';

  @override
  String deleteAlbumMessage(String name) {
    return '删除相册「$name」？相册内的照片不会被删除。';
  }

  @override
  String get noAlbums => '暂无相册';

  @override
  String get createAlbumHint => '创建相册来整理你的照片';

  @override
  String get backupPhotos => '照片备份';

  @override
  String get backupPhotosDesc => '将设备中的照片上传到 NAS 安全保存。';

  @override
  String get manualUpload => '手动上传';

  @override
  String get selectPhotosToUpload => '选择要上传的照片';

  @override
  String get uploadToNasPhotos => '上传到 NAS 的 /photo/Upload';

  @override
  String get backupInfoHint => '上传的照片将被 Synology Photos 自动索引，并出现在时间线中。';

  @override
  String get noPhotosInAlbum => '此相册中没有照片';

  @override
  String get downloadLinkCopied => '下载链接已复制到剪贴板';

  @override
  String get photoInfo => '照片信息';

  @override
  String get filenameLabel => '文件名';

  @override
  String get takenOn => '拍摄日期';

  @override
  String get resolution => '分辨率';

  @override
  String get fileSize => '文件大小';

  @override
  String get video => '视频';

  @override
  String get photo => '照片';

  @override
  String downloadSavedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get uploadDestination => '上传目标';

  @override
  String get selectUploadDest => '选择上传文件夹';

  @override
  String get selectMediaToUpload => '选择照片和视频';

  @override
  String uploadToNasDest(String dest) {
    return '上传到 NAS 的 $dest';
  }

  @override
  String lastUploadResult(int count) {
    return '上次上传：$count 个文件成功';
  }

  @override
  String get renameAlbum => '重命名相册';

  @override
  String get limitedAccess => '访问受限';

  @override
  String get limitedAccessDesc => '系统监控需要管理员权限。文件管理器、媒体中心和相册完全可用。';

  @override
  String get quota => '配额';

  @override
  String get quotaMB => '配额 (MB)';

  @override
  String get unlimited => '无限制';

  @override
  String get sharePermissions => '共享权限';

  @override
  String get readWrite => '读写';

  @override
  String get readOnly => '只读';

  @override
  String get noAccess => '无权访问';

  @override
  String get adminOnly => '仅管理员';

  @override
  String get quotaUpdated => '配额已更新';

  @override
  String get permissionUpdated => '权限已更新';

  @override
  String get premiumFeature => '高级功能';

  @override
  String get premiumFeatureDesc =>
      'Media Hub 和 Photos 是 VIP 会员专属高级功能。请联系开发者升级您的账户。';

  @override
  String get vipMember => 'VIP 会员';

  @override
  String get freeUser => '免费用户';

  @override
  String get otpDialogTitle => '两步验证';

  @override
  String get otpDialogMessage => '您的 NAS 需要验证码。请输入身份验证器应用中的 6 位数字代码。';

  @override
  String get verify => '验证';

  @override
  String get quickConnectFailed => 'QuickConnect 解析失败';

  @override
  String get updateAvailable => '有新版本';

  @override
  String get whatsNew => '更新内容';

  @override
  String get later => '稍后';

  @override
  String get updateNow => '立即更新';

  @override
  String get downloading => '正在下载更新...';

  @override
  String get updateFailed => '更新失败';
}

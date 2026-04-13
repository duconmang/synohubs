// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Synology NAS Management';

  @override
  String get connecting => 'Connecting...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get signInPrivacyNote =>
      'Your data stays on your device.\nGoogle account is used only for identity\nand optional backup to your Google Drive.';

  @override
  String get signInCancelled => 'Sign-in was cancelled';

  @override
  String signInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get noDataStoredOnServers => 'No data is stored on our servers';

  @override
  String get nasAddress => 'NAS ADDRESS';

  @override
  String get ipOrHostname => 'IP or hostname';

  @override
  String get port => 'Port';

  @override
  String get protocol => 'PROTOCOL';

  @override
  String get usernameLabel => 'USERNAME';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get invalidPortNumber => 'Invalid port number';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get connect => 'Connect';

  @override
  String get myNas => 'My NAS';

  @override
  String get addNas => 'Add NAS';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get noNasTitle => 'No NAS Added Yet';

  @override
  String get noNasSubtitle => 'Tap \"Add NAS\" to connect\nyour Synology NAS';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => 'Backup to Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Restore from Google Drive';

  @override
  String get signOut => 'Sign Out';

  @override
  String get backingUp => 'Backing up to Google Drive...';

  @override
  String get backupSuccessful => 'Backup successful';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoringFromDrive => 'Restoring from Google Drive...';

  @override
  String get restoreSuccessful => 'Restore successful';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get noBackupFound => 'No backup found on Google Drive';

  @override
  String get nameThisNas => 'Name this NAS';

  @override
  String get nasNicknameHint => 'e.g. NAS Home, Office NAS';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get rename => 'Rename';

  @override
  String get details => 'Details';

  @override
  String get remove => 'Remove';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get host => 'Host';

  @override
  String get username => 'Username';

  @override
  String get model => 'Model';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => 'Last Connected';

  @override
  String get removeNasTitle => 'Remove NAS';

  @override
  String removeNasMessage(String name) {
    return 'Remove \"$name\" from your list?';
  }

  @override
  String get nasRemoved => 'NAS removed';

  @override
  String get language => 'Language';

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
  String get dashboard => 'Dashboard';

  @override
  String get files => 'Files';

  @override
  String get media => 'Media';

  @override
  String get photos => 'Photos';

  @override
  String get healthy => 'HEALTHY';

  @override
  String get dsmVersion => 'DSM VERSION';

  @override
  String get uptime => 'UPTIME';

  @override
  String get lanIp => 'LAN IP';

  @override
  String get serial => 'SERIAL';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => 'SERVICES';

  @override
  String get cpuTemp => 'CPU TEMP';

  @override
  String get disks => 'DISKS';

  @override
  String get resourceMonitor => 'Resource Monitor';

  @override
  String get storageAndVolumes => 'Storage & Volumes';

  @override
  String get storageCapacity => 'STORAGE CAPACITY';

  @override
  String get diskHealth => 'Disk Health';

  @override
  String bayN(int n) {
    return 'Bay $n';
  }

  @override
  String get normal => 'Normal';

  @override
  String get installedPackages => 'Installed Packages';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get resourceMonitorAction => 'Resource\nMonitor';

  @override
  String get storageManagerAction => 'Storage\nManager';

  @override
  String get logCenterAction => 'Log\nCenter';

  @override
  String get restart => 'Restart';

  @override
  String get shutdown => 'Shutdown';

  @override
  String get refresh => 'Refresh';

  @override
  String confirmActionTitle(String action) {
    return '$action NAS?';
  }

  @override
  String confirmActionMessage(String action) {
    return 'Are you sure you want to $action your NAS?';
  }

  @override
  String get fileManager => 'File Manager';

  @override
  String get notConnected => 'Not connected';

  @override
  String errorCode(String code) {
    return 'Error $code';
  }

  @override
  String get newFolder => 'New Folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get newName => 'New name';

  @override
  String get failedToCreateFolder => 'Failed to create folder';

  @override
  String get failedToRename => 'Failed to rename';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return 'Delete $count item$suffix?';
  }

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String failedToDelete(String name) {
    return 'Failed to delete: $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return '$action $count item$suffix';
  }

  @override
  String get copied => 'Copied';

  @override
  String get cut => 'Cut';

  @override
  String failedToCopyMove(String action) {
    return 'Failed to $action';
  }

  @override
  String get shareLinkCopied => 'Share link copied!';

  @override
  String get couldNotGenerateLink => 'Could not generate link';

  @override
  String get failedToCreateShareLink => 'Failed to create share link';

  @override
  String couldNotReadFile(String name) {
    return 'Could not read file: $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return 'Uploaded $count file$suffix';
  }

  @override
  String failedError(String error) {
    return 'Failed: $error';
  }

  @override
  String get copy => 'Copy';

  @override
  String get shareLink => 'Share Link';

  @override
  String get qrCode => 'QR Code';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String get searchFiles => 'Search files...';

  @override
  String searchInFolder(String folder) {
    return 'Search in $folder...';
  }

  @override
  String get searchFailed => 'Search failed';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get emptyFolder => 'Empty folder';

  @override
  String get sortByName => 'Name';

  @override
  String get sortBySize => 'Size';

  @override
  String get sortByDate => 'Date Modified';

  @override
  String get sortByType => 'Type';

  @override
  String get listView => 'List view';

  @override
  String get gridView => 'Grid view';

  @override
  String get root => 'Root';

  @override
  String get clipboardMove => 'Clipboard: move';

  @override
  String get clipboardCopy => 'Clipboard: copy';

  @override
  String get pasteHere => 'Paste Here';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get couldNotGenerateShareLink => 'Could not generate share link';

  @override
  String get sort => 'Sort';

  @override
  String get mediaHub => 'Media Hub';

  @override
  String get selectFolderDescription =>
      'Select a folder on your NAS to scan and browse media files';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get startingScan => 'Starting scan...';

  @override
  String scanningFolder(String name) {
    return 'Scanning: $name';
  }

  @override
  String mediaFilesFound(int count) {
    return '$count media files found';
  }

  @override
  String get tmdbApiKey => 'TMDB API Key';

  @override
  String get tmdbApiKeyInstructions =>
      'Use the \"API Key (v3 auth)\" from your TMDB account settings — NOT the Read Access Token.';

  @override
  String get tmdbApiKeyHelp => 'Get a free key at themoviedb.org/settings/api';

  @override
  String get tmdbApiKeyHint => 'Paste API Key (v3) here';

  @override
  String get changeFolder => 'Change folder';

  @override
  String get tmdbKeyConfigured => 'TMDB key configured ✓';

  @override
  String get setTmdbApiKey => 'Set TMDB API key';

  @override
  String get rescanFolder => 'Re-scan folder';

  @override
  String get chooseMediaFolder => 'Choose a media folder';

  @override
  String get allMedia => 'All Media';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String get filters => 'Filters';

  @override
  String get allPhotos => 'All Photos';

  @override
  String get favorites => 'Favorites';

  @override
  String get recent => 'Recent';

  @override
  String get hidden => 'Hidden';

  @override
  String get recentlyAddedPhotos => 'RECENTLY ADDED';

  @override
  String get viewAll => 'View all';

  @override
  String get myAlbums => 'MY ALBUMS';

  @override
  String get family => 'Family';

  @override
  String get travel => 'Travel';

  @override
  String get workAndProjects => 'Work & Projects';

  @override
  String itemsCount(String count) {
    return '$count items';
  }

  @override
  String get logCenter => 'Log Center';

  @override
  String get overview => 'Overview';

  @override
  String get logs => 'Logs';

  @override
  String get connections => 'Connections';

  @override
  String get totalLogs => 'Total Logs';

  @override
  String get info => 'Info';

  @override
  String get warnings => 'Warnings';

  @override
  String get errors => 'Errors';

  @override
  String lastNLogs(int count) {
    return 'Last $count Logs';
  }

  @override
  String get noLogsAvailable => 'No logs available';

  @override
  String get systemLogs => 'System Logs';

  @override
  String nItems(int count) {
    return '$count items';
  }

  @override
  String get level => 'Level';

  @override
  String get time => 'Time';

  @override
  String get user => 'User';

  @override
  String get event => 'Event';

  @override
  String get noConnectionLogs => 'No connection logs';

  @override
  String get type => 'Type';

  @override
  String get ip => 'IP';

  @override
  String get date => 'Date';

  @override
  String get performance => 'Performance';

  @override
  String get details_tab => 'Details';

  @override
  String get utilization => 'Utilization (%)';

  @override
  String get memory => 'Memory';

  @override
  String get network => 'Network';

  @override
  String get diskIO => 'Disk I/O';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get read => 'Read';

  @override
  String get write => 'Write';

  @override
  String get activeConnections => 'Active Connections';

  @override
  String get processId => 'PID';

  @override
  String get process => 'Process';

  @override
  String get systemDetails => 'System Details';

  @override
  String get cpuModel => 'CPU Model';

  @override
  String get cpuCores => 'CPU Cores';

  @override
  String get totalRam => 'Total RAM';

  @override
  String get temperature => 'Temperature';

  @override
  String get systemTime => 'System Time';

  @override
  String get storageManager => 'Storage Manager';

  @override
  String get storage => 'Storage';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => 'System Health';

  @override
  String get totalStorage => 'Total Storage';

  @override
  String get used => 'Used';

  @override
  String get available => 'Available';

  @override
  String get volumeUsage => 'Volume Usage';

  @override
  String get critical => 'Critical';

  @override
  String get usageExceedsThreshold => 'Usage exceeds 90%';

  @override
  String get storageHealthy => 'Storage healthy';

  @override
  String get driveInformation => 'Drive Information';

  @override
  String get status => 'Status';

  @override
  String get capacity => 'Capacity';

  @override
  String get diskTemperature => 'Disk Temperature';

  @override
  String get userAndGroup => 'User & Group';

  @override
  String get users => 'Users';

  @override
  String get groups => 'Groups';

  @override
  String get allUsers => 'All Users';

  @override
  String nUsers(int count) {
    return '$count users';
  }

  @override
  String get admin => 'ADMIN';

  @override
  String get active => 'Active';

  @override
  String get disabled => 'Disabled';

  @override
  String get allGroups => 'All Groups';

  @override
  String nGroups(int count) {
    return '$count groups';
  }

  @override
  String get members => 'Members';

  @override
  String get noUsers => 'No users found';

  @override
  String get noGroups => 'No groups found';

  @override
  String get loadingVideo => 'Loading video...';

  @override
  String get failedToPlayVideo => 'Failed to play video';

  @override
  String get settings => 'Settings';

  @override
  String get nasConnection => 'NAS Connection';

  @override
  String get connection => 'Connection';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAndColors => 'Theme & Colors';

  @override
  String get darkCyanAccent => 'Dark • Cyan accent';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get systemAlerts => 'System Alerts';

  @override
  String get backupAlerts => 'Backup Alerts';

  @override
  String get storageWarnings => 'Storage Warnings';

  @override
  String get about => 'About';

  @override
  String get aboutSynoHub => 'About SynoHub';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get upToDate => 'Up to date';

  @override
  String get theme => 'THEME';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get system => 'System';

  @override
  String get accentColor => 'ACCENT COLOR';

  @override
  String get cyan => 'Cyan';

  @override
  String get teal => 'Teal';

  @override
  String get gold => 'Gold';

  @override
  String get purple => 'Purple';

  @override
  String get preview => 'PREVIEW';

  @override
  String get accentColorPreview => 'Accent color preview';

  @override
  String get connectionSettings => 'Connection';

  @override
  String get server => 'SERVER';

  @override
  String get nasAddressSetting => 'NAS Address';

  @override
  String get ipHostnameOrQuickConnect => 'IP, hostname, or QuickConnect ID';

  @override
  String get portLabel => 'Port';

  @override
  String get protocolLabel => 'PROTOCOL';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => 'ACCOUNT';

  @override
  String get password => 'Password';

  @override
  String get rememberLogin => 'Remember Login';

  @override
  String get logout => 'Logout';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get connectedNas => 'CONNECTED NAS';

  @override
  String get dsmVersionLabel => 'DSM Version';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get application => 'APPLICATION';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get madeWithFlutter => 'Made with ❤ Flutter';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => 'No active connections';

  @override
  String get connectedUsers => 'Connected Users';

  @override
  String get memoryBreakdown => 'Memory Breakdown';

  @override
  String get total => 'Total';

  @override
  String get cached => 'Cached';

  @override
  String get bufferLabel => 'Buffer';

  @override
  String get diskInformation => 'Disk Information';

  @override
  String driveN(int n) {
    return 'Drive $n';
  }

  @override
  String get healthyStatus => 'Healthy';

  @override
  String get degraded => 'Degraded';

  @override
  String get allStorageHealthy => 'All storage pools and volumes are healthy.';

  @override
  String get storagePoolDegraded =>
      'Issues have occurred to a Storage Pool. Please go to the Storage page for details.';

  @override
  String get raidType => 'RAID Type';

  @override
  String get drives => 'Drives';

  @override
  String nDisks(int count) {
    return '$count disk(s)';
  }

  @override
  String get device => 'Device';

  @override
  String get drive => 'Drive';

  @override
  String get size => 'Size';

  @override
  String get noStoragePoolData => 'No storage pool data available';

  @override
  String get noDiskInfo => 'No disk information available';

  @override
  String get systemGroup => 'SYSTEM';

  @override
  String get noMembers => 'No members';

  @override
  String membersCount(int count) {
    return 'Members ($count)';
  }

  @override
  String get manage => 'Manage';

  @override
  String get createUser => 'Create User';

  @override
  String get email => 'Email';

  @override
  String get description => 'Description';

  @override
  String get usernameAndPasswordRequired =>
      'Username and password are required';

  @override
  String get userCreatedSuccessfully => 'User created successfully';

  @override
  String editName(String name) {
    return 'Edit \"$name\"';
  }

  @override
  String get userUpdated => 'User updated';

  @override
  String changePasswordTitle(String name) {
    return 'Change Password - $name';
  }

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String userEnabled(String name) {
    return '$name enabled';
  }

  @override
  String userDisabled(String name) {
    return '$name disabled';
  }

  @override
  String get deleteUserTitle => 'Delete User?';

  @override
  String deleteUserMessage(String name) {
    return 'Are you sure you want to delete user \"$name\"? This cannot be undone.';
  }

  @override
  String userDeleted(String name) {
    return 'User \"$name\" deleted';
  }

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameRequired => 'Group name is required';

  @override
  String get groupCreated => 'Group created';

  @override
  String get groupUpdated => 'Group updated';

  @override
  String get deleteGroupTitle => 'Delete Group?';

  @override
  String deleteGroupMessage(String name) {
    return 'Are you sure you want to delete group \"$name\"?';
  }

  @override
  String groupDeleted(String name) {
    return 'Group \"$name\" deleted';
  }

  @override
  String membersOfGroup(String name) {
    return 'Members of \"$name\"';
  }

  @override
  String get membersUpdated => 'Members updated';

  @override
  String get edit => 'Edit';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get confirm => 'Confirm';

  @override
  String get statusLabel => 'Status';

  @override
  String get connected => 'Connected';

  @override
  String get nature => 'Nature';

  @override
  String get urban => 'Urban';

  @override
  String get chooseFolder => 'Choose Folder';

  @override
  String get addTmdbKeyHint => 'Add TMDB key for movie covers';

  @override
  String get scanningMediaFiles => 'Scanning media files...';

  @override
  String get newestFilesSubtitle => 'Newest files from your library';

  @override
  String get allVideos => 'All Videos';

  @override
  String get videosLabel => 'Videos';

  @override
  String get imagesLabel => 'Images';

  @override
  String get audioLabel => 'Audio';

  @override
  String get foldersLabel => 'Folders';

  @override
  String get latest => 'LATEST';

  @override
  String get play => 'Play';

  @override
  String get change => 'Change';

  @override
  String get selectMediaFolder => 'Select Media Folder';

  @override
  String get select => 'Select';

  @override
  String get noSubfolders => 'No subfolders';

  @override
  String get tapSelectHint => 'Tap \"Select\" to use this folder';

  @override
  String nFiles(int count) {
    return '$count files';
  }

  @override
  String nVideos(int count) {
    return '$count videos';
  }

  @override
  String nImages(int count) {
    return '$count images';
  }

  @override
  String nTracks(int count) {
    return '$count tracks';
  }

  @override
  String get sampleAlpineReflection => 'Alpine Reflection';

  @override
  String get sampleEmeraldMorning => 'Emerald Morning';

  @override
  String get sampleNeonPulse => 'Neon Pulse';

  @override
  String get connectionLogs => 'Connection Logs';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return 'User: $userPct%  ·  System: $systemPct%';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '$usedMb MB used / $totalMb MB  ·  Cache: $cachedMb MB';
  }

  @override
  String driveHddDetail(int n, String size) {
    return 'Drive $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return 'Storage Pool $n';
  }

  @override
  String volumeN(int n) {
    return 'Volume $n';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get insufficientPermission =>
      'Insufficient permission. Admin access required.';

  @override
  String get invalidParameter => 'Invalid parameter';

  @override
  String get accountIsDisabled => 'Account is disabled';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get userGroupNotFound => 'User/Group not found';

  @override
  String get nameAlreadyExists => 'Name already exists';

  @override
  String operationFailedCode(int code) {
    return 'Operation failed (error $code)';
  }

  @override
  String get notAvailable => 'N/A';

  @override
  String get timeline => 'Timeline';

  @override
  String get albumsTab => 'Albums';

  @override
  String get backup => 'Backup';

  @override
  String get sharedSpace => 'Shared Space';

  @override
  String get personalSpace => 'Personal Space';

  @override
  String get searchPhotos => 'Search photos...';

  @override
  String get addToAlbum => 'Add to Album';

  @override
  String uploadingProgress(int current, int total) {
    return 'Uploading $current of $total...';
  }

  @override
  String deletePhotosTitle(int count) {
    return 'Delete $count item(s)?';
  }

  @override
  String get deletePhotosMessage =>
      'These items will be permanently deleted. This cannot be undone.';

  @override
  String addedToAlbumN(String name) {
    return 'Added to \"$name\"';
  }

  @override
  String uploadedNPhotos(int count) {
    return 'Uploaded $count photo(s)';
  }

  @override
  String get createAlbum => 'Create Album';

  @override
  String get albumName => 'Album name';

  @override
  String get create => 'Create';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String photoCount(int count) {
    return '$count photos';
  }

  @override
  String get photosApiHint =>
      'Make sure Synology Photos is installed and running on your NAS.';

  @override
  String get noPhotosTitle => 'No Photos Yet';

  @override
  String get noPhotosSubtitle =>
      'Upload photos to your NAS or enable backup to get started.';

  @override
  String get uploadPhotos => 'Upload Photos';

  @override
  String get deleteAlbum => 'Delete Album';

  @override
  String deleteAlbumMessage(String name) {
    return 'Delete album \"$name\"? Photos inside will not be deleted.';
  }

  @override
  String get noAlbums => 'No Albums';

  @override
  String get createAlbumHint => 'Create albums to organize your photos';

  @override
  String get backupPhotos => 'Photo Backup';

  @override
  String get backupPhotosDesc =>
      'Upload photos from your device to your NAS for safekeeping.';

  @override
  String get manualUpload => 'Manual Upload';

  @override
  String get selectPhotosToUpload => 'Select Photos to Upload';

  @override
  String get uploadToNasPhotos => 'Upload to /photo/Upload on your NAS';

  @override
  String get backupInfoHint =>
      'Uploaded photos will be automatically indexed by Synology Photos and will appear in your timeline.';

  @override
  String get noPhotosInAlbum => 'No photos in this album';

  @override
  String get downloadLinkCopied => 'Download link copied to clipboard';

  @override
  String get photoInfo => 'Photo Info';

  @override
  String get filenameLabel => 'Filename';

  @override
  String get takenOn => 'Date Taken';

  @override
  String get resolution => 'Resolution';

  @override
  String get fileSize => 'File Size';

  @override
  String get video => 'Video';

  @override
  String get photo => 'Photo';

  @override
  String downloadSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get uploadDestination => 'Upload Destination';

  @override
  String get selectUploadDest => 'Select Upload Folder';

  @override
  String get selectMediaToUpload => 'Select Photos & Videos';

  @override
  String uploadToNasDest(String dest) {
    return 'Upload to $dest on your NAS';
  }

  @override
  String lastUploadResult(int count) {
    return 'Last upload: $count file(s) uploaded successfully';
  }

  @override
  String get renameAlbum => 'Rename Album';

  @override
  String get limitedAccess => 'Limited Access';

  @override
  String get limitedAccessDesc =>
      'System monitoring requires admin privileges. File Manager, Media Hub, and Photos are fully available.';

  @override
  String get quota => 'Quota';

  @override
  String get quotaMB => 'Quota (MB)';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get sharePermissions => 'Share Permissions';

  @override
  String get readWrite => 'Read/Write';

  @override
  String get readOnly => 'Read Only';

  @override
  String get noAccess => 'No Access';

  @override
  String get adminOnly => 'Admin Only';

  @override
  String get quotaUpdated => 'Quota updated';

  @override
  String get permissionUpdated => 'Permission updated';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get premiumFeatureDesc =>
      'Media Hub and Photos are premium features available to VIP members. Contact the developer to upgrade your account.';

  @override
  String get vipMember => 'VIP Member';

  @override
  String get freeUser => 'Free User';

  @override
  String get otpDialogTitle => 'Two-Factor Authentication';

  @override
  String get otpDialogMessage =>
      'Your NAS requires a verification code. Enter the 6-digit code from your authenticator app.';

  @override
  String get verify => 'Verify';

  @override
  String get quickConnectFailed => 'QuickConnect resolution failed';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get whatsNew => 'What\'s New';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get downloading => 'Downloading update...';

  @override
  String get updateFailed => 'Update failed';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SynoHub'**
  String get appTitle;

  /// No description provided for @synologyNasManagement.
  ///
  /// In en, this message translates to:
  /// **'Synology NAS Management'**
  String get synologyNasManagement;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get version;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @signInPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your device.\nGoogle account is used only for identity\nand optional backup to your Google Drive.'**
  String get signInPrivacyNote;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled'**
  String get signInCancelled;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String signInFailed(String error);

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @noDataStoredOnServers.
  ///
  /// In en, this message translates to:
  /// **'No data is stored on our servers'**
  String get noDataStoredOnServers;

  /// No description provided for @nasAddress.
  ///
  /// In en, this message translates to:
  /// **'NAS ADDRESS'**
  String get nasAddress;

  /// No description provided for @ipOrHostname.
  ///
  /// In en, this message translates to:
  /// **'IP or hostname'**
  String get ipOrHostname;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'PROTOCOL'**
  String get protocol;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get usernameHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @invalidPortNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid port number'**
  String get invalidPortNumber;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @myNas.
  ///
  /// In en, this message translates to:
  /// **'My NAS'**
  String get myNas;

  /// No description provided for @addNas.
  ///
  /// In en, this message translates to:
  /// **'Add NAS'**
  String get addNas;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @noNasTitle.
  ///
  /// In en, this message translates to:
  /// **'No NAS Added Yet'**
  String get noNasTitle;

  /// No description provided for @noNasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add NAS\" to connect\nyour Synology NAS'**
  String get noNasSubtitle;

  /// No description provided for @deviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String deviceCount(int count);

  /// No description provided for @backupToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Backup to Google Drive'**
  String get backupToGoogleDrive;

  /// No description provided for @restoreFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromGoogleDrive;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @backingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up to Google Drive...'**
  String get backingUp;

  /// No description provided for @backupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Backup successful'**
  String get backupSuccessful;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoringFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restoring from Google Drive...'**
  String get restoringFromDrive;

  /// No description provided for @restoreSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Restore successful'**
  String get restoreSuccessful;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @noBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No backup found on Google Drive'**
  String get noBackupFound;

  /// No description provided for @nameThisNas.
  ///
  /// In en, this message translates to:
  /// **'Name this NAS'**
  String get nameThisNas;

  /// No description provided for @nasNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. NAS Home, Office NAS'**
  String get nasNicknameHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @dsm.
  ///
  /// In en, this message translates to:
  /// **'DSM'**
  String get dsm;

  /// No description provided for @lastConnected.
  ///
  /// In en, this message translates to:
  /// **'Last Connected'**
  String get lastConnected;

  /// No description provided for @removeNasTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove NAS'**
  String get removeNasTitle;

  /// No description provided for @removeNasMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your list?'**
  String removeNasMessage(String name);

  /// No description provided for @nasRemoved.
  ///
  /// In en, this message translates to:
  /// **'NAS removed'**
  String get nasRemoved;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get healthy;

  /// No description provided for @dsmVersion.
  ///
  /// In en, this message translates to:
  /// **'DSM VERSION'**
  String get dsmVersion;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'UPTIME'**
  String get uptime;

  /// No description provided for @lanIp.
  ///
  /// In en, this message translates to:
  /// **'LAN IP'**
  String get lanIp;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'SERIAL'**
  String get serial;

  /// No description provided for @cpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @ram.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get ram;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'SERVICES'**
  String get services;

  /// No description provided for @cpuTemp.
  ///
  /// In en, this message translates to:
  /// **'CPU TEMP'**
  String get cpuTemp;

  /// No description provided for @disks.
  ///
  /// In en, this message translates to:
  /// **'DISKS'**
  String get disks;

  /// No description provided for @resourceMonitor.
  ///
  /// In en, this message translates to:
  /// **'Resource Monitor'**
  String get resourceMonitor;

  /// No description provided for @storageAndVolumes.
  ///
  /// In en, this message translates to:
  /// **'Storage & Volumes'**
  String get storageAndVolumes;

  /// No description provided for @storageCapacity.
  ///
  /// In en, this message translates to:
  /// **'STORAGE CAPACITY'**
  String get storageCapacity;

  /// No description provided for @diskHealth.
  ///
  /// In en, this message translates to:
  /// **'Disk Health'**
  String get diskHealth;

  /// No description provided for @bayN.
  ///
  /// In en, this message translates to:
  /// **'Bay {n}'**
  String bayN(int n);

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @installedPackages.
  ///
  /// In en, this message translates to:
  /// **'Installed Packages'**
  String get installedPackages;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @resourceMonitorAction.
  ///
  /// In en, this message translates to:
  /// **'Resource\nMonitor'**
  String get resourceMonitorAction;

  /// No description provided for @storageManagerAction.
  ///
  /// In en, this message translates to:
  /// **'Storage\nManager'**
  String get storageManagerAction;

  /// No description provided for @logCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Log\nCenter'**
  String get logCenterAction;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @shutdown.
  ///
  /// In en, this message translates to:
  /// **'Shutdown'**
  String get shutdown;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @confirmActionTitle.
  ///
  /// In en, this message translates to:
  /// **'{action} NAS?'**
  String confirmActionTitle(String action);

  /// No description provided for @confirmActionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to {action} your NAS?'**
  String confirmActionMessage(String action);

  /// No description provided for @fileManager.
  ///
  /// In en, this message translates to:
  /// **'File Manager'**
  String get fileManager;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Error {code}'**
  String errorCode(String code);

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @failedToCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get failedToCreateFolder;

  /// No description provided for @failedToRename.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename'**
  String get failedToRename;

  /// No description provided for @deleteItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} item{suffix}?'**
  String deleteItemsTitle(int count, String suffix);

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {name}'**
  String failedToDelete(String name);

  /// No description provided for @copiedItems.
  ///
  /// In en, this message translates to:
  /// **'{action} {count} item{suffix}'**
  String copiedItems(String action, int count, String suffix);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @failedToCopyMove.
  ///
  /// In en, this message translates to:
  /// **'Failed to {action}'**
  String failedToCopyMove(String action);

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Share link copied!'**
  String get shareLinkCopied;

  /// No description provided for @couldNotGenerateLink.
  ///
  /// In en, this message translates to:
  /// **'Could not generate link'**
  String get couldNotGenerateLink;

  /// No description provided for @failedToCreateShareLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to create share link'**
  String get failedToCreateShareLink;

  /// No description provided for @couldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read file: {name}'**
  String couldNotReadFile(String name);

  /// No description provided for @uploadedFiles.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} file{suffix}'**
  String uploadedFiles(int count, String suffix);

  /// No description provided for @failedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedError(String error);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Search files...'**
  String get searchFiles;

  /// No description provided for @searchInFolder.
  ///
  /// In en, this message translates to:
  /// **'Search in {folder}...'**
  String searchInFolder(String folder);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyFolder;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortBySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortBySize;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date Modified'**
  String get sortByDate;

  /// No description provided for @sortByType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortByType;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @root.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get root;

  /// No description provided for @clipboardMove.
  ///
  /// In en, this message translates to:
  /// **'Clipboard: move'**
  String get clipboardMove;

  /// No description provided for @clipboardCopy.
  ///
  /// In en, this message translates to:
  /// **'Clipboard: copy'**
  String get clipboardCopy;

  /// No description provided for @pasteHere.
  ///
  /// In en, this message translates to:
  /// **'Paste Here'**
  String get pasteHere;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @couldNotGenerateShareLink.
  ///
  /// In en, this message translates to:
  /// **'Could not generate share link'**
  String get couldNotGenerateShareLink;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @mediaHub.
  ///
  /// In en, this message translates to:
  /// **'Media Hub'**
  String get mediaHub;

  /// No description provided for @selectFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a folder on your NAS to scan and browse media files'**
  String get selectFolderDescription;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @startingScan.
  ///
  /// In en, this message translates to:
  /// **'Starting scan...'**
  String get startingScan;

  /// No description provided for @scanningFolder.
  ///
  /// In en, this message translates to:
  /// **'Scanning: {name}'**
  String scanningFolder(String name);

  /// No description provided for @mediaFilesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} media files found'**
  String mediaFilesFound(int count);

  /// No description provided for @tmdbApiKey.
  ///
  /// In en, this message translates to:
  /// **'TMDB API Key'**
  String get tmdbApiKey;

  /// No description provided for @tmdbApiKeyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Use the \"API Key (v3 auth)\" from your TMDB account settings — NOT the Read Access Token.'**
  String get tmdbApiKeyInstructions;

  /// No description provided for @tmdbApiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Get a free key at themoviedb.org/settings/api'**
  String get tmdbApiKeyHelp;

  /// No description provided for @tmdbApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste API Key (v3) here'**
  String get tmdbApiKeyHint;

  /// No description provided for @changeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get changeFolder;

  /// No description provided for @tmdbKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'TMDB key configured ✓'**
  String get tmdbKeyConfigured;

  /// No description provided for @setTmdbApiKey.
  ///
  /// In en, this message translates to:
  /// **'Set TMDB API key'**
  String get setTmdbApiKey;

  /// No description provided for @rescanFolder.
  ///
  /// In en, this message translates to:
  /// **'Re-scan folder'**
  String get rescanFolder;

  /// No description provided for @chooseMediaFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a media folder'**
  String get chooseMediaFolder;

  /// No description provided for @allMedia.
  ///
  /// In en, this message translates to:
  /// **'All Media'**
  String get allMedia;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allPhotos.
  ///
  /// In en, this message translates to:
  /// **'All Photos'**
  String get allPhotos;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @recentlyAddedPhotos.
  ///
  /// In en, this message translates to:
  /// **'RECENTLY ADDED'**
  String get recentlyAddedPhotos;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @myAlbums.
  ///
  /// In en, this message translates to:
  /// **'MY ALBUMS'**
  String get myAlbums;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @workAndProjects.
  ///
  /// In en, this message translates to:
  /// **'Work & Projects'**
  String get workAndProjects;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(String count);

  /// No description provided for @logCenter.
  ///
  /// In en, this message translates to:
  /// **'Log Center'**
  String get logCenter;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @totalLogs.
  ///
  /// In en, this message translates to:
  /// **'Total Logs'**
  String get totalLogs;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @lastNLogs.
  ///
  /// In en, this message translates to:
  /// **'Last {count} Logs'**
  String lastNLogs(int count);

  /// No description provided for @noLogsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get noLogsAvailable;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get systemLogs;

  /// No description provided for @nItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String nItems(int count);

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @noConnectionLogs.
  ///
  /// In en, this message translates to:
  /// **'No connection logs'**
  String get noConnectionLogs;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ip;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @details_tab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details_tab;

  /// No description provided for @utilization.
  ///
  /// In en, this message translates to:
  /// **'Utilization (%)'**
  String get utilization;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @diskIO.
  ///
  /// In en, this message translates to:
  /// **'Disk I/O'**
  String get diskIO;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @write.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get write;

  /// No description provided for @activeConnections.
  ///
  /// In en, this message translates to:
  /// **'Active Connections'**
  String get activeConnections;

  /// No description provided for @processId.
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get processId;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @systemDetails.
  ///
  /// In en, this message translates to:
  /// **'System Details'**
  String get systemDetails;

  /// No description provided for @cpuModel.
  ///
  /// In en, this message translates to:
  /// **'CPU Model'**
  String get cpuModel;

  /// No description provided for @cpuCores.
  ///
  /// In en, this message translates to:
  /// **'CPU Cores'**
  String get cpuCores;

  /// No description provided for @totalRam.
  ///
  /// In en, this message translates to:
  /// **'Total RAM'**
  String get totalRam;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @systemTime.
  ///
  /// In en, this message translates to:
  /// **'System Time'**
  String get systemTime;

  /// No description provided for @storageManager.
  ///
  /// In en, this message translates to:
  /// **'Storage Manager'**
  String get storageManager;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @hddSsd.
  ///
  /// In en, this message translates to:
  /// **'HDD/SSD'**
  String get hddSsd;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get systemHealth;

  /// No description provided for @totalStorage.
  ///
  /// In en, this message translates to:
  /// **'Total Storage'**
  String get totalStorage;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @volumeUsage.
  ///
  /// In en, this message translates to:
  /// **'Volume Usage'**
  String get volumeUsage;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @usageExceedsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Usage exceeds 90%'**
  String get usageExceedsThreshold;

  /// No description provided for @storageHealthy.
  ///
  /// In en, this message translates to:
  /// **'Storage healthy'**
  String get storageHealthy;

  /// No description provided for @driveInformation.
  ///
  /// In en, this message translates to:
  /// **'Drive Information'**
  String get driveInformation;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @diskTemperature.
  ///
  /// In en, this message translates to:
  /// **'Disk Temperature'**
  String get diskTemperature;

  /// No description provided for @userAndGroup.
  ///
  /// In en, this message translates to:
  /// **'User & Group'**
  String get userAndGroup;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @nUsers.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String nUsers(int count);

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get admin;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All Groups'**
  String get allGroups;

  /// No description provided for @nGroups.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String nGroups(int count);

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroups;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get loadingVideo;

  /// No description provided for @failedToPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to play video'**
  String get failedToPlayVideo;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @nasConnection.
  ///
  /// In en, this message translates to:
  /// **'NAS Connection'**
  String get nasConnection;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAndColors.
  ///
  /// In en, this message translates to:
  /// **'Theme & Colors'**
  String get themeAndColors;

  /// No description provided for @darkCyanAccent.
  ///
  /// In en, this message translates to:
  /// **'Dark • Cyan accent'**
  String get darkCyanAccent;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @systemAlerts.
  ///
  /// In en, this message translates to:
  /// **'System Alerts'**
  String get systemAlerts;

  /// No description provided for @backupAlerts.
  ///
  /// In en, this message translates to:
  /// **'Backup Alerts'**
  String get backupAlerts;

  /// No description provided for @storageWarnings.
  ///
  /// In en, this message translates to:
  /// **'Storage Warnings'**
  String get storageWarnings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutSynoHub.
  ///
  /// In en, this message translates to:
  /// **'About SynoHub'**
  String get aboutSynoHub;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get theme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'ACCENT COLOR'**
  String get accentColor;

  /// No description provided for @cyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get cyan;

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get preview;

  /// No description provided for @accentColorPreview.
  ///
  /// In en, this message translates to:
  /// **'Accent color preview'**
  String get accentColorPreview;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionSettings;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get server;

  /// No description provided for @nasAddressSetting.
  ///
  /// In en, this message translates to:
  /// **'NAS Address'**
  String get nasAddressSetting;

  /// No description provided for @ipHostnameOrQuickConnect.
  ///
  /// In en, this message translates to:
  /// **'IP, hostname, or QuickConnect ID'**
  String get ipHostnameOrQuickConnect;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @protocolLabel.
  ///
  /// In en, this message translates to:
  /// **'PROTOCOL'**
  String get protocolLabel;

  /// No description provided for @http.
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get http;

  /// No description provided for @https.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get https;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberLogin.
  ///
  /// In en, this message translates to:
  /// **'Remember Login'**
  String get rememberLogin;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @versionN.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionN(String version);

  /// No description provided for @connectedNas.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED NAS'**
  String get connectedNas;

  /// No description provided for @dsmVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'DSM Version'**
  String get dsmVersionLabel;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION'**
  String get application;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @madeWithFlutter.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤ Flutter'**
  String get madeWithFlutter;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 SynoHub'**
  String get copyright;

  /// No description provided for @noActiveConnections.
  ///
  /// In en, this message translates to:
  /// **'No active connections'**
  String get noActiveConnections;

  /// No description provided for @connectedUsers.
  ///
  /// In en, this message translates to:
  /// **'Connected Users'**
  String get connectedUsers;

  /// No description provided for @memoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Memory Breakdown'**
  String get memoryBreakdown;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @cached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cached;

  /// No description provided for @bufferLabel.
  ///
  /// In en, this message translates to:
  /// **'Buffer'**
  String get bufferLabel;

  /// No description provided for @diskInformation.
  ///
  /// In en, this message translates to:
  /// **'Disk Information'**
  String get diskInformation;

  /// No description provided for @driveN.
  ///
  /// In en, this message translates to:
  /// **'Drive {n}'**
  String driveN(int n);

  /// No description provided for @healthyStatus.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthyStatus;

  /// No description provided for @degraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get degraded;

  /// No description provided for @allStorageHealthy.
  ///
  /// In en, this message translates to:
  /// **'All storage pools and volumes are healthy.'**
  String get allStorageHealthy;

  /// No description provided for @storagePoolDegraded.
  ///
  /// In en, this message translates to:
  /// **'Issues have occurred to a Storage Pool. Please go to the Storage page for details.'**
  String get storagePoolDegraded;

  /// No description provided for @raidType.
  ///
  /// In en, this message translates to:
  /// **'RAID Type'**
  String get raidType;

  /// No description provided for @drives.
  ///
  /// In en, this message translates to:
  /// **'Drives'**
  String get drives;

  /// No description provided for @nDisks.
  ///
  /// In en, this message translates to:
  /// **'{count} disk(s)'**
  String nDisks(int count);

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @drive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get drive;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @noStoragePoolData.
  ///
  /// In en, this message translates to:
  /// **'No storage pool data available'**
  String get noStoragePoolData;

  /// No description provided for @noDiskInfo.
  ///
  /// In en, this message translates to:
  /// **'No disk information available'**
  String get noDiskInfo;

  /// No description provided for @systemGroup.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get systemGroup;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String membersCount(int count);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @usernameAndPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Username and password are required'**
  String get usernameAndPasswordRequired;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccessfully;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit \"{name}\"'**
  String editName(String name);

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password - {name}'**
  String changePasswordTitle(String name);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @userEnabled.
  ///
  /// In en, this message translates to:
  /// **'{name} enabled'**
  String userEnabled(String name);

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'{name} disabled'**
  String userDisabled(String name);

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User?'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete user \"{name}\"? This cannot be undone.'**
  String deleteUserMessage(String name);

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User \"{name}\" deleted'**
  String userDeleted(String name);

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequired;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get groupCreated;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated'**
  String get groupUpdated;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Group?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete group \"{name}\"?'**
  String deleteGroupMessage(String name);

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" deleted'**
  String groupDeleted(String name);

  /// No description provided for @membersOfGroup.
  ///
  /// In en, this message translates to:
  /// **'Members of \"{name}\"'**
  String membersOfGroup(String name);

  /// No description provided for @membersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Members updated'**
  String get membersUpdated;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @urban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get urban;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get chooseFolder;

  /// No description provided for @addTmdbKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Add TMDB key for movie covers'**
  String get addTmdbKeyHint;

  /// No description provided for @scanningMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'Scanning media files...'**
  String get scanningMediaFiles;

  /// No description provided for @newestFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Newest files from your library'**
  String get newestFilesSubtitle;

  /// No description provided for @allVideos.
  ///
  /// In en, this message translates to:
  /// **'All Videos'**
  String get allVideos;

  /// No description provided for @videosLabel.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosLabel;

  /// No description provided for @imagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesLabel;

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// No description provided for @foldersLabel.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersLabel;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'LATEST'**
  String get latest;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @selectMediaFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Media Folder'**
  String get selectMediaFolder;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @noSubfolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get noSubfolders;

  /// No description provided for @tapSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Select\" to use this folder'**
  String get tapSelectHint;

  /// No description provided for @nFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String nFiles(int count);

  /// No description provided for @nVideos.
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String nVideos(int count);

  /// No description provided for @nImages.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String nImages(int count);

  /// No description provided for @nTracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String nTracks(int count);

  /// No description provided for @sampleAlpineReflection.
  ///
  /// In en, this message translates to:
  /// **'Alpine Reflection'**
  String get sampleAlpineReflection;

  /// No description provided for @sampleEmeraldMorning.
  ///
  /// In en, this message translates to:
  /// **'Emerald Morning'**
  String get sampleEmeraldMorning;

  /// No description provided for @sampleNeonPulse.
  ///
  /// In en, this message translates to:
  /// **'Neon Pulse'**
  String get sampleNeonPulse;

  /// No description provided for @connectionLogs.
  ///
  /// In en, this message translates to:
  /// **'Connection Logs'**
  String get connectionLogs;

  /// No description provided for @cpuUsageBreakdown.
  ///
  /// In en, this message translates to:
  /// **'User: {userPct}%  ·  System: {systemPct}%'**
  String cpuUsageBreakdown(String userPct, String systemPct);

  /// No description provided for @memoryUsageDetail.
  ///
  /// In en, this message translates to:
  /// **'{usedMb} MB used / {totalMb} MB  ·  Cache: {cachedMb} MB'**
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb);

  /// No description provided for @driveHddDetail.
  ///
  /// In en, this message translates to:
  /// **'Drive {n} (HDD)  ·  {size}'**
  String driveHddDetail(int n, String size);

  /// No description provided for @storagePoolN.
  ///
  /// In en, this message translates to:
  /// **'Storage Pool {n}'**
  String storagePoolN(int n);

  /// No description provided for @volumeN.
  ///
  /// In en, this message translates to:
  /// **'Volume {n}'**
  String volumeN(int n);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @insufficientPermission.
  ///
  /// In en, this message translates to:
  /// **'Insufficient permission. Admin access required.'**
  String get insufficientPermission;

  /// No description provided for @invalidParameter.
  ///
  /// In en, this message translates to:
  /// **'Invalid parameter'**
  String get invalidParameter;

  /// No description provided for @accountIsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account is disabled'**
  String get accountIsDisabled;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @userGroupNotFound.
  ///
  /// In en, this message translates to:
  /// **'User/Group not found'**
  String get userGroupNotFound;

  /// No description provided for @nameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Name already exists'**
  String get nameAlreadyExists;

  /// No description provided for @operationFailedCode.
  ///
  /// In en, this message translates to:
  /// **'Operation failed (error {code})'**
  String operationFailedCode(int code);

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @albumsTab.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTab;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @sharedSpace.
  ///
  /// In en, this message translates to:
  /// **'Shared Space'**
  String get sharedSpace;

  /// No description provided for @personalSpace.
  ///
  /// In en, this message translates to:
  /// **'Personal Space'**
  String get personalSpace;

  /// No description provided for @searchPhotos.
  ///
  /// In en, this message translates to:
  /// **'Search photos...'**
  String get searchPhotos;

  /// No description provided for @addToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to Album'**
  String get addToAlbum;

  /// No description provided for @uploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}...'**
  String uploadingProgress(int current, int total);

  /// No description provided for @deletePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} item(s)?'**
  String deletePhotosTitle(int count);

  /// No description provided for @deletePhotosMessage.
  ///
  /// In en, this message translates to:
  /// **'These items will be permanently deleted. This cannot be undone.'**
  String get deletePhotosMessage;

  /// No description provided for @addedToAlbumN.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{name}\"'**
  String addedToAlbumN(String name);

  /// No description provided for @uploadedNPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} photo(s)'**
  String uploadedNPhotos(int count);

  /// No description provided for @createAlbum.
  ///
  /// In en, this message translates to:
  /// **'Create Album'**
  String get createAlbum;

  /// No description provided for @albumName.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get albumName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String photoCount(int count);

  /// No description provided for @photosApiHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure Synology Photos is installed and running on your NAS.'**
  String get photosApiHint;

  /// No description provided for @noPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'No Photos Yet'**
  String get noPhotosTitle;

  /// No description provided for @noPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload photos to your NAS or enable backup to get started.'**
  String get noPhotosSubtitle;

  /// No description provided for @uploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload Photos'**
  String get uploadPhotos;

  /// No description provided for @deleteAlbum.
  ///
  /// In en, this message translates to:
  /// **'Delete Album'**
  String get deleteAlbum;

  /// No description provided for @deleteAlbumMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete album \"{name}\"? Photos inside will not be deleted.'**
  String deleteAlbumMessage(String name);

  /// No description provided for @noAlbums.
  ///
  /// In en, this message translates to:
  /// **'No Albums'**
  String get noAlbums;

  /// No description provided for @createAlbumHint.
  ///
  /// In en, this message translates to:
  /// **'Create albums to organize your photos'**
  String get createAlbumHint;

  /// No description provided for @backupPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photo Backup'**
  String get backupPhotos;

  /// No description provided for @backupPhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload photos from your device to your NAS for safekeeping.'**
  String get backupPhotosDesc;

  /// No description provided for @manualUpload.
  ///
  /// In en, this message translates to:
  /// **'Manual Upload'**
  String get manualUpload;

  /// No description provided for @selectPhotosToUpload.
  ///
  /// In en, this message translates to:
  /// **'Select Photos to Upload'**
  String get selectPhotosToUpload;

  /// No description provided for @uploadToNasPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload to /photo/Upload on your NAS'**
  String get uploadToNasPhotos;

  /// No description provided for @backupInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Uploaded photos will be automatically indexed by Synology Photos and will appear in your timeline.'**
  String get backupInfoHint;

  /// No description provided for @noPhotosInAlbum.
  ///
  /// In en, this message translates to:
  /// **'No photos in this album'**
  String get noPhotosInAlbum;

  /// No description provided for @downloadLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Download link copied to clipboard'**
  String get downloadLinkCopied;

  /// No description provided for @photoInfo.
  ///
  /// In en, this message translates to:
  /// **'Photo Info'**
  String get photoInfo;

  /// No description provided for @filenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filenameLabel;

  /// No description provided for @takenOn.
  ///
  /// In en, this message translates to:
  /// **'Date Taken'**
  String get takenOn;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @downloadSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String downloadSavedTo(String path);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @uploadDestination.
  ///
  /// In en, this message translates to:
  /// **'Upload Destination'**
  String get uploadDestination;

  /// No description provided for @selectUploadDest.
  ///
  /// In en, this message translates to:
  /// **'Select Upload Folder'**
  String get selectUploadDest;

  /// No description provided for @selectMediaToUpload.
  ///
  /// In en, this message translates to:
  /// **'Select Photos & Videos'**
  String get selectMediaToUpload;

  /// No description provided for @uploadToNasDest.
  ///
  /// In en, this message translates to:
  /// **'Upload to {dest} on your NAS'**
  String uploadToNasDest(String dest);

  /// No description provided for @lastUploadResult.
  ///
  /// In en, this message translates to:
  /// **'Last upload: {count} file(s) uploaded successfully'**
  String lastUploadResult(int count);

  /// No description provided for @renameAlbum.
  ///
  /// In en, this message translates to:
  /// **'Rename Album'**
  String get renameAlbum;

  /// No description provided for @limitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Limited Access'**
  String get limitedAccess;

  /// No description provided for @limitedAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'System monitoring requires admin privileges. File Manager, Media Hub, and Photos are fully available.'**
  String get limitedAccessDesc;

  /// No description provided for @quota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get quota;

  /// No description provided for @quotaMB.
  ///
  /// In en, this message translates to:
  /// **'Quota (MB)'**
  String get quotaMB;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @sharePermissions.
  ///
  /// In en, this message translates to:
  /// **'Share Permissions'**
  String get sharePermissions;

  /// No description provided for @readWrite.
  ///
  /// In en, this message translates to:
  /// **'Read/Write'**
  String get readWrite;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnly;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'No Access'**
  String get noAccess;

  /// No description provided for @adminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin Only'**
  String get adminOnly;

  /// No description provided for @quotaUpdated.
  ///
  /// In en, this message translates to:
  /// **'Quota updated'**
  String get quotaUpdated;

  /// No description provided for @permissionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Permission updated'**
  String get permissionUpdated;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumFeature;

  /// No description provided for @premiumFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Media Hub and Photos are premium features available to VIP members. Contact the developer to upgrade your account.'**
  String get premiumFeatureDesc;

  /// No description provided for @vipMember.
  ///
  /// In en, this message translates to:
  /// **'VIP Member'**
  String get vipMember;

  /// No description provided for @freeUser.
  ///
  /// In en, this message translates to:
  /// **'Free User'**
  String get freeUser;

  /// No description provided for @otpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get otpDialogTitle;

  /// No description provided for @otpDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your NAS requires a verification code. Enter the 6-digit code from your authenticator app.'**
  String get otpDialogMessage;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @quickConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'QuickConnect resolution failed'**
  String get quickConnectFailed;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get downloading;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'fr',
    'ja',
    'pt',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

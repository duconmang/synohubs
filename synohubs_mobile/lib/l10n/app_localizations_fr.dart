// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Gestion Synology NAS';

  @override
  String get connecting => 'Connexion...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get signInPrivacyNote =>
      'Vos données restent sur votre appareil.\nLe compte Google est utilisé uniquement pour l\'identité\net la sauvegarde optionnelle sur Google Drive.';

  @override
  String get signInCancelled => 'Connexion annulée';

  @override
  String signInFailed(String error) {
    return 'Échec de connexion : $error';
  }

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get noDataStoredOnServers =>
      'Aucune donnée n\'est stockée sur nos serveurs';

  @override
  String get nasAddress => 'ADRESSE NAS';

  @override
  String get ipOrHostname => 'IP ou nom d\'hôte';

  @override
  String get port => 'Port';

  @override
  String get protocol => 'PROTOCOLE';

  @override
  String get usernameLabel => 'NOM D\'UTILISATEUR';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'MOT DE PASSE';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => 'Tous les champs sont requis';

  @override
  String get invalidPortNumber => 'Numéro de port invalide';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get connect => 'Connecter';

  @override
  String get myNas => 'Mon NAS';

  @override
  String get addNas => 'Ajouter un NAS';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get noNasTitle => 'Aucun NAS ajouté';

  @override
  String get noNasSubtitle =>
      'Appuyez sur \"Ajouter un NAS\" pour connecter\nvotre Synology NAS';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils',
      one: '1 appareil',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => 'Sauvegarder sur Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Restaurer depuis Google Drive';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get backingUp => 'Sauvegarde sur Google Drive...';

  @override
  String get backupSuccessful => 'Sauvegarde réussie';

  @override
  String backupFailed(String error) {
    return 'Échec de sauvegarde : $error';
  }

  @override
  String get restoringFromDrive => 'Restauration depuis Google Drive...';

  @override
  String get restoreSuccessful => 'Restauration réussie';

  @override
  String restoreFailed(String error) {
    return 'Échec de restauration : $error';
  }

  @override
  String get noBackupFound => 'Aucune sauvegarde trouvée sur Google Drive';

  @override
  String get nameThisNas => 'Nommer ce NAS';

  @override
  String get nasNicknameHint => 'ex. NAS Maison, NAS Bureau';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get ok => 'OK';

  @override
  String get rename => 'Renommer';

  @override
  String get details => 'Détails';

  @override
  String get remove => 'Supprimer';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get host => 'Hôte';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get model => 'Modèle';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => 'Dernière connexion';

  @override
  String get removeNasTitle => 'Supprimer le NAS';

  @override
  String removeNasMessage(String name) {
    return 'Supprimer \"$name\" de votre liste ?';
  }

  @override
  String get nasRemoved => 'NAS supprimé';

  @override
  String get language => 'Langue';

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
  String get dashboard => 'Tableau de bord';

  @override
  String get files => 'Fichiers';

  @override
  String get media => 'Médias';

  @override
  String get photos => 'Photos';

  @override
  String get healthy => 'SAIN';

  @override
  String get dsmVersion => 'VERSION DSM';

  @override
  String get uptime => 'TEMPS ACTIF';

  @override
  String get lanIp => 'IP LAN';

  @override
  String get serial => 'SÉRIE';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => 'SERVICES';

  @override
  String get cpuTemp => 'TEMP CPU';

  @override
  String get disks => 'DISQUES';

  @override
  String get resourceMonitor => 'Moniteur de ressources';

  @override
  String get storageAndVolumes => 'Stockage et volumes';

  @override
  String get storageCapacity => 'CAPACITÉ DE STOCKAGE';

  @override
  String get diskHealth => 'Santé des disques';

  @override
  String bayN(int n) {
    return 'Baie $n';
  }

  @override
  String get normal => 'Normal';

  @override
  String get installedPackages => 'Paquets installés';

  @override
  String get running => 'En cours';

  @override
  String get stopped => 'Arrêté';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get resourceMonitorAction => 'Moniteur\nRessources';

  @override
  String get storageManagerAction => 'Gestionnaire\nStockage';

  @override
  String get logCenterAction => 'Centre\nJournaux';

  @override
  String get restart => 'Redémarrer';

  @override
  String get shutdown => 'Éteindre';

  @override
  String get refresh => 'Actualiser';

  @override
  String confirmActionTitle(String action) {
    return '$action le NAS ?';
  }

  @override
  String confirmActionMessage(String action) {
    return 'Êtes-vous sûr de vouloir $action votre NAS ?';
  }

  @override
  String get fileManager => 'Gestionnaire de fichiers';

  @override
  String get notConnected => 'Non connecté';

  @override
  String errorCode(String code) {
    return 'Erreur $code';
  }

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get folderName => 'Nom du dossier';

  @override
  String get newName => 'Nouveau nom';

  @override
  String get failedToCreateFolder => 'Échec de création du dossier';

  @override
  String get failedToRename => 'Échec du renommage';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return 'Supprimer $count élément$suffix ?';
  }

  @override
  String get cannotBeUndone => 'Cette action est irréversible.';

  @override
  String failedToDelete(String name) {
    return 'Échec de suppression : $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return '$action $count élément$suffix';
  }

  @override
  String get copied => 'Copié';

  @override
  String get cut => 'Coupé';

  @override
  String failedToCopyMove(String action) {
    return 'Échec de $action';
  }

  @override
  String get shareLinkCopied => 'Lien de partage copié !';

  @override
  String get couldNotGenerateLink => 'Impossible de générer le lien';

  @override
  String get failedToCreateShareLink => 'Échec de création du lien de partage';

  @override
  String couldNotReadFile(String name) {
    return 'Impossible de lire le fichier : $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return '$count fichier$suffix envoyé$suffix';
  }

  @override
  String failedError(String error) {
    return 'Échec : $error';
  }

  @override
  String get copy => 'Copier';

  @override
  String get shareLink => 'Partager le lien';

  @override
  String get qrCode => 'Code QR';

  @override
  String nSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get searchFiles => 'Rechercher des fichiers...';

  @override
  String searchInFolder(String folder) {
    return 'Rechercher dans $folder...';
  }

  @override
  String get searchFailed => 'Échec de la recherche';

  @override
  String get noResultsFound => 'Aucun résultat';

  @override
  String get emptyFolder => 'Dossier vide';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortBySize => 'Taille';

  @override
  String get sortByDate => 'Date de modification';

  @override
  String get sortByType => 'Type';

  @override
  String get listView => 'Vue liste';

  @override
  String get gridView => 'Vue grille';

  @override
  String get root => 'Racine';

  @override
  String get clipboardMove => 'Presse-papiers : déplacer';

  @override
  String get clipboardCopy => 'Presse-papiers : copier';

  @override
  String get pasteHere => 'Coller ici';

  @override
  String get linkCopied => 'Lien copié !';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get couldNotGenerateShareLink =>
      'Impossible de générer le lien de partage';

  @override
  String get sort => 'Trier';

  @override
  String get mediaHub => 'Centre multimédia';

  @override
  String get selectFolderDescription =>
      'Sélectionnez un dossier sur votre NAS pour scanner et parcourir les fichiers multimédia';

  @override
  String get selectFolder => 'Sélectionner un dossier';

  @override
  String get startingScan => 'Début du scan...';

  @override
  String scanningFolder(String name) {
    return 'Scan en cours : $name';
  }

  @override
  String mediaFilesFound(int count) {
    return '$count fichiers multimédia trouvés';
  }

  @override
  String get tmdbApiKey => 'Clé API TMDB';

  @override
  String get tmdbApiKeyInstructions =>
      'Utilisez la \"API Key (v3 auth)\" de vos paramètres TMDB — PAS le Read Access Token.';

  @override
  String get tmdbApiKeyHelp =>
      'Obtenez une clé gratuite sur themoviedb.org/settings/api';

  @override
  String get tmdbApiKeyHint => 'Collez la clé API (v3) ici';

  @override
  String get changeFolder => 'Changer de dossier';

  @override
  String get tmdbKeyConfigured => 'Clé TMDB configurée ✓';

  @override
  String get setTmdbApiKey => 'Configurer la clé API TMDB';

  @override
  String get rescanFolder => 'Re-scanner le dossier';

  @override
  String get chooseMediaFolder => 'Choisir un dossier multimédia';

  @override
  String get allMedia => 'Tous les médias';

  @override
  String get recentlyAdded => 'Ajoutés récemment';

  @override
  String get filters => 'Filtres';

  @override
  String get allPhotos => 'Toutes les photos';

  @override
  String get favorites => 'Favoris';

  @override
  String get recent => 'Récent';

  @override
  String get hidden => 'Masqué';

  @override
  String get recentlyAddedPhotos => 'AJOUTÉS RÉCEMMENT';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get myAlbums => 'MES ALBUMS';

  @override
  String get family => 'Famille';

  @override
  String get travel => 'Voyage';

  @override
  String get workAndProjects => 'Travail et projets';

  @override
  String itemsCount(String count) {
    return '$count éléments';
  }

  @override
  String get logCenter => 'Centre de journaux';

  @override
  String get overview => 'Aperçu';

  @override
  String get logs => 'Journaux';

  @override
  String get connections => 'Connexions';

  @override
  String get totalLogs => 'Total des journaux';

  @override
  String get info => 'Info';

  @override
  String get warnings => 'Avertissements';

  @override
  String get errors => 'Erreurs';

  @override
  String lastNLogs(int count) {
    return '$count derniers journaux';
  }

  @override
  String get noLogsAvailable => 'Aucun journal disponible';

  @override
  String get systemLogs => 'Journaux système';

  @override
  String nItems(int count) {
    return '$count éléments';
  }

  @override
  String get level => 'Niveau';

  @override
  String get time => 'Heure';

  @override
  String get user => 'Utilisateur';

  @override
  String get event => 'Événement';

  @override
  String get noConnectionLogs => 'Aucun journal de connexion';

  @override
  String get type => 'Type';

  @override
  String get ip => 'IP';

  @override
  String get date => 'Date';

  @override
  String get performance => 'Performance';

  @override
  String get details_tab => 'Détails';

  @override
  String get utilization => 'Utilisation (%)';

  @override
  String get memory => 'Mémoire';

  @override
  String get network => 'Réseau';

  @override
  String get diskIO => 'E/S disque';

  @override
  String get download => 'Téléchargement';

  @override
  String get upload => 'Envoi';

  @override
  String get read => 'Lecture';

  @override
  String get write => 'Écriture';

  @override
  String get activeConnections => 'Connexions actives';

  @override
  String get processId => 'PID';

  @override
  String get process => 'Processus';

  @override
  String get systemDetails => 'Détails système';

  @override
  String get cpuModel => 'Modèle CPU';

  @override
  String get cpuCores => 'Cœurs CPU';

  @override
  String get totalRam => 'RAM totale';

  @override
  String get temperature => 'Température';

  @override
  String get systemTime => 'Heure système';

  @override
  String get storageManager => 'Gestionnaire de stockage';

  @override
  String get storage => 'Stockage';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => 'Santé du système';

  @override
  String get totalStorage => 'Stockage total';

  @override
  String get used => 'Utilisé';

  @override
  String get available => 'Disponible';

  @override
  String get volumeUsage => 'Utilisation des volumes';

  @override
  String get critical => 'Critique';

  @override
  String get usageExceedsThreshold => 'Utilisation supérieure à 90 %';

  @override
  String get storageHealthy => 'Stockage sain';

  @override
  String get driveInformation => 'Informations du disque';

  @override
  String get status => 'Statut';

  @override
  String get capacity => 'Capacité';

  @override
  String get diskTemperature => 'Température du disque';

  @override
  String get userAndGroup => 'Utilisateurs et groupes';

  @override
  String get users => 'Utilisateurs';

  @override
  String get groups => 'Groupes';

  @override
  String get allUsers => 'Tous les utilisateurs';

  @override
  String nUsers(int count) {
    return '$count utilisateurs';
  }

  @override
  String get admin => 'ADMIN';

  @override
  String get active => 'Actif';

  @override
  String get disabled => 'Désactivé';

  @override
  String get allGroups => 'Tous les groupes';

  @override
  String nGroups(int count) {
    return '$count groupes';
  }

  @override
  String get members => 'Membres';

  @override
  String get noUsers => 'Aucun utilisateur trouvé';

  @override
  String get noGroups => 'Aucun groupe trouvé';

  @override
  String get loadingVideo => 'Chargement de la vidéo...';

  @override
  String get failedToPlayVideo => 'Échec de lecture de la vidéo';

  @override
  String get settings => 'Paramètres';

  @override
  String get nasConnection => 'Connexion NAS';

  @override
  String get connection => 'Connexion';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeAndColors => 'Thème et couleurs';

  @override
  String get darkCyanAccent => 'Sombre • Accent cyan';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get systemAlerts => 'Alertes système';

  @override
  String get backupAlerts => 'Alertes de sauvegarde';

  @override
  String get storageWarnings => 'Alertes de stockage';

  @override
  String get about => 'À propos';

  @override
  String get aboutSynoHub => 'À propos de SynoHub';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get upToDate => 'À jour';

  @override
  String get theme => 'THÈME';

  @override
  String get dark => 'Sombre';

  @override
  String get light => 'Clair';

  @override
  String get system => 'Système';

  @override
  String get accentColor => 'COULEUR D\'ACCENT';

  @override
  String get cyan => 'Cyan';

  @override
  String get teal => 'Sarcelle';

  @override
  String get gold => 'Or';

  @override
  String get purple => 'Violet';

  @override
  String get preview => 'APERÇU';

  @override
  String get accentColorPreview => 'Aperçu de la couleur d\'accent';

  @override
  String get connectionSettings => 'Connexion';

  @override
  String get server => 'SERVEUR';

  @override
  String get nasAddressSetting => 'Adresse NAS';

  @override
  String get ipHostnameOrQuickConnect => 'IP, nom d\'hôte ou QuickConnect ID';

  @override
  String get portLabel => 'Port';

  @override
  String get protocolLabel => 'PROTOCOLE';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => 'COMPTE';

  @override
  String get password => 'Mot de passe';

  @override
  String get rememberLogin => 'Se souvenir de la connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get connectedNas => 'NAS CONNECTÉ';

  @override
  String get dsmVersionLabel => 'Version DSM';

  @override
  String get serialNumber => 'Numéro de série';

  @override
  String get application => 'APPLICATION';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get sourceCode => 'Code source';

  @override
  String get madeWithFlutter => 'Fait avec ❤ Flutter';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => 'Aucune connexion active';

  @override
  String get connectedUsers => 'Utilisateurs connectés';

  @override
  String get memoryBreakdown => 'Détail de la mémoire';

  @override
  String get total => 'Total';

  @override
  String get cached => 'En cache';

  @override
  String get bufferLabel => 'Tampon';

  @override
  String get diskInformation => 'Informations du disque';

  @override
  String driveN(int n) {
    return 'Disque $n';
  }

  @override
  String get healthyStatus => 'Sain';

  @override
  String get degraded => 'Dégradé';

  @override
  String get allStorageHealthy =>
      'Tous les pools de stockage et volumes sont sains.';

  @override
  String get storagePoolDegraded =>
      'Des problèmes sont survenus dans un pool de stockage. Consultez la page Stockage pour plus de détails.';

  @override
  String get raidType => 'Type RAID';

  @override
  String get drives => 'Disques';

  @override
  String nDisks(int count) {
    return '$count disque(s)';
  }

  @override
  String get device => 'Appareil';

  @override
  String get drive => 'Disque';

  @override
  String get size => 'Taille';

  @override
  String get noStoragePoolData => 'Aucune donnée de pool de stockage';

  @override
  String get noDiskInfo => 'Aucune information sur les disques';

  @override
  String get systemGroup => 'SYSTÈME';

  @override
  String get noMembers => 'Aucun membre';

  @override
  String membersCount(int count) {
    return 'Membres ($count)';
  }

  @override
  String get manage => 'Gérer';

  @override
  String get createUser => 'Créer un utilisateur';

  @override
  String get email => 'E-mail';

  @override
  String get description => 'Description';

  @override
  String get usernameAndPasswordRequired =>
      'Le nom d\'utilisateur et le mot de passe sont requis';

  @override
  String get userCreatedSuccessfully => 'Utilisateur créé avec succès';

  @override
  String editName(String name) {
    return 'Modifier \"$name\"';
  }

  @override
  String get userUpdated => 'Utilisateur mis à jour';

  @override
  String changePasswordTitle(String name) {
    return 'Changer le mot de passe - $name';
  }

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordCannotBeEmpty => 'Le mot de passe ne peut pas être vide';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordChanged => 'Mot de passe modifié';

  @override
  String userEnabled(String name) {
    return '$name activé';
  }

  @override
  String userDisabled(String name) {
    return '$name désactivé';
  }

  @override
  String get deleteUserTitle => 'Supprimer l\'utilisateur ?';

  @override
  String deleteUserMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer l\'utilisateur \"$name\" ? Cette action est irréversible.';
  }

  @override
  String userDeleted(String name) {
    return 'Utilisateur \"$name\" supprimé';
  }

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get groupNameRequired => 'Le nom du groupe est requis';

  @override
  String get groupCreated => 'Groupe créé';

  @override
  String get groupUpdated => 'Groupe mis à jour';

  @override
  String get deleteGroupTitle => 'Supprimer le groupe ?';

  @override
  String deleteGroupMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer le groupe \"$name\" ?';
  }

  @override
  String groupDeleted(String name) {
    return 'Groupe \"$name\" supprimé';
  }

  @override
  String membersOfGroup(String name) {
    return 'Membres de \"$name\"';
  }

  @override
  String get membersUpdated => 'Membres mis à jour';

  @override
  String get edit => 'Modifier';

  @override
  String get enable => 'Activer';

  @override
  String get disable => 'Désactiver';

  @override
  String get confirm => 'Confirmer';

  @override
  String get statusLabel => 'Statut';

  @override
  String get connected => 'Connecté';

  @override
  String get nature => 'Nature';

  @override
  String get urban => 'Urbain';

  @override
  String get chooseFolder => 'Choisir un dossier';

  @override
  String get addTmdbKeyHint =>
      'Ajouter une clé TMDB pour les affiches de films';

  @override
  String get scanningMediaFiles => 'Analyse des fichiers multimédias...';

  @override
  String get newestFilesSubtitle =>
      'Les fichiers les plus récents de votre bibliothèque';

  @override
  String get allVideos => 'Toutes les vidéos';

  @override
  String get videosLabel => 'Vidéos';

  @override
  String get imagesLabel => 'Images';

  @override
  String get audioLabel => 'Audio';

  @override
  String get foldersLabel => 'Dossiers';

  @override
  String get latest => 'RÉCENT';

  @override
  String get play => 'Lire';

  @override
  String get change => 'Changer';

  @override
  String get selectMediaFolder => 'Sélectionner un dossier multimédia';

  @override
  String get select => 'Sélectionner';

  @override
  String get noSubfolders => 'Aucun sous-dossier';

  @override
  String get tapSelectHint =>
      'Appuyez sur \"Sélectionner\" pour utiliser ce dossier';

  @override
  String nFiles(int count) {
    return '$count fichiers';
  }

  @override
  String nVideos(int count) {
    return '$count vidéos';
  }

  @override
  String nImages(int count) {
    return '$count images';
  }

  @override
  String nTracks(int count) {
    return '$count pistes';
  }

  @override
  String get sampleAlpineReflection => 'Reflet alpin';

  @override
  String get sampleEmeraldMorning => 'Matin émeraude';

  @override
  String get sampleNeonPulse => 'Pulsion néon';

  @override
  String get connectionLogs => 'Journaux de connexion';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return 'Utilisateur : $userPct %  ·  Système : $systemPct %';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '$usedMb Mo utilisés / $totalMb Mo  ·  Cache : $cachedMb Mo';
  }

  @override
  String driveHddDetail(int n, String size) {
    return 'Disque $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return 'Pool de stockage $n';
  }

  @override
  String volumeN(int n) {
    return 'Volume $n';
  }

  @override
  String get unknown => 'Inconnu';

  @override
  String get insufficientPermission =>
      'Autorisation insuffisante. Accès administrateur requis.';

  @override
  String get invalidParameter => 'Paramètre invalide';

  @override
  String get accountIsDisabled => 'Le compte est désactivé';

  @override
  String get permissionDenied => 'Accès refusé';

  @override
  String get userGroupNotFound => 'Utilisateur/Groupe introuvable';

  @override
  String get nameAlreadyExists => 'Le nom existe déjà';

  @override
  String operationFailedCode(int code) {
    return 'Opération échouée (erreur $code)';
  }

  @override
  String get notAvailable => 'N/D';

  @override
  String get timeline => 'Chronologie';

  @override
  String get albumsTab => 'Albums';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get sharedSpace => 'Espace partagé';

  @override
  String get personalSpace => 'Espace personnel';

  @override
  String get searchPhotos => 'Rechercher des photos...';

  @override
  String get addToAlbum => 'Ajouter à l\'album';

  @override
  String uploadingProgress(int current, int total) {
    return 'Téléversement $current/$total...';
  }

  @override
  String deletePhotosTitle(int count) {
    return 'Supprimer $count élément(s) ?';
  }

  @override
  String get deletePhotosMessage =>
      'Ces éléments seront supprimés définitivement. Cette action est irréversible.';

  @override
  String addedToAlbumN(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String uploadedNPhotos(int count) {
    return '$count photo(s) téléversée(s)';
  }

  @override
  String get createAlbum => 'Créer un album';

  @override
  String get albumName => 'Nom de l\'album';

  @override
  String get create => 'Créer';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String photoCount(int count) {
    return '$count photos';
  }

  @override
  String get photosApiHint =>
      'Assurez-vous que Synology Photos est installé et en cours d\'exécution sur votre NAS.';

  @override
  String get noPhotosTitle => 'Aucune photo';

  @override
  String get noPhotosSubtitle =>
      'Téléversez des photos sur votre NAS ou activez la sauvegarde pour commencer.';

  @override
  String get uploadPhotos => 'Téléverser des photos';

  @override
  String get deleteAlbum => 'Supprimer l\'album';

  @override
  String deleteAlbumMessage(String name) {
    return 'Supprimer l\'album « $name » ? Les photos qu\'il contient ne seront pas supprimées.';
  }

  @override
  String get noAlbums => 'Aucun album';

  @override
  String get createAlbumHint => 'Créez des albums pour organiser vos photos';

  @override
  String get backupPhotos => 'Sauvegarde photos';

  @override
  String get backupPhotosDesc =>
      'Téléversez les photos de votre appareil vers votre NAS pour les sauvegarder.';

  @override
  String get manualUpload => 'Téléversement manuel';

  @override
  String get selectPhotosToUpload => 'Sélectionner des photos à téléverser';

  @override
  String get uploadToNasPhotos => 'Téléverser vers /photo/Upload sur votre NAS';

  @override
  String get backupInfoHint =>
      'Les photos téléversées seront automatiquement indexées par Synology Photos et apparaîtront dans votre chronologie.';

  @override
  String get noPhotosInAlbum => 'Aucune photo dans cet album';

  @override
  String get downloadLinkCopied =>
      'Lien de téléchargement copié dans le presse-papiers';

  @override
  String get photoInfo => 'Infos de la photo';

  @override
  String get filenameLabel => 'Nom du fichier';

  @override
  String get takenOn => 'Date de prise de vue';

  @override
  String get resolution => 'Résolution';

  @override
  String get fileSize => 'Taille du fichier';

  @override
  String get video => 'Vidéo';

  @override
  String get photo => 'Photo';

  @override
  String downloadSavedTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get uploadDestination => 'Destination de l\'envoi';

  @override
  String get selectUploadDest => 'Sélectionner le dossier';

  @override
  String get selectMediaToUpload => 'Sélectionner photos et vidéos';

  @override
  String uploadToNasDest(String dest) {
    return 'Envoyer vers $dest sur votre NAS';
  }

  @override
  String lastUploadResult(int count) {
    return 'Dernier envoi : $count fichier(s) envoyé(s)';
  }

  @override
  String get renameAlbum => 'Renommer l\'album';

  @override
  String get limitedAccess => 'Accès limité';

  @override
  String get limitedAccessDesc =>
      'La surveillance système nécessite des privilèges admin. Le gestionnaire de fichiers, Media Hub et Photos sont entièrement disponibles.';

  @override
  String get quota => 'Quota';

  @override
  String get quotaMB => 'Quota (Mo)';

  @override
  String get unlimited => 'Illimité';

  @override
  String get sharePermissions => 'Permissions de partage';

  @override
  String get readWrite => 'Lecture/Écriture';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get noAccess => 'Aucun accès';

  @override
  String get adminOnly => 'Admin uniquement';

  @override
  String get quotaUpdated => 'Quota mis à jour';

  @override
  String get permissionUpdated => 'Permission mise à jour';

  @override
  String get premiumFeature => 'Fonctionnalité Premium';

  @override
  String get premiumFeatureDesc =>
      'Media Hub et Photos sont des fonctionnalités premium réservées aux membres VIP. Contactez le développeur pour mettre à niveau votre compte.';

  @override
  String get vipMember => 'Membre VIP';

  @override
  String get freeUser => 'Utilisateur gratuit';

  @override
  String get otpDialogTitle => 'Authentification à deux facteurs';

  @override
  String get otpDialogMessage =>
      'Votre NAS nécessite un code de vérification. Entrez le code à 6 chiffres de votre application d\'authentification.';

  @override
  String get verify => 'Vérifier';

  @override
  String get quickConnectFailed => 'Échec de la résolution QuickConnect';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get whatsNew => 'Nouveautés';

  @override
  String get later => 'Plus tard';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get downloading => 'Téléchargement de la mise à jour...';

  @override
  String get updateFailed => 'Échec de la mise à jour';
}

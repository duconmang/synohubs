// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Gerenciamento Synology NAS';

  @override
  String get connecting => 'Conectando...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => 'Faça login para continuar';

  @override
  String get signInPrivacyNote =>
      'Seus dados ficam no seu dispositivo.\nA conta Google é usada apenas para identidade\ne backup opcional no Google Drive.';

  @override
  String get signInCancelled => 'Login cancelado';

  @override
  String signInFailed(String error) {
    return 'Falha no login: $error';
  }

  @override
  String get signInWithGoogle => 'Entrar com Google';

  @override
  String get noDataStoredOnServers =>
      'Nenhum dado é armazenado em nossos servidores';

  @override
  String get nasAddress => 'ENDEREÇO NAS';

  @override
  String get ipOrHostname => 'IP ou nome do host';

  @override
  String get port => 'Porta';

  @override
  String get protocol => 'PROTOCOLO';

  @override
  String get usernameLabel => 'USUÁRIO';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'SENHA';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => 'Todos os campos são obrigatórios';

  @override
  String get invalidPortNumber => 'Número de porta inválido';

  @override
  String get rememberMe => 'Lembrar-me';

  @override
  String get connect => 'Conectar';

  @override
  String get myNas => 'Meu NAS';

  @override
  String get addNas => 'Adicionar NAS';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get noNasTitle => 'Nenhum NAS Adicionado';

  @override
  String get noNasSubtitle =>
      'Toque em \"Adicionar NAS\" para conectar\nseu Synology NAS';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos',
      one: '1 dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => 'Backup no Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Restaurar do Google Drive';

  @override
  String get signOut => 'Sair';

  @override
  String get backingUp => 'Fazendo backup no Google Drive...';

  @override
  String get backupSuccessful => 'Backup realizado com sucesso';

  @override
  String backupFailed(String error) {
    return 'Falha no backup: $error';
  }

  @override
  String get restoringFromDrive => 'Restaurando do Google Drive...';

  @override
  String get restoreSuccessful => 'Restauração bem-sucedida';

  @override
  String restoreFailed(String error) {
    return 'Falha na restauração: $error';
  }

  @override
  String get noBackupFound => 'Nenhum backup encontrado no Google Drive';

  @override
  String get nameThisNas => 'Nomear este NAS';

  @override
  String get nasNicknameHint => 'ex. NAS Casa, NAS Escritório';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get ok => 'OK';

  @override
  String get rename => 'Renomear';

  @override
  String get details => 'Detalhes';

  @override
  String get remove => 'Remover';

  @override
  String get delete => 'Excluir';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get host => 'Host';

  @override
  String get username => 'Usuário';

  @override
  String get model => 'Modelo';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => 'Última conexão';

  @override
  String get removeNasTitle => 'Remover NAS';

  @override
  String removeNasMessage(String name) {
    return 'Remover \"$name\" da sua lista?';
  }

  @override
  String get nasRemoved => 'NAS removido';

  @override
  String get language => 'Idioma';

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
  String get dashboard => 'Painel';

  @override
  String get files => 'Arquivos';

  @override
  String get media => 'Mídia';

  @override
  String get photos => 'Fotos';

  @override
  String get healthy => 'SAUDÁVEL';

  @override
  String get dsmVersion => 'VERSÃO DSM';

  @override
  String get uptime => 'TEMPO ATIVO';

  @override
  String get lanIp => 'IP LAN';

  @override
  String get serial => 'SERIAL';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => 'SERVIÇOS';

  @override
  String get cpuTemp => 'TEMP CPU';

  @override
  String get disks => 'DISCOS';

  @override
  String get resourceMonitor => 'Monitor de Recursos';

  @override
  String get storageAndVolumes => 'Armazenamento e Volumes';

  @override
  String get storageCapacity => 'CAPACIDADE DE ARMAZENAMENTO';

  @override
  String get diskHealth => 'Saúde do Disco';

  @override
  String bayN(int n) {
    return 'Baia $n';
  }

  @override
  String get normal => 'Normal';

  @override
  String get installedPackages => 'Pacotes Instalados';

  @override
  String get running => 'Em execução';

  @override
  String get stopped => 'Parado';

  @override
  String get quickActions => 'Ações Rápidas';

  @override
  String get resourceMonitorAction => 'Monitor\nRecursos';

  @override
  String get storageManagerAction => 'Gerenciador\nArmazenamento';

  @override
  String get logCenterAction => 'Centro\nde Logs';

  @override
  String get restart => 'Reiniciar';

  @override
  String get shutdown => 'Desligar';

  @override
  String get refresh => 'Atualizar';

  @override
  String confirmActionTitle(String action) {
    return '$action NAS?';
  }

  @override
  String confirmActionMessage(String action) {
    return 'Tem certeza de que deseja $action seu NAS?';
  }

  @override
  String get fileManager => 'Gerenciador de Arquivos';

  @override
  String get notConnected => 'Não conectado';

  @override
  String errorCode(String code) {
    return 'Erro $code';
  }

  @override
  String get newFolder => 'Nova Pasta';

  @override
  String get folderName => 'Nome da pasta';

  @override
  String get newName => 'Novo nome';

  @override
  String get failedToCreateFolder => 'Falha ao criar pasta';

  @override
  String get failedToRename => 'Falha ao renomear';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return 'Excluir $count item$suffix?';
  }

  @override
  String get cannotBeUndone => 'Esta ação não pode ser desfeita.';

  @override
  String failedToDelete(String name) {
    return 'Falha ao excluir: $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return '$action $count item$suffix';
  }

  @override
  String get copied => 'Copiado';

  @override
  String get cut => 'Recortado';

  @override
  String failedToCopyMove(String action) {
    return 'Falha ao $action';
  }

  @override
  String get shareLinkCopied => 'Link de compartilhamento copiado!';

  @override
  String get couldNotGenerateLink => 'Não foi possível gerar o link';

  @override
  String get failedToCreateShareLink =>
      'Falha ao criar link de compartilhamento';

  @override
  String couldNotReadFile(String name) {
    return 'Não foi possível ler o arquivo: $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return '$count arquivo$suffix enviado$suffix';
  }

  @override
  String failedError(String error) {
    return 'Falha: $error';
  }

  @override
  String get copy => 'Copiar';

  @override
  String get shareLink => 'Compartilhar Link';

  @override
  String get qrCode => 'Código QR';

  @override
  String nSelected(int count) {
    return '$count selecionado(s)';
  }

  @override
  String get searchFiles => 'Buscar arquivos...';

  @override
  String searchInFolder(String folder) {
    return 'Buscar em $folder...';
  }

  @override
  String get searchFailed => 'Falha na busca';

  @override
  String get noResultsFound => 'Nenhum resultado encontrado';

  @override
  String get emptyFolder => 'Pasta vazia';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortBySize => 'Tamanho';

  @override
  String get sortByDate => 'Data de modificação';

  @override
  String get sortByType => 'Tipo';

  @override
  String get listView => 'Visualização em lista';

  @override
  String get gridView => 'Visualização em grade';

  @override
  String get root => 'Raiz';

  @override
  String get clipboardMove => 'Área de transferência: mover';

  @override
  String get clipboardCopy => 'Área de transferência: copiar';

  @override
  String get pasteHere => 'Colar Aqui';

  @override
  String get linkCopied => 'Link copiado!';

  @override
  String get copyLink => 'Copiar Link';

  @override
  String get couldNotGenerateShareLink =>
      'Não foi possível gerar link de compartilhamento';

  @override
  String get sort => 'Ordenar';

  @override
  String get mediaHub => 'Central de Mídia';

  @override
  String get selectFolderDescription =>
      'Selecione uma pasta no NAS para escanear e navegar em arquivos de mídia';

  @override
  String get selectFolder => 'Selecionar Pasta';

  @override
  String get startingScan => 'Iniciando escaneamento...';

  @override
  String scanningFolder(String name) {
    return 'Escaneando: $name';
  }

  @override
  String mediaFilesFound(int count) {
    return '$count arquivos de mídia encontrados';
  }

  @override
  String get tmdbApiKey => 'Chave API TMDB';

  @override
  String get tmdbApiKeyInstructions =>
      'Use a \"API Key (v3 auth)\" das configurações da sua conta TMDB — NÃO o Read Access Token.';

  @override
  String get tmdbApiKeyHelp =>
      'Obtenha uma chave gratuita em themoviedb.org/settings/api';

  @override
  String get tmdbApiKeyHint => 'Cole a API Key (v3) aqui';

  @override
  String get changeFolder => 'Alterar pasta';

  @override
  String get tmdbKeyConfigured => 'Chave TMDB configurada ✓';

  @override
  String get setTmdbApiKey => 'Configurar chave API TMDB';

  @override
  String get rescanFolder => 'Re-escanear pasta';

  @override
  String get chooseMediaFolder => 'Escolher pasta de mídia';

  @override
  String get allMedia => 'Todas as Mídias';

  @override
  String get recentlyAdded => 'Adicionados Recentemente';

  @override
  String get filters => 'Filtros';

  @override
  String get allPhotos => 'Todas as Fotos';

  @override
  String get favorites => 'Favoritos';

  @override
  String get recent => 'Recentes';

  @override
  String get hidden => 'Ocultos';

  @override
  String get recentlyAddedPhotos => 'ADICIONADOS RECENTEMENTE';

  @override
  String get viewAll => 'Ver tudo';

  @override
  String get myAlbums => 'MEUS ÁLBUNS';

  @override
  String get family => 'Família';

  @override
  String get travel => 'Viagem';

  @override
  String get workAndProjects => 'Trabalho e Projetos';

  @override
  String itemsCount(String count) {
    return '$count itens';
  }

  @override
  String get logCenter => 'Centro de Logs';

  @override
  String get overview => 'Visão geral';

  @override
  String get logs => 'Logs';

  @override
  String get connections => 'Conexões';

  @override
  String get totalLogs => 'Total de Logs';

  @override
  String get info => 'Info';

  @override
  String get warnings => 'Avisos';

  @override
  String get errors => 'Erros';

  @override
  String lastNLogs(int count) {
    return 'Últimos $count logs';
  }

  @override
  String get noLogsAvailable => 'Nenhum log disponível';

  @override
  String get systemLogs => 'Logs do Sistema';

  @override
  String nItems(int count) {
    return '$count itens';
  }

  @override
  String get level => 'Nível';

  @override
  String get time => 'Hora';

  @override
  String get user => 'Usuário';

  @override
  String get event => 'Evento';

  @override
  String get noConnectionLogs => 'Sem logs de conexão';

  @override
  String get type => 'Tipo';

  @override
  String get ip => 'IP';

  @override
  String get date => 'Data';

  @override
  String get performance => 'Desempenho';

  @override
  String get details_tab => 'Detalhes';

  @override
  String get utilization => 'Utilização (%)';

  @override
  String get memory => 'Memória';

  @override
  String get network => 'Rede';

  @override
  String get diskIO => 'E/S de Disco';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get read => 'Leitura';

  @override
  String get write => 'Escrita';

  @override
  String get activeConnections => 'Conexões Ativas';

  @override
  String get processId => 'PID';

  @override
  String get process => 'Processo';

  @override
  String get systemDetails => 'Detalhes do Sistema';

  @override
  String get cpuModel => 'Modelo CPU';

  @override
  String get cpuCores => 'Núcleos CPU';

  @override
  String get totalRam => 'RAM Total';

  @override
  String get temperature => 'Temperatura';

  @override
  String get systemTime => 'Hora do Sistema';

  @override
  String get storageManager => 'Gerenciador de Armazenamento';

  @override
  String get storage => 'Armazenamento';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => 'Saúde do Sistema';

  @override
  String get totalStorage => 'Armazenamento Total';

  @override
  String get used => 'Usado';

  @override
  String get available => 'Disponível';

  @override
  String get volumeUsage => 'Uso de Volume';

  @override
  String get critical => 'Crítico';

  @override
  String get usageExceedsThreshold => 'Uso acima de 90%';

  @override
  String get storageHealthy => 'Armazenamento saudável';

  @override
  String get driveInformation => 'Informações do Disco';

  @override
  String get status => 'Status';

  @override
  String get capacity => 'Capacidade';

  @override
  String get diskTemperature => 'Temperatura do Disco';

  @override
  String get userAndGroup => 'Usuários e Grupos';

  @override
  String get users => 'Usuários';

  @override
  String get groups => 'Grupos';

  @override
  String get allUsers => 'Todos os Usuários';

  @override
  String nUsers(int count) {
    return '$count usuários';
  }

  @override
  String get admin => 'ADMIN';

  @override
  String get active => 'Ativo';

  @override
  String get disabled => 'Desativado';

  @override
  String get allGroups => 'Todos os Grupos';

  @override
  String nGroups(int count) {
    return '$count grupos';
  }

  @override
  String get members => 'Membros';

  @override
  String get noUsers => 'Nenhum usuário encontrado';

  @override
  String get noGroups => 'Nenhum grupo encontrado';

  @override
  String get loadingVideo => 'Carregando vídeo...';

  @override
  String get failedToPlayVideo => 'Falha ao reproduzir vídeo';

  @override
  String get settings => 'Configurações';

  @override
  String get nasConnection => 'Conexão NAS';

  @override
  String get connection => 'Conexão';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeAndColors => 'Tema e Cores';

  @override
  String get darkCyanAccent => 'Escuro • Ciano';

  @override
  String get notifications => 'Notificações';

  @override
  String get pushNotifications => 'Notificações Push';

  @override
  String get systemAlerts => 'Alertas do Sistema';

  @override
  String get backupAlerts => 'Alertas de Backup';

  @override
  String get storageWarnings => 'Alertas de Armazenamento';

  @override
  String get about => 'Sobre';

  @override
  String get aboutSynoHub => 'Sobre o SynoHub';

  @override
  String get checkForUpdates => 'Verificar Atualizações';

  @override
  String get upToDate => 'Atualizado';

  @override
  String get theme => 'TEMA';

  @override
  String get dark => 'Escuro';

  @override
  String get light => 'Claro';

  @override
  String get system => 'Sistema';

  @override
  String get accentColor => 'COR DE DESTAQUE';

  @override
  String get cyan => 'Ciano';

  @override
  String get teal => 'Azul-petróleo';

  @override
  String get gold => 'Dourado';

  @override
  String get purple => 'Roxo';

  @override
  String get preview => 'VISUALIZAÇÃO';

  @override
  String get accentColorPreview => 'Visualização da cor de destaque';

  @override
  String get connectionSettings => 'Conexão';

  @override
  String get server => 'SERVIDOR';

  @override
  String get nasAddressSetting => 'Endereço NAS';

  @override
  String get ipHostnameOrQuickConnect => 'IP, nome do host ou QuickConnect ID';

  @override
  String get portLabel => 'Porta';

  @override
  String get protocolLabel => 'PROTOCOLO';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => 'CONTA';

  @override
  String get password => 'Senha';

  @override
  String get rememberLogin => 'Lembrar Login';

  @override
  String get logout => 'Sair';

  @override
  String versionN(String version) {
    return 'Versão $version';
  }

  @override
  String get connectedNas => 'NAS CONECTADO';

  @override
  String get dsmVersionLabel => 'Versão DSM';

  @override
  String get serialNumber => 'Número de Série';

  @override
  String get application => 'APLICATIVO';

  @override
  String get openSourceLicenses => 'Licenças Open Source';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get sourceCode => 'Código Fonte';

  @override
  String get madeWithFlutter => 'Feito com ❤ Flutter';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => 'Nenhuma conexão ativa';

  @override
  String get connectedUsers => 'Usuários Conectados';

  @override
  String get memoryBreakdown => 'Detalhamento da Memória';

  @override
  String get total => 'Total';

  @override
  String get cached => 'Cache';

  @override
  String get bufferLabel => 'Buffer';

  @override
  String get diskInformation => 'Informações do Disco';

  @override
  String driveN(int n) {
    return 'Disco $n';
  }

  @override
  String get healthyStatus => 'Saudável';

  @override
  String get degraded => 'Degradado';

  @override
  String get allStorageHealthy =>
      'Todos os pools de armazenamento e volumes estão saudáveis.';

  @override
  String get storagePoolDegraded =>
      'Ocorreram problemas em um pool de armazenamento. Acesse a página de Armazenamento para detalhes.';

  @override
  String get raidType => 'Tipo RAID';

  @override
  String get drives => 'Discos';

  @override
  String nDisks(int count) {
    return '$count disco(s)';
  }

  @override
  String get device => 'Dispositivo';

  @override
  String get drive => 'Disco';

  @override
  String get size => 'Tamanho';

  @override
  String get noStoragePoolData => 'Nenhum dado de pool de armazenamento';

  @override
  String get noDiskInfo => 'Nenhuma informação de disco disponível';

  @override
  String get systemGroup => 'SISTEMA';

  @override
  String get noMembers => 'Sem membros';

  @override
  String membersCount(int count) {
    return 'Membros ($count)';
  }

  @override
  String get manage => 'Gerenciar';

  @override
  String get createUser => 'Criar Usuário';

  @override
  String get email => 'E-mail';

  @override
  String get description => 'Descrição';

  @override
  String get usernameAndPasswordRequired => 'Usuário e senha são obrigatórios';

  @override
  String get userCreatedSuccessfully => 'Usuário criado com sucesso';

  @override
  String editName(String name) {
    return 'Editar \"$name\"';
  }

  @override
  String get userUpdated => 'Usuário atualizado';

  @override
  String changePasswordTitle(String name) {
    return 'Alterar Senha - $name';
  }

  @override
  String get newPassword => 'Nova Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get passwordCannotBeEmpty => 'A senha não pode estar vazia';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get passwordChanged => 'Senha alterada';

  @override
  String userEnabled(String name) {
    return '$name ativado';
  }

  @override
  String userDisabled(String name) {
    return '$name desativado';
  }

  @override
  String get deleteUserTitle => 'Excluir Usuário?';

  @override
  String deleteUserMessage(String name) {
    return 'Tem certeza de que deseja excluir o usuário \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String userDeleted(String name) {
    return 'Usuário \"$name\" excluído';
  }

  @override
  String get createGroup => 'Criar Grupo';

  @override
  String get groupName => 'Nome do Grupo';

  @override
  String get groupNameRequired => 'O nome do grupo é obrigatório';

  @override
  String get groupCreated => 'Grupo criado';

  @override
  String get groupUpdated => 'Grupo atualizado';

  @override
  String get deleteGroupTitle => 'Excluir Grupo?';

  @override
  String deleteGroupMessage(String name) {
    return 'Tem certeza de que deseja excluir o grupo \"$name\"?';
  }

  @override
  String groupDeleted(String name) {
    return 'Grupo \"$name\" excluído';
  }

  @override
  String membersOfGroup(String name) {
    return 'Membros de \"$name\"';
  }

  @override
  String get membersUpdated => 'Membros atualizados';

  @override
  String get edit => 'Editar';

  @override
  String get enable => 'Ativar';

  @override
  String get disable => 'Desativar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get statusLabel => 'Status';

  @override
  String get connected => 'Conectado';

  @override
  String get nature => 'Natureza';

  @override
  String get urban => 'Urbano';

  @override
  String get chooseFolder => 'Escolher pasta';

  @override
  String get addTmdbKeyHint => 'Adicionar chave TMDB para capas de filmes';

  @override
  String get scanningMediaFiles => 'Verificando arquivos de mídia...';

  @override
  String get newestFilesSubtitle => 'Arquivos mais recentes da sua biblioteca';

  @override
  String get allVideos => 'Todos os vídeos';

  @override
  String get videosLabel => 'Vídeos';

  @override
  String get imagesLabel => 'Imagens';

  @override
  String get audioLabel => 'Áudio';

  @override
  String get foldersLabel => 'Pastas';

  @override
  String get latest => 'RECENTE';

  @override
  String get play => 'Reproduzir';

  @override
  String get change => 'Alterar';

  @override
  String get selectMediaFolder => 'Selecionar pasta de mídia';

  @override
  String get select => 'Selecionar';

  @override
  String get noSubfolders => 'Sem subpastas';

  @override
  String get tapSelectHint => 'Toque em \"Selecionar\" para usar esta pasta';

  @override
  String nFiles(int count) {
    return '$count arquivos';
  }

  @override
  String nVideos(int count) {
    return '$count vídeos';
  }

  @override
  String nImages(int count) {
    return '$count imagens';
  }

  @override
  String nTracks(int count) {
    return '$count faixas';
  }

  @override
  String get sampleAlpineReflection => 'Reflexo alpino';

  @override
  String get sampleEmeraldMorning => 'Manhã esmeralda';

  @override
  String get sampleNeonPulse => 'Pulso neon';

  @override
  String get connectionLogs => 'Registros de conexão';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return 'Usuário: $userPct%  ·  Sistema: $systemPct%';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '$usedMb MB usados / $totalMb MB  ·  Cache: $cachedMb MB';
  }

  @override
  String driveHddDetail(int n, String size) {
    return 'Disco $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return 'Pool de armazenamento $n';
  }

  @override
  String volumeN(int n) {
    return 'Volume $n';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get insufficientPermission =>
      'Permissão insuficiente. Acesso de administrador necessário.';

  @override
  String get invalidParameter => 'Parâmetro inválido';

  @override
  String get accountIsDisabled => 'A conta está desativada';

  @override
  String get permissionDenied => 'Permissão negada';

  @override
  String get userGroupNotFound => 'Usuário/Grupo não encontrado';

  @override
  String get nameAlreadyExists => 'O nome já existe';

  @override
  String operationFailedCode(int code) {
    return 'Operação falhou (erro $code)';
  }

  @override
  String get notAvailable => 'N/D';

  @override
  String get timeline => 'Linha do tempo';

  @override
  String get albumsTab => 'Álbuns';

  @override
  String get backup => 'Backup';

  @override
  String get sharedSpace => 'Espaço compartilhado';

  @override
  String get personalSpace => 'Espaço pessoal';

  @override
  String get searchPhotos => 'Pesquisar fotos...';

  @override
  String get addToAlbum => 'Adicionar ao Álbum';

  @override
  String uploadingProgress(int current, int total) {
    return 'Enviando $current/$total...';
  }

  @override
  String deletePhotosTitle(int count) {
    return 'Excluir $count item(ns)?';
  }

  @override
  String get deletePhotosMessage =>
      'Estes itens serão excluídos permanentemente. Esta ação não pode ser desfeita.';

  @override
  String addedToAlbumN(String name) {
    return 'Adicionado a \"$name\"';
  }

  @override
  String uploadedNPhotos(int count) {
    return '$count foto(s) enviada(s)';
  }

  @override
  String get createAlbum => 'Criar Álbum';

  @override
  String get albumName => 'Nome do álbum';

  @override
  String get create => 'Criar';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String photoCount(int count) {
    return '$count fotos';
  }

  @override
  String get photosApiHint =>
      'Certifique-se de que o Synology Photos está instalado e em execução no seu NAS.';

  @override
  String get noPhotosTitle => 'Nenhuma foto';

  @override
  String get noPhotosSubtitle =>
      'Envie fotos para o NAS ou ative o backup para começar.';

  @override
  String get uploadPhotos => 'Enviar Fotos';

  @override
  String get deleteAlbum => 'Excluir Álbum';

  @override
  String deleteAlbumMessage(String name) {
    return 'Excluir o álbum \"$name\"? As fotos dentro dele não serão excluídas.';
  }

  @override
  String get noAlbums => 'Nenhum Álbum';

  @override
  String get createAlbumHint => 'Crie álbuns para organizar suas fotos';

  @override
  String get backupPhotos => 'Backup de Fotos';

  @override
  String get backupPhotosDesc =>
      'Envie fotos do seu dispositivo para o NAS para mantê-las seguras.';

  @override
  String get manualUpload => 'Upload Manual';

  @override
  String get selectPhotosToUpload => 'Selecionar fotos para enviar';

  @override
  String get uploadToNasPhotos => 'Enviar para /photo/Upload no NAS';

  @override
  String get backupInfoHint =>
      'Fotos enviadas serão indexadas automaticamente pelo Synology Photos e aparecerão na linha do tempo.';

  @override
  String get noPhotosInAlbum => 'Nenhuma foto neste álbum';

  @override
  String get downloadLinkCopied =>
      'Link de download copiado para a área de transferência';

  @override
  String get photoInfo => 'Informações da Foto';

  @override
  String get filenameLabel => 'Nome do arquivo';

  @override
  String get takenOn => 'Data da captura';

  @override
  String get resolution => 'Resolução';

  @override
  String get fileSize => 'Tamanho do arquivo';

  @override
  String get video => 'Vídeo';

  @override
  String get photo => 'Foto';

  @override
  String downloadSavedTo(String path) {
    return 'Salvo em $path';
  }

  @override
  String downloadFailed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get uploadDestination => 'Destino do upload';

  @override
  String get selectUploadDest => 'Selecionar pasta de upload';

  @override
  String get selectMediaToUpload => 'Selecionar fotos e vídeos';

  @override
  String uploadToNasDest(String dest) {
    return 'Enviar para $dest no seu NAS';
  }

  @override
  String lastUploadResult(int count) {
    return 'Último upload: $count arquivo(s) enviado(s)';
  }

  @override
  String get renameAlbum => 'Renomear Álbum';

  @override
  String get limitedAccess => 'Acesso Limitado';

  @override
  String get limitedAccessDesc =>
      'O monitoramento do sistema requer privilégios de administrador. Gerenciador de Arquivos, Media Hub e Fotos estão totalmente disponíveis.';

  @override
  String get quota => 'Cota';

  @override
  String get quotaMB => 'Cota (MB)';

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get sharePermissions => 'Permissões de Compartilhamento';

  @override
  String get readWrite => 'Leitura/Escrita';

  @override
  String get readOnly => 'Somente Leitura';

  @override
  String get noAccess => 'Sem Acesso';

  @override
  String get adminOnly => 'Somente Admin';

  @override
  String get quotaUpdated => 'Cota atualizada';

  @override
  String get permissionUpdated => 'Permissão atualizada';

  @override
  String get premiumFeature => 'Recurso Premium';

  @override
  String get premiumFeatureDesc =>
      'Media Hub e Photos são recursos premium disponíveis para membros VIP. Entre em contato com o desenvolvedor para atualizar sua conta.';

  @override
  String get vipMember => 'Membro VIP';

  @override
  String get freeUser => 'Usuário gratuito';

  @override
  String get otpDialogTitle => 'Autenticação de dois fatores';

  @override
  String get otpDialogMessage =>
      'Seu NAS requer um código de verificação. Digite o código de 6 dígitos do seu aplicativo autenticador.';

  @override
  String get verify => 'Verificar';

  @override
  String get quickConnectFailed => 'Falha na resolução do QuickConnect';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get whatsNew => 'Novidades';

  @override
  String get later => 'Mais tarde';

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get downloading => 'Baixando atualização...';

  @override
  String get updateFailed => 'Falha na atualização';
}

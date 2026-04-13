// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'SynoHub';

  @override
  String get synologyNasManagement => 'Quản Lý Synology NAS';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String get version => 'v1.0.0';

  @override
  String get signInToContinue => 'Đăng nhập để tiếp tục';

  @override
  String get signInPrivacyNote =>
      'Dữ liệu của bạn được lưu trên thiết bị.\nTài khoản Google chỉ dùng để xác thực\nvà sao lưu tùy chọn lên Google Drive.';

  @override
  String get signInCancelled => 'Đăng nhập đã bị hủy';

  @override
  String signInFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get signInWithGoogle => 'Đăng nhập bằng Google';

  @override
  String get noDataStoredOnServers =>
      'Không có dữ liệu nào được lưu trên máy chủ';

  @override
  String get nasAddress => 'ĐỊA CHỈ NAS';

  @override
  String get ipOrHostname => 'IP hoặc tên máy chủ';

  @override
  String get port => 'Cổng';

  @override
  String get protocol => 'GIAO THỨC';

  @override
  String get usernameLabel => 'TÊN ĐĂNG NHẬP';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'MẬT KHẨU';

  @override
  String get passwordHint => '••••••••';

  @override
  String get allFieldsRequired => 'Vui lòng điền đầy đủ thông tin';

  @override
  String get invalidPortNumber => 'Số cổng không hợp lệ';

  @override
  String get rememberMe => 'Ghi nhớ đăng nhập';

  @override
  String get connect => 'Kết nối';

  @override
  String get myNas => 'NAS Của Tôi';

  @override
  String get addNas => 'Thêm NAS';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get noNasTitle => 'Chưa Có NAS Nào';

  @override
  String get noNasSubtitle =>
      'Nhấn \"Thêm NAS\" để kết nối\nSynology NAS của bạn';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị',
      one: '1 thiết bị',
    );
    return '$_temp0';
  }

  @override
  String get backupToGoogleDrive => 'Sao lưu lên Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Khôi phục từ Google Drive';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get backingUp => 'Đang sao lưu lên Google Drive...';

  @override
  String get backupSuccessful => 'Sao lưu thành công';

  @override
  String backupFailed(String error) {
    return 'Sao lưu thất bại: $error';
  }

  @override
  String get restoringFromDrive => 'Đang khôi phục từ Google Drive...';

  @override
  String get restoreSuccessful => 'Khôi phục thành công';

  @override
  String restoreFailed(String error) {
    return 'Khôi phục thất bại: $error';
  }

  @override
  String get noBackupFound => 'Không tìm thấy bản sao lưu trên Google Drive';

  @override
  String get nameThisNas => 'Đặt tên NAS';

  @override
  String get nasNicknameHint => 'VD: NAS Nhà, NAS Văn Phòng';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get close => 'Đóng';

  @override
  String get ok => 'OK';

  @override
  String get rename => 'Đổi tên';

  @override
  String get details => 'Chi tiết';

  @override
  String get remove => 'Xóa';

  @override
  String get delete => 'Xóa';

  @override
  String get retry => 'Thử lại';

  @override
  String get host => 'Máy chủ';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get model => 'Model';

  @override
  String get dsm => 'DSM';

  @override
  String get lastConnected => 'Kết nối lần cuối';

  @override
  String get removeNasTitle => 'Xóa NAS';

  @override
  String removeNasMessage(String name) {
    return 'Xóa \"$name\" khỏi danh sách?';
  }

  @override
  String get nasRemoved => 'Đã xóa NAS';

  @override
  String get language => 'Ngôn ngữ';

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
  String get dashboard => 'Tổng quan';

  @override
  String get files => 'Tệp';

  @override
  String get media => 'Đa phương tiện';

  @override
  String get photos => 'Ảnh';

  @override
  String get healthy => 'KHỎE MẠNH';

  @override
  String get dsmVersion => 'PHIÊN BẢN DSM';

  @override
  String get uptime => 'THỜI GIAN HOẠT ĐỘNG';

  @override
  String get lanIp => 'IP LAN';

  @override
  String get serial => 'SỐ SERIAL';

  @override
  String get cpu => 'CPU';

  @override
  String get ram => 'RAM';

  @override
  String get services => 'DỊCH VỤ';

  @override
  String get cpuTemp => 'NHIỆT ĐỘ CPU';

  @override
  String get disks => 'Ổ ĐĨA';

  @override
  String get resourceMonitor => 'Giám Sát Tài Nguyên';

  @override
  String get storageAndVolumes => 'Lưu Trữ & Volume';

  @override
  String get storageCapacity => 'DUNG LƯỢNG LƯU TRỮ';

  @override
  String get diskHealth => 'Tình Trạng Ổ Đĩa';

  @override
  String bayN(int n) {
    return 'Bay $n';
  }

  @override
  String get normal => 'Bình thường';

  @override
  String get installedPackages => 'Gói Đã Cài';

  @override
  String get running => 'Đang chạy';

  @override
  String get stopped => 'Đã dừng';

  @override
  String get quickActions => 'Thao Tác Nhanh';

  @override
  String get resourceMonitorAction => 'Giám Sát\nTài Nguyên';

  @override
  String get storageManagerAction => 'Quản Lý\nLưu Trữ';

  @override
  String get logCenterAction => 'Trung Tâm\nNhật Ký';

  @override
  String get restart => 'Khởi động lại';

  @override
  String get shutdown => 'Tắt máy';

  @override
  String get refresh => 'Làm mới';

  @override
  String confirmActionTitle(String action) {
    return '$action NAS?';
  }

  @override
  String confirmActionMessage(String action) {
    return 'Bạn có chắc chắn muốn $action NAS không?';
  }

  @override
  String get fileManager => 'Quản Lý Tệp';

  @override
  String get notConnected => 'Chưa kết nối';

  @override
  String errorCode(String code) {
    return 'Lỗi $code';
  }

  @override
  String get newFolder => 'Thư mục mới';

  @override
  String get folderName => 'Tên thư mục';

  @override
  String get newName => 'Tên mới';

  @override
  String get failedToCreateFolder => 'Không thể tạo thư mục';

  @override
  String get failedToRename => 'Không thể đổi tên';

  @override
  String deleteItemsTitle(int count, String suffix) {
    return 'Xóa $count mục$suffix?';
  }

  @override
  String get cannotBeUndone => 'Không thể hoàn tác.';

  @override
  String failedToDelete(String name) {
    return 'Xóa thất bại: $name';
  }

  @override
  String copiedItems(String action, int count, String suffix) {
    return 'Đã $action $count mục$suffix';
  }

  @override
  String get copied => 'Sao chép';

  @override
  String get cut => 'Cắt';

  @override
  String failedToCopyMove(String action) {
    return 'Thất bại khi $action';
  }

  @override
  String get shareLinkCopied => 'Đã sao chép liên kết chia sẻ!';

  @override
  String get couldNotGenerateLink => 'Không thể tạo liên kết';

  @override
  String get failedToCreateShareLink => 'Không thể tạo liên kết chia sẻ';

  @override
  String couldNotReadFile(String name) {
    return 'Không thể đọc tệp: $name';
  }

  @override
  String uploadedFiles(int count, String suffix) {
    return 'Đã tải lên $count tệp$suffix';
  }

  @override
  String failedError(String error) {
    return 'Thất bại: $error';
  }

  @override
  String get copy => 'Sao chép';

  @override
  String get shareLink => 'Chia Sẻ Liên Kết';

  @override
  String get qrCode => 'Mã QR';

  @override
  String nSelected(int count) {
    return 'Đã chọn $count';
  }

  @override
  String get searchFiles => 'Tìm kiếm tệp...';

  @override
  String searchInFolder(String folder) {
    return 'Tìm trong $folder...';
  }

  @override
  String get searchFailed => 'Tìm kiếm thất bại';

  @override
  String get noResultsFound => 'Không tìm thấy kết quả';

  @override
  String get emptyFolder => 'Thư mục trống';

  @override
  String get sortByName => 'Tên';

  @override
  String get sortBySize => 'Kích thước';

  @override
  String get sortByDate => 'Ngày sửa đổi';

  @override
  String get sortByType => 'Loại';

  @override
  String get listView => 'Xem danh sách';

  @override
  String get gridView => 'Xem lưới';

  @override
  String get root => 'Gốc';

  @override
  String get clipboardMove => 'Bộ nhớ tạm: di chuyển';

  @override
  String get clipboardCopy => 'Bộ nhớ tạm: sao chép';

  @override
  String get pasteHere => 'Dán Vào Đây';

  @override
  String get linkCopied => 'Đã sao chép liên kết!';

  @override
  String get copyLink => 'Sao Chép Liên Kết';

  @override
  String get couldNotGenerateShareLink => 'Không thể tạo liên kết chia sẻ';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get mediaHub => 'Trung Tâm Đa Phương Tiện';

  @override
  String get selectFolderDescription =>
      'Chọn thư mục trên NAS để quét và duyệt tệp đa phương tiện';

  @override
  String get selectFolder => 'Chọn Thư Mục';

  @override
  String get startingScan => 'Đang bắt đầu quét...';

  @override
  String scanningFolder(String name) {
    return 'Đang quét: $name';
  }

  @override
  String mediaFilesFound(int count) {
    return 'Tìm thấy $count tệp đa phương tiện';
  }

  @override
  String get tmdbApiKey => 'Khóa API TMDB';

  @override
  String get tmdbApiKeyInstructions =>
      'Sử dụng \"API Key (v3 auth)\" từ cài đặt tài khoản TMDB — KHÔNG dùng Read Access Token.';

  @override
  String get tmdbApiKeyHelp =>
      'Lấy khóa miễn phí tại themoviedb.org/settings/api';

  @override
  String get tmdbApiKeyHint => 'Dán API Key (v3) vào đây';

  @override
  String get changeFolder => 'Đổi thư mục';

  @override
  String get tmdbKeyConfigured => 'Đã cấu hình khóa TMDB ✓';

  @override
  String get setTmdbApiKey => 'Đặt khóa API TMDB';

  @override
  String get rescanFolder => 'Quét lại thư mục';

  @override
  String get chooseMediaFolder => 'Chọn thư mục đa phương tiện';

  @override
  String get allMedia => 'Tất Cả';

  @override
  String get recentlyAdded => 'Mới Thêm';

  @override
  String get filters => 'Bộ lọc';

  @override
  String get allPhotos => 'Tất Cả Ảnh';

  @override
  String get favorites => 'Yêu thích';

  @override
  String get recent => 'Gần đây';

  @override
  String get hidden => 'Ẩn';

  @override
  String get recentlyAddedPhotos => 'MỚI THÊM GẦN ĐÂY';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get myAlbums => 'ALBUM CỦA TÔI';

  @override
  String get family => 'Gia đình';

  @override
  String get travel => 'Du lịch';

  @override
  String get workAndProjects => 'Công việc & Dự án';

  @override
  String itemsCount(String count) {
    return '$count mục';
  }

  @override
  String get logCenter => 'Trung Tâm Nhật Ký';

  @override
  String get overview => 'Tổng quan';

  @override
  String get logs => 'Nhật ký';

  @override
  String get connections => 'Kết nối';

  @override
  String get totalLogs => 'Tổng nhật ký';

  @override
  String get info => 'Thông tin';

  @override
  String get warnings => 'Cảnh báo';

  @override
  String get errors => 'Lỗi';

  @override
  String lastNLogs(int count) {
    return '$count nhật ký gần nhất';
  }

  @override
  String get noLogsAvailable => 'Không có nhật ký';

  @override
  String get systemLogs => 'Nhật Ký Hệ Thống';

  @override
  String nItems(int count) {
    return '$count mục';
  }

  @override
  String get level => 'Mức độ';

  @override
  String get time => 'Thời gian';

  @override
  String get user => 'Người dùng';

  @override
  String get event => 'Sự kiện';

  @override
  String get noConnectionLogs => 'Không có nhật ký kết nối';

  @override
  String get type => 'Loại';

  @override
  String get ip => 'IP';

  @override
  String get date => 'Ngày';

  @override
  String get performance => 'Hiệu Suất';

  @override
  String get details_tab => 'Chi tiết';

  @override
  String get utilization => 'Sử dụng (%)';

  @override
  String get memory => 'Bộ nhớ';

  @override
  String get network => 'Mạng';

  @override
  String get diskIO => 'I/O Ổ Đĩa';

  @override
  String get download => 'Tải xuống';

  @override
  String get upload => 'Tải lên';

  @override
  String get read => 'Đọc';

  @override
  String get write => 'Ghi';

  @override
  String get activeConnections => 'Kết Nối Đang Hoạt Động';

  @override
  String get processId => 'PID';

  @override
  String get process => 'Tiến trình';

  @override
  String get systemDetails => 'Chi Tiết Hệ Thống';

  @override
  String get cpuModel => 'Model CPU';

  @override
  String get cpuCores => 'Số lõi CPU';

  @override
  String get totalRam => 'Tổng RAM';

  @override
  String get temperature => 'Nhiệt độ';

  @override
  String get systemTime => 'Thời gian hệ thống';

  @override
  String get storageManager => 'Quản Lý Lưu Trữ';

  @override
  String get storage => 'Lưu trữ';

  @override
  String get hddSsd => 'HDD/SSD';

  @override
  String get systemHealth => 'Tình Trạng Hệ Thống';

  @override
  String get totalStorage => 'Tổng dung lượng';

  @override
  String get used => 'Đã dùng';

  @override
  String get available => 'Khả dụng';

  @override
  String get volumeUsage => 'Sử Dụng Volume';

  @override
  String get critical => 'Nghiêm trọng';

  @override
  String get usageExceedsThreshold => 'Sử dụng vượt quá 90%';

  @override
  String get storageHealthy => 'Lưu trữ khỏe mạnh';

  @override
  String get driveInformation => 'Thông Tin Ổ Đĩa';

  @override
  String get status => 'Trạng thái';

  @override
  String get capacity => 'Dung lượng';

  @override
  String get diskTemperature => 'Nhiệt độ ổ đĩa';

  @override
  String get userAndGroup => 'Người Dùng & Nhóm';

  @override
  String get users => 'Người dùng';

  @override
  String get groups => 'Nhóm';

  @override
  String get allUsers => 'Tất Cả Người Dùng';

  @override
  String nUsers(int count) {
    return '$count người dùng';
  }

  @override
  String get admin => 'QUẢN TRỊ';

  @override
  String get active => 'Hoạt động';

  @override
  String get disabled => 'Đã tắt';

  @override
  String get allGroups => 'Tất Cả Nhóm';

  @override
  String nGroups(int count) {
    return '$count nhóm';
  }

  @override
  String get members => 'Thành viên';

  @override
  String get noUsers => 'Không tìm thấy người dùng';

  @override
  String get noGroups => 'Không tìm thấy nhóm';

  @override
  String get loadingVideo => 'Đang tải video...';

  @override
  String get failedToPlayVideo => 'Không thể phát video';

  @override
  String get settings => 'Cài Đặt';

  @override
  String get nasConnection => 'Kết Nối NAS';

  @override
  String get connection => 'Kết nối';

  @override
  String get appearance => 'Giao diện';

  @override
  String get themeAndColors => 'Chủ Đề & Màu Sắc';

  @override
  String get darkCyanAccent => 'Tối • Xanh lục lam';

  @override
  String get notifications => 'Thông báo';

  @override
  String get pushNotifications => 'Thông Báo Đẩy';

  @override
  String get systemAlerts => 'Cảnh Báo Hệ Thống';

  @override
  String get backupAlerts => 'Cảnh Báo Sao Lưu';

  @override
  String get storageWarnings => 'Cảnh Báo Lưu Trữ';

  @override
  String get about => 'Giới thiệu';

  @override
  String get aboutSynoHub => 'Về SynoHub';

  @override
  String get checkForUpdates => 'Kiểm Tra Cập Nhật';

  @override
  String get upToDate => 'Đã cập nhật';

  @override
  String get theme => 'CHỦ ĐỀ';

  @override
  String get dark => 'Tối';

  @override
  String get light => 'Sáng';

  @override
  String get system => 'Hệ thống';

  @override
  String get accentColor => 'MÀU NHẤN';

  @override
  String get cyan => 'Xanh lục lam';

  @override
  String get teal => 'Xanh ngọc';

  @override
  String get gold => 'Vàng';

  @override
  String get purple => 'Tím';

  @override
  String get preview => 'XEM TRƯỚC';

  @override
  String get accentColorPreview => 'Xem trước màu nhấn';

  @override
  String get connectionSettings => 'Kết nối';

  @override
  String get server => 'MÁY CHỦ';

  @override
  String get nasAddressSetting => 'Địa chỉ NAS';

  @override
  String get ipHostnameOrQuickConnect =>
      'IP, tên máy chủ, hoặc QuickConnect ID';

  @override
  String get portLabel => 'Cổng';

  @override
  String get protocolLabel => 'GIAO THỨC';

  @override
  String get http => 'HTTP';

  @override
  String get https => 'HTTPS';

  @override
  String get account => 'TÀI KHOẢN';

  @override
  String get password => 'Mật khẩu';

  @override
  String get rememberLogin => 'Ghi Nhớ Đăng Nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String versionN(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get connectedNas => 'NAS ĐÃ KẾT NỐI';

  @override
  String get dsmVersionLabel => 'Phiên bản DSM';

  @override
  String get serialNumber => 'Số Serial';

  @override
  String get application => 'ỨNG DỤNG';

  @override
  String get openSourceLicenses => 'Giấy Phép Mã Nguồn Mở';

  @override
  String get privacyPolicy => 'Chính Sách Bảo Mật';

  @override
  String get sourceCode => 'Mã Nguồn';

  @override
  String get madeWithFlutter => 'Được tạo với ❤ Flutter';

  @override
  String get copyright => '© 2026 SynoHub';

  @override
  String get noActiveConnections => 'Không có kết nối nào';

  @override
  String get connectedUsers => 'Người Dùng Đang Kết Nối';

  @override
  String get memoryBreakdown => 'Phân Tích Bộ Nhớ';

  @override
  String get total => 'Tổng';

  @override
  String get cached => 'Bộ nhớ đệm';

  @override
  String get bufferLabel => 'Bộ đệm';

  @override
  String get diskInformation => 'Thông Tin Ổ Đĩa';

  @override
  String driveN(int n) {
    return 'Ổ đĩa $n';
  }

  @override
  String get healthyStatus => 'Khỏe mạnh';

  @override
  String get degraded => 'Suy giảm';

  @override
  String get allStorageHealthy =>
      'Tất cả pool lưu trữ và volume đều khỏe mạnh.';

  @override
  String get storagePoolDegraded =>
      'Đã xảy ra sự cố với Storage Pool. Vui lòng vào trang Lưu trữ để xem chi tiết.';

  @override
  String get raidType => 'Loại RAID';

  @override
  String get drives => 'Ổ đĩa';

  @override
  String nDisks(int count) {
    return '$count ổ đĩa';
  }

  @override
  String get device => 'Thiết bị';

  @override
  String get drive => 'Ổ đĩa';

  @override
  String get size => 'Kích thước';

  @override
  String get noStoragePoolData => 'Không có dữ liệu storage pool';

  @override
  String get noDiskInfo => 'Không có thông tin ổ đĩa';

  @override
  String get systemGroup => 'HỆ THỐNG';

  @override
  String get noMembers => 'Không có thành viên';

  @override
  String membersCount(int count) {
    return 'Thành viên ($count)';
  }

  @override
  String get manage => 'Quản lý';

  @override
  String get createUser => 'Tạo Người Dùng';

  @override
  String get email => 'Email';

  @override
  String get description => 'Mô tả';

  @override
  String get usernameAndPasswordRequired =>
      'Tên đăng nhập và mật khẩu là bắt buộc';

  @override
  String get userCreatedSuccessfully => 'Tạo người dùng thành công';

  @override
  String editName(String name) {
    return 'Sửa \"$name\"';
  }

  @override
  String get userUpdated => 'Đã cập nhật người dùng';

  @override
  String changePasswordTitle(String name) {
    return 'Đổi Mật Khẩu - $name';
  }

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get passwordCannotBeEmpty => 'Mật khẩu không được để trống';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get passwordChanged => 'Đã đổi mật khẩu';

  @override
  String userEnabled(String name) {
    return 'Đã bật $name';
  }

  @override
  String userDisabled(String name) {
    return 'Đã tắt $name';
  }

  @override
  String get deleteUserTitle => 'Xóa Người Dùng?';

  @override
  String deleteUserMessage(String name) {
    return 'Bạn có chắc chắn muốn xóa người dùng \"$name\"? Không thể hoàn tác.';
  }

  @override
  String userDeleted(String name) {
    return 'Đã xóa người dùng \"$name\"';
  }

  @override
  String get createGroup => 'Tạo Nhóm';

  @override
  String get groupName => 'Tên Nhóm';

  @override
  String get groupNameRequired => 'Tên nhóm là bắt buộc';

  @override
  String get groupCreated => 'Đã tạo nhóm';

  @override
  String get groupUpdated => 'Đã cập nhật nhóm';

  @override
  String get deleteGroupTitle => 'Xóa Nhóm?';

  @override
  String deleteGroupMessage(String name) {
    return 'Bạn có chắc chắn muốn xóa nhóm \"$name\"?';
  }

  @override
  String groupDeleted(String name) {
    return 'Đã xóa nhóm \"$name\"';
  }

  @override
  String membersOfGroup(String name) {
    return 'Thành viên của \"$name\"';
  }

  @override
  String get membersUpdated => 'Đã cập nhật thành viên';

  @override
  String get edit => 'Sửa';

  @override
  String get enable => 'Bật';

  @override
  String get disable => 'Tắt';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get statusLabel => 'Trạng thái';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get nature => 'Thiên nhiên';

  @override
  String get urban => 'Thành phố';

  @override
  String get chooseFolder => 'Chọn thư mục';

  @override
  String get addTmdbKeyHint => 'Thêm khóa TMDB để hiển thị ảnh bìa phim';

  @override
  String get scanningMediaFiles => 'Đang quét tệp đa phương tiện...';

  @override
  String get newestFilesSubtitle => 'Các tệp mới nhất từ thư viện của bạn';

  @override
  String get allVideos => 'Tất cả video';

  @override
  String get videosLabel => 'Video';

  @override
  String get imagesLabel => 'Hình ảnh';

  @override
  String get audioLabel => 'Âm thanh';

  @override
  String get foldersLabel => 'Thư mục';

  @override
  String get latest => 'MỚI NHẤT';

  @override
  String get play => 'Phát';

  @override
  String get change => 'Đổi';

  @override
  String get selectMediaFolder => 'Chọn thư mục phương tiện';

  @override
  String get select => 'Chọn';

  @override
  String get noSubfolders => 'Không có thư mục con';

  @override
  String get tapSelectHint => 'Nhấn \"Chọn\" để dùng thư mục này';

  @override
  String nFiles(int count) {
    return '$count tệp';
  }

  @override
  String nVideos(int count) {
    return '$count video';
  }

  @override
  String nImages(int count) {
    return '$count hình ảnh';
  }

  @override
  String nTracks(int count) {
    return '$count bản nhạc';
  }

  @override
  String get sampleAlpineReflection => 'Phản chiếu núi Alps';

  @override
  String get sampleEmeraldMorning => 'Buổi sáng ngọc lục bảo';

  @override
  String get sampleNeonPulse => 'Nhịp đập Neon';

  @override
  String get connectionLogs => 'Nhật ký kết nối';

  @override
  String cpuUsageBreakdown(String userPct, String systemPct) {
    return 'Người dùng: $userPct%  ·  Hệ thống: $systemPct%';
  }

  @override
  String memoryUsageDetail(String usedMb, String totalMb, String cachedMb) {
    return '$usedMb MB đã dùng / $totalMb MB  ·  Bộ nhớ đệm: $cachedMb MB';
  }

  @override
  String driveHddDetail(int n, String size) {
    return 'Ổ đĩa $n (HDD)  ·  $size';
  }

  @override
  String storagePoolN(int n) {
    return 'Nhóm lưu trữ $n';
  }

  @override
  String volumeN(int n) {
    return 'Ổ đĩa $n';
  }

  @override
  String get unknown => 'Không rõ';

  @override
  String get insufficientPermission =>
      'Không đủ quyền. Yêu cầu quyền quản trị viên.';

  @override
  String get invalidParameter => 'Tham số không hợp lệ';

  @override
  String get accountIsDisabled => 'Tài khoản đã bị vô hiệu hóa';

  @override
  String get permissionDenied => 'Truy cập bị từ chối';

  @override
  String get userGroupNotFound => 'Không tìm thấy người dùng/nhóm';

  @override
  String get nameAlreadyExists => 'Tên đã tồn tại';

  @override
  String operationFailedCode(int code) {
    return 'Thao tác thất bại (lỗi $code)';
  }

  @override
  String get notAvailable => 'N/A';

  @override
  String get timeline => 'Dòng thời gian';

  @override
  String get albumsTab => 'Album';

  @override
  String get backup => 'Sao lưu';

  @override
  String get sharedSpace => 'Không gian chung';

  @override
  String get personalSpace => 'Không gian cá nhân';

  @override
  String get searchPhotos => 'Tìm kiếm ảnh...';

  @override
  String get addToAlbum => 'Thêm vào Album';

  @override
  String uploadingProgress(int current, int total) {
    return 'Đang tải lên $current/$total...';
  }

  @override
  String deletePhotosTitle(int count) {
    return 'Xóa $count mục?';
  }

  @override
  String get deletePhotosMessage =>
      'Các mục này sẽ bị xóa vĩnh viễn. Không thể hoàn tác.';

  @override
  String addedToAlbumN(String name) {
    return 'Đã thêm vào \"$name\"';
  }

  @override
  String uploadedNPhotos(int count) {
    return 'Đã tải lên $count ảnh';
  }

  @override
  String get createAlbum => 'Tạo Album';

  @override
  String get albumName => 'Tên album';

  @override
  String get create => 'Tạo';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String photoCount(int count) {
    return '$count ảnh';
  }

  @override
  String get photosApiHint =>
      'Hãy chắc chắn Synology Photos đã được cài đặt và đang chạy trên NAS của bạn.';

  @override
  String get noPhotosTitle => 'Chưa có ảnh';

  @override
  String get noPhotosSubtitle => 'Tải ảnh lên NAS hoặc bật sao lưu để bắt đầu.';

  @override
  String get uploadPhotos => 'Tải ảnh lên';

  @override
  String get deleteAlbum => 'Xóa Album';

  @override
  String deleteAlbumMessage(String name) {
    return 'Xóa album \"$name\"? Ảnh bên trong sẽ không bị xóa.';
  }

  @override
  String get noAlbums => 'Chưa có Album';

  @override
  String get createAlbumHint => 'Tạo album để sắp xếp ảnh của bạn';

  @override
  String get backupPhotos => 'Sao lưu Ảnh';

  @override
  String get backupPhotosDesc =>
      'Tải ảnh từ thiết bị lên NAS để lưu trữ an toàn.';

  @override
  String get manualUpload => 'Tải lên thủ công';

  @override
  String get selectPhotosToUpload => 'Chọn ảnh để tải lên';

  @override
  String get uploadToNasPhotos => 'Tải lên /photo/Upload trên NAS';

  @override
  String get backupInfoHint =>
      'Ảnh tải lên sẽ được Synology Photos tự động lập chỉ mục và xuất hiện trong dòng thời gian.';

  @override
  String get noPhotosInAlbum => 'Không có ảnh trong album này';

  @override
  String get downloadLinkCopied => 'Đã sao chép link tải về';

  @override
  String get photoInfo => 'Thông tin Ảnh';

  @override
  String get filenameLabel => 'Tên tệp';

  @override
  String get takenOn => 'Ngày chụp';

  @override
  String get resolution => 'Độ phân giải';

  @override
  String get fileSize => 'Kích thước';

  @override
  String get video => 'Video';

  @override
  String get photo => 'Ảnh';

  @override
  String downloadSavedTo(String path) {
    return 'Đã lưu tại $path';
  }

  @override
  String downloadFailed(String error) {
    return 'Tải xuống thất bại: $error';
  }

  @override
  String get uploadDestination => 'Thư mục đích';

  @override
  String get selectUploadDest => 'Chọn thư mục tải lên';

  @override
  String get selectMediaToUpload => 'Chọn ảnh & video';

  @override
  String uploadToNasDest(String dest) {
    return 'Tải lên $dest trên NAS';
  }

  @override
  String lastUploadResult(int count) {
    return 'Lần tải gần nhất: $count tệp tải lên thành công';
  }

  @override
  String get renameAlbum => 'Đổi tên Album';

  @override
  String get limitedAccess => 'Quyền truy cập hạn chế';

  @override
  String get limitedAccessDesc =>
      'Giám sát hệ thống yêu cầu quyền admin. Quản lý tệp, Media Hub và Photos vẫn hoạt động đầy đủ.';

  @override
  String get quota => 'Hạn mức';

  @override
  String get quotaMB => 'Hạn mức (MB)';

  @override
  String get unlimited => 'Không giới hạn';

  @override
  String get sharePermissions => 'Quyền chia sẻ';

  @override
  String get readWrite => 'Đọc/Ghi';

  @override
  String get readOnly => 'Chỉ đọc';

  @override
  String get noAccess => 'Không truy cập';

  @override
  String get adminOnly => 'Chỉ Admin';

  @override
  String get quotaUpdated => 'Đã cập nhật hạn mức';

  @override
  String get permissionUpdated => 'Đã cập nhật quyền';

  @override
  String get premiumFeature => 'Tính năng Premium';

  @override
  String get premiumFeatureDesc =>
      'Media Hub và Photos là tính năng cao cấp dành cho thành viên VIP. Liên hệ nhà phát triển để nâng cấp tài khoản.';

  @override
  String get vipMember => 'Thành viên VIP';

  @override
  String get freeUser => 'Người dùng miễn phí';

  @override
  String get otpDialogTitle => 'Xác thực hai lớp';

  @override
  String get otpDialogMessage =>
      'NAS của bạn yêu cầu mã xác minh. Nhập mã 6 chữ số từ ứng dụng xác thực.';

  @override
  String get verify => 'Xác minh';

  @override
  String get quickConnectFailed => 'Không thể phân giải QuickConnect';

  @override
  String get updateAvailable => 'Có bản cập nhật mới';

  @override
  String get whatsNew => 'Có gì mới';

  @override
  String get later => 'Để sau';

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get downloading => 'Đang tải bản cập nhật...';

  @override
  String get updateFailed => 'Cập nhật thất bại';
}

import '../utils/constants.dart';

class RemoteSource {
  final String id;          // 唯一标识符
  final String name;        // 显示名称
  final String url;         // 远程URL
  final int type;           // 源类型（HTTP/FTP/SMB等）
  final String? username;   // 用户名（如果需要）
  final String? password;   // 密码（如果需要）
  final String? domain;     // 域（SMB可能需要）
  final int? port;          // 端口（如果非默认）
  final bool isActive;      // 是否启用
  final DateTime addedDate; // 添加日期
  final DateTime? lastSyncDate; // 上次同步日期
  final bool autoSync;      // 是否自动同步
  
  RemoteSource({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.username,
    this.password,
    this.domain,
    this.port,
    this.isActive = true,
    required this.addedDate,
    this.lastSyncDate,
    this.autoSync = false,
  });
  
  // 获取源类型名称
  String get typeName {
    switch (type) {
      case AppConstants.sourceTypeHttp:
        return 'HTTP';
      case AppConstants.sourceTypeFtp:
        return 'FTP';
      case AppConstants.sourceTypeFtps:
        return 'FTPS';
      case AppConstants.sourceTypeSmb:
        return 'SMB';
      case AppConstants.sourceTypeWebdav:
        return 'WebDAV';
      default:
        return '未知';
    }
  }
  
  // 获取完整URL（包括协议、用户名、密码等）
  String get fullUrl {
    switch (type) {
      case AppConstants.sourceTypeHttp:
        final bool isHttps = url.startsWith('https://');
        final defaultPort = isHttps ? AppConstants.defaultPortHttps : AppConstants.defaultPortHttp;
        final portStr = port != null ? ':$port' : '';
        return url + (port != null ? portStr : '');
      case AppConstants.sourceTypeFtp:
        final defaultPort = AppConstants.defaultPortFtp;
        final effectivePort = port ?? defaultPort;
        if (username != null && password != null) {
          final portStr = ':$effectivePort';
          return 'ftp://$username:$password@${url.replaceAll('ftp://', '')}$portStr';
        }
        return url + (url.contains(':') ? '' : ':$effectivePort');
      case AppConstants.sourceTypeFtps:
        final defaultPort = AppConstants.defaultPortFtps;
        final effectivePort = port ?? defaultPort;
        if (username != null && password != null) {
          final portStr = ':$effectivePort';
          return 'ftps://$username:$password@${url.replaceAll('ftps://', '')}$portStr';
        }
        return url + (url.contains(':') ? '' : ':$effectivePort');
      case AppConstants.sourceTypeSmb:
        // SMB URL格式：smb://[domain;][username[:password]@]server[:port]/share/path/to/file
        final defaultPort = AppConstants.defaultPortSmb;
        final effectivePort = port ?? defaultPort;
        String smbUrl = 'smb://';
        if (domain != null && username != null) {
          smbUrl += '$domain;';
        }
        if (username != null) {
          smbUrl += '$username';
          if (password != null) {
            smbUrl += ':$password';
          }
          smbUrl += '@';
        }
        smbUrl += url.replaceAll('smb://', '');
        if (!url.contains(':')) {
          smbUrl += ':$effectivePort';
        }
        return smbUrl;
      case AppConstants.sourceTypeWebdav:
        final bool isHttps = url.startsWith('https://');
        final defaultPort = isHttps ? AppConstants.defaultPortWebdavs : AppConstants.defaultPortWebdav;
        final effectivePort = port ?? defaultPort;
        if (username != null && password != null) {
          final urlParts = url.split('://');
          if (urlParts.length > 1) {
            final hostPart = urlParts[1].split('/')[0];
            final pathPart = urlParts[1].contains('/') ? '/' + urlParts[1].split('/').skip(1).join('/') : '';
            final hostWithPort = hostPart.contains(':') ? hostPart : '$hostPart:$effectivePort';
            return '${urlParts[0]}://$username:$password@$hostWithPort$pathPart';
          }
        }
        if (!url.contains(':')) {
          final urlParts = url.split('://');
          if (urlParts.length > 1) {
            final hostPart = urlParts[1].split('/')[0];
            final pathPart = urlParts[1].contains('/') ? '/' + urlParts[1].split('/').skip(1).join('/') : '';
            return '${urlParts[0]}://$hostPart:$effectivePort$pathPart';
          }
        }
        return url;
      default:
        return url;
    }
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'username': username,
      'password': password,
      'domain': domain,
      'port': port,
      'isActive': isActive,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'lastSyncDate': lastSyncDate?.millisecondsSinceEpoch,
      'autoSync': autoSync,
    };
  }
  
  // 从JSON创建
  factory RemoteSource.fromJson(Map<String, dynamic> json) {
    return RemoteSource(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      type: json['type'],
      username: json['username'],
      password: json['password'],
      domain: json['domain'],
      port: json['port'],
      isActive: json['isActive'] ?? true,
      addedDate: DateTime.fromMillisecondsSinceEpoch(json['addedDate']),
      lastSyncDate: json['lastSyncDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncDate']) 
          : null,
      autoSync: json['autoSync'] ?? false,
    );
  }
  
  // 创建副本
  RemoteSource copyWith({
    String? name,
    String? url,
    int? type,
    String? username,
    String? password,
    String? domain,
    int? port,
    bool? isActive,
    DateTime? lastSyncDate,
    bool? autoSync,
  }) {
    return RemoteSource(
      id: this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      username: username ?? this.username,
      password: password ?? this.password,
      domain: domain ?? this.domain,
      port: port ?? this.port,
      isActive: isActive ?? this.isActive,
      addedDate: this.addedDate,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      autoSync: autoSync ?? this.autoSync,
    );
  }
} 
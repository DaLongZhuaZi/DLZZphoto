import 'dart:convert';

// 设备类型枚举
enum DeviceType {
  http,
  https,
  ftp,
  ftps,
  smb,
  ssh,
  unknown
}

// 设备类型扩展
extension DeviceTypeExtension on DeviceType {
  String get name {
    switch (this) {
      case DeviceType.http:
        return 'HTTP';
      case DeviceType.https:
        return 'HTTPS';
      case DeviceType.ftp:
        return 'FTP';
      case DeviceType.ftps:
        return 'FTPS';
      case DeviceType.smb:
        return 'SMB';
      case DeviceType.ssh:
        return 'SSH';
      case DeviceType.unknown:
        return '未知';
    }
  }
  
  String get icon {
    switch (this) {
      case DeviceType.http:
      case DeviceType.https:
        return 'http';
      case DeviceType.ftp:
        return 'storage';
      case DeviceType.ftps:
        return 'security';
      case DeviceType.smb:
        return 'computer';
      case DeviceType.ssh:
        return 'terminal';
      case DeviceType.unknown:
        return 'device_unknown';
    }
  }
  
  int get sourceType {
    switch (this) {
      case DeviceType.http:
      case DeviceType.https:
        return 0; // AppConstants.sourceTypeHttp
      case DeviceType.ftp:
        return 1; // AppConstants.sourceTypeFtp
      case DeviceType.ftps:
        return 2; // AppConstants.sourceTypeFtps
      case DeviceType.smb:
        return 3; // AppConstants.sourceTypeSmb
      case DeviceType.ssh:
      case DeviceType.unknown:
        return 0; // 默认为HTTP类型
    }
  }
}

// 发现的设备模型
class DiscoveredDevice {
  final String ip;
  final String name;
  final DeviceType type;
  final List<int> ports;
  final DateTime lastSeen;
  
  DiscoveredDevice({
    required this.ip,
    required this.name,
    required this.type,
    required this.ports,
    required this.lastSeen,
  });
  
  // 获取设备地址
  String get address {
    switch (type) {
      case DeviceType.http:
        return 'http://$ip:${ports.contains(80) ? 80 : ports.first}';
      case DeviceType.https:
        return 'https://$ip:${ports.contains(443) ? 443 : ports.first}';
      case DeviceType.ftp:
        return 'ftp://$ip:${ports.contains(21) ? 21 : ports.first}';
      case DeviceType.ftps:
        return 'ftps://$ip:${ports.contains(990) ? 990 : ports.first}';
      case DeviceType.smb:
        return 'smb://$ip:${ports.contains(445) ? 445 : ports.first}';
      case DeviceType.ssh:
        return 'ssh://$ip:${ports.contains(22) ? 22 : ports.first}';
      case DeviceType.unknown:
        return '$ip:${ports.first}';
    }
  }
  
  // 获取设备描述
  String get description {
    final portList = ports.join(', ');
    return '$name ($ip) - 开放端口: $portList';
  }
  
  // 复制并修改设备
  DiscoveredDevice copyWith({
    String? ip,
    String? name,
    DeviceType? type,
    List<int>? ports,
    DateTime? lastSeen,
  }) {
    return DiscoveredDevice(
      ip: ip ?? this.ip,
      name: name ?? this.name,
      type: type ?? this.type,
      ports: ports ?? this.ports,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
  
  // 转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'ip': ip,
      'name': name,
      'type': type.index,
      'ports': ports,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
    });
  }
  
  // 从JSON字符串创建
  factory DiscoveredDevice.fromJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return DiscoveredDevice(
      ip: data['ip'] as String,
      name: data['name'] as String,
      type: DeviceType.values[data['type'] as int],
      ports: (data['ports'] as List).cast<int>(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int),
    );
  }
} 
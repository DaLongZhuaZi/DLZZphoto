import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/discovered_device.dart';
import '../utils/constants.dart';

class NetworkScanner {
  // 单例模式
  static final NetworkScanner _instance = NetworkScanner._internal();
  factory NetworkScanner() => _instance;
  NetworkScanner._internal();
  
  // 扫描结果
  final List<DiscoveredDevice> _discoveredDevices = [];
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  
  // 扫描状态
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  
  // 扫描进度
  double _scanProgress = 0.0;
  double get scanProgress => _scanProgress;
  
  // 扫描监听器
  final StreamController<List<DiscoveredDevice>> _devicesController = 
      StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  
  // 进度监听器
  final StreamController<double> _progressController = 
      StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;
  
  // 扫描本地网络
  Future<void> scanNetwork({
    List<int>? ports, 
    Duration timeout = const Duration(milliseconds: 500),
    Function(DiscoveredDevice)? onDeviceFound,
    Function(double)? onProgress,
  }) async {
    if (_isScanning) return;
    
    _isScanning = true;
    _scanProgress = 0.0;
    _discoveredDevices.clear();
    
    _progressController.add(_scanProgress);
    _devicesController.add(_discoveredDevices);
    
    try {
      // 获取本地IP地址
      final info = NetworkInfo();
      final String? ip = await info.getWifiIP();
      
      if (ip == null) {
        throw Exception('无法获取本地IP地址');
      }
      
      // 解析IP地址，获取网段
      final subnet = ip.substring(0, ip.lastIndexOf('.'));
      
      // 要扫描的端口列表
      final portsToScan = ports ?? [
        AppConstants.defaultPortHttp,
        AppConstants.defaultPortHttps,
        AppConstants.defaultPortFtp,
        AppConstants.defaultPortFtps,
        AppConstants.defaultPortSmb,
        139, // NetBIOS
        AppConstants.defaultPortWebdav,
        AppConstants.defaultPortWebdavs,
        22, // SSH
        5000, // UPnP
        8080, // 常用的替代HTTP端口
      ];
      
      // 扫描网段中的所有IP
      final int totalHosts = 255;
      int scannedHosts = 0;
      
      // 保存历史发现的设备
      await _loadHistoryDevices();
      
      // 创建扫描任务
      final futures = <Future>[];
      
      for (int i = 1; i <= totalHosts; i++) {
        final host = '$subnet.$i';
        
        // 跳过自己
        if (host == ip) {
          scannedHosts++;
          _updateProgress(scannedHosts / totalHosts);
          continue;
        }
        
        futures.add(_scanHost(host, portsToScan, timeout).then((_) {
          scannedHosts++;
          _updateProgress(scannedHosts / totalHosts);
          
          if (onProgress != null) {
            onProgress(scannedHosts / totalHosts);
          }
        }));
      }
      
      // 等待所有扫描任务完成
      await Future.wait(futures);
      
      // 保存发现的设备
      await _saveDiscoveredDevices();
      
    } catch (e) {
      debugPrint('扫描网络出错: $e');
    } finally {
      _isScanning = false;
      _scanProgress = 1.0;
      _progressController.add(_scanProgress);
      _devicesController.add(_discoveredDevices);
    }
  }
  
  // 扫描单个主机
  Future<void> _scanHost(String host, List<int> ports, Duration timeout) async {
    for (final port in ports) {
      try {
        // 尝试连接到主机的指定端口
        final socket = await Socket.connect(host, port, timeout: timeout)
            .catchError((e) => null);
        
        if (socket != null) {
          // 关闭连接
          await socket.close();
          
          // 确定设备类型
          final deviceType = _determineDeviceType(port);
          final deviceName = await _resolveHostname(host) ?? 'Unknown Device';
          
          // 创建设备对象
          final device = DiscoveredDevice(
            ip: host,
            name: deviceName,
            type: deviceType,
            ports: [port],
            lastSeen: DateTime.now(),
          );
          
          // 检查是否已经发现过这个设备
          final existingIndex = _discoveredDevices.indexWhere((d) => d.ip == host);
          
          if (existingIndex >= 0) {
            // 更新设备信息
            final existing = _discoveredDevices[existingIndex];
            if (!existing.ports.contains(port)) {
              _discoveredDevices[existingIndex] = existing.copyWith(
                ports: [...existing.ports, port],
                lastSeen: DateTime.now(),
              );
            }
          } else {
            // 添加新设备
            _discoveredDevices.add(device);
            _devicesController.add(_discoveredDevices);
          }
        }
      } catch (e) {
        // 忽略连接错误
      }
    }
  }
  
  // 根据端口确定设备类型
  DeviceType _determineDeviceType(int port) {
    switch (port) {
      case 21: // FTP
        return DeviceType.ftp;
      case 22: // SSH
        return DeviceType.ssh;
      case 80: // HTTP
      case 8080:
        return DeviceType.http;
      case 443: // HTTPS
        return DeviceType.https;
      case 445: // SMB
      case 139: // NetBIOS
        return DeviceType.smb;
      case 990: // FTPS
        return DeviceType.ftps;
      default:
        return DeviceType.unknown;
    }
  }
  
  // 解析主机名
  Future<String?> _resolveHostname(String ip) async {
    try {
      final result = await InternetAddress(ip).reverse();
      return result.host;
    } catch (e) {
      return null;
    }
  }
  
  // 更新扫描进度
  void _updateProgress(double progress) {
    _scanProgress = progress;
    _progressController.add(progress);
  }
  
  // 加载历史发现的设备
  Future<void> _loadHistoryDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? devicesJson = prefs.getStringList('discovered_devices');
      
      if (devicesJson != null) {
        final devices = devicesJson
            .map((json) => DiscoveredDevice.fromJson(json))
            .toList();
        
        // 只保留最近7天内发现的设备
        final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
        final recentDevices = devices
            .where((device) => device.lastSeen.isAfter(cutoffDate))
            .toList();
        
        _discoveredDevices.addAll(recentDevices);
        _devicesController.add(_discoveredDevices);
      }
    } catch (e) {
      debugPrint('加载历史设备出错: $e');
    }
  }
  
  // 保存发现的设备
  Future<void> _saveDiscoveredDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> devicesJson = _discoveredDevices
          .map((device) => device.toJson())
          .toList();
      
      await prefs.setStringList('discovered_devices', devicesJson);
    } catch (e) {
      debugPrint('保存设备出错: $e');
    }
  }
  
  // 清理资源
  void dispose() {
    _devicesController.close();
    _progressController.close();
  }
} 
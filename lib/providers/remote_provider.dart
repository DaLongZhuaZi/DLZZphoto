import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/remote_source.dart';
import '../models/media_file.dart';
import '../utils/constants.dart';

class RemoteProvider with ChangeNotifier {
  final List<RemoteSource> _remoteSources = [];
  final Map<String, List<MediaFile>> _remoteFiles = {};
  bool _isLoading = false;
  String? _currentSource;
  String? _errorMessage;
  
  // 安全存储
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Getters
  List<RemoteSource> get remoteSources => _remoteSources;
  Map<String, List<MediaFile>> get remoteFiles => _remoteFiles;
  bool get isLoading => _isLoading;
  String? get currentSource => _currentSource;
  String? get errorMessage => _errorMessage;
  
  RemoteProvider() {
    _loadRemoteSources();
  }
  
  // 加载远程源
  Future<void> _loadRemoteSources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final sourceIds = await _secureStorage.read(key: AppConstants.remoteSourcesKey);
      
      if (sourceIds != null) {
        final List<String> ids = sourceIds.split(',');
        
        for (final id in ids) {
          final sourceJson = await _secureStorage.read(key: 'source_$id');
          if (sourceJson != null) {
            final source = RemoteSource.fromJson(jsonDecode(sourceJson));
            _remoteSources.add(source);
          }
        }
      }
    } catch (e) {
      _errorMessage = '加载远程源时出错: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 保存远程源
  Future<void> _saveRemoteSources() async {
    try {
      final List<String> ids = _remoteSources.map((s) => s.id).toList();
      await _secureStorage.write(key: AppConstants.remoteSourcesKey, value: ids.join(','));
      
      for (final source in _remoteSources) {
        await _secureStorage.write(
          key: 'source_${source.id}',
          value: jsonEncode(source.toJson()),
        );
      }
    } catch (e) {
      _errorMessage = '保存远程源时出错: $e';
      notifyListeners();
    }
  }
  
  // 添加远程源
  Future<void> addRemoteSource(RemoteSource source) async {
    _remoteSources.add(source);
    await _saveRemoteSources();
    notifyListeners();
  }
  
  // 更新远程源
  Future<void> updateRemoteSource(RemoteSource updatedSource) async {
    final index = _remoteSources.indexWhere((s) => s.id == updatedSource.id);
    if (index != -1) {
      _remoteSources[index] = updatedSource;
      await _saveRemoteSources();
      notifyListeners();
    }
  }
  
  // 删除远程源
  Future<void> removeRemoteSource(String id) async {
    _remoteSources.removeWhere((s) => s.id == id);
    _remoteFiles.remove(id);
    await _secureStorage.delete(key: 'source_$id');
    await _saveRemoteSources();
    notifyListeners();
  }
  
  // 设置当前源
  void setCurrentSource(String? sourceId) {
    _currentSource = sourceId;
    notifyListeners();
  }
  
  // 获取当前源的文件
  List<MediaFile> getCurrentSourceFiles() {
    if (_currentSource == null) {
      return [];
    }
    return _remoteFiles[_currentSource] ?? [];
  }
  
  // 扫描远程源
  Future<void> scanRemoteSource(String sourceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final sourceIndex = _remoteSources.indexWhere((s) => s.id == sourceId);
      if (sourceIndex == -1) {
        _errorMessage = '找不到远程源';
        return;
      }
      
      final source = _remoteSources[sourceIndex];
      final List<MediaFile> files = [];
      
      switch (source.type) {
        case AppConstants.sourceTypeHttp:
          await _scanHttpSource(source, files);
          break;
        case AppConstants.sourceTypeFtp:
          await _scanFtpSource(source, files);
          break;
        case AppConstants.sourceTypeFtps:
          await _scanFtpSource(source, files, secure: true);
          break;
        case AppConstants.sourceTypeSmb:
          await _scanSmbSource(source, files);
          break;
        case AppConstants.sourceTypeWebdav:
          await _scanWebdavSource(source, files);
          break;
      }
      
      _remoteFiles[sourceId] = files;
      
      // 更新最后同步时间
      final updatedSource = source.copyWith(lastSyncDate: DateTime.now());
      _remoteSources[sourceIndex] = updatedSource;
      await _saveRemoteSources();
      
    } catch (e) {
      _errorMessage = '扫描远程源时出错: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 扫描HTTP源
  Future<void> _scanHttpSource(RemoteSource source, List<MediaFile> files) async {
    try {
      final url = source.url;
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // 尝试解析目录列表
        final content = response.body;
        
        // 简单的HTML解析，寻找链接
        final linkRegex = RegExp("href=[\"']([^\"']*)[\"']");
        final matches = linkRegex.allMatches(content);
        
        for (final match in matches) {
          final link = match.group(1);
          if (link != null && !link.startsWith('?') && !link.startsWith('/')) {
            final fileUrl = Uri.parse(url).resolve(link).toString();
            final fileName = path.basename(link);
            final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
            
            // 检查是否为支持的媒体文件
            if (AppConstants.supportedImageFormats.contains(extension)) {
              files.add(MediaFile.fromRemoteFile(
                url: fileUrl,
                name: fileName,
                type: MediaType.image,
                modified: DateTime.now(),
                size: 0, // 无法确定大小
                sourceType: 'HTTP',
                parentFolder: url,
              ));
            } else if (AppConstants.supportedVideoFormats.contains(extension)) {
              files.add(MediaFile.fromRemoteFile(
                url: fileUrl,
                name: fileName,
                type: MediaType.video,
                modified: DateTime.now(),
                size: 0, // 无法确定大小
                sourceType: 'HTTP',
                parentFolder: url,
              ));
            }
          }
        }
      }
    } catch (e) {
      throw Exception('HTTP源扫描失败: $e');
    }
  }
  
  // 扫描FTP源
  Future<void> _scanFtpSource(RemoteSource source, List<MediaFile> files, {bool secure = false}) async {
    try {
      final defaultPort = secure ? AppConstants.defaultPortFtps : AppConstants.defaultPortFtp;
      final ftpConnect = FTPConnect(
        source.url.replaceAll('ftp://', '').replaceAll('ftps://', ''),
        port: source.port ?? defaultPort,
        user: source.username ?? 'anonymous',
        pass: source.password ?? '',
        timeout: 30,
        securityType: secure ? SecurityType.FTPS : SecurityType.FTP,
      );
      
      await ftpConnect.connect();
      final dirResult = await ftpConnect.listDirectoryContent();
      await ftpConnect.disconnect();
      
      for (final ftpEntry in dirResult) {
        if (ftpEntry.type == FTPEntryType.FILE) {
          final fileName = ftpEntry.name;
          final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
          
          // 检查是否为支持的媒体文件
          if (AppConstants.supportedImageFormats.contains(extension)) {
            files.add(MediaFile.fromRemoteFile(
              url: '${source.url}/$fileName',
              name: fileName,
              type: MediaType.image,
              modified: ftpEntry.modifyTime ?? DateTime.now(),
              size: ftpEntry.size ?? 0,
              sourceType: secure ? 'FTPS' : 'FTP',
              parentFolder: source.url,
            ));
          } else if (AppConstants.supportedVideoFormats.contains(extension)) {
            files.add(MediaFile.fromRemoteFile(
              url: '${source.url}/$fileName',
              name: fileName,
              type: MediaType.video,
              modified: ftpEntry.modifyTime ?? DateTime.now(),
              size: ftpEntry.size ?? 0,
              sourceType: secure ? 'FTPS' : 'FTP',
              parentFolder: source.url,
            ));
          }
        }
      }
    } catch (e) {
      throw Exception('FTP源扫描失败: $e');
    }
  }
  
  // 扫描SMB源
  Future<void> _scanSmbSource(RemoteSource source, List<MediaFile> files) async {
    try {
      // SMB客户端实现
      // 注意：这里使用的是示例实现，实际应用中可能需要更复杂的SMB客户端
      // 可以考虑使用native方法或其他库
      
      // 这里只是占位符，实际实现需要根据具体的SMB库
      throw UnimplementedError('SMB源扫描尚未实现');
    } catch (e) {
      throw Exception('SMB源扫描失败: $e');
    }
  }
  
  // 扫描WebDAV源
  Future<void> _scanWebdavSource(RemoteSource source, List<MediaFile> files) async {
    try {
      // 创建WebDAV客户端
      final client = webdav.newClient(
        source.url,
        user: source.username ?? '',
        password: source.password ?? '',
      );
      
      // 列出目录内容
      final contents = await client.readDir('/');
      
      for (final item in contents) {
        if (item.isDir != true) { // 如果是文件
          final fileName = item.name;
          if (fileName == null) continue;
          
          final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
          
          // 检查是否为支持的媒体文件
          if (AppConstants.supportedImageFormats.contains(extension)) {
            files.add(MediaFile.fromRemoteFile(
              url: '${source.url}/${item.path ?? fileName}',
              name: fileName,
              type: MediaType.image,
              modified: item.mTime ?? DateTime.now(),
              size: item.size ?? 0,
              sourceType: 'WebDAV',
              parentFolder: source.url,
            ));
          } else if (AppConstants.supportedVideoFormats.contains(extension)) {
            files.add(MediaFile.fromRemoteFile(
              url: '${source.url}/${item.path ?? fileName}',
              name: fileName,
              type: MediaType.video,
              modified: item.mTime ?? DateTime.now(),
              size: item.size ?? 0,
              sourceType: 'WebDAV',
              parentFolder: source.url,
            ));
          }
        }
      }
    } catch (e) {
      throw Exception('WebDAV源扫描失败: $e');
    }
  }
  
  // 下载远程文件
  Future<File?> downloadRemoteFile(MediaFile file) async {
    if (!file.isRemote) return null;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = path.join(tempDir.path, file.name);
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        return localFile;
      }
      
      final sourceType = file.sourceType;
      
      if (sourceType == 'HTTP') {
        final response = await http.get(Uri.parse(file.remoteUrl!));
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile;
      } else if (sourceType == 'FTP' || sourceType == 'FTPS') {
        final source = _remoteSources.firstWhere(
          (s) => file.remoteUrl!.startsWith(s.url),
          orElse: () => throw Exception('找不到对应的远程源'),
        );
        
        final ftpConnect = FTPConnect(
          source.url.replaceAll('ftp://', '').replaceAll('ftps://', ''),
          port: source.port ?? 21,
          user: source.username ?? 'anonymous',
          pass: source.password ?? '',
          timeout: 30,
          securityType: sourceType == 'FTPS' ? SecurityType.FTPS : SecurityType.FTP,
        );
        
        await ftpConnect.connect();
        final remotePath = file.remoteUrl!.replaceAll(source.url, '');
        await ftpConnect.downloadFile(remotePath, localFile);
        await ftpConnect.disconnect();
        return localFile;
      } else if (sourceType == 'WebDAV') {
        final source = _remoteSources.firstWhere(
          (s) => file.remoteUrl!.startsWith(s.url),
          orElse: () => throw Exception('找不到对应的远程源'),
        );
        
        final client = webdav.newClient(
          source.url,
          user: source.username ?? '',
          password: source.password ?? '',
        );
        
        final remotePath = file.remoteUrl!.replaceAll(source.url, '');
        final data = await client.read(remotePath);
        await localFile.writeAsBytes(data);
        return localFile;
      }
      
      return null;
    } catch (e) {
      _errorMessage = '下载文件失败: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 创建新的远程源
  RemoteSource createRemoteSource({
    required String name,
    required String url,
    required int type,
    String? username,
    String? password,
    String? domain,
    int? port,
  }) {
    // 如果未指定端口，使用默认端口
    int? effectivePort = port;
    if (port == null) {
      switch (type) {
        case AppConstants.sourceTypeHttp:
          effectivePort = url.startsWith('https://') ? 
            AppConstants.defaultPortHttps : AppConstants.defaultPortHttp;
          break;
        case AppConstants.sourceTypeFtp:
          effectivePort = AppConstants.defaultPortFtp;
          break;
        case AppConstants.sourceTypeFtps:
          effectivePort = AppConstants.defaultPortFtps;
          break;
        case AppConstants.sourceTypeSmb:
          effectivePort = AppConstants.defaultPortSmb;
          break;
        case AppConstants.sourceTypeWebdav:
          effectivePort = url.startsWith('https://') ? 
            AppConstants.defaultPortWebdavs : AppConstants.defaultPortWebdav;
          break;
      }
    }
    
    final uuid = const Uuid().v4();
    return RemoteSource(
      id: uuid,
      name: name,
      url: url,
      type: type,
      username: username,
      password: password,
      domain: domain,
      port: effectivePort,
      isActive: true,
      addedDate: DateTime.now(),
    );
  }
} 
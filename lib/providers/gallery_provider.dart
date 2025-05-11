import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_file.dart';
import '../utils/constants.dart';

class GalleryProvider with ChangeNotifier {
  List<MediaFile> _mediaFiles = [];
  List<String> _folders = [];
  Map<String, List<MediaFile>> _folderContents = {};
  bool _isLoading = false;
  String? _currentFolder;
  String? _errorMessage;
  
  // 自定义分组
  Map<String, List<String>> _customGroups = {};
  
  // 选中的文件（用于批量操作）
  final Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;
  
  // 标签和收藏管理
  final Map<String, List<String>> _fileTags = {};
  final Set<String> _favoriteFiles = {};
  final Set<String> _hiddenFiles = {};
  
  // Getters
  List<MediaFile> get mediaFiles => _mediaFiles;
  List<String> get folders => _folders;
  Map<String, List<MediaFile>> get folderContents => _folderContents;
  bool get isLoading => _isLoading;
  String? get currentFolder => _currentFolder;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get customGroups => _customGroups;
  Set<String> get selectedFiles => _selectedFiles;
  bool get isSelectionMode => _isSelectionMode;
  
  // 获取所有文件（包括当前文件夹中的文件）
  List<MediaFile> get allFiles {
    if (_currentFolder == null) {
      return _mediaFiles;
    } else {
      return _folderContents[_currentFolder] ?? [];
    }
  }
  
  // 获取收藏的文件
  List<MediaFile> get favoriteFiles {
    return _mediaFiles.where((file) => _favoriteFiles.contains(file.path)).toList();
  }
  
  // 获取带有指定标签的文件
  List<MediaFile> getFilesByTag(String tag) {
    final filePaths = <String>{};
    
    _fileTags.forEach((path, tags) {
      if (tags.contains(tag)) {
        filePaths.add(path);
      }
    });
    
    return _mediaFiles.where((file) => filePaths.contains(file.path)).toList();
  }
  
  // 获取所有标签
  List<String> get allTags {
    final tags = <String>{};
    
    _fileTags.forEach((path, fileTags) {
      tags.addAll(fileTags);
    });
    
    return tags.toList()..sort();
  }
  
  GalleryProvider() {
    _loadCustomGroups();
    _loadTagsAndFavorites();
    requestPermissions();
  }
  
  // 请求权限并加载媒体文件
  Future<void> requestPermissions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 请求存储权限
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();
      
      if (storageStatus.isGranted || photosStatus.isGranted || videosStatus.isGranted) {
        await scanMediaFiles();
      } else {
        _errorMessage = '需要存储权限来访问媒体文件';
      }
    } catch (e) {
      _errorMessage = '加载媒体文件时出错: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 扫描媒体文件
  Future<void> scanMediaFiles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final List<MediaFile> allFiles = [];
      final Set<String> folderPaths = {};
      
      // 获取外部存储目录
      final externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null) {
        for (final dir in externalDirs) {
          // 获取DCIM和Pictures目录
          final dcimDir = Directory(path.join(dir.path, '..', '..', 'DCIM'));
          final picturesDir = Directory(path.join(dir.path, '..', '..', 'Pictures'));
          
          if (await dcimDir.exists()) {
            await _scanDirectory(dcimDir, allFiles, folderPaths);
          }
          
          if (await picturesDir.exists()) {
            await _scanDirectory(picturesDir, allFiles, folderPaths);
          }
        }
      }
      
      // 获取下载目录
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        await _scanDirectory(downloadDir, allFiles, folderPaths);
      }
      
      _mediaFiles = allFiles;
      _folders = folderPaths.toList();
      
      // 按文件夹组织媒体文件
      _folderContents = {};
      for (final file in _mediaFiles) {
        final folderPath = file.parentFolder ?? '';
        if (!_folderContents.containsKey(folderPath)) {
          _folderContents[folderPath] = [];
        }
        _folderContents[folderPath]!.add(file);
      }
      
      // 检测相似文件夹
      detectSimilarFolders();
    } catch (e) {
      _errorMessage = '扫描媒体文件时出错: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 扫描目录
  Future<void> _scanDirectory(Directory directory, List<MediaFile> files, Set<String> folders) async {
    try {
      final List<FileSystemEntity> entities = await directory.list(recursive: false).toList();
      
      // 添加文件夹
      folders.add(directory.path);
      
      for (final entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase().replaceAll('.', '');
          
          // 检查是否为支持的媒体文件
          if (AppConstants.supportedImageFormats.contains(extension) || 
              AppConstants.supportedVideoFormats.contains(extension)) {
            final mediaFile = await MediaFile.fromFile(entity);
            files.add(mediaFile);
          }
        } else if (entity is Directory) {
          // 递归扫描子目录
          await _scanDirectory(entity, files, folders);
        }
      }
    } catch (e) {
      debugPrint('扫描目录 ${directory.path} 时出错: $e');
    }
  }
  
  // 设置当前文件夹
  void setCurrentFolder(String folderPath) {
    _currentFolder = folderPath;
    notifyListeners();
  }
  
  // 导航返回上一级文件夹
  void navigateBack() {
    if (_currentFolder == null) return;
    
    final parts = _currentFolder!.split('/');
    if (parts.length <= 1) {
      _currentFolder = null;
    } else {
      parts.removeLast();
      _currentFolder = parts.join('/');
    }
    
    notifyListeners();
  }
  
  // 获取当前文件夹的媒体文件
  List<MediaFile> getCurrentFolderFiles() {
    if (_currentFolder == null) {
      return _mediaFiles;
    }
    return _folderContents[_currentFolder] ?? [];
  }
  
  // 获取指定文件夹中的所有文件
  List<MediaFile> getFilesInFolder(String folderPath) {
    return _mediaFiles.where((file) => 
      file.parentFolder == folderPath
    ).toList();
  }
  
  // 按名称排序媒体文件
  void sortByName(bool descending) {
    _mediaFiles.sort((a, b) => descending 
        ? b.name.compareTo(a.name) 
        : a.name.compareTo(b.name));
    
    // 同时排序文件夹内容
    _folderContents.forEach((key, files) {
      files.sort((a, b) => descending 
          ? b.name.compareTo(a.name) 
          : a.name.compareTo(b.name));
    });
    
    notifyListeners();
  }
  
  // 按日期排序媒体文件
  void sortByDate(bool descending) {
    _mediaFiles.sort((a, b) => descending 
        ? b.modified.compareTo(a.modified) 
        : a.modified.compareTo(b.modified));
    
    // 同时排序文件夹内容
    _folderContents.forEach((key, files) {
      files.sort((a, b) => descending 
          ? b.modified.compareTo(a.modified) 
          : a.modified.compareTo(b.modified));
    });
    
    notifyListeners();
  }
  
  // 按大小排序媒体文件
  void sortBySize(bool descending) {
    _mediaFiles.sort((a, b) => descending 
        ? b.size.compareTo(a.size) 
        : a.size.compareTo(b.size));
    
    // 同时排序文件夹内容
    _folderContents.forEach((key, files) {
      files.sort((a, b) => descending 
          ? b.size.compareTo(a.size) 
          : a.size.compareTo(b.size));
    });
    
    notifyListeners();
  }
  
  // 按类型排序媒体文件
  void sortByType(bool descending) {
    _mediaFiles.sort((a, b) {
      final typeComparison = a.type.index.compareTo(b.type.index);
      if (typeComparison != 0) {
        return descending ? -typeComparison : typeComparison;
      }
      // 相同类型则按名称排序
      return a.name.compareTo(b.name);
    });
    
    // 同时排序文件夹内容
    _folderContents.forEach((key, files) {
      files.sort((a, b) {
        final typeComparison = a.type.index.compareTo(b.type.index);
        if (typeComparison != 0) {
          return descending ? -typeComparison : typeComparison;
        }
        // 相同类型则按名称排序
        return a.name.compareTo(b.name);
      });
    });
    
    notifyListeners();
  }
  
  // 应用排序
  void applySorting(int sortType, bool descending) {
    switch (sortType) {
      case AppConstants.sortByName:
        sortByName(descending);
        break;
      case AppConstants.sortByDate:
        sortByDate(descending);
        break;
      case AppConstants.sortBySize:
        sortBySize(descending);
        break;
      case AppConstants.sortByType:
        sortByType(descending);
        break;
      case AppConstants.sortByCustom:
        // 自定义排序实现
        break;
    }
  }
  
  // 文件删除方法
  Future<bool> deleteFile(MediaFile file) async {
    try {
      if (!file.isRemote) {
        final fileObj = File(file.path);
        await fileObj.delete();
        
        // 从列表中移除文件
        _mediaFiles.removeWhere((f) => f.path == file.path);
        
        // 从文件夹内容中移除
        if (file.parentFolder != null) {
          _folderContents[file.parentFolder]?.removeWhere((f) => f.path == file.path);
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除文件失败: $e');
      return false;
    }
  }
  
  // 批量删除文件
  Future<int> deleteSelectedFiles() async {
    int deletedCount = 0;
    
    for (final filePath in _selectedFiles.toList()) {
      final fileToDelete = _mediaFiles.firstWhere(
        (file) => file.path == filePath,
        orElse: () => throw Exception('找不到文件'),
      );
      
      final success = await deleteFile(fileToDelete);
      if (success) {
        deletedCount++;
        _selectedFiles.remove(filePath);
      }
    }
    
    exitSelectionMode();
    return deletedCount;
  }
  
  // 选择文件
  void toggleFileSelection(String filePath) {
    if (_selectedFiles.contains(filePath)) {
      _selectedFiles.remove(filePath);
    } else {
      _selectedFiles.add(filePath);
    }
    
    // 如果没有选中任何文件，退出选择模式
    if (_selectedFiles.isEmpty) {
      _isSelectionMode = false;
    } else {
      _isSelectionMode = true;
    }
    
    notifyListeners();
  }
  
  // 进入选择模式
  void enterSelectionMode() {
    _isSelectionMode = true;
    notifyListeners();
  }
  
  // 退出选择模式
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedFiles.clear();
    notifyListeners();
  }
  
  // 全选/取消全选
  void toggleSelectAll() {
    final currentFiles = allFiles;
    
    if (_selectedFiles.length == currentFiles.length) {
      // 如果已经全选，则取消全选
      _selectedFiles.clear();
      _isSelectionMode = false;
    } else {
      // 否则全选
      _selectedFiles.clear();
      for (final file in currentFiles) {
        _selectedFiles.add(file.path);
      }
      _isSelectionMode = true;
    }
    
    notifyListeners();
  }
  
  // 加载标签和收藏
  Future<void> _loadTagsAndFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载标签
      final tagsJson = prefs.getStringList('file_tags');
      if (tagsJson != null) {
        _fileTags.clear();
        for (final json in tagsJson) {
          final parts = json.split('|');
          if (parts.length >= 2) {
            final filePath = parts[0];
            final tags = parts.sublist(1);
            _fileTags[filePath] = tags;
          }
        }
      }
      
      // 加载收藏
      final favorites = prefs.getStringList('favorite_files');
      if (favorites != null) {
        _favoriteFiles.clear();
        _favoriteFiles.addAll(favorites);
      }
      
      // 加载隐藏文件
      final hidden = prefs.getStringList('hidden_files');
      if (hidden != null) {
        _hiddenFiles.clear();
        _hiddenFiles.addAll(hidden);
      }
    } catch (e) {
      debugPrint('加载标签和收藏时出错: $e');
    }
  }
  
  // 保存标签
  Future<void> _saveFileTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> tagsJson = [];
      
      _fileTags.forEach((filePath, tags) {
        final json = [filePath, ...tags].join('|');
        tagsJson.add(json);
      });
      
      await prefs.setStringList('file_tags', tagsJson);
    } catch (e) {
      debugPrint('保存文件标签时出错: $e');
    }
  }
  
  // 保存收藏
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_files', _favoriteFiles.toList());
    } catch (e) {
      debugPrint('保存收藏文件时出错: $e');
    }
  }
  
  // 保存隐藏文件
  Future<void> _saveHiddenFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_files', _hiddenFiles.toList());
    } catch (e) {
      debugPrint('保存隐藏文件时出错: $e');
    }
  }
  
  // 添加文件标签
  Future<void> addFileTag(String filePath, String tag) async {
    if (!_fileTags.containsKey(filePath)) {
      _fileTags[filePath] = [];
    }
    
    if (!_fileTags[filePath]!.contains(tag)) {
      _fileTags[filePath]!.add(tag);
      await _saveFileTags();
      notifyListeners();
    }
  }
  
  // 移除文件标签
  Future<void> removeFileTag(String filePath, String tag) async {
    if (_fileTags.containsKey(filePath)) {
      _fileTags[filePath]!.remove(tag);
      
      if (_fileTags[filePath]!.isEmpty) {
        _fileTags.remove(filePath);
      }
      
      await _saveFileTags();
      notifyListeners();
    }
  }
  
  // 获取文件标签
  List<String> getFileTags(String filePath) {
    return _fileTags[filePath] ?? [];
  }
  
  // 切换收藏状态
  Future<void> toggleFavorite(String filePath) async {
    if (_favoriteFiles.contains(filePath)) {
      _favoriteFiles.remove(filePath);
    } else {
      _favoriteFiles.add(filePath);
    }
    
    await _saveFavorites();
    notifyListeners();
  }
  
  // 检查是否收藏
  bool isFavorite(String filePath) {
    return _favoriteFiles.contains(filePath);
  }
  
  // 切换隐藏状态
  Future<void> toggleHidden(String filePath) async {
    if (_hiddenFiles.contains(filePath)) {
      _hiddenFiles.remove(filePath);
    } else {
      _hiddenFiles.add(filePath);
    }
    
    await _saveHiddenFiles();
    notifyListeners();
  }
  
  // 检查是否隐藏
  bool isHidden(String filePath) {
    return _hiddenFiles.contains(filePath);
  }
  
  // 批量添加标签
  Future<void> addTagToSelectedFiles(String tag) async {
    for (final filePath in _selectedFiles) {
      await addFileTag(filePath, tag);
    }
  }
  
  // 批量添加到收藏
  Future<void> addSelectedFilesToFavorites() async {
    _favoriteFiles.addAll(_selectedFiles);
    await _saveFavorites();
    notifyListeners();
  }
  
  // 批量从收藏中移除
  Future<void> removeSelectedFilesFromFavorites() async {
    for (final filePath in _selectedFiles) {
      _favoriteFiles.remove(filePath);
    }
    await _saveFavorites();
    notifyListeners();
  }
  
  // 批量隐藏文件
  Future<void> hideSelectedFiles() async {
    _hiddenFiles.addAll(_selectedFiles);
    await _saveHiddenFiles();
    notifyListeners();
  }
  
  // 检测重复文件
  List<List<MediaFile>> detectDuplicateFiles() {
    final Map<String, List<MediaFile>> filesByHash = {};
    final List<List<MediaFile>> result = [];
    
    // 按照文件大小和文件名分组
    for (final file in _mediaFiles) {
      // 创建一个简单的"指纹"，基于文件大小和名称
      final fileHash = '${file.size}_${file.name}';
      
      if (filesByHash.containsKey(fileHash)) {
        filesByHash[fileHash]!.add(file);
      } else {
        filesByHash[fileHash] = [file];
      }
    }
    
    // 筛选出重复的文件组
    filesByHash.forEach((hash, files) {
      if (files.length > 1) {
        result.add(files);
      }
    });
    
    // 按照文件组中文件数量排序（从多到少）
    result.sort((a, b) => b.length.compareTo(a.length));
    
    return result;
  }
  
  // 检测相似文件夹
  void detectSimilarFolders() {
    final Map<String, List<String>> similarFolders = {};
    
    // 提取文件夹名称的关键部分
    for (final folderPath in _folders) {
      final folderName = path.basename(folderPath).toLowerCase();
      
      // 移除常见前缀和后缀，保留核心名称
      String coreName = folderName
          .replaceAll(RegExp(r'^\d+[-_\s]*'), '') // 移除开头的数字和分隔符
          .replaceAll(RegExp(r'[-_\s]*\d+$'), ''); // 移除结尾的分隔符和数字
      
      // 如果核心名称长度过短，使用原始名称
      if (coreName.length < 3) {
        coreName = folderName;
      }
      
      if (!similarFolders.containsKey(coreName)) {
        similarFolders[coreName] = [];
      }
      similarFolders[coreName]!.add(folderPath);
    }
    
    // 只保留有多个文件夹的相似组
    _customGroups = {};
    similarFolders.forEach((coreName, folders) {
      if (folders.length > 1) {
        _customGroups[coreName] = folders;
      }
    });
    
    // 保存自定义分组
    _saveCustomGroups();
  }
  
  // 加载自定义分组
  Future<void> _loadCustomGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getStringList(AppConstants.customGroupsKey);
      
      if (groupsJson != null) {
        _customGroups = {};
        for (final json in groupsJson) {
          final parts = json.split('|');
          if (parts.length >= 2) {
            final groupName = parts[0];
            final folderPaths = parts.sublist(1);
            _customGroups[groupName] = folderPaths;
          }
        }
      }
    } catch (e) {
      debugPrint('加载自定义分组时出错: $e');
    }
  }
  
  // 保存自定义分组
  Future<void> _saveCustomGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> groupsJson = [];
      
      _customGroups.forEach((groupName, folderPaths) {
        final json = [groupName, ...folderPaths].join('|');
        groupsJson.add(json);
      });
      
      await prefs.setStringList(AppConstants.customGroupsKey, groupsJson);
    } catch (e) {
      debugPrint('保存自定义分组时出错: $e');
    }
  }
  
  // 添加自定义分组
  Future<void> addCustomGroup(String groupName, List<String> folderPaths) async {
    _customGroups[groupName] = folderPaths;
    await _saveCustomGroups();
    notifyListeners();
  }
  
  // 删除自定义分组
  Future<void> removeCustomGroup(String groupName) async {
    _customGroups.remove(groupName);
    await _saveCustomGroups();
    notifyListeners();
  }
  
  // 更新自定义分组
  Future<void> updateCustomGroup(String groupName, List<String> folderPaths) async {
    if (_customGroups.containsKey(groupName)) {
      _customGroups[groupName] = folderPaths;
      await _saveCustomGroups();
      notifyListeners();
    }
  }
} 
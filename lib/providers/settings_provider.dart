import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

import '../models/media_file.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _showHiddenFiles = false;
  String _language = 'zh_CN';
  ViewMode _viewMode = ViewMode.grid;
  SortBy _sortBy = SortBy.date;
  SortOrder _sortOrder = SortOrder.descending;
  
  // 新增属性
  int _sortType = 1; // 0: 名称, 1: 日期, 2: 大小, 3: 类型
  bool _sortDescending = true;
  bool _showFolders = true;
  bool _showImages = true;
  bool _showVideos = true;
  bool _autoPlayVideo = false;
  bool _loopVideo = false;
  double _defaultBrightness = 0.7;
  double _defaultVolume = 0.5;
  double _defaultPlaybackSpeed = 1.0;
  
  bool get isDarkMode => _isDarkMode;
  bool get showHiddenFiles => _showHiddenFiles;
  String get language => _language;
  ViewMode get viewMode => _viewMode;
  SortBy get sortBy => _sortBy;
  SortOrder get sortOrder => _sortOrder;
  
  // 新增getter
  int get sortType => _sortType;
  bool get sortDescending => _sortDescending;
  bool get showFolders => _showFolders;
  bool get showImages => _showImages;
  bool get showVideos => _showVideos;
  bool get autoPlayVideo => _autoPlayVideo;
  bool get loopVideo => _loopVideo;
  double get defaultBrightness => _defaultBrightness;
  double get defaultVolume => _defaultVolume;
  double get defaultPlaybackSpeed => _defaultPlaybackSpeed;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _showHiddenFiles = _prefs.getBool('showHiddenFiles') ?? false;
    _language = _prefs.getString('language') ?? 'zh_CN';
    
    final viewModeIndex = _prefs.getInt('viewMode') ?? 0;
    _viewMode = ViewMode.values[viewModeIndex];
    
    final sortByIndex = _prefs.getInt('sortBy') ?? 1; // 默认按日期
    _sortBy = SortBy.values[sortByIndex];
    
    final sortOrderIndex = _prefs.getInt('sortOrder') ?? 1; // 默认降序
    _sortOrder = SortOrder.values[sortOrderIndex];
    
    // 加载新增设置
    _sortType = _prefs.getInt('sortType') ?? 1;
    _sortDescending = _prefs.getBool('sortDescending') ?? true;
    _showFolders = _prefs.getBool('showFolders') ?? true;
    _showImages = _prefs.getBool('showImages') ?? true;
    _showVideos = _prefs.getBool('showVideos') ?? true;
    _autoPlayVideo = _prefs.getBool('autoPlayVideo') ?? false;
    _loopVideo = _prefs.getBool('loopVideo') ?? false;
    _defaultBrightness = _prefs.getDouble('defaultBrightness') ?? 0.7;
    _defaultVolume = _prefs.getDouble('defaultVolume') ?? 0.5;
    _defaultPlaybackSpeed = _prefs.getDouble('defaultPlaybackSpeed') ?? 1.0;
    
    notifyListeners();
  }
  
  set isDarkMode(bool value) {
    _isDarkMode = value;
    _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
  
  set showHiddenFiles(bool value) {
    _showHiddenFiles = value;
    _prefs.setBool('showHiddenFiles', value);
    notifyListeners();
  }
  
  set language(String value) {
    _language = value;
    _prefs.setString('language', value);
    notifyListeners();
  }
  
  set viewMode(ViewMode value) {
    _viewMode = value;
    _prefs.setInt('viewMode', value.index);
    notifyListeners();
  }
  
  set sortBy(SortBy value) {
    _sortBy = value;
    _prefs.setInt('sortBy', value.index);
    notifyListeners();
  }
  
  set sortOrder(SortOrder value) {
    _sortOrder = value;
    _prefs.setInt('sortOrder', value.index);
    notifyListeners();
  }
  
  // 新增setter方法
  void setSortType(int value) {
    _sortType = value;
    _prefs.setInt('sortType', value);
    notifyListeners();
  }
  
  void setSortDescending(bool value) {
    _sortDescending = value;
    _prefs.setBool('sortDescending', value);
    notifyListeners();
  }
  
  void setViewMode(ViewMode value) {
    _viewMode = value;
    _prefs.setInt('viewMode', value.index);
    notifyListeners();
  }
  
  void setShowFolders(bool value) {
    _showFolders = value;
    _prefs.setBool('showFolders', value);
    notifyListeners();
  }
  
  void setShowImages(bool value) {
    _showImages = value;
    _prefs.setBool('showImages', value);
    notifyListeners();
  }
  
  void setShowVideos(bool value) {
    _showVideos = value;
    _prefs.setBool('showVideos', value);
    notifyListeners();
  }
  
  void setShowHiddenFiles(bool value) {
    _showHiddenFiles = value;
    _prefs.setBool('showHiddenFiles', value);
    notifyListeners();
  }
  
  void setAutoPlayVideo(bool value) {
    _autoPlayVideo = value;
    _prefs.setBool('autoPlayVideo', value);
    notifyListeners();
  }
  
  void setLoopVideo(bool value) {
    _loopVideo = value;
    _prefs.setBool('loopVideo', value);
    notifyListeners();
  }
  
  void setDefaultBrightness(double value) {
    _defaultBrightness = value;
    _prefs.setDouble('defaultBrightness', value);
    notifyListeners();
  }
  
  void setDefaultVolume(double value) {
    _defaultVolume = value;
    _prefs.setDouble('defaultVolume', value);
    notifyListeners();
  }
  
  void setDefaultPlaybackSpeed(double value) {
    _defaultPlaybackSpeed = value;
    _prefs.setDouble('defaultPlaybackSpeed', value);
    notifyListeners();
  }
} 
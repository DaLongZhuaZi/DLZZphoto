import 'package:flutter/material.dart';

// 应用程序常量
class AppConstants {
  // 应用名称
  static const String appName = '照片库';
  
  // 应用版本
  static const String appVersion = '1.0.0';
  
  // 共享首选项键
  static const String themePreference = 'theme_preference';
  static const String sortPreference = 'sort_preference';
  static const String viewModePreference = 'view_mode_preference';
  static const String remoteSourcesKey = 'remote_sources';
  static const String customGroupsKey = 'custom_groups';
  
  // 支持的图片格式
  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif', 'raw', 'svg'
  ];
  
  // 支持的视频格式
  static const List<String> supportedVideoFormats = [
    'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', '3gp', 'mpeg', 'm4v'
  ];
  
  // 排序类型
  static const int sortByName = 0;
  static const int sortByDate = 1;
  static const int sortBySize = 2;
  static const int sortByType = 3;
  static const int sortByCustom = 4;
  
  // 视图模式
  static const int viewModeGrid = 0;
  static const int viewModeList = 1;
  
  // 远程源类型
  static const int sourceTypeHttp = 0;
  static const int sourceTypeFtp = 1;
  static const int sourceTypeFtps = 2;
  static const int sourceTypeSmb = 3;
  static const int sourceTypeWebdav = 4;
  
  // 远程源默认端口
  static const int defaultPortHttp = 80;
  static const int defaultPortHttps = 443;
  static const int defaultPortFtp = 21;
  static const int defaultPortFtps = 990;
  static const int defaultPortSmb = 445;
  static const int defaultPortWebdav = 80;
  static const int defaultPortWebdavs = 443;
}

// 颜色常量
class AppColors {
  static const Color primaryLight = Color(0xFF6200EE);
  static const Color primaryDark = Color(0xFFBB86FC);
  
  static const Color secondaryLight = Color(0xFF03DAC6);
  static const Color secondaryDark = Color(0xFF03DAC6);
  
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  static const Color errorLight = Color(0xFFB00020);
  static const Color errorDark = Color(0xFFCF6679);
  
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF000000);
  
  static const Color onSecondaryLight = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  
  static const Color onBackgroundLight = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  
  static const Color onSurfaceLight = Color(0xFF000000);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);
}

// 尺寸常量
class AppSizes {
  // 边距
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // 圆角
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  
  // 图标尺寸
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  
  // 字体尺寸
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;
  
  // 网格视图中的列数
  static const int gridColumnsPhone = 3;
  static const int gridColumnsTablet = 5;
  static const int gridColumnsLandscape = 7;
}

// 持续时间常量
class AppDurations {
  static const Duration shortest = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
} 
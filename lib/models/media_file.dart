import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/constants.dart';

enum MediaType {
  image,
  video,
  folder,
  unknown
}

enum ViewMode { grid, list }

enum SortBy { name, date, size, type }

enum SortOrder { ascending, descending }

class MediaFile {
  final String id;          // 唯一标识符
  final String path;        // 文件路径
  final String name;        // 文件名
  final MediaType type;     // 媒体类型
  final DateTime modified;  // 修改时间
  final int size;           // 文件大小（字节）
  final String? parentFolder; // 父文件夹路径
  final bool isRemote;      // 是否为远程文件
  final String? remoteUrl;  // 远程URL（如果适用）
  final String? sourceType; // 远程源类型（http/ftp/smb等）
  final int? width;         // 宽度（如果是图片或视频）
  final int? height;        // 高度（如果是图片或视频）
  final int? duration;      // 持续时间（如果是视频，以毫秒为单位）
  final String? thumbnailPath; // 缩略图路径
  final List<String> tags;  // 文件标签
  final bool isFavorite;    // 是否收藏
  final bool isHidden;      // 是否隐藏
  
  MediaFile({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    required this.modified,
    required this.size,
    this.parentFolder,
    this.isRemote = false,
    this.remoteUrl,
    this.sourceType,
    this.width,
    this.height,
    this.duration,
    this.thumbnailPath,
    this.tags = const [],
    this.isFavorite = false,
    this.isHidden = false,
  });
  
  // 从文件创建媒体文件对象
  static Future<MediaFile> fromFile(File file) async {
    final filePath = file.path;
    final fileName = p.basename(filePath);
    final extension = p.extension(filePath).toLowerCase().replaceAll('.', '');
    final fileStats = await file.stat();
    
    // 确定媒体类型
    MediaType mediaType = MediaType.unknown;
    if (AppConstants.supportedImageFormats.contains(extension)) {
      mediaType = MediaType.image;
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      mediaType = MediaType.video;
    }
    
    return MediaFile(
      id: filePath,
      path: filePath,
      name: fileName,
      type: mediaType,
      modified: fileStats.modified,
      size: fileStats.size,
      parentFolder: p.dirname(filePath),
      isRemote: false,
    );
  }
  
  // 从目录创建媒体文件对象
  static Future<MediaFile> fromDirectory(Directory directory) async {
    final dirPath = directory.path;
    final dirName = p.basename(dirPath);
    final dirStats = await directory.stat();
    
    return MediaFile(
      id: dirPath,
      path: dirPath,
      name: dirName,
      type: MediaType.folder,
      modified: dirStats.modified,
      size: 0, // 目录大小需要单独计算
      parentFolder: p.dirname(dirPath),
      isRemote: false,
    );
  }
  
  // 从远程文件创建媒体文件对象
  static MediaFile fromRemoteFile({
    required String url,
    required String name,
    required MediaType type,
    required DateTime modified,
    required int size,
    required String sourceType,
    String? parentFolder,
    int? width,
    int? height,
    int? duration,
    String? thumbnailPath,
    List<String> tags = const [],
    bool isFavorite = false,
    bool isHidden = false,
  }) {
    return MediaFile(
      id: url,
      path: url,
      name: name,
      type: type,
      modified: modified,
      size: size,
      parentFolder: parentFolder,
      isRemote: true,
      remoteUrl: url,
      sourceType: sourceType,
      width: width,
      height: height,
      duration: duration,
      thumbnailPath: thumbnailPath,
      tags: tags,
      isFavorite: isFavorite,
      isHidden: isHidden,
    );
  }
  
  // 获取文件扩展名
  String get extension => p.extension(name).toLowerCase().replaceAll('.', '');
  
  // 判断两个媒体文件是否相同
  bool isSameFile(MediaFile other) {
    if (isRemote && other.isRemote) {
      return remoteUrl == other.remoteUrl;
    } else if (!isRemote && !other.isRemote) {
      return path == other.path;
    }
    return false;
  }
  
  // 创建带有新标签的副本
  MediaFile copyWithTags(List<String> newTags) {
    return MediaFile(
      id: id,
      path: path,
      name: name,
      type: type,
      modified: modified,
      size: size,
      parentFolder: parentFolder,
      isRemote: isRemote,
      remoteUrl: remoteUrl,
      sourceType: sourceType,
      width: width,
      height: height,
      duration: duration,
      thumbnailPath: thumbnailPath,
      tags: newTags,
      isFavorite: isFavorite,
      isHidden: isHidden,
    );
  }
  
  // 创建带有收藏状态的副本
  MediaFile copyWithFavorite(bool favorite) {
    return MediaFile(
      id: id,
      path: path,
      name: name,
      type: type,
      modified: modified,
      size: size,
      parentFolder: parentFolder,
      isRemote: isRemote,
      remoteUrl: remoteUrl,
      sourceType: sourceType,
      width: width,
      height: height,
      duration: duration,
      thumbnailPath: thumbnailPath,
      tags: tags,
      isFavorite: favorite,
      isHidden: isHidden,
    );
  }
  
  // 创建带有隐藏状态的副本
  MediaFile copyWithHidden(bool hidden) {
    return MediaFile(
      id: id,
      path: path,
      name: name,
      type: type,
      modified: modified,
      size: size,
      parentFolder: parentFolder,
      isRemote: isRemote,
      remoteUrl: remoteUrl,
      sourceType: sourceType,
      width: width,
      height: height,
      duration: duration,
      thumbnailPath: thumbnailPath,
      tags: tags,
      isFavorite: isFavorite,
      isHidden: hidden,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'type': type.index,
      'modified': modified.millisecondsSinceEpoch,
      'size': size,
      'parentFolder': parentFolder,
      'isRemote': isRemote,
      'remoteUrl': remoteUrl,
      'sourceType': sourceType,
      'width': width,
      'height': height,
      'duration': duration,
      'thumbnailPath': thumbnailPath,
      'tags': tags,
      'isFavorite': isFavorite,
      'isHidden': isHidden,
    };
  }
  
  // 从JSON创建
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      type: MediaType.values[json['type']],
      modified: DateTime.fromMillisecondsSinceEpoch(json['modified']),
      size: json['size'],
      parentFolder: json['parentFolder'],
      isRemote: json['isRemote'] ?? false,
      remoteUrl: json['remoteUrl'],
      sourceType: json['sourceType'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
      thumbnailPath: json['thumbnailPath'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : const [],
      isFavorite: json['isFavorite'] ?? false,
      isHidden: json['isHidden'] ?? false,
    );
  }
} 
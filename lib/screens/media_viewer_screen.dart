import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;

import '../models/media_file.dart';
import '../providers/remote_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_indicator.dart';
import '../providers/gallery_provider.dart';

class MediaViewerScreen extends StatefulWidget {
  final MediaFile file;
  
  const MediaViewerScreen({
    super.key,
    required this.file,
  });
  
  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = false;
  String? _errorMessage;
  File? _localFile;
  
  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }
  
  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeMedia() async {
    if (widget.file.type == MediaType.video) {
      await _initializeVideoPlayer();
    } else if (widget.file.type == MediaType.image && widget.file.isRemote) {
      await _downloadRemoteFile();
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      if (widget.file.isRemote) {
        await _downloadRemoteFile();
        if (_localFile == null) {
          throw Exception('无法下载远程视频文件');
        }
        
        _videoPlayerController = VideoPlayerController.file(_localFile!);
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.file.path));
      }
      
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: settingsProvider.autoPlayVideo,
        looping: settingsProvider.loopVideo,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Theme.of(context).primaryColorLight,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 16),
                Text(
                  '播放错误: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _errorMessage = '初始化视频播放器失败: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _downloadRemoteFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final remoteProvider = Provider.of<RemoteProvider>(context, listen: false);
      _localFile = await remoteProvider.downloadRemoteFile(widget.file);
      
      if (_localFile == null) {
        throw Exception('无法下载远程文件');
      }
    } catch (e) {
      _errorMessage = '下载远程文件失败: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 实现分享功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: '加载媒体文件...');
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              '出错了',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeMedia,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (widget.file.type == MediaType.video) {
      return _buildVideoPlayer();
    } else {
      return _buildImageViewer();
    }
  }
  
  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return const Center(
        child: Text(
          '无法播放视频',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Chewie(
      controller: _chewieController!,
    );
  }
  
  Widget _buildImageViewer() {
    if (widget.file.isRemote) {
      if (_localFile != null) {
        return PhotoView(
          imageProvider: FileImage(_localFile!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      } else if (widget.file.remoteUrl != null) {
        return PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.file.remoteUrl!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      } else {
        return const Center(
          child: Text(
            '无法加载远程图片',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    } else {
      return PhotoView(
        imageProvider: FileImage(File(widget.file.path)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
  
  void _showOptionsMenu(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final isFavorite = galleryProvider.isFavorite(widget.file.path);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('文件信息'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileInfo(context);
                },
              ),
              ListTile(
                leading: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                title: Text(isFavorite ? '从收藏中移除' : '添加到收藏'),
                onTap: () async {
                  Navigator.pop(context);
                  await galleryProvider.toggleFavorite(widget.file.path);
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('管理标签'),
                onTap: () {
                  Navigator.pop(context);
                  _showTagsDialog(context);
                },
              ),
              if (widget.file.type == MediaType.image) ...[
                ListTile(
                  leading: const Icon(Icons.wallpaper),
                  title: const Text('设为壁纸'),
                  onTap: () {
                    Navigator.pop(context);
                    // 实现设为壁纸功能
                    _showNotImplementedSnackBar('设为壁纸功能');
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showFileInfo(BuildContext context) {
    final fileSize = _formatFileSize(widget.file.size);
    final extension = path.extension(widget.file.name).toLowerCase().replaceAll('.', '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('文件信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('名称', widget.file.name),
              _buildInfoRow('类型', extension.toUpperCase()),
              _buildInfoRow('大小', fileSize),
              _buildInfoRow('位置', widget.file.parentFolder ?? '未知'),
              _buildInfoRow('修改日期', _formatDate(widget.file.modified)),
              if (widget.file.isRemote)
                _buildInfoRow('来源', widget.file.sourceType ?? '远程'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除文件'),
          content: Text('确定要删除 ${widget.file.name} 吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFile();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deleteFile() async {
    try {
      if (!widget.file.isRemote) {
        final file = File(widget.file.path);
        await file.delete();
      }
      
      // 返回上一页
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除文件失败: $e'),
          ),
        );
      }
    }
  }
  
  String _formatFileSize(int size) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double s = size.toDouble();
    
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    
    return i == 0 ? '$s ${suffixes[i]}' : '${s.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
  
  void _showTagsDialog(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final currentTags = galleryProvider.getFileTags(widget.file.path);
    final allTags = galleryProvider.allTags;
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('管理标签'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: '添加新标签',
                            hintText: '输入标签名称',
                          ),
                          onSubmitted: (value) async {
                            if (value.isNotEmpty) {
                              await galleryProvider.addFileTag(widget.file.path, value);
                              textController.clear();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final value = textController.text;
                          if (value.isNotEmpty) {
                            await galleryProvider.addFileTag(widget.file.path, value);
                            textController.clear();
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('当前标签:'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...galleryProvider.getFileTags(widget.file.path).map((tag) {
                        return Chip(
                          label: Text(tag),
                          onDeleted: () async {
                            await galleryProvider.removeFileTag(widget.file.path, tag);
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                  if (allTags.isNotEmpty && currentTags.length < allTags.length) ...[
                    const SizedBox(height: 16),
                    const Text('建议标签:'),
                    Wrap(
                      spacing: 8,
                      children: [
                        ...allTags
                            .where((tag) => !currentTags.contains(tag))
                            .map((tag) {
                          return ActionChip(
                            label: Text(tag),
                            onPressed: () async {
                              await galleryProvider.addFileTag(widget.file.path, tag);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showNotImplementedSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature 尚未实现')),
    );
  }
} 
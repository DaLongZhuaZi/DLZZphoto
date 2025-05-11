import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/media_file.dart';
import '../providers/gallery_provider.dart';
import '../widgets/empty_state.dart';
import '../screens/media_viewer_screen.dart';

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  bool _isLoading = true;
  List<List<MediaFile>> _duplicateGroups = [];
  
  @override
  void initState() {
    super.initState();
    _detectDuplicates();
  }
  
  Future<void> _detectDuplicates() async {
    setState(() {
      _isLoading = true;
    });
    
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final duplicateGroups = galleryProvider.detectDuplicateFiles();
    
    setState(() {
      _duplicateGroups = duplicateGroups;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重复文件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _detectDuplicates,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在检测重复文件...'),
          ],
        ),
      );
    }
    
    if (_duplicateGroups.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: '没有重复文件',
        message: '没有检测到重复的图片或视频',
      );
    }
    
    return ListView.builder(
      itemCount: _duplicateGroups.length,
      itemBuilder: (context, index) {
        final group = _duplicateGroups[index];
        return _buildDuplicateGroup(group);
      },
    );
  }
  
  Widget _buildDuplicateGroup(List<MediaFile> group) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '发现 ${group.length} 个重复文件: ${group.first.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: group.length,
              itemBuilder: (context, index) {
                final file = group[index];
                return _buildDuplicateItem(file);
              },
            ),
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () {
                  _showDeleteAllDialog(group);
                },
                child: const Text('全部删除'),
              ),
              TextButton(
                onPressed: () {
                  _showKeepOneDialog(group);
                },
                child: const Text('仅保留一个'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDuplicateItem(MediaFile file) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaViewerScreen(file: file),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: file.isRemote
                    ? Image.network(
                        file.remoteUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(file);
                        },
                      )
                    : Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(file);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatFileSize(file.size),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _getSourceName(file),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(MediaFile file) {
    IconData icon;
    Color color;
    
    if (file.type == MediaType.image) {
      icon = Icons.image;
      color = Colors.blue;
    } else if (file.type == MediaType.video) {
      icon = Icons.videocam;
      color = Colors.red;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          icon,
          size: 36,
          color: color,
        ),
      ),
    );
  }
  
  void _showDeleteAllDialog(List<MediaFile> group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除所有重复文件'),
          content: Text('确定要删除所有 ${group.length} 个重复文件吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _deleteFiles(group);
                Navigator.pop(context);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
  
  void _showKeepOneDialog(List<MediaFile> group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('保留一个文件'),
          content: const Text('选择要保留的文件，其他重复文件将被删除。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        );
      },
    ).then((_) {
      // 显示选择对话框
      _showSelectFileDialog(group);
    });
  }
  
  void _showSelectFileDialog(List<MediaFile> group) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择要保留的文件'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: group.length,
                  itemBuilder: (context, index) {
                    final file = group[index];
                    return ListTile(
                      leading: file.isRemote
                          ? const Icon(Icons.cloud)
                          : const Icon(Icons.folder),
                      title: Text(
                        _getSourceName(file),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatFileSize(file.size)} · ${_formatDate(file.modified)}',
                      ),
                      onTap: () {
                        // 保留选中的文件，删除其他文件
                        final filesToDelete = [...group];
                        filesToDelete.removeAt(index);
                        _deleteFiles(filesToDelete);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _deleteFiles(List<MediaFile> files) async {
    int deletedCount = 0;
    
    for (final file in files) {
      if (!file.isRemote) {
        try {
          final fileObj = File(file.path);
          await fileObj.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('删除文件失败: $e');
        }
      }
    }
    
    // 刷新重复文件列表
    _detectDuplicates();
    
    // 显示结果
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 $deletedCount 个文件'),
        ),
      );
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
    final dateFormat = DateFormat('yyyy-MM-dd');
    return dateFormat.format(date);
  }
  
  String _getSourceName(MediaFile file) {
    if (file.isRemote) {
      return file.sourceType ?? '远程';
    } else {
      final parts = file.parentFolder?.split('/') ?? [];
      return parts.isNotEmpty ? parts.last : '本地';
    }
  }
} 
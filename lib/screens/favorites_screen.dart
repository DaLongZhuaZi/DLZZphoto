import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../providers/gallery_provider.dart';
import '../providers/settings_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_list_item.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    final favoriteFiles = galleryProvider.favoriteFiles;
    
    if (favoriteFiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('收藏'),
        ),
        body: const EmptyState(
          icon: Icons.favorite_border,
          title: '暂无收藏',
          message: '您还没有收藏任何文件，长按文件可以添加到收藏',
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('收藏 (${favoriteFiles.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortingOptions(context);
            },
          ),
        ],
      ),
      body: _buildBody(context, favoriteFiles, settingsProvider),
    );
  }
  
  Widget _buildBody(BuildContext context, List<MediaFile> files, SettingsProvider settingsProvider) {
    // 应用排序
    _sortFiles(files, settingsProvider.sortBy, settingsProvider.sortOrder);
    
    if (settingsProvider.viewMode == ViewMode.grid) {
      return MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        padding: const EdgeInsets.all(4),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return MediaGridItem(
            file: files[index],
            onLongPress: () {
              _showFileOptions(context, files[index]);
            },
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return MediaListItem(
            file: files[index],
            onLongPress: () {
              _showFileOptions(context, files[index]);
            },
          );
        },
      );
    }
  }
  
  void _sortFiles(List<MediaFile> files, SortBy sortBy, SortOrder sortOrder) {
    files.sort((a, b) {
      int compareResult;
      
      switch (sortBy) {
        case SortBy.name:
          compareResult = a.name.compareTo(b.name);
          break;
        case SortBy.date:
          compareResult = a.modified.compareTo(b.modified);
          break;
        case SortBy.size:
          compareResult = a.size.compareTo(b.size);
          break;
        case SortBy.type:
          compareResult = a.type.toString().compareTo(b.type.toString());
          break;
        default:
          compareResult = a.modified.compareTo(b.modified);
      }
      
      return sortOrder == SortOrder.ascending ? compareResult : -compareResult;
    });
  }
  
  void _showSortingOptions(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('排序方式'),
                    trailing: DropdownButton<SortBy>(
                      value: settingsProvider.sortBy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.sortBy = value;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: SortBy.name, child: Text('名称')),
                        DropdownMenuItem(value: SortBy.date, child: Text('日期')),
                        DropdownMenuItem(value: SortBy.size, child: Text('大小')),
                        DropdownMenuItem(value: SortBy.type, child: Text('类型')),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('排序顺序'),
                    trailing: DropdownButton<SortOrder>(
                      value: settingsProvider.sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.sortOrder = value;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: SortOrder.ascending, child: Text('升序')),
                        DropdownMenuItem(value: SortOrder.descending, child: Text('降序')),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('视图模式'),
                    trailing: DropdownButton<ViewMode>(
                      value: settingsProvider.viewMode,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.viewMode = value;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: ViewMode.grid, child: Text('网格')),
                        DropdownMenuItem(value: ViewMode.list, child: Text('列表')),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showFileOptions(BuildContext context, MediaFile file) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    
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
                  _showFileInfo(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('从收藏中移除'),
                onTap: () async {
                  Navigator.pop(context);
                  await galleryProvider.toggleFavorite(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除文件'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, file);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showFileInfo(BuildContext context, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('文件信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('名称', file.name),
              _buildInfoRow('类型', file.extension.toUpperCase()),
              _buildInfoRow('大小', _formatFileSize(file.size)),
              _buildInfoRow('位置', file.parentFolder ?? '未知'),
              _buildInfoRow('修改日期', _formatDate(file.modified)),
              if (file.isRemote)
                _buildInfoRow('来源', file.sourceType ?? '远程'),
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
  
  void _showDeleteConfirmation(BuildContext context, MediaFile file) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除文件'),
          content: Text('确定要删除 ${file.name} 吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await galleryProvider.deleteFile(file);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
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
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 
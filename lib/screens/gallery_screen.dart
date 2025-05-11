import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../providers/gallery_provider.dart';
import '../providers/settings_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_list_item.dart';
import '../widgets/folder_grid_item.dart';
import '../widgets/folder_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../utils/constants.dart';
import 'search_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isLoading = true;
  String? _currentFolder;
  
  @override
  void initState() {
    super.initState();
    _refreshMediaFiles();
  }
  
  Future<void> _refreshMediaFiles() async {
    setState(() {
      _isLoading = true;
    });
    
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    await galleryProvider.scanMediaFiles();
    
    setState(() {
      _isLoading = false;
      _currentFolder = galleryProvider.currentFolder;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        leading: _currentFolder != null ? 
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              galleryProvider.navigateBack();
              setState(() {
                _currentFolder = galleryProvider.currentFolder;
              });
            },
          ) : null,
        actions: _buildAppBarActions(galleryProvider),
      ),
      body: _buildBody(),
      floatingActionButton: galleryProvider.isSelectionMode ? null : FloatingActionButton(
        onPressed: _refreshMediaFiles,
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: _buildSelectionBar(galleryProvider),
    );
  }
  
  Widget _buildTitle() {
    if (_currentFolder == null) {
      return const Text('所有照片');
    } else {
      final parts = _currentFolder!.split('/');
      return Text(parts.isNotEmpty ? parts.last : '相册');
    }
  }
  
  List<Widget> _buildAppBarActions(GalleryProvider galleryProvider) {
    if (galleryProvider.isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: '全选',
          onPressed: () {
            galleryProvider.toggleSelectAll();
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: '取消选择',
          onPressed: () {
            galleryProvider.exitSelectionMode();
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () {
            _showSortingOptions(context);
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'select':
                galleryProvider.enterSelectionMode();
                break;
              case 'refresh':
                _refreshMediaFiles();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'select',
              child: ListTile(
                leading: Icon(Icons.select_all),
                title: Text('选择模式'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('刷新'),
              ),
            ),
          ],
        ),
      ];
    }
  }
  
  Widget? _buildSelectionBar(GalleryProvider galleryProvider) {
    if (!galleryProvider.isSelectionMode) return null;
    
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('已选择 ${galleryProvider.selectedFiles.length} 项'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: '分享',
                  onPressed: () {
                    // 实现分享功能
                    _showNotImplementedSnackBar('分享功能');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除',
                  onPressed: () {
                    _showDeleteConfirmation(galleryProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: '更多',
                  onPressed: () {
                    _showMoreOptions(galleryProvider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: '加载媒体文件...');
    }
    
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    final viewMode = settingsProvider.viewMode;
    final sortBy = settingsProvider.sortBy;
    final sortOrder = settingsProvider.sortOrder;
    
    List<MediaFile> files = galleryProvider.allFiles;
    
    if (files.isEmpty) {
      return EmptyState(
        icon: Icons.photo_library,
        title: '没有媒体文件',
        message: '此位置没有找到照片或视频。',
        buttonText: '刷新',
        onButtonPressed: _refreshMediaFiles,
      );
    }
    
    // 排序文件
    _sortFiles(files, sortBy, sortOrder);
    
    // 分离文件夹和媒体文件
    final folders = files.where((file) => file.type == MediaType.folder).toList();
    final mediaFiles = files.where((file) => file.type != MediaType.folder).toList();
    
    if (viewMode == ViewMode.grid) {
      return RefreshIndicator(
        onRefresh: _refreshMediaFiles,
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
          itemCount: folders.length + mediaFiles.length,
          itemBuilder: (context, index) {
            if (index < folders.length) {
              return FolderGridItem(
                folder: folders[index],
                isSelectionMode: galleryProvider.isSelectionMode,
                isSelected: galleryProvider.selectedFiles.contains(folders[index].path),
                onLongPress: () {
                  if (!galleryProvider.isSelectionMode) {
                    galleryProvider.enterSelectionMode();
                    galleryProvider.toggleFileSelection(folders[index].path);
                  }
                },
                onTap: () {
                  if (galleryProvider.isSelectionMode) {
                    galleryProvider.toggleFileSelection(folders[index].path);
                  } else {
                    galleryProvider.setCurrentFolder(folders[index].path);
                    setState(() {
                      _currentFolder = galleryProvider.currentFolder;
                    });
                  }
                },
              );
            } else {
              final file = mediaFiles[index - folders.length];
              return MediaGridItem(
                file: file,
                isSelectionMode: galleryProvider.isSelectionMode,
                isSelected: galleryProvider.selectedFiles.contains(file.path),
                onLongPress: () {
                  if (!galleryProvider.isSelectionMode) {
                    galleryProvider.enterSelectionMode();
                    galleryProvider.toggleFileSelection(file.path);
                  }
                },
                onTap: () {
                  if (galleryProvider.isSelectionMode) {
                    galleryProvider.toggleFileSelection(file.path);
                  }
                },
              );
            }
          },
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshMediaFiles,
        child: ListView.builder(
          itemCount: folders.length + mediaFiles.length,
          itemBuilder: (context, index) {
            if (index < folders.length) {
              return FolderListItem(
                folder: folders[index],
                isSelectionMode: galleryProvider.isSelectionMode,
                isSelected: galleryProvider.selectedFiles.contains(folders[index].path),
                onLongPress: () {
                  if (!galleryProvider.isSelectionMode) {
                    galleryProvider.enterSelectionMode();
                    galleryProvider.toggleFileSelection(folders[index].path);
                  }
                },
                onTap: () {
                  if (galleryProvider.isSelectionMode) {
                    galleryProvider.toggleFileSelection(folders[index].path);
                  } else {
                    galleryProvider.setCurrentFolder(folders[index].path);
                    setState(() {
                      _currentFolder = galleryProvider.currentFolder;
                    });
                  }
                },
              );
            } else {
              final file = mediaFiles[index - folders.length];
              return MediaListItem(
                file: file,
                isSelectionMode: galleryProvider.isSelectionMode,
                isSelected: galleryProvider.selectedFiles.contains(file.path),
                onLongPress: () {
                  if (!galleryProvider.isSelectionMode) {
                    galleryProvider.enterSelectionMode();
                    galleryProvider.toggleFileSelection(file.path);
                  }
                },
                onTap: () {
                  if (galleryProvider.isSelectionMode) {
                    galleryProvider.toggleFileSelection(file.path);
                  }
                },
              );
            }
          },
        ),
      );
    }
  }
  
  void _sortFiles(List<MediaFile> files, SortBy sortBy, SortOrder sortOrder) {
    files.sort((a, b) {
      // 始终将文件夹排在媒体文件之前
      if (a.type == MediaType.folder && b.type != MediaType.folder) {
        return -1;
      }
      if (a.type != MediaType.folder && b.type == MediaType.folder) {
        return 1;
      }
      
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
  
  void _showDeleteConfirmation(GalleryProvider galleryProvider) {
    final selectedCount = galleryProvider.selectedFiles.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文件'),
        content: Text('确定要删除选中的 $selectedCount 个文件吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 显示加载对话框
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在删除文件...'),
                    ],
                  ),
                ),
              );
              
              // 删除文件
              final deletedCount = await galleryProvider.deleteSelectedFiles();
              
              // 关闭加载对话框
              if (mounted) Navigator.pop(context);
              
              // 显示结果
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除 $deletedCount 个文件')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _showMoreOptions(GalleryProvider galleryProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_to_photos),
            title: const Text('添加到相册'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('添加到相册功能');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('添加到收藏'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('添加到收藏功能');
            },
          ),
          ListTile(
            leading: const Icon(Icons.hide_image),
            title: const Text('隐藏文件'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('隐藏文件功能');
            },
          ),
        ],
      ),
    );
  }
  
  void _showNotImplementedSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature 尚未实现')),
    );
  }
} 
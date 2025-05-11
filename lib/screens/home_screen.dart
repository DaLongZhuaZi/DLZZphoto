import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../providers/gallery_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/remote_provider.dart';
import '../models/media_file.dart';
import '../utils/constants.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_list_item.dart';
import '../widgets/folder_grid_item.dart';
import '../widgets/folder_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'settings_screen.dart';
import 'remote_sources_screen.dart';
import 'search_screen.dart';
import 'duplicates_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('照片库'),
        actions: [
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
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: '相册',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '文件夹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: '远程',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPhotosTab();
      case 1:
        return _buildFoldersTab();
      case 2:
        return _buildRemoteTab();
      default:
        return _buildPhotosTab();
    }
  }
  
  Widget _buildPhotosTab() {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    if (galleryProvider.isLoading) {
      return const LoadingIndicator(message: '加载媒体文件...');
    }
    
    if (galleryProvider.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '出错了',
        message: galleryProvider.errorMessage!,
        buttonText: '重试',
        onButtonPressed: () {
          galleryProvider.requestPermissions();
        },
      );
    }
    
    final mediaFiles = galleryProvider.mediaFiles.where((file) {
      if (file.type == MediaType.folder) {
        return settingsProvider.showFolders;
      } else if (file.type == MediaType.image) {
        return settingsProvider.showImages;
      } else if (file.type == MediaType.video) {
        return settingsProvider.showVideos;
      }
      return false;
    }).toList();
    
    if (mediaFiles.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library,
        title: '没有媒体文件',
        message: '没有找到图片或视频',
      );
    }
    
    // 应用排序
    galleryProvider.applySorting(
      settingsProvider.sortType,
      settingsProvider.sortDescending,
    );
    
    // 网格视图或列表视图
    if (settingsProvider.viewMode == ViewMode.grid) {
      return _buildGridView(mediaFiles);
    } else {
      return _buildListView(mediaFiles);
    }
  }
  
  Widget _buildGridView(List<MediaFile> mediaFiles) {
    // 根据屏幕大小确定列数
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = AppSizes.gridColumnsPhone;
    
    if (screenWidth > 600) {
      crossAxisCount = AppSizes.gridColumnsTablet;
    }
    
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      crossAxisCount = AppSizes.gridColumnsLandscape;
    }
    
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        final file = mediaFiles[index];
        
        if (file.type == MediaType.folder) {
          return FolderGridItem(folder: file);
        } else {
          return MediaGridItem(file: file);
        }
      },
    );
  }
  
  Widget _buildListView(List<MediaFile> mediaFiles) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        final file = mediaFiles[index];
        
        if (file.type == MediaType.folder) {
          return FolderListItem(folder: file);
        } else {
          return MediaListItem(file: file);
        }
      },
    );
  }
  
  Widget _buildFoldersTab() {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    
    if (galleryProvider.isLoading) {
      return const LoadingIndicator(message: '加载文件夹...');
    }
    
    if (galleryProvider.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '出错了',
        message: galleryProvider.errorMessage!,
        buttonText: '重试',
        onButtonPressed: () {
          galleryProvider.requestPermissions();
        },
      );
    }
    
    final folders = galleryProvider.folders;
    final customGroups = galleryProvider.customGroups;
    
    if (folders.isEmpty) {
      return const EmptyState(
        icon: Icons.folder,
        title: '没有文件夹',
        message: '没有找到媒体文件夹',
      );
    }
    
    // 显示文件夹和自定义分组
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (customGroups.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '智能分组',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...customGroups.entries.map((entry) {
            final groupName = entry.key;
            final folderPaths = entry.value;
            
            return ListTile(
              leading: const Icon(Icons.folder_special),
              title: Text(groupName),
              subtitle: Text('${folderPaths.length} 个文件夹'),
              onTap: () {
                // 显示分组中的文件夹
                _showGroupFolders(context, groupName, folderPaths);
              },
            );
          }).toList(),
          const Divider(),
        ],
        
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '所有文件夹',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...folders.map((folderPath) {
          final folderName = folderPath.split('/').last;
          final fileCount = galleryProvider.folderContents[folderPath]?.length ?? 0;
          
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(folderName),
            subtitle: Text('$fileCount 个文件'),
            onTap: () {
              galleryProvider.setCurrentFolder(folderPath);
              // 导航到文件夹内容页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderScreen(folderPath: folderPath),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildRemoteTab() {
    final remoteProvider = Provider.of<RemoteProvider>(context);
    
    if (remoteProvider.isLoading) {
      return const LoadingIndicator(message: '加载远程源...');
    }
    
    if (remoteProvider.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '出错了',
        message: remoteProvider.errorMessage!,
        buttonText: '重试',
        onButtonPressed: () {
          // 重新加载远程源
          setState(() {});
        },
      );
    }
    
    final remoteSources = remoteProvider.remoteSources;
    
    if (remoteSources.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: '没有远程源',
        message: '点击下方按钮添加远程媒体源',
        buttonText: '添加远程源',
        onButtonPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RemoteSourcesScreen()),
          );
        },
      );
    }
    
    // 显示远程源列表
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: remoteSources.length,
      itemBuilder: (context, index) {
        final source = remoteSources[index];
        final fileCount = remoteProvider.remoteFiles[source.id]?.length ?? 0;
        
        return ListTile(
          leading: _getSourceIcon(source.type),
          title: Text(source.name),
          subtitle: Text('${source.typeName} · $fileCount 个文件'),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              remoteProvider.scanRemoteSource(source.id);
            },
          ),
          onTap: () {
            remoteProvider.setCurrentSource(source.id);
            // 导航到远程源内容页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RemoteSourceScreen(sourceId: source.id),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            _showSortingOptions(context);
          },
          child: const Icon(Icons.sort),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {
            _showFolderOptions(context);
          },
          child: const Icon(Icons.create_new_folder),
        );
      case 2:
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemoteSourcesScreen()),
            );
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }
  
  Icon _getSourceIcon(int sourceType) {
    switch (sourceType) {
      case AppConstants.sourceTypeHttp:
        return const Icon(Icons.http);
      case AppConstants.sourceTypeFtp:
      case AppConstants.sourceTypeFtps:
        return const Icon(Icons.storage);
      case AppConstants.sourceTypeSmb:
        return const Icon(Icons.computer);
      case AppConstants.sourceTypeWebdav:
        return const Icon(Icons.cloud);
      default:
        return const Icon(Icons.device_unknown);
    }
  }
  
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('查找重复文件'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DuplicatesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('刷新媒体库'),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<GalleryProvider>(context, listen: false).scanMediaFiles();
                },
              ),
            ],
          ),
        );
      },
    );
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
                    trailing: DropdownButton<int>(
                      value: settingsProvider.sortType,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setSortType(value);
                          setState(() {});
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.sortByName,
                          child: Text('按名称'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortByDate,
                          child: Text('按日期'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortBySize,
                          child: Text('按大小'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortByType,
                          child: Text('按类型'),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('降序排列'),
                    value: settingsProvider.sortDescending,
                    onChanged: (value) {
                      settingsProvider.setSortDescending(value);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('视图模式'),
                    trailing: DropdownButton<ViewMode>(
                      value: settingsProvider.viewMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setViewMode(value);
                          setState(() {});
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ViewMode.grid,
                          child: Text('网格视图'),
                        ),
                        DropdownMenuItem(
                          value: ViewMode.list,
                          child: Text('列表视图'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('显示文件夹'),
                    value: settingsProvider.showFolders,
                    onChanged: (value) {
                      settingsProvider.setShowFolders(value);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('显示图片'),
                    value: settingsProvider.showImages,
                    onChanged: (value) {
                      settingsProvider.setShowImages(value);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('显示视频'),
                    value: settingsProvider.showVideos,
                    onChanged: (value) {
                      settingsProvider.setShowVideos(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showFolderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_special),
                title: const Text('管理智能分组'),
                onTap: () {
                  Navigator.pop(context);
                  // 导航到智能分组管理页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_delete),
                title: const Text('清理空文件夹'),
                onTap: () {
                  Navigator.pop(context);
                  // 清理空文件夹
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重新扫描文件夹'),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<GalleryProvider>(context, listen: false).scanMediaFiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showGroupFolders(BuildContext context, String groupName, List<String> folderPaths) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: folderPaths.length,
                    itemBuilder: (context, index) {
                      final folderPath = folderPaths[index];
                      final folderName = folderPath.split('/').last;
                      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                      final fileCount = galleryProvider.folderContents[folderPath]?.length ?? 0;
                      
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(folderName),
                        subtitle: Text('$fileCount 个文件'),
                        onTap: () {
                          Navigator.pop(context);
                          galleryProvider.setCurrentFolder(folderPath);
                          // 导航到文件夹内容页面
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderScreen(folderPath: folderPath),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// 文件夹内容屏幕
class FolderScreen extends StatelessWidget {
  final String folderPath;
  
  const FolderScreen({super.key, required this.folderPath});
  
  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final folderName = folderPath.split('/').last;
    final mediaFiles = galleryProvider.folderContents[folderPath] ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortingOptions(context);
            },
          ),
        ],
      ),
      body: mediaFiles.isEmpty
          ? const EmptyState(
              icon: Icons.photo_library,
              title: '文件夹为空',
              message: '此文件夹中没有媒体文件',
            )
          : settingsProvider.viewMode == ViewMode.grid
              ? _buildGridView(context, mediaFiles)
              : _buildListView(context, mediaFiles),
    );
  }
  
  Widget _buildGridView(BuildContext context, List<MediaFile> mediaFiles) {
    // 根据屏幕大小确定列数
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = AppSizes.gridColumnsPhone;
    
    if (screenWidth > 600) {
      crossAxisCount = AppSizes.gridColumnsTablet;
    }
    
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      crossAxisCount = AppSizes.gridColumnsLandscape;
    }
    
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        return MediaGridItem(file: mediaFiles[index]);
      },
    );
  }
  
  Widget _buildListView(BuildContext context, List<MediaFile> mediaFiles) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        return MediaListItem(file: mediaFiles[index]);
      },
    );
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
                    trailing: DropdownButton<int>(
                      value: settingsProvider.sortType,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setSortType(value);
                          setState(() {});
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.sortByName,
                          child: Text('按名称'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortByDate,
                          child: Text('按日期'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortBySize,
                          child: Text('按大小'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.sortByType,
                          child: Text('按类型'),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('降序排列'),
                    value: settingsProvider.sortDescending,
                    onChanged: (value) {
                      settingsProvider.setSortDescending(value);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('视图模式'),
                    trailing: DropdownButton<ViewMode>(
                      value: settingsProvider.viewMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setViewMode(value);
                          setState(() {});
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ViewMode.grid,
                          child: Text('网格视图'),
                        ),
                        DropdownMenuItem(
                          value: ViewMode.list,
                          child: Text('列表视图'),
                        ),
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
}

// 远程源内容屏幕
class RemoteSourceScreen extends StatelessWidget {
  final String sourceId;
  
  const RemoteSourceScreen({super.key, required this.sourceId});
  
  @override
  Widget build(BuildContext context) {
    final remoteProvider = Provider.of<RemoteProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    final sourceIndex = remoteProvider.remoteSources.indexWhere((s) => s.id == sourceId);
    if (sourceIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('远程源')),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: '找不到远程源',
          message: '此远程源可能已被删除',
        ),
      );
    }
    
    final source = remoteProvider.remoteSources[sourceIndex];
    final mediaFiles = remoteProvider.remoteFiles[sourceId] ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(source.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              remoteProvider.scanRemoteSource(sourceId);
            },
          ),
        ],
      ),
      body: remoteProvider.isLoading
          ? const LoadingIndicator(message: '加载远程文件...')
          : mediaFiles.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: '没有媒体文件',
                  message: '此远程源中没有找到媒体文件',
                  buttonText: '扫描',
                  onButtonPressed: () {
                    remoteProvider.scanRemoteSource(sourceId);
                  },
                )
              : settingsProvider.viewMode == ViewMode.grid
                  ? _buildGridView(context, mediaFiles)
                  : _buildListView(context, mediaFiles),
    );
  }
  
  Widget _buildGridView(BuildContext context, List<MediaFile> mediaFiles) {
    // 根据屏幕大小确定列数
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = AppSizes.gridColumnsPhone;
    
    if (screenWidth > 600) {
      crossAxisCount = AppSizes.gridColumnsTablet;
    }
    
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      crossAxisCount = AppSizes.gridColumnsLandscape;
    }
    
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        return MediaGridItem(file: mediaFiles[index]);
      },
    );
  }
  
  Widget _buildListView(BuildContext context, List<MediaFile> mediaFiles) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        return MediaListItem(file: mediaFiles[index]);
      },
    );
  }
} 
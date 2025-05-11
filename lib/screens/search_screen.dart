import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_file.dart';
import '../providers/gallery_provider.dart';
import '../providers/remote_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_list_item.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<MediaFile> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索图片和视频',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
              _isSearching = true;
            });
            _search(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _searchResults = [];
                  _isSearching = false;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
                _isSearching = true;
              });
              _search(_searchController.text);
            },
          ),
        ],
      ),
      body: _buildBody(settingsProvider),
    );
  }
  
  Widget _buildBody(SettingsProvider settingsProvider) {
    if (_searchQuery.isEmpty && !_isSearching) {
      return const EmptyState(
        icon: Icons.search,
        title: '搜索图片和视频',
        message: '输入关键词搜索媒体文件',
      );
    }
    
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: '未找到结果',
        message: '没有找到匹配"$_searchQuery"的媒体文件',
      );
    }
    
    if (settingsProvider.viewMode == AppConstants.viewModeGrid) {
      return _buildGridView(_searchResults);
    } else {
      return _buildListView(_searchResults);
    }
  }
  
  Widget _buildGridView(List<MediaFile> files) {
    // 根据屏幕大小确定列数
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = AppSizes.gridColumnsPhone;
    
    if (screenWidth > 600) {
      crossAxisCount = AppSizes.gridColumnsTablet;
    }
    
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      crossAxisCount = AppSizes.gridColumnsLandscape;
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      padding: const EdgeInsets.all(4),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return MediaGridItem(file: files[index]);
      },
    );
  }
  
  Widget _buildListView(List<MediaFile> files) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return MediaListItem(file: files[index]);
      },
    );
  }
  
  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    // 转为小写以进行不区分大小写的搜索
    final lowercaseQuery = query.toLowerCase();
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final remoteProvider = Provider.of<RemoteProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // 搜索本地媒体文件
    final localResults = galleryProvider.mediaFiles.where((file) {
      // 根据设置过滤文件类型
      if (!_shouldIncludeFile(file, settingsProvider)) {
        return false;
      }
      
      // 搜索文件名和路径
      return file.name.toLowerCase().contains(lowercaseQuery) ||
             (file.parentFolder?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
    
    // 搜索远程媒体文件
    final remoteResults = <MediaFile>[];
    for (final sourceId in remoteProvider.remoteFiles.keys) {
      final files = remoteProvider.remoteFiles[sourceId] ?? [];
      remoteResults.addAll(files.where((file) {
        // 根据设置过滤文件类型
        if (!_shouldIncludeFile(file, settingsProvider)) {
          return false;
        }
        
        // 搜索文件名和路径
        return file.name.toLowerCase().contains(lowercaseQuery) ||
               (file.parentFolder?.toLowerCase().contains(lowercaseQuery) ?? false);
      }));
    }
    
    // 合并结果
    final allResults = [...localResults, ...remoteResults];
    
    // 应用排序
    switch (settingsProvider.sortType) {
      case AppConstants.sortByName:
        allResults.sort((a, b) => settingsProvider.sortDescending
            ? b.name.compareTo(a.name)
            : a.name.compareTo(b.name));
        break;
      case AppConstants.sortByDate:
        allResults.sort((a, b) => settingsProvider.sortDescending
            ? b.modified.compareTo(a.modified)
            : a.modified.compareTo(b.modified));
        break;
      case AppConstants.sortBySize:
        allResults.sort((a, b) => settingsProvider.sortDescending
            ? b.size.compareTo(a.size)
            : a.size.compareTo(b.size));
        break;
      case AppConstants.sortByType:
        allResults.sort((a, b) {
          final typeComparison = a.type.index.compareTo(b.type.index);
          if (typeComparison != 0) {
            return settingsProvider.sortDescending ? -typeComparison : typeComparison;
          }
          return a.name.compareTo(b.name);
        });
        break;
    }
    
    setState(() {
      _searchResults = allResults;
      _isSearching = false;
    });
  }
  
  bool _shouldIncludeFile(MediaFile file, SettingsProvider settingsProvider) {
    if (file.type == MediaType.image) {
      return settingsProvider.showImages;
    } else if (file.type == MediaType.video) {
      return settingsProvider.showVideos;
    } else if (file.type == MediaType.folder) {
      return settingsProvider.showFolders;
    }
    return false;
  }
} 
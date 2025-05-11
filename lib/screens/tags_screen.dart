import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gallery_provider.dart';
import '../providers/settings_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/media_list_item.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final allTags = galleryProvider.allTags;

    if (allTags.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('标签'),
        ),
        body: const EmptyState(
          icon: Icons.label_outline,
          title: '暂无标签',
          message: '您还没有为任何文件添加标签',
        ),
      );
    }

    if (_selectedTag != null) {
      return _buildTagFilesScreen(context, _selectedTag!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签'),
      ),
      body: ListView.builder(
        itemCount: allTags.length,
        itemBuilder: (context, index) {
          final tag = allTags[index];
          final fileCount = galleryProvider.getFilesByTag(tag).length;
          
          return ListTile(
            leading: const Icon(Icons.label),
            title: Text(tag),
            subtitle: Text('$fileCount 个文件'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedTag = tag;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTagFilesScreen(BuildContext context, String tag) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final files = galleryProvider.getFilesByTag(tag);

    return Scaffold(
      appBar: AppBar(
        title: Text('标签: $tag'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedTag = null;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortingOptions(context);
            },
          ),
        ],
      ),
      body: _buildBody(context, files, settingsProvider),
    );
  }

  Widget _buildBody(BuildContext context, List<MediaFile> files, SettingsProvider settingsProvider) {
    if (files.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library,
        title: '没有文件',
        message: '此标签下没有文件',
      );
    }

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
          return MediaGridItem(file: files[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return MediaListItem(file: files[index]);
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
} 
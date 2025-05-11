import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/media_file.dart';
import 'tags_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildAppearanceSection(context),
          const Divider(),
          _buildGallerySection(context),
          const Divider(),
          _buildTagsSection(context),
          const Divider(),
          _buildVideoPlayerSection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '外观',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('主题'),
          trailing: DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('跟随系统'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('浅色'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('深色'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '相册',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('默认排序方式'),
          trailing: DropdownButton<int>(
            value: settingsProvider.sortType,
            onChanged: (value) {
              if (value != null) {
                settingsProvider.setSortType(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: 0, // AppConstants.sortByName
                child: Text('按名称'),
              ),
              DropdownMenuItem(
                value: 1, // AppConstants.sortByDate
                child: Text('按日期'),
              ),
              DropdownMenuItem(
                value: 2, // AppConstants.sortBySize
                child: Text('按大小'),
              ),
              DropdownMenuItem(
                value: 3, // AppConstants.sortByType
                child: Text('按类型'),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('降序排列'),
          subtitle: const Text('从新到旧、从大到小等'),
          value: settingsProvider.sortDescending,
          onChanged: (value) {
            settingsProvider.setSortDescending(value);
          },
        ),
        ListTile(
          title: const Text('默认视图模式'),
          trailing: DropdownButton<ViewMode>(
            value: settingsProvider.viewMode,
            onChanged: (value) {
              if (value != null) {
                settingsProvider.setViewMode(value);
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
        SwitchListTile(
          title: const Text('显示隐藏文件'),
          subtitle: const Text('显示以点开头的文件和文件夹'),
          value: settingsProvider.showHiddenFiles,
          onChanged: (value) {
            settingsProvider.setShowHiddenFiles(value);
          },
        ),
      ],
    );
  }
  
  Widget _buildTagsSection(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);
    final tagCount = galleryProvider.allTags.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '标签和收藏',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('管理标签'),
          subtitle: Text('$tagCount 个标签'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TagsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoPlayerSection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '视频播放器',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('默认亮度'),
          subtitle: Slider(
            value: settingsProvider.defaultBrightness,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(settingsProvider.defaultBrightness * 100).round()}%',
            onChanged: (value) {
              settingsProvider.setDefaultBrightness(value);
            },
          ),
        ),
        ListTile(
          title: const Text('默认音量'),
          subtitle: Slider(
            value: settingsProvider.defaultVolume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(settingsProvider.defaultVolume * 100).round()}%',
            onChanged: (value) {
              settingsProvider.setDefaultVolume(value);
            },
          ),
        ),
        ListTile(
          title: const Text('默认播放速度'),
          trailing: DropdownButton<double>(
            value: settingsProvider.defaultPlaybackSpeed,
            onChanged: (value) {
              if (value != null) {
                settingsProvider.setDefaultPlaybackSpeed(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: 0.25,
                child: Text('0.25x'),
              ),
              DropdownMenuItem(
                value: 0.5,
                child: Text('0.5x'),
              ),
              DropdownMenuItem(
                value: 0.75,
                child: Text('0.75x'),
              ),
              DropdownMenuItem(
                value: 1.0,
                child: Text('1.0x'),
              ),
              DropdownMenuItem(
                value: 1.25,
                child: Text('1.25x'),
              ),
              DropdownMenuItem(
                value: 1.5,
                child: Text('1.5x'),
              ),
              DropdownMenuItem(
                value: 1.75,
                child: Text('1.75x'),
              ),
              DropdownMenuItem(
                value: 2.0,
                child: Text('2.0x'),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('自动播放'),
          subtitle: const Text('打开视频时自动开始播放'),
          value: settingsProvider.autoPlayVideo,
          onChanged: (value) {
            settingsProvider.setAutoPlayVideo(value);
          },
        ),
        SwitchListTile(
          title: const Text('循环播放'),
          subtitle: const Text('视频播放完成后自动重新开始'),
          value: settingsProvider.loopVideo,
          onChanged: (value) {
            settingsProvider.setLoopVideo(value);
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '关于',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const ListTile(
          title: Text('版本'),
          trailing: Text('1.0.0'),
        ),
        ListTile(
          title: const Text('开源许可'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // 显示开源许可信息
            showLicensePage(
              context: context,
              applicationName: '照片库',
              applicationVersion: '1.0.0',
            );
          },
        ),
      ],
    );
  }
} 
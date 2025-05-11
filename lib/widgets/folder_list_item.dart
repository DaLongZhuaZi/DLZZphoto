import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/media_file.dart';
import '../providers/gallery_provider.dart';
import '../screens/home_screen.dart';

class FolderListItem extends StatelessWidget {
  final MediaFile folder;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  
  const FolderListItem({
    super.key,
    required this.folder,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final folderContents = galleryProvider.folderContents[folder.path] ?? [];
    final fileCount = folderContents.length;
    
    // 计算文件夹中的图片和视频数量
    final imageCount = folderContents.where((file) => file.type == MediaType.image).length;
    final videoCount = folderContents.where((file) => file.type == MediaType.video).length;
    
    // 格式化修改日期
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(folder.modified);
    
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(folder.name),
      subtitle: Text('$imageCount 张图片 · $videoCount 个视频 · $formattedDate'),
      trailing: isSelectionMode 
          ? Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blue : Colors.grey,
            )
          : Text('$fileCount 个文件'),
      selected: isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
  
  Widget _buildLeadingIcon() {
    if (isSelectionMode) {
      return Stack(
        children: [
          const Icon(Icons.folder, color: Colors.amber, size: 48),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(1),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      );
    }
    
    return const Icon(Icons.folder, color: Colors.amber, size: 48);
  }
} 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_file.dart';
import '../providers/gallery_provider.dart';
import '../screens/home_screen.dart';

class FolderGridItem extends StatelessWidget {
  final MediaFile folder;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  
  const FolderGridItem({
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
    final fileCount = galleryProvider.folderContents[folder.path]?.length ?? 0;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildFolderPreview(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$fileCount 个文件',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFolderPreview(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final folderContents = galleryProvider.folderContents[folder.path] ?? [];
    
    // 找出前4个媒体文件作为文件夹预览
    final mediaFiles = folderContents
        .where((file) => file.type == MediaType.image || file.type == MediaType.video)
        .take(4)
        .toList();
    
    if (mediaFiles.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.folder,
            size: 48,
            color: Colors.amber,
          ),
        ),
      );
    }
    
    // 根据媒体文件数量确定布局
    if (mediaFiles.length == 1) {
      return _buildSinglePreview(mediaFiles[0]);
    } else {
      return _buildGridPreview(mediaFiles);
    }
  }
  
  Widget _buildSinglePreview(MediaFile file) {
    if (file.thumbnailPath != null) {
      return Image.file(
        File(file.thumbnailPath!),
        fit: BoxFit.cover,
      );
    }
    
    if (!file.isRemote) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(file);
        },
      );
    }
    
    return _buildPlaceholder(file);
  }
  
  Widget _buildGridPreview(List<MediaFile> files) {
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: files.map((file) {
        if (file.thumbnailPath != null) {
          return Image.file(
            File(file.thumbnailPath!),
            fit: BoxFit.cover,
          );
        }
        
        if (!file.isRemote) {
          return Image.file(
            File(file.path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(file);
            },
          );
        }
        
        return _buildPlaceholder(file);
      }).toList(),
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
          size: 24,
          color: color,
        ),
      ),
    );
  }
} 
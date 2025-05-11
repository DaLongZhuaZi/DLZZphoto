import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/media_file.dart';
import '../providers/remote_provider.dart';
import '../screens/media_viewer_screen.dart';

class MediaGridItem extends StatelessWidget {
  final MediaFile file;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  
  const MediaGridItem({
    super.key,
    required this.file,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (!isSelectionMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaViewerScreen(file: file),
            ),
          );
        }
      },
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                _buildThumbnail(context),
                if (file.type == MediaType.video)
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 24,
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
  
  Widget _buildThumbnail(BuildContext context) {
    if (file.thumbnailPath != null) {
      return Image.file(
        File(file.thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    
    if (file.isRemote) {
      return _buildRemoteThumbnail(context);
    }
    
    return Image.file(
      File(file.path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }
  
  Widget _buildRemoteThumbnail(BuildContext context) {
    if (file.remoteUrl == null) {
      return _buildPlaceholder();
    }
    
    if (file.type == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: file.remoteUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      // 对于远程视频，尝试下载并生成缩略图
      return FutureBuilder<File?>(
        future: Provider.of<RemoteProvider>(context, listen: false)
            .downloadRemoteFile(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            );
          }
          
          return _buildPlaceholder();
        },
      );
    }
  }
  
  Widget _buildPlaceholder() {
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
          size: 48,
          color: color,
        ),
      ),
    );
  }
} 
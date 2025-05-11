import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/media_file.dart';
import '../screens/media_viewer_screen.dart';

class MediaListItem extends StatelessWidget {
  final MediaFile file;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  
  const MediaListItem({
    super.key,
    required this.file,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(file.name),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailingIcon(),
      selected: isSelected,
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
    );
  }
  
  Widget _buildLeadingIcon() {
    Widget thumbnail;
    
    if (file.thumbnailPath != null) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(file.thumbnailPath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildTypeIcon();
          },
        ),
      );
    } else if (!file.isRemote) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(file.path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildTypeIcon();
          },
        ),
      );
    } else {
      thumbnail = _buildTypeIcon();
    }
    
    if (isSelectionMode) {
      return Stack(
        children: [
          thumbnail,
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
    
    return thumbnail;
  }
  
  Widget _buildTypeIcon() {
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }
  
  Widget _buildSubtitle() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(file.modified);
    final formattedSize = _formatFileSize(file.size);
    
    String sourceInfo = '';
    if (file.isRemote && file.sourceType != null) {
      sourceInfo = ' · ${file.sourceType}';
    }
    
    return Text('$formattedDate · $formattedSize$sourceInfo');
  }
  
  Widget? _buildTrailingIcon() {
    if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Colors.blue : Colors.grey,
      );
    } else if (file.type == MediaType.video) {
      return const Icon(Icons.play_circle_outline);
    }
    return null;
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
} 
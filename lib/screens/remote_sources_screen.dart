import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/remote_source.dart';
import '../providers/remote_provider.dart';
import '../utils/constants.dart';
import 'network_scan_screen.dart';

class RemoteSourcesScreen extends StatefulWidget {
  const RemoteSourcesScreen({super.key});

  @override
  State<RemoteSourcesScreen> createState() => _RemoteSourcesScreenState();
}

class _RemoteSourcesScreenState extends State<RemoteSourcesScreen> {
  @override
  Widget build(BuildContext context) {
    final remoteProvider = Provider.of<RemoteProvider>(context);
    final remoteSources = remoteProvider.remoteSources;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程源'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '扫描网络设备',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NetworkScanScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: remoteSources.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '没有远程源',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击下方按钮添加远程媒体源',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _showAddSourceDialog(context);
                        },
                        child: const Text('添加远程源'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NetworkScanScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('扫描网络'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: remoteSources.length,
              itemBuilder: (context, index) {
                final source = remoteSources[index];
                return ListTile(
                  leading: _getSourceIcon(source.type),
                  title: Text(source.name),
                  subtitle: Text(source.url),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditSourceDialog(context, source);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmation(context, source);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    remoteProvider.scanRemoteSource(source.id);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSourceDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Icon _getSourceIcon(int sourceType) {
    switch (sourceType) {
      case AppConstants.sourceTypeHttp:
        return const Icon(Icons.http);
      case AppConstants.sourceTypeFtp:
        return const Icon(Icons.storage);
      case AppConstants.sourceTypeFtps:
        return const Icon(Icons.security);
      case AppConstants.sourceTypeSmb:
        return const Icon(Icons.computer);
      case AppConstants.sourceTypeWebdav:
        return const Icon(Icons.cloud);
      default:
        return const Icon(Icons.device_unknown);
    }
  }
  
  void _showAddSourceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String url = '';
    int type = AppConstants.sourceTypeHttp;
    String? username;
    String? password;
    String? domain;
    int? port;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加远程源'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '名称',
                          hintText: '输入远程源名称',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入名称';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          name = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: '类型',
                        ),
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 0, // AppConstants.sourceTypeHttp
                            child: Text('HTTP'),
                          ),
                          DropdownMenuItem(
                            value: 1, // AppConstants.sourceTypeFtp
                            child: Text('FTP'),
                          ),
                          DropdownMenuItem(
                            value: 2, // AppConstants.sourceTypeFtps
                            child: Text('FTPS'),
                          ),
                          DropdownMenuItem(
                            value: 3, // AppConstants.sourceTypeSmb
                            child: Text('SMB'),
                          ),
                          DropdownMenuItem(
                            value: 4, // AppConstants.sourceTypeWebdav
                            child: Text('WebDAV'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            type = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'URL',
                          hintText: _getUrlHint(type),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入URL';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          url = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (type != AppConstants.sourceTypeHttp) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            hintText: '(可选)',
                          ),
                          onSaved: (value) {
                            username = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '密码',
                            hintText: '(可选)',
                          ),
                          obscureText: true,
                          onSaved: (value) {
                            password = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: '端口',
                            hintText: _getDefaultPortHint(type),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            if (value != null && value.isNotEmpty) {
                              port = int.tryParse(value);
                            }
                          },
                        ),
                      ],
                      if (type == AppConstants.sourceTypeSmb) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '域',
                            hintText: '(可选)',
                          ),
                          onSaved: (value) {
                            domain = value;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      
                      final remoteProvider = Provider.of<RemoteProvider>(context, listen: false);
                      final source = remoteProvider.createRemoteSource(
                        name: name,
                        url: url,
                        type: type,
                        username: username,
                        password: password,
                        domain: domain,
                        port: port,
                      );
                      
                      remoteProvider.addRemoteSource(source);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showEditSourceDialog(BuildContext context, RemoteSource source) {
    final formKey = GlobalKey<FormState>();
    String name = source.name;
    String url = source.url;
    int type = source.type;
    String? username = source.username;
    String? password = source.password;
    String? domain = source.domain;
    int? port = source.port;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑远程源'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '名称',
                          hintText: '输入远程源名称',
                        ),
                        initialValue: name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入名称';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          name = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: '类型',
                        ),
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 0, // AppConstants.sourceTypeHttp
                            child: Text('HTTP'),
                          ),
                          DropdownMenuItem(
                            value: 1, // AppConstants.sourceTypeFtp
                            child: Text('FTP'),
                          ),
                          DropdownMenuItem(
                            value: 2, // AppConstants.sourceTypeFtps
                            child: Text('FTPS'),
                          ),
                          DropdownMenuItem(
                            value: 3, // AppConstants.sourceTypeSmb
                            child: Text('SMB'),
                          ),
                          DropdownMenuItem(
                            value: 4, // AppConstants.sourceTypeWebdav
                            child: Text('WebDAV'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            type = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'URL',
                          hintText: _getUrlHint(type),
                        ),
                        initialValue: url,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入URL';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          url = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (type != AppConstants.sourceTypeHttp) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            hintText: '(可选)',
                          ),
                          initialValue: username,
                          onSaved: (value) {
                            username = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '密码',
                            hintText: '(可选)',
                          ),
                          initialValue: password,
                          obscureText: true,
                          onSaved: (value) {
                            password = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: '端口',
                            hintText: _getDefaultPortHint(type),
                          ),
                          initialValue: port?.toString(),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            if (value != null && value.isNotEmpty) {
                              port = int.tryParse(value);
                            } else {
                              port = null;
                            }
                          },
                        ),
                      ],
                      if (type == AppConstants.sourceTypeSmb) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '域',
                            hintText: '(可选)',
                          ),
                          initialValue: domain,
                          onSaved: (value) {
                            domain = value;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      
                      final remoteProvider = Provider.of<RemoteProvider>(context, listen: false);
                      final updatedSource = source.copyWith(
                        name: name,
                        url: url,
                        type: type,
                        username: username,
                        password: password,
                        domain: domain,
                        port: port,
                      );
                      
                      remoteProvider.updateRemoteSource(updatedSource);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, RemoteSource source) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除远程源'),
          content: Text('确定要删除 ${source.name} 吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final remoteProvider = Provider.of<RemoteProvider>(context, listen: false);
                remoteProvider.removeRemoteSource(source.id);
                Navigator.pop(context);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
  
  String _getUrlHint(int type) {
    switch (type) {
      case AppConstants.sourceTypeHttp:
        return 'http://example.com/photos (默认端口: 80)';
      case AppConstants.sourceTypeFtp:
        return 'ftp://example.com/photos (默认端口: 21)';
      case AppConstants.sourceTypeFtps:
        return 'ftps://example.com/photos (默认端口: 990)';
      case AppConstants.sourceTypeSmb:
        return 'smb://example.com/share (默认端口: 445)';
      case AppConstants.sourceTypeWebdav:
        return 'https://example.com/webdav (默认端口: 443)';
      default:
        return '';
    }
  }
  
  String _getDefaultPortHint(int type) {
    switch (type) {
      case AppConstants.sourceTypeHttp:
        return '80';
      case AppConstants.sourceTypeFtp:
        return '21';
      case AppConstants.sourceTypeFtps:
        return '990';
      case AppConstants.sourceTypeSmb:
        return '445';
      case AppConstants.sourceTypeWebdav:
        return '80';
      default:
        return '';
    }
  }
} 
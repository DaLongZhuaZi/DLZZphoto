import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/discovered_device.dart';
import '../models/remote_source.dart';
import '../providers/remote_provider.dart';
import '../utils/network_scanner.dart';
import '../utils/constants.dart';

class NetworkScanScreen extends StatefulWidget {
  const NetworkScanScreen({super.key});

  @override
  State<NetworkScanScreen> createState() => _NetworkScanScreenState();
}

class _NetworkScanScreenState extends State<NetworkScanScreen> {
  final NetworkScanner _scanner = NetworkScanner();
  bool _isScanning = false;
  double _progress = 0.0;
  List<DiscoveredDevice> _devices = [];
  
  @override
  void initState() {
    super.initState();
    _scanner.devicesStream.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });
    
    _scanner.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
    });
    
    // 开始扫描
    _startScan();
  }
  
  void _startScan() async {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
    });
    
    await _scanner.scanNetwork(
      timeout: const Duration(milliseconds: 500),
    );
    
    setState(() {
      _isScanning = false;
      _progress = 1.0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络扫描'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
            tooltip: '重新扫描',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          if (_isScanning)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          
          // 扫描状态
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  _isScanning ? Icons.search : Icons.check_circle,
                  color: _isScanning ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _isScanning 
                      ? '正在扫描本地网络 (${(_progress * 100).toInt()}%)' 
                      : '扫描完成，发现 ${_devices.length} 个设备',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          
          // 设备列表
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: _isScanning
                        ? const CircularProgressIndicator()
                        : const Text('未发现任何设备'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return _buildDeviceItem(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceItem(DiscoveredDevice device) {
    // 获取设备图标
    IconData iconData;
    switch (device.type) {
      case DeviceType.http:
        iconData = Icons.http;
        break;
      case DeviceType.https:
        iconData = Icons.https;
        break;
      case DeviceType.ftp:
        iconData = Icons.storage;
        break;
      case DeviceType.ftps:
        iconData = Icons.security;
        break;
      case DeviceType.smb:
        iconData = Icons.computer;
        break;
      case DeviceType.ssh:
        iconData = Icons.terminal;
        break;
      case DeviceType.unknown:
      default:
        iconData = Icons.device_unknown;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(iconData, color: Colors.white),
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: ${device.ip}'),
            Text('类型: ${device.type.name}'),
            Text('端口: ${device.ports.join(", ")}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.add_circle),
          tooltip: '添加为远程源',
          onPressed: () => _showAddSourceDialog(context, device),
        ),
        onTap: () => _showDeviceDetails(context, device),
      ),
    );
  }
  
  void _showDeviceDetails(BuildContext context, DiscoveredDevice device) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(device.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IP地址: ${device.ip}'),
              const SizedBox(height: 8),
              Text('设备类型: ${device.type.name}'),
              const SizedBox(height: 8),
              Text('开放端口: ${device.ports.join(", ")}'),
              const SizedBox(height: 8),
              Text('地址: ${device.address}'),
              const SizedBox(height: 8),
              Text('最后发现时间: ${device.lastSeen.toString().substring(0, 19)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddSourceDialog(context, device);
              },
              child: const Text('添加为远程源'),
            ),
          ],
        );
      },
    );
  }
  
  void _showAddSourceDialog(BuildContext context, DiscoveredDevice device) {
    final formKey = GlobalKey<FormState>();
    String name = device.name;
    String url = device.address;
    int type = device.type.sourceType;
    String? username;
    String? password;
    String? domain;
    int? port = device.ports.first;
    
    showDialog(
      context: context,
      builder: (context) {
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
                      type = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: '服务器地址',
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
                      obscureText: true,
                      initialValue: password,
                      onSaved: (value) {
                        password = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '端口',
                        hintText: '(可选)',
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
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('远程源添加成功')),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 
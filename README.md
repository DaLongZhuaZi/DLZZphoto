# 照片库应用 (DLZZphoto)

![Flutter CI](https://github.com/DaLongZhuaZi/DLZZphoto/workflows/Flutter%20CI/badge.svg)
![部署Web版本](https://github.com/DaLongZhuaZi/DLZZphoto/workflows/部署Web版本/badge.svg)

一款功能丰富的照片和视频管理应用，支持本地和远程媒体文件浏览。

## 主要功能

- 浏览本地照片和视频
- 收藏喜爱的媒体文件
- 连接远程媒体源（HTTP、FTP、FTPS、SMB、WebDAV）
- 自动扫描本地网络中的媒体服务器
- 查找重复媒体文件
- 自定义设置和主题

## 技术特点

- 使用Flutter框架开发，支持Android、iOS、Windows、macOS和Linux
- 采用Provider状态管理
- 支持多种远程协议
- 网络扫描功能，自动发现本地网络设备
- 多语言支持

## 网络扫描功能

应用内置了强大的网络扫描功能，可以自动发现本地网络中的设备和媒体服务器：

- 扫描常用端口（HTTP、FTP、SMB等）
- 显示设备详细信息（名称、IP、端口等）
- 一键添加为远程源
- 自动保存历史发现的设备

## 远程协议支持

支持多种远程协议，并为每种协议设置了默认端口：

- HTTP (80)
- HTTPS (443)
- FTP (21)
- FTPS (990)
- SMB (445)
- WebDAV (80/443)

## 开发环境

- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code

## 如何使用

1. 克隆仓库
2. 安装依赖：`flutter pub get`
3. 运行应用：`flutter run`

## 贡献

欢迎提交Pull Request或Issue。

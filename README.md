# 📡 Meshtastic Controller

> 炫酷的 Meshtastic 网络控制 App

![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 功能特性

- 📱 **收发消息** - 通过 WiFi 连接 Meshtastic 设备
- 📊 **设备状态** - 实时查看连接状态、电池、信号
- 🎨 **炫酷UI** - 赛博朋克风格界面

## 🚀 快速开始

### 1. 配置设备地址

在 App 设置中填入您的 Meshtastic 设备 IP 地址：
```
http://192.168.3.76
```

### 2. 开发环境

```bash
# 安装依赖
flutter pub get

# 运行
flutter run
```

### 3. 构建 APK

```bash
flutter build apk --debug
```

## 📦 云编译

本项目配置了 GitHub Actions，每次推送到 main 分支会自动：
1. 编译 APK
2. 发送到您的邮箱

## 🔧 技术栈

- Flutter 3.24.0
- Provider 状态管理
- Google Fonts
- Flutter Animate

## 📄 License

MIT License

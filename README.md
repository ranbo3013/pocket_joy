# PocketJoy（口袋快乐）

> 把上班时间转化为即时正反馈的移动端情绪工具

面向职场人的解压治愈 App。通过大口袋、金币掉落、轻量音效与震动反馈，让用户在工作间隙获得「我正在积累快乐」的感受。**首页只展示金币与金条，不展示真实金额或货币符号。**

---

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Flutter 3.x（仅竖屏，iOS + Android） |
| 状态管理 | Provider |
| 敏感数据存储 | flutter_secure_storage（税后月薪加密存储） |
| 普通设置 | shared_preferences |
| 统计流水 | Hive |
| 音效播放 | audioplayers |
| 本地通知 | flutter_local_notifications + timezone |
| 动效 | 代码动画 + PNG 序列（Rive 预留接口） |
| 平台支持 | iOS / Android 移动端 |

---

## 项目结构

```
pocketjoy/
├── assets/
│   ├── animations/        # Rive/Lottie 动效文件（预留）
│   ├── audio/             # 短音效 MP3
│   ├── brand/             # App 图标、启动页
│   ├── icons/             # SVG 图标
│   └── images/            # 位图资产（口袋、金币、金条等）
├── design/
│   ├── doc/               # PRD、视觉资产清单等设计文档
│   └── img/               # 设计稿截图
├── lib/
│   ├── main.dart          # 应用入口
│   ├── app.dart           # MaterialApp 配置、路由
│   ├── config/            # 常量、设计令牌、路由、主题
│   ├── models/            # 数据模型（AppPhase、BagState、SalaryConfig 等）
│   ├── providers/         # Provider 状态管理（Config、Game、Animation）
│   ├── repositories/      # 数据持久层（Salary、Settings、Stats）
│   ├── services/          # 业务服务（音效、震动、通知、计时器、计算器等）
│   ├── ui/
│   │   ├── animations/    # 动画队列与冲突处理
│   │   ├── pages/         # 页面（Home、SalarySetup、Settings）
│   │   └── widgets/       # 可复用组件（Bag、TopBar、ControlBar 等）
│   └── utils/             # 工具函数（响应式适配等）
├── test/                  # 单元测试与 Widget 测试
└── pubspec.yaml
```

### 架构分层

```
UI Layer (pages / widgets)
    ↕  Provider (ConfigProvider / GameProvider / AnimationProvider)
    ↕  Services (Audio / Haptic / Notification / Calculator / Timer / ...)
    ↕  Repositories (Salary / Settings / Stats)
    ↕  Storage (flutter_secure_storage / shared_preferences / Hive)
```

---

## 环境要求

- **Flutter SDK** ≥ 3.12.0
- **Dart SDK** ≥ 3.12.0
- **Xcode**（iOS 开发）≥ 15.0
- **Android Studio**（Android 开发）≥ Hedgehog
- **CocoaPods**（iOS 依赖管理）

```bash
# 验证环境
flutter doctor
```

---

## 本地开发

### 1. 克隆项目

```bash
git clone <repo-url>
cd pocketjoy
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 代码生成（Hive 类型适配器）

```bash
flutter pub run build_runner build
```

### 4. 静态分析

```bash
flutter analyze
```

目标：**0 error，0 warning**。

### 5. 运行测试

```bash
flutter test
```

### 6. 启动应用

```bash
# 列出可用设备
flutter devices

# iOS 模拟器
flutter emulators --launch apple_ios_simulator
flutter run

# Android 模拟器
flutter emulators --launch <emulator_name>
flutter run

# macOS 桌面（部分功能受限，见下方说明）
flutter run -d macos

# Chrome 网页（音效需先点击页面解锁 autoplay）
flutter run -d chrome
```

---

## 平台注意事项

| 功能 | iOS 模拟器 | Android 模拟器 | macOS 桌面 | Chrome 网页 |
|------|-----------|---------------|-----------|------------|
| 音效播放 | ✅ | ✅ | ✅ | ⚠️ 需先点击页面解锁 autoplay |
| 震动反馈 | ❌ 模拟器无震动硬件 | ❌ 模拟器无震动硬件 | ❌ | ❌ |
| 本地通知 | ✅ | ✅ | ⚠️ 部分支持 | ❌ |
| 安全存储 | ✅ | ✅ | ✅ | ⚠️ 仅 localStorage |
| 竖屏锁定 | ✅ | ✅ | ❌ 不适用 | ❌ 不适用 |

> **推荐**：音效和震动测试建议使用真机或 iOS 模拟器（iOS 模拟器支持系统音频播放）。

---

## 调试模式

在 `lib/providers/game_provider.dart` 顶部有两个调试开关：

```dart
static const _debugFastDrop = true;   // true = 金币掉落用秒计（3秒一次）
static const _debugDropSeconds = 3;   // debug 模式下的掉落间隔秒数
```

- **开发调试**：`_debugFastDrop = true`，每 3 秒触发一次金币掉落，快速验证动画和音效
- **生产发布**：`_debugFastDrop = false`，使用用户设置的随机间隔（分钟级）

---

## 资产替换

所有视觉和音效资产遵循**同名覆盖**策略，替换正式资产后无需修改代码。

| 目录 | 内容 | 替换方式 |
|------|------|----------|
| `assets/audio/` | MP3 音效 | 同名覆盖，AudioService 自动引用 |
| `assets/images/` | PNG/WebP 位图 | 同名覆盖 |
| `assets/animations/` | Rive/Lottie | 同名覆盖，需同步更新引用代码 |
| `assets/icons/` | SVG 图标 | 同名覆盖 |

音效文件命名规范：

| 场景 | 文件名 |
|------|--------|
| 金币掉落 | `coin-drop.mp3` |
| 口袋接住 | `receive.mp3` |
| 金条合成 | `gold_bar.mp3` |
| 轻提示 | `prompt.mp3` |

---

## 核心业务规则

- **1000 金币 = 1 根金条**
- **每分钟分薪** = 税后月薪 ÷ 当月工作天数 ÷ 8 ÷ 60
- **本次掉落金币** = round(每分钟分薪 × 本次实际间隔分钟数)
- **随机间隔**：首次在 [min, max] 内随机，后续按 ×3、×1/2 交替
- **首页不展示真实金额或货币符号**

### 应用状态机

```
unset → running ⇄ paused
                  ⇄ background
                  → offWork
```

---

## 设置项

| 设置 | 存储位置 | 默认值 |
|------|----------|--------|
| 税后月薪 | flutter_secure_storage（加密） | 无（首次必填） |
| 工作天数 | shared_preferences | 当月周一至周五天数 |
| 随机间隔范围 | shared_preferences | 15–300 分钟 |
| 音效开关 | shared_preferences | 开启 |
| 震动开关 | shared_preferences | 开启 |
| 通知开关 | shared_preferences | 开启 |

---

## 构建与发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

发布前确认：
- [ ] `_debugFastDrop = false`
- [ ] `flutter analyze` 0 error 0 warning
- [ ] `flutter test` 全部通过
- [ ] 正式视觉资产已替换占位文件
- [ ] App 图标和启动页已配置

---

## 相关文档

- `design/doc/PocketJoy_App_V1.0产品需求文档_开发版.md` — PRD
- `design/doc/PocketJoy_V1.0视觉资产交付清单.md` — 视觉与音效规格

---

## 许可证

MIT

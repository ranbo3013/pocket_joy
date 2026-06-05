# PocketJoy

> A mobile emotional wellness tool that turns work time into instant positive feedback

A de-stress and healing app for professionals. Through a visual money bag, falling coins, lightweight sound effects, and haptic feedback, users get a sense of "I'm accumulating joy" during work breaks. **The home screen only displays coins and gold bars — no real currency amounts or symbols.**

---

## Tech Stack

| Category | Choice |
|----------|--------|
| Framework | Flutter 3.x (portrait only, iOS + Android) |
| State Management | Provider |
| Sensitive Data | flutter_secure_storage (encrypted after-tax monthly salary) |
| General Settings | shared_preferences |
| Stats Persistence | Hive |
| Audio Playback | audioplayers |
| Local Notifications | flutter_local_notifications + timezone |
| Animations | Code-driven + PNG assets (Rive integration reserved) |
| Platform Support | iOS / Android mobile |

---

## Project Structure

```
pocketjoy/
├── assets/
│   ├── animations/        # Rive/Lottie animation files (reserved)
│   ├── audio/             # Short MP3 sound effects
│   ├── brand/             # App icon, splash screen
│   ├── icons/             # SVG icons
│   └── images/            # Bitmap assets (bag, coins, gold bars, etc.)
├── design/
│   ├── doc/               # PRD, visual asset spec, and other design docs
│   └── img/               # Design mockup screenshots
├── lib/
│   ├── main.dart          # App entry point
│   ├── app.dart           # MaterialApp config, routing
│   ├── config/            # Constants, design tokens, routes, theme
│   ├── models/            # Data models (AppPhase, BagState, SalaryConfig, etc.)
│   ├── providers/         # Provider state management (Config, Game, Animation)
│   ├── repositories/      # Data persistence layer (Salary, Settings, Stats)
│   ├── services/          # Business services (audio, haptic, notification, timer, calculator, etc.)
│   ├── ui/
│   │   ├── animations/    # Animation queue and conflict handling
│   │   ├── pages/         # Pages (Home, SalarySetup, Settings)
│   │   └── widgets/       # Reusable components (Bag, TopBar, ControlBar, etc.)
│   └── utils/             # Utility functions (responsive sizing, etc.)
├── test/                  # Unit tests and widget tests
└── pubspec.yaml
```

### Architecture Layers

```
UI Layer (pages / widgets)
    ↕  Provider (ConfigProvider / GameProvider / AnimationProvider)
    ↕  Services (Audio / Haptic / Notification / Calculator / Timer / ...)
    ↕  Repositories (Salary / Settings / Stats)
    ↕  Storage (flutter_secure_storage / shared_preferences / Hive)
```

---

## Requirements

- **Flutter SDK** ≥ 3.12.0
- **Dart SDK** ≥ 3.12.0
- **Xcode** (iOS development) ≥ 15.0
- **Android Studio** (Android development) ≥ Hedgehog
- **CocoaPods** (iOS dependency management)

```bash
# Verify environment
flutter doctor
```

---

## Local Development

### 1. Clone

```bash
git clone <repo-url>
cd pocketjoy
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Code Generation (Hive Type Adapters)

```bash
flutter pub run build_runner build
```

### 4. Static Analysis

```bash
flutter analyze
```

Target: **0 errors, 0 warnings**.

### 5. Run Tests

```bash
flutter test
```

### 6. Launch the App

```bash
# List available devices
flutter devices

# iOS Simulator
flutter emulators --launch apple_ios_simulator
flutter run

# Android Emulator
flutter emulators --launch <emulator_name>
flutter run

# macOS Desktop (some features limited — see notes below)
flutter run -d macos

# Chrome (audio requires user interaction to unlock autoplay)
flutter run -d chrome
```

---

## Platform Notes

| Feature | iOS Sim | Android Emu | macOS | Chrome |
|---------|---------|-------------|-------|--------|
| Audio playback | ✅ | ✅ | ✅ | ⚠️ Requires user tap to unlock autoplay |
| Haptic feedback | ❌ No hardware | ❌ No hardware | ❌ | ❌ |
| Local notifications | ✅ | ✅ | ⚠️ Partial | ❌ |
| Secure storage | ✅ | ✅ | ✅ | ⚠️ localStorage only |
| Portrait lock | ✅ | ✅ | ❌ N/A | ❌ N/A |

> **Recommendation**: Test audio and haptics on a physical device, or use the iOS Simulator (which supports system audio playback).

---

## Debug Mode

Two debug flags at the top of `lib/providers/game_provider.dart`:

```dart
static const _debugFastDrop = true;   // true = coin drops in seconds (every 3s)
static const _debugDropSeconds = 3;   // drop interval in seconds (debug mode)
```

- **Development**: Set `_debugFastDrop = true` — a coin drops every 3 seconds for rapid animation and audio testing.
- **Production**: Set `_debugFastDrop = false` — uses the user-configured random interval (in minutes).

---

## Asset Replacement

All visual and audio assets follow a **same-name override** strategy — replace production assets without modifying code.

| Directory | Content | How to Replace |
|-----------|---------|----------------|
| `assets/audio/` | MP3 sound effects | Override with same filename; AudioService auto-picks it up |
| `assets/images/` | PNG/WebP bitmaps | Override with same filename |
| `assets/animations/` | Rive/Lottie | Override with same filename; update referencing code as needed |
| `assets/icons/` | SVG icons | Override with same filename |

Audio file naming convention:

| Scene | Filename |
|-------|----------|
| Coin drop | `coin-drop.mp3` |
| Bag catch | `receive.mp3` |
| Gold bar synthesized | `gold_bar.mp3` |
| Prompt chime | `prompt.mp3` |

---

## Core Business Rules

- **1000 coins = 1 gold bar**
- **Per-minute salary** = after-tax monthly salary ÷ workdays this month ÷ 8 ÷ 60
- **Coins per drop** = round(per-minute salary × actual interval in minutes)
- **Random interval**: First drop in [min, max]; subsequent values alternate ×3 and ×½
- **Home screen never displays real currency amounts or symbols**

### App State Machine

```
unset → running ⇄ paused
                  ⇄ background
                  → offWork
```

---

## Settings

| Setting | Storage | Default |
|---------|---------|---------|
| After-tax monthly salary | flutter_secure_storage (encrypted) | None (required on first launch) |
| Workdays per month | shared_preferences | Mon–Fri count of current month |
| Random interval range | shared_preferences | 15–300 minutes |
| Sound toggle | shared_preferences | On |
| Haptic toggle | shared_preferences | On |
| Notification toggle | shared_preferences | On |

---

## Build & Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

Pre-release checklist:
- [ ] `_debugFastDrop = false`
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all passing
- [ ] Production visual assets have replaced placeholders
- [ ] App icon and splash screen configured

---

## Related Docs

- `design/doc/PocketJoy_App_V1.0产品需求文档_开发版.md` — PRD
- `design/doc/PocketJoy_V1.0视觉资产交付清单.md` — Visual & audio spec

---

## License

MIT

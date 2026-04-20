# Project audit: Forgetrack

## Overview

- Total files: **260**
- Text files: **192**
- Total size: **78.7 MB**
- Total text lines: **24381**
- Total non-empty text lines: **21563**
- Total comment lines: **1341**
- Total TODO/FIXME/HACK markers: **18**

## Project tree

```text
Forgetrack/
├── .claude
│   └── settings.local.json
├── .gradle-user-home
│   └── wrapper
│       └── dists
│           └── gradle-8.14-all
├── android
│   ├── .kotlin
│   │   └── sessions
│   ├── app
│   │   ├── src
│   │   │   ├── debug
│   │   │   ├── main
│   │   │   └── profile
│   │   ├── build.gradle.kts
│   │   └── google-services.json
│   ├── gradle
│   │   └── wrapper
│   │       ├── gradle-wrapper.jar
│   │       └── gradle-wrapper.properties
│   ├── .gitignore
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   └── settings.gradle.kts
├── assets
│   ├── branding
│   │   ├── app-icon-foreground.png
│   │   ├── app-icon-square.png
│   │   ├── app-icon.png
│   │   ├── wordmark-dark.svg
│   │   ├── wordmark-gradient.svg
│   │   └── wordmark-light.svg
│   ├── icons
│   │   └── google
│   │       ├── google_logo.svg
│   │       └── README.md
│   └── ui
│       ├── bg_afternoon_wide.png
│       ├── bg_dawn_wide.png
│       ├── bg_day_wide.png
│       ├── bg_evening_wide.png
│       ├── bg_morning_wide.png
│       ├── bg_night_wide.jpg
│       ├── bg_night_wide.png
│       ├── bg_noon_wide.png
│       ├── bg_sunset_wide.png
│       ├── gradient_dark.jpg
│       └── gradient_light.jpg
├── audit
├── ios
│   ├── Flutter
│   │   ├── ephemeral
│   │   │   ├── flutter_lldb_helper.py
│   │   │   └── flutter_lldbinit
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   ├── flutter_export_environment.sh
│   │   ├── Generated.xcconfig
│   │   └── Release.xcconfig
│   ├── Runner
│   │   ├── Assets.xcassets
│   │   │   ├── AppIcon.appiconset
│   │   │   └── LaunchImage.imageset
│   │   ├── Base.lproj
│   │   │   ├── LaunchScreen.storyboard
│   │   │   └── Main.storyboard
│   │   ├── AppDelegate.swift
│   │   ├── GeneratedPluginRegistrant.h
│   │   ├── GeneratedPluginRegistrant.m
│   │   ├── Info.plist
│   │   ├── Runner-Bridging-Header.h
│   │   └── SceneDelegate.swift
│   ├── Runner.xcodeproj
│   │   ├── project.xcworkspace
│   │   │   ├── xcshareddata
│   │   │   └── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── xcschemes
│   │   └── project.pbxproj
│   ├── Runner.xcworkspace
│   │   ├── xcshareddata
│   │   │   ├── IDEWorkspaceChecks.plist
│   │   │   └── WorkspaceSettings.xcsettings
│   │   └── contents.xcworkspacedata
│   ├── RunnerTests
│   │   └── RunnerTests.swift
│   └── .gitignore
├── lib
│   ├── core
│   │   ├── app_branding.dart
│   │   ├── app_log.dart
│   │   └── constants.dart
│   ├── l10n
│   │   ├── app_cs.arb
│   │   ├── app_en.arb
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_cs.dart
│   │   ├── app_localizations_en.dart
│   │   └── l10n.dart
│   ├── models
│   │   ├── activity_record.dart
│   │   ├── calorie_entry.dart
│   │   ├── nutrition_day_record.dart
│   │   ├── nutrition_day_record.g.dart
│   │   ├── selected_period.dart
│   │   ├── sleep_record.dart
│   │   ├── sync_record.dart
│   │   ├── weight_card_data.dart
│   │   └── weight_record.dart
│   ├── providers
│   │   ├── auth_provider.dart
│   │   ├── calorie_provider.dart
│   │   ├── fitness_provider.dart
│   │   ├── goals_provider.dart
│   │   ├── kaloricke_tabulky_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── theme_provider.dart
│   │   └── time_theme_provider.dart
│   ├── screens
│   │   ├── activities
│   │   │   ├── widgets
│   │   │   └── activities_screen.dart
│   │   ├── body
│   │   │   ├── widgets
│   │   │   └── body_screen.dart
│   │   ├── calories
│   │   │   └── calories_screen.dart
│   │   ├── home
│   │   │   ├── widgets
│   │   │   └── home_screen.dart
│   │   └── profile
│   │       ├── dialogs
│   │       ├── sections
│   │       ├── widgets
│   │       └── profile_screen.dart
│   ├── services
│   │   ├── calorie_api_service.dart
│   │   ├── google_auth_platform_adapter.dart
│   │   ├── google_auth_service.dart
│   │   ├── health_connect_service.dart
│   │   ├── kaloricke_tabulky_service.dart
│   │   ├── kt_nutrition_database.dart
│   │   └── sheets_service.dart
│   ├── theme
│   │   ├── app_theme.dart
│   │   ├── palettes.dart
│   │   └── time_theme.dart
│   ├── widgets
│   │   ├── app_logo.dart
│   │   ├── google_logo_icon.dart
│   │   ├── google_sign_in_button.dart
│   │   ├── hc_state_widgets.dart
│   │   ├── parallax_background.dart
│   │   ├── profile_avatar_action.dart
│   │   ├── stat_display.dart
│   │   └── top_level_app_bar.dart
│   ├── app.dart
│   └── main.dart
├── linux
│   ├── flutter
│   │   ├── ephemeral
│   │   │   └── .plugin_symlinks
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   ├── runner
│   │   ├── CMakeLists.txt
│   │   ├── main.cc
│   │   ├── my_application.cc
│   │   └── my_application.h
│   ├── .gitignore
│   └── CMakeLists.txt
├── macos
│   ├── Flutter
│   │   ├── ephemeral
│   │   │   ├── Flutter-Generated.xcconfig
│   │   │   └── flutter_export_environment.sh
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Runner
│   │   ├── Assets.xcassets
│   │   │   └── AppIcon.appiconset
│   │   ├── Base.lproj
│   │   │   └── MainMenu.xib
│   │   ├── Configs
│   │   │   ├── AppInfo.xcconfig
│   │   │   ├── Debug.xcconfig
│   │   │   ├── Release.xcconfig
│   │   │   └── Warnings.xcconfig
│   │   ├── AppDelegate.swift
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   ├── Runner.xcodeproj
│   │   ├── project.xcworkspace
│   │   │   └── xcshareddata
│   │   ├── xcshareddata
│   │   │   └── xcschemes
│   │   └── project.pbxproj
│   ├── Runner.xcworkspace
│   │   ├── xcshareddata
│   │   │   └── IDEWorkspaceChecks.plist
│   │   └── contents.xcworkspacedata
│   ├── RunnerTests
│   │   └── RunnerTests.swift
│   └── .gitignore
├── test
│   └── widget_test.dart
├── tooling
│   ├── branding_assets.md
│   ├── generate_branding_assets.ps1
│   └── project_audit.py
├── web
│   ├── icons
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── favicon.png
│   ├── index.html
│   └── manifest.json
├── windows
│   ├── flutter
│   │   ├── ephemeral
│   │   │   └── .plugin_symlinks
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   ├── runner
│   │   ├── resources
│   │   │   └── app_icon.ico
│   │   ├── CMakeLists.txt
│   │   ├── flutter_window.cpp
│   │   ├── flutter_window.h
│   │   ├── main.cpp
│   │   ├── resource.h
│   │   ├── runner.exe.manifest
│   │   ├── Runner.rc
│   │   ├── utils.cpp
│   │   ├── utils.h
│   │   ├── win32_window.cpp
│   │   └── win32_window.h
│   ├── .gitignore
│   └── CMakeLists.txt
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── devtools_options.yaml
├── flutter_01.png
├── flutter_02.png
├── flutter_03.png
├── flutter_04.png
├── flutter_05.png
├── flutter_06.png
├── flutter_07.png
├── l10n.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

## File types

- `.dart`: 67
- `.png`: 63
- `.xml`: 12
- `.xcconfig`: 10
- `<no_ext>`: 9
- `.h`: 9
- `.plist`: 7
- `.swift`: 7
- `.json`: 6
- `.txt`: 6
- `.yaml`: 4
- `.svg`: 4
- `.md`: 4
- `.cc`: 4
- `.cpp`: 4
- `.kts`: 3
- `.properties`: 3
- `.jpg`: 3
- `.xcworkspacedata`: 3
- `.py`: 2
- `.sh`: 2
- `.pbxproj`: 2
- `.xcsettings`: 2
- `.xcscheme`: 2
- `.storyboard`: 2
- `.arb`: 2
- `.cmake`: 2
- `.entitlements`: 2
- `.lck`: 1
- `.part`: 1
- `.java`: 1
- `.kt`: 1
- `.jar`: 1
- `.bat`: 1
- `.m`: 1
- `.xib`: 1
- `.lock`: 1
- `.ps1`: 1
- `.html`: 1
- `.ico`: 1
- `.manifest`: 1
- `.rc`: 1

## Largest files by line count

| File | Lines | Non-empty | Comments | TODOs | Size |
|---|---:|---:|---:|---:|---:|
| `lib/models/nutrition_day_record.g.dart` | 2003 | 1823 | 6 | 0 | 57.9 KB |
| `pubspec.lock` | 1087 | 1087 | 0 | 0 | 32.5 KB |
| `lib/l10n/app_localizations.dart` | 1075 | 903 | 692 | 0 | 28.9 KB |
| `lib/screens/home/home_screen.dart` | 964 | 889 | 18 | 0 | 33.0 KB |
| `lib/services/kaloricke_tabulky_service.dart` | 874 | 727 | 21 | 0 | 28.6 KB |
| `lib/screens/calories/calories_screen.dart` | 757 | 683 | 17 | 0 | 22.8 KB |
| `macos/Runner.xcodeproj/project.pbxproj` | 705 | 689 | 0 | 0 | 26.5 KB |
| `ios/Runner.xcodeproj/project.pbxproj` | 620 | 605 | 0 | 0 | 24.2 KB |
| `lib/services/health_connect_service.dart` | 590 | 474 | 30 | 0 | 18.3 KB |
| `lib/providers/kaloricke_tabulky_provider.dart` | 558 | 486 | 19 | 0 | 19.1 KB |
| `lib/screens/home/widgets/weight_card.dart` | 514 | 464 | 16 | 0 | 17.8 KB |
| `lib/l10n/app_localizations_cs.dart` | 498 | 339 | 3 | 0 | 10.9 KB |
| `lib/l10n/app_localizations_en.dart` | 498 | 339 | 3 | 0 | 10.5 KB |
| `lib/l10n/app_en.arb` | 494 | 337 | 0 | 0 | 20.2 KB |
| `tooling/project_audit.py` | 489 | 419 | 2 | 13 | 14.2 KB |
| `lib/screens/profile/widgets/profile_settings_widgets.dart` | 478 | 442 | 0 | 0 | 12.9 KB |
| `lib/providers/fitness_provider.dart` | 473 | 411 | 57 | 0 | 17.8 KB |
| `lib/theme/app_theme.dart` | 375 | 350 | 19 | 0 | 13.4 KB |
| `lib/screens/profile/sections/profile_kt_section.dart` | 371 | 342 | 0 | 0 | 11.1 KB |
| `lib/screens/home/widgets/steps_card.dart` | 345 | 323 | 0 | 0 | 11.6 KB |
| `macos/Runner/Base.lproj/MainMenu.xib` | 343 | 343 | 0 | 0 | 23.5 KB |
| `lib/screens/activities/widgets/activity_cards.dart` | 334 | 310 | 0 | 0 | 10.6 KB |
| `lib/screens/profile/sections/profile_goals_section.dart` | 311 | 296 | 0 | 0 | 9.6 KB |
| `lib/screens/home/widgets/calorie_summary_card.dart` | 310 | 293 | 5 | 0 | 10.3 KB |
| `lib/screens/body/widgets/body_cards.dart` | 298 | 278 | 0 | 0 | 10.0 KB |

## Suspiciously large files (>= 400 lines)

- `lib/models/nutrition_day_record.g.dart` — 2003 lines
- `pubspec.lock` — 1087 lines
- `lib/l10n/app_localizations.dart` — 1075 lines
- `lib/screens/home/home_screen.dart` — 964 lines
- `lib/services/kaloricke_tabulky_service.dart` — 874 lines
- `lib/screens/calories/calories_screen.dart` — 757 lines
- `macos/Runner.xcodeproj/project.pbxproj` — 705 lines
- `ios/Runner.xcodeproj/project.pbxproj` — 620 lines
- `lib/services/health_connect_service.dart` — 590 lines
- `lib/providers/kaloricke_tabulky_provider.dart` — 558 lines
- `lib/screens/home/widgets/weight_card.dart` — 514 lines
- `lib/l10n/app_localizations_cs.dart` — 498 lines
- `lib/l10n/app_localizations_en.dart` — 498 lines
- `lib/l10n/app_en.arb` — 494 lines
- `tooling/project_audit.py` — 489 lines
- `lib/screens/profile/widgets/profile_settings_widgets.dart` — 478 lines
- `lib/providers/fitness_provider.dart` — 473 lines

## Largest directories by text line count

| Directory | Files | Text files | Lines | TODOs | Size |
|---|---:|---:|---:|---:|---:|
| `lib/l10n` | 6 | 6 | 2754 | 0 | 77.4 KB |
| `lib/models` | 9 | 9 | 2446 | 0 | 70.4 KB |
| `lib/services` | 7 | 7 | 2194 | 0 | 70.5 KB |
| `lib/screens/home/widgets` | 5 | 5 | 1505 | 0 | 50.8 KB |
| `lib/providers` | 8 | 8 | 1490 | 0 | 51.1 KB |
| `/` | 15 | 8 | 1307 | 0 | 7.5 MB |
| `lib/screens/profile/sections` | 5 | 5 | 1141 | 0 | 33.9 KB |
| `lib/screens/home` | 1 | 1 | 964 | 0 | 33.0 KB |
| `lib/widgets` | 8 | 8 | 927 | 0 | 28.9 KB |
| `windows/runner` | 11 | 11 | 812 | 0 | 24.9 KB |
| `tooling` | 3 | 3 | 787 | 13 | 24.9 KB |
| `lib/screens/calories` | 1 | 1 | 757 | 0 | 22.8 KB |
| `macos/Runner.xcodeproj` | 1 | 1 | 705 | 0 | 26.5 KB |
| `lib/theme` | 3 | 3 | 625 | 0 | 22.9 KB |
| `ios/Runner.xcodeproj` | 1 | 1 | 620 | 0 | 24.2 KB |
| `lib/screens/profile/widgets` | 2 | 2 | 528 | 0 | 14.1 KB |
| `lib/screens/activities/widgets` | 2 | 2 | 493 | 0 | 15.8 KB |
| `lib/screens/body/widgets` | 2 | 2 | 391 | 0 | 13.1 KB |
| `android` | 7 | 7 | 343 | 0 | 9.9 KB |
| `macos/Runner/Base.lproj` | 1 | 1 | 343 | 0 | 23.5 KB |

## Duplicate filenames

- `.gitignore`
  - `.gitignore`
  - `android/.gitignore`
  - `ios/.gitignore`
  - `linux/.gitignore`
  - `macos/.gitignore`
  - `windows/.gitignore`
- `AndroidManifest.xml`
  - `android/app/src/debug/AndroidManifest.xml`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/profile/AndroidManifest.xml`
- `AppDelegate.swift`
  - `ios/Runner/AppDelegate.swift`
  - `macos/Runner/AppDelegate.swift`
- `CMakeLists.txt`
  - `linux/CMakeLists.txt`
  - `linux/flutter/CMakeLists.txt`
  - `linux/runner/CMakeLists.txt`
  - `windows/CMakeLists.txt`
  - `windows/flutter/CMakeLists.txt`
  - `windows/runner/CMakeLists.txt`
- `Contents.json`
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`
  - `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `Debug.xcconfig`
  - `ios/Flutter/Debug.xcconfig`
  - `macos/Runner/Configs/Debug.xcconfig`
- `IDEWorkspaceChecks.plist`
  - `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
  - `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
  - `macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
  - `macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `Info.plist`
  - `ios/Runner/Info.plist`
  - `macos/Runner/Info.plist`
- `README.md`
  - `assets/icons/google/README.md`
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
  - `README.md`
- `Release.xcconfig`
  - `ios/Flutter/Release.xcconfig`
  - `macos/Runner/Configs/Release.xcconfig`
- `Runner.xcscheme`
  - `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
  - `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- `RunnerTests.swift`
  - `ios/RunnerTests/RunnerTests.swift`
  - `macos/RunnerTests/RunnerTests.swift`
- `WorkspaceSettings.xcsettings`
  - `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
  - `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
- `build.gradle.kts`
  - `android/app/build.gradle.kts`
  - `android/build.gradle.kts`
- `contents.xcworkspacedata`
  - `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
  - `ios/Runner.xcworkspace/contents.xcworkspacedata`
  - `macos/Runner.xcworkspace/contents.xcworkspacedata`
- `flutter_export_environment.sh`
  - `ios/Flutter/flutter_export_environment.sh`
  - `macos/Flutter/ephemeral/flutter_export_environment.sh`
- `generated_plugin_registrant.cc`
  - `linux/flutter/generated_plugin_registrant.cc`
  - `windows/flutter/generated_plugin_registrant.cc`
- `generated_plugin_registrant.h`
  - `linux/flutter/generated_plugin_registrant.h`
  - `windows/flutter/generated_plugin_registrant.h`
- `generated_plugins.cmake`
  - `linux/flutter/generated_plugins.cmake`
  - `windows/flutter/generated_plugins.cmake`
- `ic_launcher.png`
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png`
- `ic_launcher_round.png`
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png`
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png`
- `launch_background.xml`
  - `android/app/src/main/res/drawable-v21/launch_background.xml`
  - `android/app/src/main/res/drawable/launch_background.xml`
- `project.pbxproj`
  - `ios/Runner.xcodeproj/project.pbxproj`
  - `macos/Runner.xcodeproj/project.pbxproj`
- `styles.xml`
  - `android/app/src/main/res/values-night-v31/styles.xml`
  - `android/app/src/main/res/values-night/styles.xml`
  - `android/app/src/main/res/values-v31/styles.xml`
  - `android/app/src/main/res/values/styles.xml`

## Recommended cleanup targets

Prioritize these first:

1. Files over ~300–500 lines, especially UI/state files.
2. Directories with high line count and many TODOs.
3. Duplicate filename patterns that make navigation confusing.
4. Files with low comments but very high non-empty line counts.
5. Any screen/provider/service doing too many things at once.

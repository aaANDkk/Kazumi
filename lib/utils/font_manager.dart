import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FontManager {
  static const String customFontFamily = 'CustomUserFont';
  static bool _isLoaded = false;
  static String? _loadedFilePath;

  static bool get isLoaded => _isLoaded;

  /// Loads the custom font from [filePath] via Flutter's [FontLoader].
  static Future<bool> loadCustomFont(String filePath) async {
    if (_isLoaded && _loadedFilePath == filePath) {
      return true;
    }
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        KazumiLogger().w('FontManager: font file does not exist: $filePath');
        return false;
      }
      final bytes = await file.readAsBytes();
      final fontLoader = FontLoader(customFontFamily);
      fontLoader.addFont(Future.value(
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
      ));

      await fontLoader.load();
      _isLoaded = true;
      _loadedFilePath = filePath;
      KazumiLogger().i('FontManager: custom font loaded from $filePath');
      return true;
    } catch (e, stack) {
      KazumiLogger()
          .e('FontManager: failed to load custom font', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Picks a .ttf file from the file manager, copies it to safe app storage,
  /// loads it into the runtime, and persists settings.
  static Future<bool> pickAndApplyCustomFont() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf'],
      );
      if (result == null || result.files.isEmpty) {
        return false;
      }

      final sourcePath = result.files.single.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        return false;
      }

      final supportDir = await getApplicationSupportDirectory();
      final fontsDir = Directory(p.join(supportDir.path, 'fonts'));
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }

      final fileName = result.files.single.name;
      final destFile = File(p.join(fontsDir.path, 'user_custom.ttf'));
      await File(sourcePath).copy(destFile.path);

      final success = await loadCustomFont(destFile.path);
      if (success) {
        await GStorage.putSetting(SettingsKeys.customFontPath, destFile.path);
        await GStorage.putSetting(SettingsKeys.customFontName, fileName);
        await GStorage.putSetting(SettingsKeys.useCustomFont, true);
        return true;
      }
      return false;
    } catch (e, stack) {
      KazumiLogger()
          .e('FontManager: pick and apply font failed', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Disables custom font and falls back to system font.
  static Future<void> disableCustomFont() async {
    await GStorage.putSetting(SettingsKeys.useCustomFont, false);
  }
}

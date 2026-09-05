import 'package:kazumi/modules/roads/road_module.dart';

class EpisodeUtils {
  /// Extracts the numeric episode number from an episode title.
  /// E.g. "第01集" -> 1, "第12.5话" -> 12.5, "EP08" -> 8, "03" -> 3.
  static num? extractEpisodeNumber(String title) {
    if (title.isEmpty) return null;

    // Pattern 1: 第X集 / 第X话 / 第X期 / 第X回
    final match1 = RegExp(r'第\s*(\d+(?:\.\d+)?)\s*[集话話期回]').firstMatch(title);
    if (match1 != null) {
      return num.tryParse(match1.group(1)!);
    }

    // Pattern 2: EP X / E X / ep X
    final match2 =
        RegExp(r'(?:EP|ep|Ep|E|e)\s*(\d+(?:\.\d+)?)').firstMatch(title);
    if (match2 != null) {
      return num.tryParse(match2.group(1)!);
    }

    // Pattern 3: # X
    final match3 = RegExp(r'#\s*(\d+(?:\.\d+)?)').firstMatch(title);
    if (match3 != null) {
      return num.tryParse(match3.group(1)!);
    }

    // Pattern 4: Standalone numbers, e.g. "01", "1", " 12 "
    final trimmed = title.trim();
    final matchExactNum = RegExp(r'^\d+(?:\.\d+)?$').firstMatch(trimmed);
    if (matchExactNum != null) {
      return num.tryParse(trimmed);
    }

    // Pattern 5: Fallback to the first integer or decimal in the string
    final matchFallback = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(title);
    if (matchFallback != null) {
      return num.tryParse(matchFallback.group(1)!);
    }

    return null;
  }

  /// Checks whether a list of episode titles is in descending order (e.g. Ep 12 -> Ep 1).
  static bool isDescendingOrder(List<String> titles) {
    if (titles.length < 2) return false;

    num? firstNum;
    for (int i = 0; i < titles.length && i < 5; i++) {
      firstNum = extractEpisodeNumber(titles[i]);
      if (firstNum != null) break;
    }

    num? lastNum;
    for (int i = titles.length - 1; i >= 0 && i >= titles.length - 5; i--) {
      lastNum = extractEpisodeNumber(titles[i]);
      if (lastNum != null) break;
    }

    if (firstNum != null && lastNum != null) {
      return firstNum > lastNum;
    }

    return false;
  }

  /// Normalizes a [Road] so its episodes are strictly in ascending order (1 -> N).
  /// Returns a normalized Road (reversed if original was descending).
  static Road normalizeRoad(Road road) {
    if (isDescendingOrder(road.identifier)) {
      return Road(
        name: road.name,
        data: road.data.reversed.toList(),
        identifier: road.identifier.reversed.toList(),
      );
    }
    return road;
  }

  /// Finds the 1-based index of the next episode in [road].
  /// Returns `null` if already at the latest episode or if not found.
  static int? findNextEpisodeIndex({
    required Road road,
    required int currentEpisode1Based,
    String? currentEpisodeUrl,
    String? currentEpisodeTitle,
  }) {
    if (road.data.isEmpty) return null;

    // 1. Locate current index (0-based) in road.data
    int currentIdx = -1;
    if (currentEpisodeUrl != null && currentEpisodeUrl.isNotEmpty) {
      currentIdx = road.data.indexOf(currentEpisodeUrl);
    }
    if (currentIdx == -1) {
      currentIdx = currentEpisode1Based - 1;
    }
    if (currentIdx < 0 || currentIdx >= road.data.length) {
      currentIdx = 0;
    }

    // 2. Try to match by episode number (current + 1)
    String curTitle = '';
    if (currentIdx < road.identifier.length) {
      curTitle = road.identifier[currentIdx];
    } else if (currentEpisodeTitle != null && currentEpisodeTitle.isNotEmpty) {
      curTitle = currentEpisodeTitle;
    }

    final curNum = extractEpisodeNumber(curTitle);
    if (curNum != null) {
      final targetNum = curNum + 1;
      for (int i = 0; i < road.identifier.length; i++) {
        final numVal = extractEpisodeNumber(road.identifier[i]);
        if (numVal != null && (numVal - targetNum).abs() < 0.01) {
          return i + 1; // 1-based
        }
      }
    }

    // 3. Fallback based on road order direction
    if (isDescendingOrder(road.identifier)) {
      // In descending list, the next episode (higher number) is at previous index
      if (currentIdx - 1 >= 0) {
        return currentIdx; // (currentIdx - 1) + 1 = currentIdx
      }
      return null; // Already at the latest episode
    } else {
      // In ascending list, next episode is at next index
      if (currentIdx + 1 < road.data.length) {
        return currentIdx + 2; // (currentIdx + 1) + 1
      }
      return null; // Already at the latest episode
    }
  }

  /// Helper to resolve target 1-based episode index for the current watch.
  /// If [currentEpisodeUrl] is found, returns its exact 1-based index in [road].
  static int resolveCurrentEpisodeIndex({
    required Road road,
    required int fallbackEpisode1Based,
    String? currentEpisodeUrl,
  }) {
    if (currentEpisodeUrl != null && currentEpisodeUrl.isNotEmpty) {
      final idx = road.data.indexOf(currentEpisodeUrl);
      if (idx != -1) {
        return idx + 1;
      }
    }
    if (fallbackEpisode1Based >= 1 &&
        fallbackEpisode1Based <= road.data.length) {
      return fallbackEpisode1Based;
    }
    return 1;
  }
}

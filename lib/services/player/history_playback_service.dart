import 'package:kazumi/modules/download/download_module.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/episode_utils.dart';

sealed class HistoryPlaybackResult {
  const HistoryPlaybackResult();
}

class HistoryPlaybackReady extends HistoryPlaybackResult {
  const HistoryPlaybackReady(this.args);

  final VideoPlaybackArgs args;
}

class HistoryPlaybackUnavailable extends HistoryPlaybackResult {
  const HistoryPlaybackUnavailable(this.reason);

  final String reason;
}

/// Restores a history entry into arguments the player route can take.
///
/// The history page and the my page share this one resolution path; cards
/// carry no source-lookup logic of their own.
class HistoryPlaybackService {
  HistoryPlaybackService(this._pluginsController, this._downloadController);

  final PluginsController _pluginsController;
  final DownloadController _downloadController;

  /// [cancelToken] lets the caller abort the online lookup, e.g. when the
  /// loading dialog it put up is dismissed.
  /// [nextEpisode] determines whether to play the next episode instead of continuing current one.
  Future<HistoryPlaybackResult> open(
    History history, {
    RuleCancelToken? cancelToken,
    bool nextEpisode = false,
  }) async {
    if (HistoryEntryKind.normalize(history.entryKind) ==
        HistoryEntryKind.offline) {
      return _offlineResult(history, nextEpisode: nextEpisode);
    }

    return _onlineResult(history, cancelToken, nextEpisode: nextEpisode);
  }

  Future<HistoryPlaybackResult> _onlineResult(
    History history,
    RuleCancelToken? cancelToken, {
    bool nextEpisode = false,
  }) async {
    if (history.lastSrc.isEmpty) {
      return const HistoryPlaybackUnavailable('播放地址为空');
    }
    Plugin? targetPlugin;
    for (final plugin in _pluginsController.pluginList) {
      if (plugin.name == history.adapterName) {
        targetPlugin = plugin;
        break;
      }
    }
    if (targetPlugin == null) {
      return const HistoryPlaybackUnavailable('未找到对应播放插件');
    }
    try {
      final rawRoads = await targetPlugin.queryChapterRoads(
        history.lastSrc,
        cancelToken: cancelToken,
      );
      if (rawRoads.isEmpty) {
        return const HistoryPlaybackUnavailable('在线源不可用，请重新选择播放源');
      }

      // Normalize roads so descending order sources become ascending order
      final roads = rawRoads.map(EpisodeUtils.normalizeRoad).toList();

      int roadIndex = 0;
      final progress = history.progresses[history.lastWatchEpisode];
      if (progress != null &&
          progress.road >= 0 &&
          progress.road < roads.length) {
        roadIndex = progress.road;
      }
      final targetRoad = roads[roadIndex];

      int? targetEpisode;
      int targetOffset = 0;

      if (nextEpisode) {
        final nextIdx = EpisodeUtils.findNextEpisodeIndex(
          road: targetRoad,
          currentEpisode1Based: history.lastWatchEpisode,
          currentEpisodeUrl: history.episodePageUrl,
          currentEpisodeTitle: history.lastWatchEpisodeName,
        );
        if (nextIdx == null) {
          return const HistoryPlaybackUnavailable('当前已是最新集了');
        }
        targetEpisode = nextIdx;
        targetOffset = 0;
      } else {
        targetEpisode = EpisodeUtils.resolveCurrentEpisodeIndex(
          road: targetRoad,
          fallbackEpisode1Based: history.lastWatchEpisode,
          currentEpisodeUrl: history.episodePageUrl,
        );
        targetOffset = progress?.progress.inSeconds ?? 0;
      }

      return HistoryPlaybackReady(
        OnlineVideoPlaybackArgs(
          bangumiItem: history.bangumiItem,
          plugin: targetPlugin,
          title: history.bangumiItem.nameCn.isEmpty
              ? history.bangumiItem.name
              : history.bangumiItem.nameCn,
          src: history.lastSrc,
          roads: roads,
          targetEpisode: targetEpisode,
          targetRoad: roadIndex,
          targetOffset: targetOffset,
        ),
      );
    } catch (_) {
      KazumiLogger().w("QueryManager: failed to query roads");
      return const HistoryPlaybackUnavailable('在线源不可用，请重新选择播放源');
    }
  }

  HistoryPlaybackResult _offlineResult(
    History history, {
    bool nextEpisode = false,
  }) {
    final downloadedEpisodes = _downloadController.getCompletedEpisodes(
      history.bangumiItem.id,
      history.adapterName,
    );
    if (downloadedEpisodes.isEmpty) {
      return const HistoryPlaybackUnavailable('未找到可用缓存');
    }

    // Sort downloaded episodes by episodeNumber
    downloadedEpisodes
        .sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    DownloadEpisode? targetEpisode;
    if (nextEpisode) {
      int currentEpNum = history.lastWatchEpisode;
      if (history.episodePageUrl.isNotEmpty) {
        for (final ep in downloadedEpisodes) {
          if (ep.episodePageUrl == history.episodePageUrl) {
            currentEpNum = ep.episodeNumber;
            break;
          }
        }
      }
      for (final ep in downloadedEpisodes) {
        if (ep.episodeNumber > currentEpNum) {
          targetEpisode = ep;
          break;
        }
      }
      if (targetEpisode == null) {
        return const HistoryPlaybackUnavailable('当前已是最新集了或下一集未下载');
      }
    } else {
      DownloadEpisode? numberMatch;
      for (final episode in downloadedEpisodes) {
        if (history.episodePageUrl.isNotEmpty &&
            episode.episodePageUrl == history.episodePageUrl) {
          targetEpisode = episode;
          break;
        }
        if (episode.episodeNumber == history.lastWatchEpisode) {
          numberMatch ??= episode;
        }
      }
      targetEpisode ??= numberMatch;
      if (targetEpisode == null) {
        return const HistoryPlaybackUnavailable('未找到可用缓存');
      }
    }

    final localPath = _downloadController.getLocalVideoPath(
      history.bangumiItem.id,
      history.adapterName,
      targetEpisode.episodeNumber,
    );
    if (localPath == null) {
      return const HistoryPlaybackUnavailable('本地缓存文件不存在');
    }

    return HistoryPlaybackReady(
      OfflineVideoPlaybackArgs(
        bangumiItem: history.bangumiItem,
        pluginName: history.adapterName,
        episodeNumber: targetEpisode.episodeNumber,
        road: targetEpisode.road,
        downloadedEpisodes: downloadedEpisodes,
      ),
    );
  }
}

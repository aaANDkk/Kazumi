import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/modules/my/recent_watch_item.dart';
import 'package:kazumi/services/player/history_playback_service.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/date_time.dart';
import 'package:kazumi/utils/device.dart';

class RecentWatchCard extends StatefulWidget {
  const RecentWatchCard({super.key, required this.item});

  final RecentWatchItem item;

  @override
  State<RecentWatchCard> createState() => _RecentWatchCardState();
}

class _RecentWatchCardState extends State<RecentWatchCard> {
  static const double _coverWidth = 86;
  static const double _coverHeight = 118;

  final HistoryPlaybackService _playbackService =
      inject<HistoryPlaybackService>();

  RuleCancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _openDetail() {
    context.pushNamed(
      '/info/',
      arguments: widget.item.history.bangumiItem,
    );
  }

  Future<void> _play({required bool nextEpisode}) async {
    _cancelToken?.cancel();
    final cancelToken = RuleCancelToken();
    _cancelToken = cancelToken;
    KazumiDialog.showLoading(
      msg: '获取中',
      barrierDismissible: isDesktop(),
      onDismiss: cancelToken.cancel,
    );
    final result = await _playbackService.open(
      widget.item.history,
      cancelToken: cancelToken,
      nextEpisode: nextEpisode,
    );
    KazumiDialog.dismiss();
    if (!mounted) return;
    switch (result) {
      case HistoryPlaybackReady(:final args):
        context.pushNamed('/video/', arguments: args);
      case HistoryPlaybackUnavailable(:final reason):
        KazumiDialog.showToast(message: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: _coverHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '看到 ${item.episodeLabel}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _pill(
                            label: item.sourceLabel,
                            background: colorScheme.secondaryContainer,
                            foreground: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: _pill(
                              label: item.adapterName,
                              background: colorScheme.surfaceContainerHighest,
                              foreground: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatTimestampToRelativeTime(
                              item.lastWatchTime.millisecondsSinceEpoch ~/ 1000,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          SizedBox(
                            height: 32,
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _play(nextEpisode: false),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 16),
                              label: const Text(
                                '继续观看',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _play(nextEpisode: true),
                              icon: const Icon(Icons.skip_next_rounded,
                                  size: 16),
                              label: const Text(
                                '下一集',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: NetworkImgLayer(
        src: widget.item.coverUrl,
        width: _coverWidth,
        height: _coverHeight,
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 10,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

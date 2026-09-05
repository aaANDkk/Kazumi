import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/services/player/history_playback_service.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/date_time.dart';

String _historySourceText(String entryKind) {
  return HistoryEntryKind.normalize(entryKind) == HistoryEntryKind.offline
      ? '缓存'
      : '在线';
}

class BangumiHistoryCardV extends StatefulWidget {
  const BangumiHistoryCardV({
    super.key,
    required this.historyItem,
    this.showDelete = false,
    this.onDeleted,
  });

  final History historyItem;
  final bool showDelete;
  final VoidCallback? onDeleted;

  @override
  State<BangumiHistoryCardV> createState() => _BangumiHistoryCardVState();
}

class _BangumiHistoryCardVState extends State<BangumiHistoryCardV> {
  final CollectController collectController = inject<CollectController>();
  final HistoryPlaybackService _playbackService =
      inject<HistoryPlaybackService>();

  RuleCancelToken? _queryRoadsCancelToken;

  @override
  void dispose() {
    _queryRoadsCancelToken?.cancel();
    super.dispose();
  }

  void _onCardTap() {
    if (widget.showDelete) {
      widget.onDeleted?.call();
      return;
    }
    context.pushNamed(
      '/info/',
      arguments: widget.historyItem.bangumiItem,
    );
  }

  Future<void> _playEpisode({required bool nextEpisode}) async {
    if (widget.showDelete) {
      KazumiDialog.showToast(message: '编辑模式');
      return;
    }
    _queryRoadsCancelToken?.cancel();
    final cancelToken = RuleCancelToken();
    _queryRoadsCancelToken = cancelToken;
    KazumiDialog.showLoading(
      msg: '获取中',
      barrierDismissible: isDesktop(),
      onDismiss: cancelToken.cancel,
    );
    final result = await _playbackService.open(
      widget.historyItem,
      cancelToken: cancelToken,
      nextEpisode: nextEpisode,
    );
    KazumiDialog.dismiss();
    if (!mounted) return;
    switch (result) {
      case HistoryPlaybackReady(:final args):
        context.pushNamed('/video/', arguments: args);
      case HistoryPlaybackUnavailable(:final reason):
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          KazumiDialog.showToast(message: reason, context: context);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const double imageWidth = 86;
    const double imageHeight = 118;
    final String title = widget.historyItem.bangumiItem.nameCn.isEmpty
        ? widget.historyItem.bangumiItem.name
        : widget.historyItem.bangumiItem.nameCn;
    final String episodeText = widget.historyItem.lastWatchEpisodeName.isEmpty
        ? '第${widget.historyItem.lastWatchEpisode}话'
        : widget.historyItem.lastWatchEpisodeName;
    final String sourceText = _historySourceText(widget.historyItem.entryKind);

    return Dismissible(
      key: ValueKey(widget.historyItem.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        widget.onDeleted?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: _onCardTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: NetworkImgLayer(
                    src: widget.historyItem.bangumiItem.images['large'] ?? '',
                    width: imageWidth,
                    height: imageHeight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: imageHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (!widget.showDelete)
                              Observer(
                                builder: (context) {
                                  collectController.collectibles.length;
                                  return SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CollectButton(
                                      onClose: () {
                                        FocusScope.of(context).unfocus();
                                      },
                                      bangumiItem:
                                          widget.historyItem.bangumiItem,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            if (widget.showDelete)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: colorScheme.error,
                                  ),
                                  tooltip: '删除记录',
                                  onPressed: () {
                                    widget.onDeleted?.call();
                                  },
                                ),
                              ),
                          ],
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
                                episodeText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$sourceText · ${widget.historyItem.adapterName}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatTimestampToRelativeTime(widget.historyItem
                                      .lastWatchTime.millisecondsSinceEpoch ~/
                                  1000),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () =>
                                    _playEpisode(nextEpisode: false),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () =>
                                    _playEpisode(nextEpisode: true),
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
      ),
    );
  }
}

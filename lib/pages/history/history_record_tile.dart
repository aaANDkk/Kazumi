import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';

class HistoryRecordTile extends StatelessWidget {
  const HistoryRecordTile({
    super.key,
    required this.history,
    required this.onPlay,
    this.onPlayNext,
    required this.onDetails,
    required this.onDelete,
    required this.collectType,
    required this.onChangeCollect,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.editing = false,
    this.busy = false,
  });

  final History history;
  final VoidCallback onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback onDetails;
  final Future<void> Function() onDelete;
  final CollectType collectType;
  final ValueChanged<CollectType>? onChangeCollect;
  final BorderRadius borderRadius;
  final bool editing;
  final bool busy;

  double get _progressRatio {
    final progress = history.progresses[history.lastWatchEpisode];
    return progress?.progressRatio ?? 0.0;
  }

  String get _position {
    final progress = history.progresses[history.lastWatchEpisode]?.progress;
    if (progress == null || progress.inSeconds <= 0) return '';
    final seconds = (progress.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (progress.inMinutes % 60).toString().padLeft(2, '0');
    final position = progress.inHours > 0
        ? '${progress.inHours}:$minutes:$seconds'
        : '${progress.inMinutes}:$seconds';
    return '看到 $position';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = history.bangumiItem.nameCn.isEmpty
        ? history.bangumiItem.name
        : history.bangumiItem.nameCn;
    final episode = history.lastWatchEpisodeName.isEmpty
        ? '第 ${history.lastWatchEpisode} 话'
        : history.lastWatchEpisodeName;
    final source = HistoryEntryKind.normalize(history.entryKind) ==
            HistoryEntryKind.offline
        ? '缓存'
        : '在线';
    final time =
        TimeOfDay.fromDateTime(history.lastWatchTime.toLocal()).format(context);
    final image = history.bangumiItem.images['large'] ?? '';
    final position = _position;
    final progressRatio = _progressRatio;

    return Dismissible(
      key: ValueKey(history.key),
      direction:
          busy || editing ? DismissDirection.none : DismissDirection.endToStart,
      // The parent removes saved deletions; failed writes keep the row usable.
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: borderRadius,
        ),
        child:
            Icon(Icons.delete_outline_rounded, color: colors.onErrorContainer),
      ),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Keep menu focus outside the card's InkWell to prevent stuck highlights.
            Positioned.fill(
              child: Semantics(
                button: !editing && !busy,
                label: [
                  title,
                  episode,
                  position,
                  source,
                  history.adapterName,
                  time
                ].where((text) => text.isNotEmpty).join('，'),
                child: InkWell(onTap: editing || busy ? null : onDetails),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final coverWidth = wide ? 72.0 : 60.0;
                final coverHeight = wide ? 100.0 : 84.0;
                final coverGap = wide ? 16.0 : 12.0;
                final actionsGap = wide ? 16.0 : 8.0;

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: wide ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: wide ? 15.5 : 14.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      episode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: wide ? 13 : 12.5,
                      ),
                    ),
                    if (progressRatio > 0.0) ...[
                      SizedBox(height: wide ? 6 : 4),
                      Padding(
                        padding: EdgeInsets.only(right: wide ? 36.0 : 24.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: wide ? 3.5 : 3.0,
                              backgroundColor: colors.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(colors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: wide ? 6 : 4),
                    Text(
                      [
                        source,
                        if (history.adapterName.isNotEmpty) history.adapterName,
                        time
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: wide ? 12 : 11.5,
                      ),
                    ),
                  ],
                );
                final actions = _actions(context, wide: wide);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: image.isEmpty
                                  ? Container(
                                      width: coverWidth,
                                      height: coverHeight,
                                      color: colors.surfaceContainerHighest,
                                      child: Icon(Icons.movie_outlined,
                                          color: colors.onSurfaceVariant),
                                    )
                                  : NetworkImgLayer(
                                      src: image,
                                      width: coverWidth,
                                      height: coverHeight,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: coverGap),
                        Expanded(
                          child: ExcludeSemantics(
                            child: IgnorePointer(child: content),
                          ),
                        ),
                        if (!largeText) ...[
                          SizedBox(width: actionsGap),
                          actions,
                        ],
                      ],
                    ),
                    if (largeText) ...[
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, {required bool wide}) {
    final colors = Theme.of(context).colorScheme;
    final buttonSize = wide ? const Size(38, 38) : const Size(32, 32);
    final iconSize = wide ? 20.0 : 18.0;
    final buttonRadius = wide ? 10.0 : 8.0;
    final buttonSpacing = wide ? 8.0 : 6.0;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final normalActionsWidth = buttonSize.width * 3 + buttonSpacing * 2;

    if (busy) {
      return SizedBox(
        width: normalActionsWidth,
        height: buttonSize.height,
        child: Center(child: LoadingIndicator(size: wide ? 20 : 16)),
      );
    }
    if (editing) {
      return SizedBox(
        width: normalActionsWidth,
        height: buttonSize.height,
        child: Align(
          alignment: Alignment.centerRight,
          child: IconButton.filledTonal(
            tooltip: '删除记录',
            style: IconButton.styleFrom(
              minimumSize: buttonSize,
              fixedSize: buttonSize,
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
              padding: EdgeInsets.zero,
              shape: buttonShape,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: iconSize),
          ),
        ),
      );
    }

    final buttons = [
      IconButton.filledTonal(
        tooltip: '继续播放',
        style: IconButton.styleFrom(
          minimumSize: buttonSize,
          fixedSize: buttonSize,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          padding: EdgeInsets.zero,
          shape: buttonShape,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: onPlay,
        icon: Icon(Icons.play_arrow_rounded, size: iconSize),
      ),
      if (onPlayNext != null)
        IconButton.filledTonal(
          tooltip: '下一集',
          style: IconButton.styleFrom(
            minimumSize: buttonSize,
            fixedSize: buttonSize,
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.onSurfaceVariant,
            padding: EdgeInsets.zero,
            shape: buttonShape,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPlayNext,
          icon: Icon(Icons.skip_next_rounded, size: iconSize),
        ),
      MenuAnchor(
        consumeOutsideTap: true,
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.info_outline_rounded),
            onPressed: onDetails,
            child: const Text('番剧详情'),
          ),
          SubmenuButton(
            leadingIcon: const Icon(Icons.bookmark_outline_rounded),
            menuChildren: [
              for (final type in CollectType.values)
                MenuItemButton(
                  leadingIcon: Icon(collectType == type
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded),
                  onPressed: onChangeCollect == null
                      ? null
                      : () => onChangeCollect!(type),
                  child: Text(type.label),
                ),
            ],
            child: Text('收藏 · ${collectType.label}'),
          ),
          const Divider(),
          MenuItemButton(
            leadingIcon:
                Icon(Icons.delete_outline_rounded, color: colors.error),
            onPressed: onDelete,
            child: Text('删除记录', style: TextStyle(color: colors.error)),
          ),
        ],
        builder: (context, controller, child) => IconButton.filledTonal(
          tooltip: '更多操作',
          style: IconButton.styleFrom(
            minimumSize: buttonSize,
            fixedSize: buttonSize,
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.onSurfaceVariant,
            padding: EdgeInsets.zero,
            shape: buttonShape,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: Icon(Icons.more_horiz_rounded, size: iconSize),
        ),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: buttonSpacing),
          buttons[i],
        ],
      ],
    );
  }
}

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
    final cardShape = RoundedSuperellipseBorder(borderRadius: borderRadius);

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
        decoration: ShapeDecoration(
          color: colors.errorContainer,
          shape: cardShape,
        ),
        child:
            Icon(Icons.delete_outline_rounded, color: colors.onErrorContainer),
      ),
      child: Material(
        color: colors.surfaceContainerLow,
        shape: cardShape,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final coverWidth = wide ? 68.0 : 58.0;
                final coverHeight = coverWidth * 1.38;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
                        fontSize: 13,
                      ),
                    ),
                    if (progressRatio > 0.0) ...[
                      const SizedBox(height: 5),
                      ClipPath(
                        clipper: ShapeBorderClipper(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 3,
                            backgroundColor: colors.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(colors.primary),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
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
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                );
                final actions = _actions(context, wide: wide || largeText);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: IgnorePointer(
                            child: ClipPath(
                              clipper: ShapeBorderClipper(
                                shape: RoundedSuperellipseBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: ExcludeSemantics(
                            child: IgnorePointer(child: content),
                          ),
                        ),
                        if (!largeText) ...[
                          const SizedBox(width: 8),
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
    final buttonSize = wide ? const Size(36, 36) : const Size(30, 30);
    final iconSize = wide ? 20.0 : 16.0;
    final buttonRadius = wide ? 10.0 : 8.0;
    final buttonShape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );

    if (busy) {
      return SizedBox(
        width: buttonSize.width,
        height: buttonSize.height,
        child: const Center(child: LoadingIndicator(size: 18)),
      );
    }
    if (editing) {
      return IconButton.filledTonal(
        tooltip: '删除记录',
        style: IconButton.styleFrom(
          minimumSize: buttonSize,
          fixedSize: buttonSize,
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
          padding: EdgeInsets.zero,
          shape: buttonShape,
        ),
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline_rounded, size: iconSize),
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
          ),
          onPressed: onPlayNext,
          icon: Icon(Icons.skip_next_rounded, size: iconSize),
        ),
      MenuAnchor(
        consumeOutsideTap: true,
        style: MenuStyle(
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
        builder: (context, controller, child) => IconButton(
          tooltip: '更多操作',
          style: IconButton.styleFrom(
            minimumSize: buttonSize,
            fixedSize: buttonSize,
            padding: EdgeInsets.zero,
            shape: buttonShape,
          ),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: Icon(Icons.more_horiz_rounded, size: iconSize),
        ),
      ),
    ];
    return wide
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                buttons[i],
              ],
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                buttons[i],
              ],
            ],
          );
  }
}

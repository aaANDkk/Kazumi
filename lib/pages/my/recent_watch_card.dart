import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/bangumi_history_card.dart';
import 'package:kazumi/modules/my/recent_watch_item.dart';

class RecentWatchCard extends StatelessWidget {
  const RecentWatchCard({super.key, required this.item});

  final RecentWatchItem item;

  @override
  Widget build(BuildContext context) {
    return BangumiHistoryCardV(
      historyItem: item.history,
      margin: EdgeInsets.zero,
      enableDismiss: false,
    );
  }
}


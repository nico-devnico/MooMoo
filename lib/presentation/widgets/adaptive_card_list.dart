import 'package:flutter/material.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_spacing.dart';

/// A scrollable list of cards that splits into columns once there is room.
///
/// Cards keep their intrinsic height (unlike a [GridView], which forces a
/// single aspect ratio), so the same widget works for a dense admin row and a
/// tall contribution card. Below [maxItemWidth] it degrades to a plain
/// [ListView], which is what phones get.
class AdaptiveCardList extends StatelessWidget {
  const AdaptiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.spacing = AppSpacing.m,
    this.maxItemWidth = 460,
    this.maxColumns = 3,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double spacing;

  /// Width above which an extra column is added.
  final double maxItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - padding.horizontal;
        final columns = adaptiveColumnCount(
          inner,
          maxItemWidth: maxItemWidth,
          max: maxColumns,
        );

        if (columns <= 1) {
          return ListView.separated(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (context, index) => SizedBox(height: spacing),
            itemBuilder: itemBuilder,
          );
        }

        return SingleChildScrollView(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) SizedBox(width: spacing),
                Expanded(child: _column(context, column, columns)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _column(BuildContext context, int column, int columns) {
    final children = <Widget>[];
    for (var index = column; index < itemCount; index += columns) {
      if (children.isNotEmpty) children.add(SizedBox(height: spacing));
      children.add(itemBuilder(context, index));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

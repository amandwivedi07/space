import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/extensions/datetime_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';
import 'circle_bubble.dart';
import 'person_bubble.dart';

/// The cluster as a staggered masonry grid — airy, no overlap, most recent
/// spaces first, with the web app's mono time-ago badge above each bubble.
class ClusterGrid extends StatefulWidget {
  const ClusterGrid({
    super.key,
    required this.people,
    required this.circles,
    required this.membersOf,
    required this.onOpenPerson,
    required this.onOpenCircle,
  });

  final List<Person> people;
  final List<CircleSpace> circles;
  final List<Person> Function(CircleSpace) membersOf;
  final ValueChanged<Person> onOpenPerson;
  final ValueChanged<CircleSpace> onOpenCircle;

  @override
  State<ClusterGrid> createState() => _ClusterGridState();
}

class _ClusterGridState extends State<ClusterGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppConstants.driftPeriod,
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  List<_ClusterEntry> get _entries {
    final entries = [
      ...widget.people.map(_ClusterEntry.person),
      ...widget.circles.map(_ClusterEntry.circle),
    ]..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 700 ? 4 : 3;
      const hPadding = 20.0;
      const spacing = 14.0;
      final columnWidth =
          (constraints.maxWidth - hPadding * 2 - spacing * (columns - 1)) /
              columns;
      final entries = _entries;

      return MasonryGridView.count(
        crossAxisCount: columns,
        mainAxisSpacing: 26,
        crossAxisSpacing: spacing,
        padding: const EdgeInsets.fromLTRB(hPadding, 12, hPadding, 120),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, index) => _ClusterTile(
          entry: entries[index],
          index: index,
          columnWidth: columnWidth,
          drift: _drift,
          membersOf: widget.membersOf,
          onOpenPerson: widget.onOpenPerson,
          onOpenCircle: widget.onOpenCircle,
        ),
      );
    });
  }
}

class _ClusterTile extends StatelessWidget {
  const _ClusterTile({
    required this.entry,
    required this.index,
    required this.columnWidth,
    required this.drift,
    required this.membersOf,
    required this.onOpenPerson,
    required this.onOpenCircle,
  });

  final _ClusterEntry entry;
  final int index;
  final double columnWidth;
  final Animation<double> drift;
  final List<Person> Function(CircleSpace) membersOf;
  final ValueChanged<Person> onOpenPerson;
  final ValueChanged<CircleSpace> onOpenCircle;

  double get _bubbleSize =>
      columnWidth *
      switch (entry.sizeKey) {
        'xl' => 0.98,
        'lg' => 0.86,
        'md' => 0.74,
        _ => 0.64,
      };

  /// Deterministic vertical offset that creates the staggered rhythm.
  double get _stagger => (index % 3) * 14 + (entry.id.hashCode % 18);

  @override
  Widget build(BuildContext context) {
    final bubble = switch (entry) {
      _PersonEntry(:final person) => PersonBubble(
          person: person,
          size: _bubbleSize,
          onTap: () => onOpenPerson(person),
        ),
      _CircleEntry(:final circle) => CircleBubble(
          circle: circle,
          members: membersOf(circle),
          size: _bubbleSize,
          onTap: () => onOpenCircle(circle),
        ),
    };

    return Padding(
      padding: EdgeInsets.only(top: _stagger),
      child: AnimatedBuilder(
        animation: drift,
        builder: (context, child) {
          final phase = index * 0.9;
          final t = drift.value * 2 * pi;
          return Transform.translate(
            offset: Offset(sin(t + phase) * 2.2, cos(t + phase * 1.3) * 3),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.lastActivity.compactAgo,
                style: AppTypography.mono(
                    context.muted.withValues(alpha: 0.8), 9)),
            const SizedBox(height: 6),
            bubble,
            if (entry case _CircleEntry(:final circle))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${circle.memberIds.length} together'.toUpperCase(),
                    style: AppTypography.mono(context.muted, 8)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A person or a circle, unified for the grid.
sealed class _ClusterEntry {
  const _ClusterEntry();

  factory _ClusterEntry.person(Person person) = _PersonEntry;
  factory _ClusterEntry.circle(CircleSpace circle) = _CircleEntry;

  String get id;
  String get sizeKey;
  DateTime get lastActivity;
}

class _PersonEntry extends _ClusterEntry {
  const _PersonEntry(this.person);
  final Person person;

  @override
  String get id => person.id;
  @override
  String get sizeKey => person.sizeKey;
  @override
  DateTime get lastActivity => person.lastActivity;
}

class _CircleEntry extends _ClusterEntry {
  const _CircleEntry(this.circle);
  final CircleSpace circle;

  @override
  String get id => circle.id;
  @override
  String get sizeKey => circle.sizeKey;
  @override
  DateTime get lastActivity => circle.lastActivity;
}

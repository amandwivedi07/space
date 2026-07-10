import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/extensions/datetime_x.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_list_item.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';

/// Search panel that slides over the cluster.
class SearchOverlay extends StatelessWidget {
  const SearchOverlay({
    super.key,
    required this.people,
    required this.circles,
    required this.onQuery,
    required this.onClose,
    required this.onOpenPerson,
    required this.onOpenCircle,
  });

  final List<Person> people;
  final List<CircleSpace> circles;
  final ValueChanged<String> onQuery;
  final VoidCallback onClose;
  final ValueChanged<Person> onOpenPerson;
  final ValueChanged<CircleSpace> onOpenCircle;

  @override
  Widget build(BuildContext context) {
    final empty = people.isEmpty && circles.isEmpty;
    return Container(
      color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: AppSearchBar(
                hint: AppStrings.searchHint,
                autofocus: true,
                onChanged: onQuery,
                onClose: onClose,
              ),
            ),
            Expanded(
              child: empty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: AppStrings.noOneByThatName)
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      children: [
                        for (final person in people)
                          AppListItem(
                            leading: AppAvatar(
                              name: person.name,
                              palette: SpacePalette.byId(person.paletteId),
                              size: 42,
                            ),
                            title: person.name,
                            subtitle: person.presence.label,
                            trailing: Text(
                                person.lastActivity.agoLabel,
                                style: context.text.bodySmall),
                            onTap: () => onOpenPerson(person),
                          ),
                        for (final circle in circles)
                          AppListItem(
                            leading: AppAvatar(
                              name: circle.name,
                              palette: SpacePalette.iris,
                              size: 42,
                            ),
                            title: circle.name,
                            subtitle:
                                '${circle.memberIds.length} people · quiet circle',
                            onTap: () => onOpenCircle(circle),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

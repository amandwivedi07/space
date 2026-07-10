import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/person.dart';

/// 4-column grid of selectable people for circle creation.
class MemberPickerGrid extends StatelessWidget {
  const MemberPickerGrid({
    super.key,
    required this.people,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<Person> people;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          final selected = selectedIds.contains(person.id);
          return GestureDetector(
            onTap: () => onToggle(person.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppAvatar(
                      name: person.name,
                      palette: SpacePalette.byId(person.paletteId),
                      size: 50,
                      ringColor: selected ? context.ink : null,
                    ),
                    if (selected)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: context.colors.surface, width: 1.5),
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 10,
                              color: context.theme.scaffoldBackgroundColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(person.name,
                    style: context.text.bodySmall?.copyWith(
                        color: context.ink, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}

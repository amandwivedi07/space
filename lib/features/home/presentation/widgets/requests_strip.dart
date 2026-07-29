import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/person.dart';

/// Invitations waiting on an answer, shown above the cluster. Incoming ones
/// can be answered here; outgoing ones just say they are still waiting.
class RequestsStrip extends StatelessWidget {
  const RequestsStrip({
    super.key,
    required this.people,
    required this.onAccept,
    required this.onDecline,
  });

  final List<Person> people;
  final void Function(Person) onAccept;
  final void Function(Person) onDecline;

  @override
  Widget build(BuildContext context) {
    final incoming =
        people.where((p) => p.request == SpaceRequest.incoming).toList();
    final outgoing =
        people.where((p) => p.request == SpaceRequest.outgoing).toList();
    if (incoming.isEmpty && outgoing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (incoming.isNotEmpty) ...[
            Text(
              incoming.length == 1
                  ? 'SOMEONE IS ASKING'
                  : '${incoming.length} PEOPLE ARE ASKING',
              style: AppTypography.mono(context.muted, 9),
            ),
            const SizedBox(height: 8),
            for (final person in incoming)
              _IncomingRow(
                person: person,
                onAccept: () => onAccept(person),
                onDecline: () => onDecline(person),
              ),
          ],
          if (outgoing.isNotEmpty) ...[
            if (incoming.isNotEmpty) const SizedBox(height: 10),
            Text('WAITING ON THEM',
                style: AppTypography.mono(context.muted, 9)),
            const SizedBox(height: 6),
            Text(
              outgoing.map((p) => p.name).join(', '),
              style: context.text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _IncomingRow extends StatelessWidget {
  const _IncomingRow({
    required this.person,
    required this.onAccept,
    required this.onDecline,
  });

  final Person person;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AppAvatar(
            name: person.name,
            palette: SpacePalette.byId(person.paletteId),
            avatarUrl: person.avatarUrl,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(person.name,
                    style: context.text.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                if (person.handle.isNotEmpty)
                  Text('@${person.handle}', style: context.text.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onDecline, child: const Text('Not now')),
          const SizedBox(width: 4),
          FilledButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/data/models/person.dart';

/// Replaces the composer while a direct space is still an invitation. The
/// server refuses cards in this state too — this only explains why.
class PendingNotice extends StatelessWidget {
  const PendingNotice({super.key, required this.request, required this.name});

  final SpaceRequest request;
  final String name;

  @override
  Widget build(BuildContext context) {
    final incoming = request == SpaceRequest.incoming;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.muted.withValues(alpha: 0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incoming ? 'THEY ASKED FIRST' : 'WAITING ON THEM',
            style: AppTypography.mono(context.muted, 9),
          ),
          const SizedBox(height: 8),
          Text(
            incoming
                ? 'Accept $name’s request from home and this room opens up.'
                : '$name has to accept before either of you can say anything.',
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

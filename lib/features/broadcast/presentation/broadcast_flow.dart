import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/fade_options.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../space_ai/presentation/screens/space_ai_screen.dart';
import '../data/repositories/broadcast_repository.dart';
import 'screens/broadcast_room_screen.dart';

/// Broadcasting starts where every other hard-to-say thing starts: with
/// SpaceAI. The same screen drafts it, and picking a phrasing sends it — with
/// one confirmation, because this is the only send in the app that reaches
/// everybody at once.
Future<void> startBroadcast(BuildContext context, WidgetRef ref) async {
  final outcome = await SpaceAiScreen.open(context, forBroadcast: true);
  if (outcome is! AiDraftChosen || !context.mounted) return;

  final audience = await ref.read(broadcastRepositoryProvider).audience();
  if (!context.mounted) return;
  final count = audience.when(success: (n) => n, failure: (_) => 0);
  if (count == 0) {
    AppDialog.alert(context,
        title: 'Nobody yet',
        body: 'Open a space with someone first — a broadcast goes to the '
            'people you already share one with.');
    return;
  }

  final sure = await AppDialog.confirm(
    context,
    title: 'Send to $count ${count == 1 ? "person" : "people"}?',
    body: 'Each of them sees it as an ordinary message from you. '
        'Nobody is told it went to anyone else.',
    confirmLabel: 'Send',
  );
  if (!sure || !context.mounted) return;

  final result = await ref.read(broadcastRepositoryProvider).send(
        body: outcome.text,
        fade: FadeOption.m60,
        aiGenerated: true,
      );
  if (!context.mounted) return;
  result.when(
    success: (sent) {
      AppToast.show(
        context,
        'Sent to ${sent.recipientCount} '
        '${sent.recipientCount == 1 ? "person" : "people"}',
        icon: Icons.campaign_rounded,
      );
      // Land in the everyone room so the thing just sent is visible, the way
      // sending into a space leaves you looking at it.
      BroadcastRoomScreen.open(context);
    },
    failure: (message) =>
        AppDialog.alert(context, title: "Couldn't send", body: message),
  );
}

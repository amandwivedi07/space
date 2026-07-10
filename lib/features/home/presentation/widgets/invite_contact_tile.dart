import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/services/share_launcher_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_list_item.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/contact.dart';

/// A not-yet-here contact with WhatsApp / SMS invite actions.
class InviteContactTile extends ConsumerWidget {
  const InviteContactTile({super.key, required this.contact});

  final Contact contact;

  static const _inviteMessage =
      "I saved you a spot on Space — a quiet place where conversations are temporary. Come find me.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(shareLauncherProvider);
    return AppListItem(
      leading: AppAvatar(name: contact.name, palette: SpacePalette.sand, size: 42),
      title: contact.name,
      subtitle: '${contact.phone} · ${AppStrings.notYetHere}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Invite ${contact.name} on WhatsApp',
            icon: Icon(Icons.chat_rounded, size: 19, color: context.muted),
            onPressed: () async {
              final ok = await launcher.whatsApp(
                  phone: contact.phone, message: _inviteMessage);
              if (!ok && context.mounted) {
                AppToast.show(context, "Couldn't open WhatsApp");
              }
            },
          ),
          IconButton(
            tooltip: 'Invite ${contact.name} by SMS',
            icon: Icon(Icons.sms_outlined, size: 19, color: context.muted),
            onPressed: () async {
              final ok = await launcher.sms(
                  phone: contact.phone, message: _inviteMessage);
              if (!ok && context.mounted) {
                AppToast.show(context, "Couldn't open Messages");
              }
            },
          ),
        ],
      ),
    );
  }
}

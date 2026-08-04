/// One exchange in the SpaceAI conversation. The sheet used to throw the
/// previous answer away on every attempt; a thread lets someone push back —
/// "shorter", "warmer" — and see what changed.
sealed class AiTurn {
  const AiTurn();
}

/// What you asked, shown as your own bubble.
class AiAsk extends AiTurn {
  const AiAsk(this.text);
  final String text;
}

/// Phrasings to choose from, under the line SpaceAI says about its angle.
/// [note] is decoration: it is often empty and the drafts stand alone.
class AiDrafts extends AiTurn {
  const AiDrafts({required this.drafts, this.note = ''});
  final List<String> drafts;
  final String note;
}

/// A generated picture, already stored server-side and ready to send on.
class AiPicture extends AiTurn {
  const AiPicture({required this.url, required this.prompt});
  final String url;
  final String prompt;
}

/// SpaceAI is working. Replaced in place by whatever comes back.
class AiThinking extends AiTurn {
  const AiThinking(this.stage);
  final String stage;
}

/// It could not answer. Kept in the thread rather than thrown as a dialog, so
/// the conversation above it survives.
class AiTrouble extends AiTurn {
  const AiTrouble(this.message);
  final String message;
}

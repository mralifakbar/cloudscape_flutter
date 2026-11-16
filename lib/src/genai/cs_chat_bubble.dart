import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_loading_bar.dart';

/// Chat bubble types (Cloudscape `ChatBubbleProps.Type`).
enum CsChatBubbleType {
  /// A message from the other party (the AI assistant or another person):
  /// filled with `color-background-chat-bubble-incoming`.
  incoming,

  /// A message the current user sent: no fill.
  outgoing,
}

/// Which side the bubble and its avatar sit on (Cloudscape
/// `ChatBubbleProps.Align`).
enum CsChatBubbleAlign {
  /// Avatar first, at the inline start.
  start,

  /// Bubble first, then the avatar, at the inline end.
  end,
}

/// Cloudscape's `ChatBubble`: one message in a conversation, paired with an
/// avatar.
///
/// [child] is the message content; [actions] is a footer for message
/// actions such as copy or feedback buttons. [showLoadingBar] adds the
/// gen-AI loading bar along the bottom edge while a response streams (set
/// the avatar's `loading` too).
///
/// ```dart
/// CsChatBubble(
///   type: CsChatBubbleType.incoming,
///   ariaLabel: 'Generative AI assistant at 3:42pm',
///   avatar: const CsAvatar(
///     color: CsAvatarColor.genAi,
///     icon: CsIcons.genAi,
///     ariaLabel: 'Generative AI assistant',
///   ),
///   child: const Text('The bucket example-bucket has versioning enabled.'),
/// )
/// ```
class CsChatBubble extends StatelessWidget {
  const CsChatBubble({
    super.key,
    required this.type,
    required this.ariaLabel,
    required this.child,
    this.avatar,
    this.actions,
    this.showLoadingBar = false,
    this.hideAvatar = false,
    this.stretch = false,
    this.align = CsChatBubbleAlign.start,
  });

  final CsChatBubbleType type;

  /// Accessible name of the message group, unique per bubble, such as
  /// "Sample user at 3:42pm".
  final String ariaLabel;

  /// The message content.
  final Widget child;

  /// Avatar paired with the message. Use `CsAvatar`.
  final Widget? avatar;

  /// Footer actions, such as a row of icon buttons.
  final Widget? actions;

  /// Shows the masked gen-AI loading bar along the bottom of the bubble.
  final bool showLoadingBar;

  /// Hides the avatar but keeps its space, for consecutive messages from
  /// the same author. The hidden avatar is also removed from focus and the
  /// semantics tree (Cloudscape sets `inert`).
  final bool hideAvatar;

  /// Fill the available width instead of fitting the content, so footers
  /// line up across messages.
  final bool stretch;
  final CsChatBubbleAlign align;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final incoming = type == CsChatBubbleType.incoming;
    final foreground = incoming ? c.textChatBubbleIncoming : c.textChatBubbleOutgoing;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.chatBubble));
    // Root text: body-m on the heading-m line height (22px).
    final style = cs.body.copyWith(
      color: foreground,
      height: CsFontTokens.lineHeightHeadingM / CsFontTokens.fontSizeBodyM,
    );

    Widget message = Padding(
      padding: EdgeInsets.all(cs.space.scaledS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: cs.space.scaledS,
        children: [child, ?actions],
      ),
    );
    message = DecoratedBox(
      decoration: BoxDecoration(
        color: incoming ? c.backgroundChatBubbleIncoming : c.backgroundChatBubbleOutgoing,
        borderRadius: radius,
      ),
      child: DefaultTextStyle.merge(
        style: style,
        child: IconTheme.merge(
          data: IconThemeData(color: foreground),
          child: message,
        ),
      ),
    );
    if (showLoadingBar) {
      message = ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            message,
            const PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: CsLoadingBar(variant: CsLoadingBarVariant.genAiMasked),
            ),
          ],
        ),
      );
    }
    final messageArea = Flexible(fit: stretch ? FlexFit.tight : FlexFit.loose, child: message);

    Widget? avatarSlot;
    if (avatar != null) {
      avatarSlot = Padding(
        padding: EdgeInsets.symmetric(vertical: cs.space.scaledXs),
        child: hideAvatar
            ? ExcludeSemantics(
                child: ExcludeFocus(
                  child: IgnorePointer(child: Opacity(opacity: 0, child: avatar)),
                ),
              )
            : avatar,
      );
    }

    final end = align == CsChatBubbleAlign.end;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: ariaLabel,
      child: Row(
        mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: cs.space.scaledXs,
        children: end ? [messageArea, ?avatarSlot] : [?avatarSlot, messageArea],
      ),
    );
  }
}

import 'package:equatable/equatable.dart';

/// Author of a chat message in the Career Coach UI.
enum ChatRole { user, assistant }

/// Lifecycle of an assistant message while/after it is generated.
enum ChatMessageStatus {
  /// Fully received (the default for user messages and finished replies).
  complete,

  /// Tokens are still streaming into this message.
  streaming,

  /// Generation failed before completing.
  failed,
}

/// A single message in a Career Coach conversation.
///
/// Immutable; the controller replaces messages via [copyWith] as tokens stream
/// in. [id] is a stable per-message key for the list.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.status = ChatMessageStatus.complete,
  });

  final String id;
  final ChatRole role;
  final String text;
  final ChatMessageStatus status;

  bool get isUser => role == ChatRole.user;
  bool get isStreaming => status == ChatMessageStatus.streaming;
  bool get isFailed => status == ChatMessageStatus.failed;

  ChatMessage copyWith({String? text, ChatMessageStatus? status}) => ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, role, text, status];
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/career_coach/domain/chat_message.dart';

/// Persistence seam for the Career Coach conversation history.
///
/// Today the only implementation is [InMemoryChatHistoryStore] (session
/// scoped). Adding durable persistence later — a `SharedPreferences` cache or a
/// Firestore-backed `users/{uid}/coachChats` collection — means writing a new
/// [ChatHistoryStore] and rebinding [chatHistoryStoreProvider]. **No feature
/// code changes**, because the controller depends only on this interface.
///
/// Mirrors the resume analysis store (`resume_analysis_store.dart`).
abstract interface class ChatHistoryStore {
  /// Returns the stored conversation (empty if none yet).
  List<ChatMessage> read();

  /// Persists the full [messages] list as the current conversation.
  Future<void> write(List<ChatMessage> messages);

  /// Clears the stored conversation.
  Future<void> clear();
}

/// Default store: keeps the conversation in memory for the app session only.
class InMemoryChatHistoryStore implements ChatHistoryStore {
  List<ChatMessage> _messages = const [];

  @override
  List<ChatMessage> read() => _messages;

  @override
  Future<void> write(List<ChatMessage> messages) async =>
      _messages = List.unmodifiable(messages);

  @override
  Future<void> clear() async => _messages = const [];
}

/// The app-wide [ChatHistoryStore]. Swap persistence strategies by changing only
/// this binding (overridden with a fake/seed in tests).
final chatHistoryStoreProvider =
    Provider<ChatHistoryStore>((ref) => InMemoryChatHistoryStore());

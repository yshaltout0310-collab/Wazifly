import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service.dart';
import 'firebase_ai_service.dart';

/// The app-wide [AiService]. Swap providers by changing only this binding
/// (overridden with a fake in tests).
final aiServiceProvider = Provider<AiService>((ref) => FirebaseAiService());

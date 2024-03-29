import '../../models/typing_event.dart';
import '../../models/user.dart';

abstract class ITypingNotification {
  Future<bool> send({required TypingEvent event, required User to});
  Stream<TypingEvent> subscribe(User user, List<String> userIds);
  Future<void> dispose();
}

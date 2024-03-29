import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late TypingNotification sut;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = TypingNotification(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user1 = User.fromJson({
    'id': '1234',
    'active': true,
    'last_sean': DateTime.now(),
  });
  final user2 = User.fromJson({
    'id': '1111',
    'active': true,
    'last_sean': DateTime.now(),
  });

  test('sent typing notification successfully', () async {
    TypingEvent typingEvent = TypingEvent(
      from: user2.id!,
      to: user1.id!,
      event: Typing.start,
    );

    final res = await sut.send(event: typingEvent, to: user1);

    expect(res, true);
  });

  test('successfully subscribe and receive typing events', () async {
    sut.subscribe(user2, [user1.id!]).listen(expectAsync1(
      (event) {
        expect(event.from, user1.id);
      },
      count: 2,
    ));

    TypingEvent typing = TypingEvent(
      from: user1.id!,
      to: user2.id!,
      event: Typing.start,
    );
    TypingEvent stopTyping = TypingEvent(
      from: user1.id!,
      to: user2.id!,
      event: Typing.stop,
    );

    await sut.send(event: typing, to: user2);
    await sut.send(event: stopTyping, to: user2);
  });
}

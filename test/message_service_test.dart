import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_service_impl.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late MessageService sut;

  setUp(() async {
    connection = await r.connect();
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDb(r, connection);
    sut = MessageService(r, connection, encryption);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user1 = User.fromJson({
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now(),
  });
  final user2 = User.fromJson({
    'id': '1111',
    'active': true,
    'last_seen': DateTime.now(),
  });

  test('sent message successfully', () async {
    Message message = Message(
      from: user1.id!,
      to: '3456',
      timestamp: DateTime.now(),
      contents: 'this is a message',
    );

    final bool res = await sut.send(message);

    expect(res, true);
  });

  test('successfully subscribe and receive messages', () async {
    const contents = 'this is a message';
    // const user2Contents = 'this is another message';
    sut.messages(activeUser: user2).listen(expectAsync1((message) {
          expect(message.to, user2.id);
          expect(message.id, isNotEmpty);
          expect(message.contents, contents);
        }, count: 2));

    Message firstMessage = Message(
      from: user1.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: contents,
    );
    Message secondMessage = Message(
      from: user1.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: contents,
    );

    await sut.send(firstMessage);
    await sut.send(secondMessage);
  });

  test('successfully subscribe and receive new messages', () async {
    Message firstMessage = Message(
      from: user1.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: 'this is a message',
    );
    Message secondMessage = Message(
      from: user1.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: 'this is another message',
    );

    await sut.send(firstMessage);
    await sut
        .send(secondMessage)
        .whenComplete(() => sut.messages(activeUser: user2).listen(expectAsync1(
              (event) {
                expect(firstMessage.to, user2.id);
              },
              count: 2,
            )));
  });
}

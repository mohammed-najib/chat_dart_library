import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user/user_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late UserService sut;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = UserService(r, connection);
  });

  tearDown(() async {
    await cleanDb(r, connection);
  });

  test('create a new user document in database', () async {
    final user = User(
      userName: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: DateTime.now(),
    );

    final userWithId = await sut.connect(user);
    expect(userWithId.id, isNotEmpty);
  });

  test('get online users', () async {
    final user = User(
      userName: 'test',
      photoUrl: 'url',
      active: true,
      lastSeen: DateTime.now(),
    );
    // arrange
    await sut.connect(user);
    // act
    final users = await sut.onLine();
    // assert
    expect(users.length, 1);
  });
}

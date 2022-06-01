import 'dart:async';

import 'package:chat/src/models/user.dart';

import 'package:chat/src/models/message.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import '../encryption/encryption_service_contract.dart';
import 'message_service_contract.dart';

class MessageService implements IMessageService {
  final Connection _connection;
  final RethinkDb r;
  final IEncryptionService _encryptionService;

  MessageService(this.r, this._connection, this._encryptionService);

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription? _changeFeed;

  @override
  dispose() async {
    await _controller.close();
    await _changeFeed?.cancel();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessages(activeUser);

    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    final data = message.toJson();
    data['contents'] = _encryptionService.encrypt(message.contents);
    final Map record = await r.table('messages').insert(data).run(_connection);

    return record['inserted'] == 1;
  }

  _startReceivingMessages(User activeUser) {
    _changeFeed = r
        .table('messages')
        .filter({'to': activeUser.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final Message message = _messageFromFeed(feedData);
                _controller.sink.add(message);
                _removeDeliverredMessage(message);
              })
              .catchError((err) => print(err.toString()))
              .onError((error, stackTrace) => print(error));
        });
  }

  Message _messageFromFeed(Map<String, dynamic> feedData) {
    final data = feedData['new_val'];
    data['contents'] = _encryptionService.decrypt(data['contents']);

    return Message.fromJson(data);
  }

  _removeDeliverredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}

import 'dart:async';

import 'package:rethink_db_ns/rethink_db_ns.dart';

import '../../models/typing_event.dart';
import '../../models/user.dart';
import 'typing_notification_service_contract.dart';

class TypingNotification extends ITypingNotification {
  final Connection _connection;
  final RethinkDb _r;

  TypingNotification(this._r, this._connection);

  final _controller = StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changeFeed;

  @override
  dispose() async {
    await _controller.close();
    await _changeFeed?.cancel();
  }

  @override
  Future<bool> send({required TypingEvent event, required User to}) async {
    if (!to.active!) return false;
    final Map record = await _r
        .table('typing_events')
        .insert(event.toJson(), {'conflict': 'update'}).run(_connection);

    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);

    return _controller.stream;
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changeFeed = _r
        .table('typing_events')
        .filter((event) => event('to')
            .eq(user.id)
            .and(_r.expr(userIds).contains(event('from'))))
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final TypingEvent typing = _eventFromFeed(feedData);
                _controller.sink.add(typing);
                _removeEvent(typing);
              })
              .catchError((err) => print(err.toString()))
              .onError((error, stackTrace) => print(error));
        });
  }

  TypingEvent _eventFromFeed(Map<String, dynamic> feedData) {
    final data = feedData['new_val'];

    return TypingEvent.fromJson(data);
  }

  _removeEvent(TypingEvent event) {
    _r
        .table('typing_events')
        .get(event.id)
        .delete({'return_changes': false}).run(_connection);
  }
}

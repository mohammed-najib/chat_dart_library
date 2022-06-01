import 'dart:async';

import 'package:chat/src/models/user.dart';

import 'package:chat/src/models/receipt.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'receipt_service_contract.dart';

class ReceiptService extends IReceiptService {
  final Connection _connection;
  final RethinkDb r;

  ReceiptService(this.r, this._connection);

  final _controller = StreamController<Receipt>.broadcast();
  StreamSubscription? _changeFeed;

  @override
  dispose() async {
    await _controller.close();
    await _changeFeed?.cancel();
  }

  @override
  Stream<Receipt> receipts(User user) {
    _startReceivingReceipts(user);

    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    final data = receipt.toJson();
    final Map record = await r.table('receipts').insert(data).run(_connection);

    return record['inserted'] == 1;
  }

  _startReceivingReceipts(User user) {
    _changeFeed = r
        .table('receipts')
        .filter({'recipient': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final Receipt receipt = _receiptFromFeed(feedData);
                _controller.sink.add(receipt);
              })
              .catchError((err) => print(err.toString()))
              .onError((error, stackTrace) => print(error));
        });
  }

  Receipt _receiptFromFeed(Map<String, dynamic> feedData) {
    final data = feedData['new_val'];

    return Receipt.fromJson(data);
  }
}

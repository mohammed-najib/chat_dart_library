enum ReceiptStatus {
  sent,
  deliverred,
  read,
}

extension EnumParsing on ReceiptStatus {
  String value() => toString().split('.').last;

  static ReceiptStatus fromString(String status) =>
      ReceiptStatus.values.firstWhere((element) => element.value() == status);
}

class Receipt {
  final String recipient;
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;
  String? _id;

  String? get id => _id;

  Receipt({
    required this.recipient,
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  toJson() => {
        'recipient': recipient,
        'message_id': messageId,
        'status': status.value(),
        'timestamp': timestamp,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final receipt = Receipt(
      recipient: json['recipient'],
      messageId: json['message_id'],
      status: EnumParsing.fromString(json['status']),
      timestamp: json['timestamp'],
    );
    receipt._id = json['id'];

    return receipt;
  }
}

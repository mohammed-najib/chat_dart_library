enum Typing {
  start,
  stop,
}

extension TypingParsing on Typing {
  String value() => toString().split('.').last;

  static Typing fromString(String status) =>
      Typing.values.firstWhere((element) => element.value() == status);
}

class TypingEvent {
  final String from;
  final String to;
  final Typing event;
  String? _id;
  String? get id => _id;

  TypingEvent({
    required this.from,
    required this.to,
    required this.event,
  });

  toJson() => {
        'from': from,
        'to': to,
        'event': event.value(),
      };

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    final receipt = TypingEvent(
      from: json['from'],
      to: json['to'],
      event: TypingParsing.fromString(json['event']),
    );
    receipt._id = json['id'];

    return receipt;
  }
}

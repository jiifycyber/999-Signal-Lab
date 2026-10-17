import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  const url = 'wss://bridge.sciool.net/ws/po';
  const target = 'AUDCHF_OTC';

  print('CONNECTING: $url');
  print('TARGET: $target');
  print('');

  final channel = WebSocketChannel.connect(Uri.parse(url));

  await channel.ready;

  var seen = 0;

  await for (final message in channel.stream) {
    dynamic data;

    try {
      data = jsonDecode(message as String);
    } catch (_) {
      continue;
    }

    if (data is! Map<String, dynamic>) continue;
    if (data['event'] != 'price') continue;

    final symbol = '${data['symbol']}';

    if (symbol != target) continue;

    final price = data['price'];
    final timestamp = data['timestamp'];

    DateTime? sourceTime;

    if (timestamp is num) {
      sourceTime = DateTime.fromMillisecondsSinceEpoch(
        (timestamp.toDouble() * 1000).round(),
        isUtc: true,
      );
    }

    seen++;

    print(
      '${seen.toString().padLeft(2, '0')}  '
      '$symbol  '
      'price=$price  '
      'source=${sourceTime?.toIso8601String() ?? timestamp}  '
      'received=${DateTime.now().toUtc().toIso8601String()}',
    );

    if (seen >= 20) {
      break;
    }
  }

  await channel.sink.close();
}

import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
final url = Uri.parse('wss://bridge.sciool.net/ws/po');
print('CONNECTING: $url');

final ws = WebSocketChannel.connect(url);

try {
await ws.ready.timeout(const Duration(seconds: 10));
print('CONNECTED');

await ws.stream
    .timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) {
        print('NO LIVE MESSAGE FOR 10 SECONDS');
        sink.close();
      },
    )
    .take(20)
    .forEach((message) {
      print('MESSAGE: $message');
    });
} catch (e) {
print('ERROR: $e');
} finally {
await ws.sink.close();
}
}

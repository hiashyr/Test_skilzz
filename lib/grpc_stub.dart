// Minimal stub for web builds where package:grpc is unavailable.

class ClientChannel {
  ClientChannel(String host, {int? port, ChannelOptions? options});
  Future<void> shutdown() async {}
}

class ChannelOptions {
  final Object? credentials;
  const ChannelOptions({this.credentials});
}

class ChannelCredentials {
  static const insecure = null;
}

enum AppLocalWebServer {
  reader(8080);

  const AppLocalWebServer(this.port);

  static const String localhost = 'localhost';

  final int port;

  String get host => localhost;

  Uri get uri => Uri.http('$localhost:$port');
}

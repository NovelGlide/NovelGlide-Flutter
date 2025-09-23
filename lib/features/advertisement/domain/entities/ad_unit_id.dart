import 'dart:io';

enum AdUnitId {
  homepageCompact(
    android: 'ca-app-pub-1579558558142906/6034508731',
    ios: 'ca-app-pub-1579558558142906/3980025184',
  ),
  homepageMedium(
    android: 'ca-app-pub-1579558558142906/2816467381',
    ios: 'ca-app-pub-1579558558142906/3937977361',
  ),
  tableOfContents(
    android: 'ca-app-pub-1579558558142906/1014366989',
    ios: 'ca-app-pub-1579558558142906/4345955953',
  ),
  reader(
    android: 'ca-app-pub-1579558558142906/5399183177',
    ios: 'ca-app-pub-1579558558142906/7476667706',
  );

  const AdUnitId({this.android, this.ios});

  final String? android;
  final String? ios;

  String? get id => Platform.isAndroid
      ? android
      : Platform.isIOS
          ? ios
          : null;
}

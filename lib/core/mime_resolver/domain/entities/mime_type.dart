enum MimeType {
  // Archives
  epub(
    <String>['application/epub+zip'],
    <String>['epub'],
  ),
  zip(
    <String>['application/zip'],
    <String>['zip'],
  ),

  // XML
  atomFeed(
    <String>['application/atom+xml'],
    <String>[],
  ),
  xhtml(
    <String>['application/xhtml+xml'],
    <String>['xhtml'],
  ),

  // Images
  pdf(
    <String>['application/pdf'],
    <String>['pdf'],
  ),
  jpg(
    <String>['image/jpeg'],
    <String>['jpg'],
  ),
  png(
    <String>['image/png'],
    <String>['png'],
  ),
  gif(
    <String>['image/gif'],
    <String>['gif'],
  ),
  bmp(
    <String>['image/bmp'],
    <String>['bmp'],
  );

  const MimeType(this.tagList, this.extensionList);

  static MimeType? tryParse(String? typeString) {
    if (typeString?.isNotEmpty == true) {
      for (MimeType type in values) {
        if (type.tagList.any((String tag) => tag == typeString)) {
          return type;
        }
      }
    }

    return null;
  }

  final List<String> tagList;
  final List<String> extensionList;

  bool get isImage =>
      this == MimeType.png ||
      this == MimeType.jpg ||
      this == MimeType.gif ||
      this == MimeType.bmp;
}

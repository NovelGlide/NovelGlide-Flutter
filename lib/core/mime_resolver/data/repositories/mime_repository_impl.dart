import '../../domain/entities/mime_type.dart';
import '../../domain/repositories/mime_repository.dart';
import '../data_sources/mime_local_source.dart';

class MimeRepositoryImpl implements MimeRepository {
  MimeRepositoryImpl(this._localSource);

  final MimeLocalSource _localSource;

  @override
  Future<MimeType?> lookupAll(String path) async {
    final String? tag = await _localSource.lookupAll(path);
    return MimeType.tryParse(tag);
  }
}

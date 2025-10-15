import '../../main.dart';
import 'image_processor.dart';

void setupImageProcessorDependencies() {
  sl.registerLazySingleton<ImageProcessor>(
    () => ImageProcessor(),
  );
}

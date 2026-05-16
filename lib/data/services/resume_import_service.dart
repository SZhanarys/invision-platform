import 'resume_import_service_stub.dart'
    if (dart.library.html) 'resume_import_service_web.dart';

abstract class ResumeImportService {
  bool get supportsFilePicker;

  Future<ImportedResumeFile?> pickResumeFile();
}

class ImportedResumeFile {
  const ImportedResumeFile({required this.fileName, required this.content});

  final String fileName;
  final String content;
}

ResumeImportService createResumeImportService() =>
    createResumeImportServiceImpl();

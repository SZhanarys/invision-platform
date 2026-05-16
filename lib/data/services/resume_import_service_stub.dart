import 'resume_import_service.dart';

class UnsupportedResumeImportService implements ResumeImportService {
  @override
  bool get supportsFilePicker => false;

  @override
  Future<ImportedResumeFile?> pickResumeFile() async => null;
}

ResumeImportService createResumeImportServiceImpl() =>
    UnsupportedResumeImportService();

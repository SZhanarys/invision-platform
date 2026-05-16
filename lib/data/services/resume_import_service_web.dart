// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'resume_import_service.dart';

class WebResumeImportService implements ResumeImportService {
  @override
  bool get supportsFilePicker => true;

  @override
  Future<ImportedResumeFile?> pickResumeFile() {
    final completer = Completer<ImportedResumeFile?>();
    final input = html.FileUploadInputElement()
      ..accept = '.txt,.md,.json,text/plain'
      ..multiple = false;

    input.onChange.first.then((_) {
      final file = input.files?.isNotEmpty == true ? input.files!.first : null;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoad.first.then((_) {
        completer.complete(
          ImportedResumeFile(
            fileName: file.name,
            content: (reader.result ?? '').toString(),
          ),
        );
      });
      reader.onError.first.then((_) {
        completer.complete(null);
      });
    });

    input.click();
    return completer.future;
  }
}

ResumeImportService createResumeImportServiceImpl() => WebResumeImportService();

class ResumeImportData {
  const ResumeImportData({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.skills,
    required this.valueStatement,
    required this.experienceSummary,
    required this.projects,
    required this.email,
    required this.sourceLabel,
    required this.confidenceNotes,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String skills;
  final String valueStatement;
  final String experienceSummary;
  final String projects;
  final String email;
  final String sourceLabel;
  final List<String> confidenceNotes;

  bool get hasUsefulData =>
      firstName.isNotEmpty ||
      lastName.isNotEmpty ||
      phoneNumber.isNotEmpty ||
      skills.isNotEmpty ||
      valueStatement.isNotEmpty ||
      experienceSummary.isNotEmpty ||
      projects.isNotEmpty ||
      email.isNotEmpty;
}

final class ResumeParser {
  const ResumeParser._();

  static ResumeImportData parse({
    required String rawText,
    required String sourceLabel,
  }) {
    final normalized = rawText.replaceAll('\r', '');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final email = _extractEmail(normalized);
    final phone = _extractPhone(normalized);
    final name = _extractName(lines);
    final sections = _extractSections(lines);

    final skills = _mergeContent([
      sections['skills'],
      sections['stack'],
      _extractTaggedLine(lines, ['skills', 'stack', 'навыки', 'стек']),
    ]);
    final value = _mergeContent([
      sections['summary'],
      sections['about'],
      sections['value'],
      _extractTaggedLine(lines, ['about', 'summary', 'о себе', 'ценность']),
    ]);
    final experience = _mergeContent([
      sections['experience'],
      sections['work'],
      _extractTaggedLine(lines, ['experience', 'work', 'опыт', 'опыт работы']),
    ]);
    final projects = _mergeContent([
      sections['projects'],
      _extractTaggedLine(lines, ['projects', 'project', 'проекты', 'проект']),
    ]);

    final confidenceNotes = <String>[
      if (email.isNotEmpty) 'Email recognized',
      if (phone.isNotEmpty) 'Phone recognized',
      if (skills.isNotEmpty) 'Skills section recognized',
      if (experience.isNotEmpty) 'Experience section recognized',
      if (projects.isNotEmpty) 'Projects section recognized',
    ];

    return ResumeImportData(
      firstName: name.$1,
      lastName: name.$2,
      phoneNumber: phone,
      skills: skills,
      valueStatement: value.isNotEmpty
          ? value
          : _buildFallbackValue(experience, skills),
      experienceSummary: experience,
      projects: projects,
      email: email,
      sourceLabel: sourceLabel,
      confidenceNotes: confidenceNotes,
    );
  }

  static (String, String) _extractName(List<String> lines) {
    if (lines.isEmpty) {
      return ('', '');
    }

    for (final line in lines.take(3)) {
      if (line.contains('@') ||
          line.length > 80 ||
          RegExp(r'\d').hasMatch(line)) {
        continue;
      }

      final cleaned = line
          .replaceAll(RegExp(r'[^A-Za-zА-Яа-яЁё\s-]'), '')
          .trim();
      final parts = cleaned
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return (parts[1], parts[0]);
      }
    }

    return ('', '');
  }

  static String _extractEmail(String text) {
    final match = RegExp(r'[\w\.\-]+@[\w\.\-]+\.\w+').firstMatch(text);
    return match?.group(0)?.trim() ?? '';
  }

  static String _extractPhone(String text) {
    final match = RegExp(r'(\+?\d[\d\-\s\(\)]{8,}\d)').firstMatch(text);
    return match?.group(0)?.trim() ?? '';
  }

  static Map<String, String> _extractSections(List<String> lines) {
    final sections = <String, List<String>>{};
    String? currentKey;

    for (final line in lines) {
      final sectionKey = _sectionKey(line);
      if (sectionKey != null) {
        currentKey = sectionKey;
        final inlineValue = _extractAfterColon(line);
        if (inlineValue.isNotEmpty) {
          sections.putIfAbsent(currentKey, () => []).add(inlineValue);
        }
        continue;
      }

      if (currentKey != null) {
        sections.putIfAbsent(currentKey, () => []).add(line);
      }
    }

    return sections.map((key, value) => MapEntry(key, value.join('\n').trim()));
  }

  static String? _sectionKey(String line) {
    final lower = line.toLowerCase();
    if (_startsWithAny(lower, ['skills', 'навыки', 'stack', 'стек'])) {
      return 'skills';
    }
    if (_startsWithAny(lower, [
      'experience',
      'опыт работы',
      'опыт',
      'work experience',
    ])) {
      return 'experience';
    }
    if (_startsWithAny(lower, ['projects', 'project', 'проекты', 'проект'])) {
      return 'projects';
    }
    if (_startsWithAny(lower, ['summary', 'about', 'о себе'])) {
      return 'summary';
    }
    if (_startsWithAny(lower, ['value', 'ценность', 'why hire'])) {
      return 'value';
    }
    if (_startsWithAny(lower, ['work', 'employment'])) {
      return 'work';
    }
    return null;
  }

  static bool _startsWithAny(String value, List<String> options) {
    return options.any((option) => value.startsWith(option));
  }

  static String _extractTaggedLine(List<String> lines, List<String> tags) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (tags.any((tag) => lower.startsWith(tag))) {
        final value = _extractAfterColon(line);
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  static String _extractAfterColon(String line) {
    final index = line.indexOf(':');
    if (index == -1 || index == line.length - 1) {
      return '';
    }
    return line.substring(index + 1).trim();
  }

  static String _mergeContent(List<String?> values) {
    return values
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join('\n')
        .trim();
  }

  static String _buildFallbackValue(String experience, String skills) {
    if (experience.isEmpty && skills.isEmpty) {
      return '';
    }

    final parts = <String>[];
    if (skills.isNotEmpty) {
      parts.add('Strong stack signals: ${skills.split('\n').first}');
    }
    if (experience.isNotEmpty) {
      parts.add('Experience highlights: ${experience.split('\n').first}');
    }
    return parts.join('. ');
  }
}

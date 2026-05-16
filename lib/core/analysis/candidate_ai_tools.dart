class JobMatchResult {
  const JobMatchResult({
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
    required this.recommendation,
    required this.summary,
  });

  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String recommendation;
  final String summary;
}

final class CandidateAiTools {
  const CandidateAiTools._();

  static JobMatchResult buildJobMatch({
    required Map<String, dynamic> candidate,
    required String jobDescription,
  }) {
    final candidateSkills = extractSkills(candidate);
    final requiredSkills = _tokenize(
      jobDescription,
    ).where((token) => token.length >= 3).toSet().toList();
    final matched = requiredSkills
        .where(
          (skill) => candidateSkills.any(
            (candidateSkill) =>
                candidateSkill.contains(skill) ||
                skill.contains(candidateSkill),
          ),
        )
        .take(8)
        .toList();
    final missing = requiredSkills
        .where((skill) => !matched.contains(skill))
        .take(8)
        .toList();
    final baseScore = candidateScore(candidate);
    final matchRatio = requiredSkills.isEmpty
        ? 0.55
        : matched.length / requiredSkills.length;
    final score = (baseScore * 0.55 + matchRatio * 45).round().clamp(0, 100);

    return JobMatchResult(
      score: score,
      matchedSkills: matched,
      missingSkills: missing,
      recommendation: score >= 82
          ? 'Сильное совпадение. Есть смысл вести кандидата в следующий этап и проверять глубину на интервью.'
          : score >= 68
          ? 'Частичное совпадение. Стоит интервьюировать, но проверить пробелы и реальные кейсы.'
          : 'Совпадение слабое. Лучше уточнить стек вакансии или искать более близкий профиль.',
      summary: matched.isEmpty
          ? 'Прямых совпадений по вакансии пока мало.'
          : 'Основные совпадения: ${matched.take(4).join(', ')}.',
    );
  }

  static List<String> buildInterviewPack(Map<String, dynamic> candidate) {
    final skills = extractSkills(candidate);
    final questions = <String>[
      'Какой ваш самый сильный проект и за какой результат вы отвечали лично?',
      'Расскажите про сложную задачу, где пришлось разбираться с неопределенностью и принимать решение.',
      'Как вы проверяете качество своей работы до релиза?',
    ];

    if (skills.any(
      (skill) => skill.contains('java') || skill.contains('spring'),
    )) {
      questions.add(
        'Опишите backend trade-off в Java или Spring, который вы принимали на реальном проекте.',
      );
    }
    if (skills.any(
      (skill) => skill.contains('flutter') || skill.contains('dart'),
    )) {
      questions.add(
        'Как вы строили архитектуру Flutter-приложения и как решали вопросы производительности?',
      );
    }
    if (skills.any(
      (skill) =>
          skill.contains('react') ||
          skill.contains('javascript') ||
          skill.contains('typescript'),
    )) {
      questions.add(
        'Как вы держите frontend-код поддерживаемым, когда требования продукта часто меняются?',
      );
    }
    if (skills.any(
      (skill) =>
          skill.contains('docker') ||
          skill.contains('ci') ||
          skill.contains('cd'),
    )) {
      questions.add(
        'Как вы участвовали в delivery-процессе, CI/CD или инфраструктурных задачах?',
      );
    }

    return questions.take(6).toList();
  }

  static List<String> detectRedFlags(Map<String, dynamic> candidate) {
    final redFlags = <String>[];
    final score = candidateScore(candidate);
    final verdict = (candidate['aiVerdict'] ?? '').toString().trim();
    final value = (candidate['valueStatement'] ?? '').toString().trim();
    final experience = (candidate['experienceSummary'] ?? '').toString().trim();
    final skills = extractSkills(candidate);
    final projects = extractProjects(candidate);

    if (score < 70) {
      redFlags.add('Низкий AI score: профиль требует дополнительной проверки.');
    }
    if (skills.length < 3) {
      redFlags.add('Слишком мало явных навыков в анкете.');
    }
    if (projects.isEmpty) {
      redFlags.add('Нет описанных проектов, трудно оценить реальную практику.');
    }
    if (experience.length < 60) {
      redFlags.add(
        'Опыт описан слишком кратко, мало конкретики по роли и результатам.',
      );
    }
    if (value.length < 40) {
      redFlags.add('Слабая формулировка ценности кандидата.');
    }
    if (verdict.isEmpty) {
      redFlags.add('Нет AI verdict, профиль выглядит недообогащенным.');
    }

    return redFlags;
  }

  static String shortlistLabel(Map<String, dynamic> candidate) {
    final score = candidateScore(candidate);
    if (score >= 90) {
      return 'Сильный шорт-лист';
    }
    if (score >= 78) {
      return 'Звать на интервью';
    }
    if (score >= 65) {
      return 'Нужно больше фактов';
    }
    return 'Высокий риск';
  }

  static int candidateScore(Map<String, dynamic> candidate) {
    final value = candidate['aiScore'] ?? candidate['score'];
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> extractSkills(Map<String, dynamic> candidate) {
    final rawSkills =
        candidate['skills'] ?? candidate['skill'] ?? candidate['stack'];
    if (rawSkills is List) {
      return rawSkills
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (rawSkills == null) {
      return const [];
    }
    return rawSkills
        .toString()
        .split(RegExp(r'[,\n]'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<String> extractProjects(Map<String, dynamic> candidate) {
    final rawProjects = candidate['projects'];
    if (rawProjects is List) {
      return rawProjects
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (rawProjects == null) {
      return const [];
    }
    return rawProjects
        .toString()
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static Set<String> _tokenize(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Zа-яА-Я0-9\+\#]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}

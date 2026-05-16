import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resume/resume_parser.dart';
import '../../core/ui/theme_toggle_button.dart';
import '../../data/services/questionnaire_service.dart';
import '../../data/services/resume_import_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxNameLength = 120;
  static const int _maxPhoneLength = 32;
  static const int _maxSkillsLength = 4000;
  static const int _maxValueLength = 5000;
  static const int _maxExperienceLength = 8000;
  static const int _maxProjectsLength = 5000;
  static const List<String> _aiStatuses = [
    'Идет магия ИИ...',
    'Анализируем ваш опыт...',
    'Нормализуем навыки...',
    'Собираем отчет для рекрутера...',
  ];
  static const String _demoResume = '''
Sarsen Aruzhan
Phone: +7 777 123 45 67
Email: aruzhan.sarsen@gmail.com

Summary:
Backend engineer with strong Java and Spring Boot background. Built production APIs, worked with PostgreSQL, Docker and CI/CD, mentored juniors and improved release stability.

Skills:
Java, Spring Boot, REST API, PostgreSQL, Docker, Kafka, CI/CD, Testing

Experience:
Built and supported production backend services. Improved API performance, worked with product team, owned integrations and release quality.

Projects:
Banking API platform
Recruitment automation platform
Internal analytics dashboard
''';

  final _formKey = GlobalKey<FormState>();
  final _questionnaireService = QuestionnaireService();
  final _resumeImportService = createResumeImportService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();
  final _valueController = TextEditingController();
  final _experienceController = TextEditingController();
  final _projectsController = TextEditingController();

  bool _isCheckingStatus = true;
  bool _isSubmitting = false;
  bool _hasExistingSubmission = false;
  bool _isImportingResume = false;
  int _statusIndex = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    _valueController.dispose();
    _experienceController.dispose();
    _projectsController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final status = await _questionnaireService.fetchStatus(widget.userId);
    if (!mounted) {
      return;
    }

    setState(() {
      _hasExistingSubmission = status['submitted'] == true;
      _isCheckingStatus = false;
    });
  }

  void _startStatusRotation() {
    _statusTimer?.cancel();
    _statusIndex = 0;
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || !_isSubmitting) {
        return;
      }
      setState(() {
        _statusIndex = (_statusIndex + 1) % _aiStatuses.length;
      });
    });
  }

  void _stopStatusRotation() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusIndex = 0;
    });
    _startStatusRotation();

    final response = await _questionnaireService.submit(
      userId: widget.userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      skillsInput: _skillsController.text.trim(),
      valueStatement: _valueController.text.trim(),
      experienceSummary: _experienceController.text.trim(),
      projectsInput: _projectsController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    _stopStatusRotation();
    setState(() => _isSubmitting = false);

    final message = (response['message'] ?? 'Ошибка запроса').toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (response['ok'] == true) {
      setState(() => _hasExistingSubmission = true);
    }
  }

  Future<void> _importFromFile() async {
    if (_isImportingResume) {
      return;
    }

    setState(() => _isImportingResume = true);
    final imported = await _resumeImportService.pickResumeFile();
    if (!mounted) {
      return;
    }
    setState(() => _isImportingResume = false);

    if (imported == null || imported.content.trim().isEmpty) {
      return;
    }

    await _previewImportedResume(
      ResumeParser.parse(
        rawText: imported.content,
        sourceLabel: imported.fileName,
      ),
    );
  }

  Future<void> _importFromPaste() async {
    final controller = TextEditingController();
    final rawText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Вставить резюме'),
          content: SizedBox(
            width: 620,
            child: TextField(
              controller: controller,
              minLines: 12,
              maxLines: 18,
              decoration: const InputDecoration(
                hintText: 'Вставьте сюда текст резюме или анкеты кандидата...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Распознать'),
            ),
          ],
        );
      },
    );

    if (!mounted || rawText == null || rawText.trim().isEmpty) {
      return;
    }

    await _previewImportedResume(
      ResumeParser.parse(rawText: rawText, sourceLabel: 'Вставленный текст'),
    );
  }

  Future<void> _loadDemoResume() async {
    await _previewImportedResume(
      ResumeParser.parse(rawText: _demoResume, sourceLabel: 'Демо-резюме'),
    );
  }

  Future<void> _previewImportedResume(ResumeImportData data) async {
    if (!data.hasUsefulData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось распознать данные резюме. Попробуйте вставить более структурированный текст.',
          ),
        ),
      );
      return;
    }

    final shouldApply =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Умный импорт резюме'),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Источник: ${data.sourceLabel}'),
                    const SizedBox(height: 14),
                    _PreviewRow(
                      title: 'Имя',
                      value: '${data.lastName} ${data.firstName}'.trim(),
                    ),
                    _PreviewRow(title: 'Телефон', value: data.phoneNumber),
                    _PreviewRow(title: 'Email', value: data.email),
                    _PreviewRow(title: 'Навыки', value: data.skills),
                    _PreviewRow(title: 'Ценность', value: data.valueStatement),
                    _PreviewRow(title: 'Опыт', value: data.experienceSummary),
                    _PreviewRow(title: 'Проекты', value: data.projects),
                    if (data.confidenceNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Распознано:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...data.confidenceNotes.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $item'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Заполнить анкету'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldApply || !mounted) {
      return;
    }

    _applyImport(data);
  }

  void _applyImport(ResumeImportData data) {
    if (data.firstName.isNotEmpty) {
      _firstNameController.text = data.firstName;
    }
    if (data.lastName.isNotEmpty) {
      _lastNameController.text = data.lastName;
    }
    if (data.phoneNumber.isNotEmpty) {
      _phoneController.text = data.phoneNumber;
    }
    if (data.skills.isNotEmpty) {
      _skillsController.text = data.skills;
    }
    if (data.valueStatement.isNotEmpty) {
      _valueController.text = data.valueStatement;
    }
    if (data.experienceSummary.isNotEmpty) {
      _experienceController.text = data.experienceSummary;
    }
    if (data.projects.isNotEmpty) {
      _projectsController.text = data.projects;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Анкета заполнена из резюме. Проверьте поля и отправьте на анализ.',
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Обязательное поле';
    }

    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) {
      return 'Введите корректный номер телефона';
    }
    if (value.trim().length > _maxPhoneLength) {
      return 'Номер телефона слишком длинный';
    }

    return null;
  }

  String? _minLengthValidator(String? value, int min, String message) {
    if (value == null || value.trim().isEmpty) {
      return 'Обязательное поле';
    }
    if (value.trim().length < min) {
      return message;
    }
    return null;
  }

  String? _maxLengthValidator(String? value, int max, String message) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length > max) {
      return message;
    }
    return null;
  }

  String? _combineValidators(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анкета кандидата'),
        actions: const [ThemeToggleButton()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F4EE), Color(0xFFECEFF4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFD6DEE8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Профессиональная анкета кандидата',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF162033),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasExistingSubmission
                              ? 'Анкета уже сохранена. Можно обновить данные, заново импортировать резюме и отправить повторно.'
                              : 'Заполните форму вручную или используйте умный импорт резюме, чтобы быстро собрать профиль кандидата.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5C6778),
                          ),
                        ),
                        if (_isCheckingStatus) ...[
                          const SizedBox(height: 18),
                          const LinearProgressIndicator(minHeight: 3),
                          const SizedBox(height: 8),
                          Text(
                            'Проверяем статус анкеты...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                        if (_isSubmitting) ...[
                          const SizedBox(height: 20),
                          _AiStatusBanner(
                            status: _aiStatuses[_statusIndex],
                            step: (_statusIndex + 1) / _aiStatuses.length,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _ResumeImportCard(
                          isCompact: compact,
                          supportsFilePicker:
                              _resumeImportService.supportsFilePicker,
                          isImporting: _isImportingResume,
                          onPickFile: _importFromFile,
                          onPasteText: _importFromPaste,
                          onLoadDemo: _loadDemoResume,
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _lastNameController,
                                label: 'Фамилия',
                                maxLength: _maxNameLength,
                                validator: (value) =>
                                    _combineValidators(value, [
                                      _requiredValidator,
                                      (text) => _maxLengthValidator(
                                        text,
                                        _maxNameLength,
                                        'Фамилия слишком длинная',
                                      ),
                                    ]),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: _firstNameController,
                                label: 'Имя',
                                maxLength: _maxNameLength,
                                validator: (value) =>
                                    _combineValidators(value, [
                                      _requiredValidator,
                                      (text) => _maxLengthValidator(
                                        text,
                                        _maxNameLength,
                                        'Имя слишком длинное',
                                      ),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneController,
                          label: 'Номер телефона',
                          hint: '+7 777 123 45 67',
                          keyboardType: TextInputType.phone,
                          maxLength: _maxPhoneLength,
                          validator: _phoneValidator,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _skillsController,
                          label: 'Что умеет кандидат',
                          hint: 'Flutter, Java, Spring Boot, PostgreSQL',
                          minLines: 3,
                          maxLines: null,
                          maxLength: _maxSkillsLength,
                          validator: (value) => _combineValidators(value, [
                            _requiredValidator,
                            (text) => _maxLengthValidator(
                              text,
                              _maxSkillsLength,
                              'Описание навыков слишком длинное',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _valueController,
                          label: 'Почему кандидат ценный',
                          hint:
                              'Опишите сильные стороны, пользу для бизнеса и практическую ценность.',
                          minLines: 4,
                          maxLines: null,
                          maxLength: _maxValueLength,
                          validator: (value) => _combineValidators(value, [
                            (text) => _minLengthValidator(
                              text,
                              20,
                              'Опишите ценность кандидата подробнее',
                            ),
                            (text) => _maxLengthValidator(
                              text,
                              _maxValueLength,
                              'Описание ценности слишком длинное',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _experienceController,
                          label: 'Опыт работы',
                          hint:
                              'Опишите обязанности, стек, роль, достигнутые результаты и уровень участия.',
                          minLines: 5,
                          maxLines: null,
                          maxLength: _maxExperienceLength,
                          validator: (value) => _combineValidators(value, [
                            (text) => _minLengthValidator(
                              text,
                              30,
                              'Опишите опыт работы подробнее',
                            ),
                            (text) => _maxLengthValidator(
                              text,
                              _maxExperienceLength,
                              'Описание опыта слишком длинное',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _projectsController,
                          label: 'Проекты',
                          hint:
                              'Банковское приложение, HR-платформа, CRM dashboard',
                          minLines: 4,
                          maxLines: null,
                          maxLength: _maxProjectsLength,
                          validator: (value) => _combineValidators(value, [
                            _requiredValidator,
                            (text) => _maxLengthValidator(
                              text,
                              _maxProjectsLength,
                              'Описание проектов слишком длинное',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting || _isCheckingStatus
                                ? null
                                : _submit,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF183153),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: Text(
                              _isSubmitting
                                  ? 'Сохраняем и анализируем...'
                                  : 'Отправить анкету на AI-анализ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hint,
    TextInputType? keyboardType,
    int minLines = 1,
    int? maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines == null || (maxLines > 1),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ResumeImportCard extends StatelessWidget {
  const _ResumeImportCard({
    required this.isCompact,
    required this.supportsFilePicker,
    required this.isImporting,
    required this.onPickFile,
    required this.onPasteText,
    required this.onLoadDemo,
  });

  final bool isCompact;
  final bool supportsFilePicker;
  final bool isImporting;
  final VoidCallback onPickFile;
  final VoidCallback onPasteText;
  final VoidCallback onLoadDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Супер-фича',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Умный импорт резюме',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Загрузи текстовое резюме, вставь описание кандидата или используй демо-резюме. Система распознает ключевые поля и заполнит анкету автоматически.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ImportHintChip(label: 'TXT / MD / JSON'),
              _ImportHintChip(label: 'Вставить резюме'),
              _ImportHintChip(label: 'Предпросмотр перед применением'),
              _ImportHintChip(label: 'Автозаполнение анкеты'),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (supportsFilePicker)
                ElevatedButton.icon(
                  onPressed: isImporting ? null : onPickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(isImporting ? 'Загрузка...' : 'Загрузить файл'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF183153),
                    minimumSize: Size(isCompact ? double.infinity : 180, 48),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onPasteText,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Вставить текст'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: Size(isCompact ? double.infinity : 180, 48),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onLoadDemo,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Загрузить демо-резюме'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: Size(isCompact ? double.infinity : 210, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportHintChip extends StatelessWidget {
  const _ImportHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(value.isEmpty ? 'Не распознано' : value),
        ],
      ),
    );
  }
}

class _AiStatusBanner extends StatelessWidget {
  const _AiStatusBanner({required this.status, required this.step});

  final String status;
  final double step;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: step,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

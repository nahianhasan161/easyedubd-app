import 'package:easyedubd_app/core/startup/startup_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MissingProfileOnboardingScreen extends ConsumerStatefulWidget {
  const MissingProfileOnboardingScreen({super.key});

  @override
  ConsumerState<MissingProfileOnboardingScreen> createState() =>
      _MissingProfileOnboardingScreenState();
}

class _MissingProfileOnboardingScreenState
    extends ConsumerState<MissingProfileOnboardingScreen> {
  final _controllers = <String, TextEditingController>{};
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showCustomDepartment = false;
  final TextEditingController _customDepartmentController = TextEditingController();

  List<_ProfileStep> _steps = const [];
  bool _stepsInitialized = false;

  late final List<_FieldDef> _allFields;

  @override
  void initState() {
    super.initState();
    _allFields = [
      _FieldDef(
        key: 'fullName',
        title: "Let's get to know you",
        question: 'What is your full name?',
        icon: Icons.person_outline,
        hint: 'e.g. John Doe',
        inputType: TextInputType.name,
      ),
      _FieldDef(
        key: 'phone',
        title: 'Phone Number',
        question: 'What is your phone number?',
        icon: Icons.phone_outlined,
        hint: 'e.g. 017xxxxxxxx',
        inputType: TextInputType.phone,
      ),
      _FieldDef(
        key: 'currentLevel',
        title: 'Academic Level',
        question: 'What is your current academic level?',
        icon: Icons.school_outlined,
        hint: 'Select your program',
        inputType: TextInputType.text,
        options: const [
          'Honours',
          'BSC Honours',
          'Degree',
          'Masters',
        ],
      ),
      _FieldDef(
        key: 'institute',
        title: 'Institute',
        question: 'What is your institute name?',
        icon: Icons.location_city_outlined,
        hint: 'e.g. National University',
        inputType: TextInputType.text,
      ),
      _FieldDef(
        key: 'department',
        title: 'Department',
        question: 'What is your department?',
        icon: Icons.menu_book_outlined,
        hint: 'e.g. Computer Science',
        inputType: TextInputType.text,
      ),
      _FieldDef(
        key: 'session',
        title: 'Session',
        question: 'What is your session?',
        icon: Icons.calendar_today_outlined,
        hint: 'Select session',
        inputType: TextInputType.text,
        options: _sessionYearOptions(),
      ),
      _FieldDef(
        key: 'currentYear',
        title: 'Current Year',
        question: 'What is your current year?',
        icon: Icons.show_chart_outlined,
        hint: 'Select year',
        inputType: TextInputType.text,
        options: const ['1', '2', '3', '4'],
      ),
      _FieldDef(
        key: 'gender',
        title: 'Gender',
        question: 'What is your gender?',
        icon: Icons.people_outline,
        hint: 'e.g. Male, Female, Other',
        inputType: TextInputType.text,
      ),
    ];
    _rebuildSteps();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _customDepartmentController.dispose();
    super.dispose();
  }

  List<_FieldDef> _missingFields() {
    final profile = ref.read(currentProfileProvider).value;
    return _allFields.where((def) {
      final value = switch (def.key) {
        'fullName' => profile?.fullName,
        'phone' => profile?.phone,
        'currentLevel' => profile?.currentLevel,
        'institute' => profile?.institute,
        'department' => profile?.department,
        'session' => profile?.session,
        'currentYear' => profile?.currentYear,
        'gender' => profile?.gender,
        String() => null,
      };
      return value == null || value.trim().isEmpty;
    }).toList();
  }

  void _rebuildSteps() {
    final missing = _missingFields();
    final currentKeys = _steps.map((s) => s.key).toSet();
    final newKeys = missing.map((f) => f.key).toSet();
    if (currentKeys == newKeys && _stepsInitialized) return;
    _stepsInitialized = true;

    _steps = missing.map((def) {
      final profile = ref.read(currentProfileProvider).value;
      final existingValue = switch (def.key) {
        'fullName' => profile?.fullName ?? '',
        'phone' => profile?.phone ?? '',
        'currentLevel' => profile?.currentLevel ?? '',
        'institute' => profile?.institute ?? '',
        'department' => profile?.department ?? '',
        'session' => profile?.session ?? '',
        'currentYear' => profile?.currentYear ?? '',
        'gender' => profile?.gender ?? '',
        String() => '',
      };

      if (def.key == 'department') {
        final presetOptions = const [
          'Chemistry',
          'Mathematics',
          'Physics',
          'Zoology',
          'Botany',
        ];
        _showCustomDepartment =
            existingValue.isNotEmpty && !presetOptions.contains(existingValue);
        if (_showCustomDepartment) {
          _customDepartmentController.text = existingValue;
        }
      }

      final existing = _controllers[def.key];
      if (existing != null) {
        return _ProfileStep(
          key: def.key,
          title: def.title,
          question: def.question,
          icon: def.icon,
          field: def.key,
          hint: def.hint,
          inputType: def.inputType,
          options: def.options,
          controller: existing,
        );
      }

      final c = TextEditingController(text: existingValue);
      _controllers[def.key] = c;
      return _ProfileStep(
        key: def.key,
        title: def.title,
        question: def.question,
        icon: def.icon,
        field: def.key,
        hint: def.hint,
        inputType: def.inputType,
        options: def.options,
        controller: c,
      );
    }).toList();

    if (_currentStep >= _steps.length) {
      _currentStep = _steps.isEmpty ? 0 : _steps.length - 1;
    }
  }

  Future<void> _completeOnboarding(Map<String, String> values) async {
    setState(() => _isLoading = true);
    try {
      final profile = ref.read(currentProfileProvider).value;

      final onBoardingFields = <String>{
        'fullName',
        'phone',
        'currentLevel',
        'institute',
        'department',
        'session',
        'currentYear',
        'gender',
      };

      final departmentRaw = _showCustomDepartment
          ? _customDepartmentController.text.trim()
          : values['department'];
      final trimmedDepartment = departmentRaw?.trim();
      final departmentValue = trimmedDepartment == null || trimmedDepartment.isEmpty
          ? null
          : trimmedDepartment;

      final updated = (profile ?? const Profile(id: '')).copyWith(
        fullName: onBoardingFields.contains('fullName')
            ? values['fullName']?.trim()
            : profile?.fullName,
        phone: onBoardingFields.contains('phone')
            ? values['phone']?.trim()
            : profile?.phone,
        currentLevel: onBoardingFields.contains('currentLevel')
            ? values['currentLevel']?.trim()
            : profile?.currentLevel,
        institute: onBoardingFields.contains('institute')
            ? values['institute']?.trim()
            : profile?.institute,
        department: onBoardingFields.contains('department')
            ? departmentValue
            : profile?.department,
        session: onBoardingFields.contains('session')
            ? values['session']?.trim()
            : profile?.session,
        currentYear: onBoardingFields.contains('currentYear')
            ? values['currentYear']?.trim()
            : profile?.currentYear,
        gender: onBoardingFields.contains('gender')
            ? values['gender']?.trim()
            : profile?.gender,
      );

      await ref.read(profileControllerProvider.notifier).save(updated);
      await ref.read(startupProvider.notifier).initialize();
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onNext() async {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      final values = <String, String>{};
      for (final step in _steps) {
        if (step.key == 'department' && _showCustomDepartment) {
          values[step.field] = _customDepartmentController.text.trim();
        } else {
          values[step.field] = step.controller.text.trim();
        }
      }
      await _completeOnboarding(values);
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final profileAsync = ref.watch(currentProfileProvider);

    _rebuildSteps();

    if (profileAsync.value != null && ref.read(profileCompleteProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;
    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_currentStep == 0
              ? Icons.close
              : Icons.arrow_back),
          onPressed: _onBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Column(
                    key: ValueKey(step.key),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon, size: 48, color: primary),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        step.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.question,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (step.options != null &&
                          step.options!.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: step.controller.text.isEmpty
                              ? null
                              : step.controller.text,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: step.hint,
                            border: const OutlineInputBorder(),
                          ),
                          items: step.options!
                              .map(
                                (option) =>
                                    DropdownMenuItem(value: option, child: Text(option)),
                              )
                              .toList(),
                          onChanged: (selected) {
                            if (selected != null) {
                              setState(() => step.controller.text = selected);
                            }
                          },
                        ),
                      ] else if (step.key == 'department') ...[
                        DropdownButtonFormField<String>(
                          value: _showCustomDepartment
                              ? 'Other'
                              : (step.controller.text.isEmpty
                                  ? null
                                  : step.controller.text),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select department',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Chemistry', child: Text('Chemistry')),
                            DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                            DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                            DropdownMenuItem(value: 'Zoology', child: Text('Zoology')),
                            DropdownMenuItem(value: 'Botany', child: Text('Botany')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (selected) {
                            setState(() {
                              if (selected == 'Other') {
                                _showCustomDepartment = true;
                                step.controller.text = 'Other';
                              } else {
                                _showCustomDepartment = false;
                                _customDepartmentController.clear();
                                if (selected != null) {
                                  step.controller.text = selected;
                                }
                              }
                            });
                          },
                        ),
                        if (_showCustomDepartment) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customDepartmentController,
                            decoration: InputDecoration(
                              hintText: 'Enter your department',
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) {},
                          ),
                        ],
                      ] else
                        TextField(
                          key: ValueKey('${step.key}_field'),
                          controller: step.controller,
                          keyboardType: step.inputType,
                          decoration: InputDecoration(
                            hintText: step.hint,
                            border: const OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                     ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _onNext,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _sessionYearOptions() {
    final current = DateTime.now().year;
    return [for (int y = current; y >= current - 10; y--) '$y-${y + 1}'];
  }
}

class _FieldDef {
  final String key;
  final String title;
  final String question;
  final IconData icon;
  final String hint;
  final TextInputType inputType;
  final List<String>? options;

  const _FieldDef({
    required this.key,
    required this.title,
    required this.question,
    required this.icon,
    required this.hint,
    required this.inputType,
    this.options,
  });
}

class _ProfileStep {
  final String key;
  final String title;
  final String question;
  final IconData icon;
  final String field;
  final String hint;
  final TextInputType inputType;
  final List<String>? options;
  final TextEditingController controller;

  _ProfileStep({
    required this.key,
    required this.title,
    required this.question,
    required this.icon,
    required this.field,
    required this.hint,
    required this.inputType,
    this.options,
    required this.controller,
  });
}

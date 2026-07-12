import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _currentLevelController = TextEditingController();
  final _instituteController = TextEditingController();
  final _facultyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _sessionController = TextEditingController();
  final _currentYearController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  bool _loaded = false;
  bool _showAvatarPicker = false;

  static const List<String> _demoAvatars = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Miso',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Buddy',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Coco',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Zoe',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _currentLevelController.dispose();
    _instituteController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    _sessionController.dispose();
    _currentYearController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _populate(Profile profile) {
    if (_loaded) return;
    _loaded = true;
    _fullNameController.text = profile.fullName ?? '';
    _currentLevelController.text = profile.currentLevel ?? '';
    _instituteController.text = profile.institute ?? '';
    _facultyController.text = profile.faculty ?? '';
    _departmentController.text = profile.department ?? '';
    _sessionController.text = profile.session ?? '';
    _currentYearController.text = profile.currentYear ?? '';
    _avatarUrlController.text = profile.avatarUrl ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = ref.read(currentUserIdProvider);
    if (id == null) return;

    final profile = Profile(
      id: id,
      fullName: _fullNameController.text.trim(),
      currentLevel: _currentLevelController.text.trim(),
      institute: _instituteController.text.trim(),
      faculty: _facultyController.text.trim(),
      department: _departmentController.text.trim(),
      session: _sessionController.text.trim(),
      currentYear: _currentYearController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
    );

    await ref.read(profileControllerProvider.notifier).save(profile);

    if (!mounted) return;

    final saveState = ref.read(profileControllerProvider);

    if (saveState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: ${saveState.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile != null) _populate(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showAvatarPicker = !_showAvatarPicker),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _currentAvatar(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_showAvatarPicker)
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: _demoAvatars.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final url = _demoAvatars[index];
                          final selected = _avatarUrlController.text == url;
                          final primary = Theme.of(context).colorScheme.primary;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _avatarUrlController.text = url),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(color: primary, width: 3)
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 33,
                                backgroundImage: NetworkImage(url),
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildField(_fullNameController, 'Full Name', true),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    controller: _currentLevelController,
                    label: 'Program',
                    options: const [
                      'Honours',
                      'BSC Honours',
                      'Degree',
                      'Masters',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(_instituteController, 'Institute', false),
                  const SizedBox(height: 12),
                  _buildField(_facultyController, 'Faculty', false),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    controller: _departmentController,
                    label: 'Department',
                    options: const [
                      'Chemistry',
                      'Mathematics',
                      'Physics',
                      'Zoology',
                      'Botany',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    controller: _sessionController,
                    label: 'Session',
                    options: _sessionYearOptions(),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    controller: _currentYearController,
                    label: 'Current Year',
                    options: const ['1', '2', '3', '4'],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _sessionYearOptions() {
    final current = DateTime.now().year;
    return [for (int y = current; y >= current - 10; y--) '$y-${y + 1}'];
  }

  Widget _currentAvatar() {
    final url = _avatarUrlController.text;
    final uri = Uri.tryParse(url);
    final valid = uri != null && uri.hasAbsolutePath;

    return CircleAvatar(
      radius: 48,
      backgroundImage: valid ? NetworkImage(url) : null,
      backgroundColor: Colors.grey[200],
      child: valid
          ? null
          : const Icon(Icons.person, size: 48, color: Colors.grey),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> options,
  }) {
    final text = controller.text;
    final value = options.contains(text) ? text : null;

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      hint: const Text('Select'),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) controller.text = selected;
      },
    );
  }
}

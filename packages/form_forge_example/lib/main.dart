import 'package:flutter/material.dart';
import 'package:form_forge/form_forge.dart';

import 'forms/login_form.dart';
import 'forms/sign_up_form.dart';
import 'forms/profile_form.dart';
import 'forms/wizard_form.dart';
import 'forms/grouped_form.dart';
import 'forms/advanced_fields_form.dart';

void main() {
  runApp(const FormForgeExampleApp());
}

/// Example app demonstrating form_forge usage.
class FormForgeExampleApp extends StatelessWidget {
  const FormForgeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FormForgeThemeProvider(
      theme: const FormForgeTheme(
        fieldSpacing: 20.0,
        formPadding: EdgeInsets.all(16),
        inputDecoration: InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      child: MaterialApp(
        title: 'form_forge Examples',
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const ExampleListPage(),
      ),
    );
  }
}

class ExampleListPage extends StatelessWidget {
  const ExampleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('form_forge Examples')),
      body: ListView(
        children: [
          _ExampleTile(
            title: 'Login Form',
            subtitle: 'Basic validation with @IsRequired and @IsEmail',
            onTap: () => _pushPage(context, const LoginFormPage()),
          ),
          _ExampleTile(
            title: 'Sign Up Form',
            subtitle: 'Cross-field validation with @MustMatch and @AsyncValidate',
            onTap: () => _pushPage(context, const SignUpFormPage()),
          ),
          _ExampleTile(
            title: 'Profile Form',
            subtitle: 'Numeric validation with @Min/@Max and boolean fields',
            onTap: () => _pushPage(context, const ProfileFormPage()),
          ),
          _ExampleTile(
            title: 'Wizard Form',
            subtitle: 'Multi-step forms with @FormStep',
            onTap: () => _pushPage(context, const WizardFormPage()),
          ),
          _ExampleTile(
            title: 'Grouped Form',
            subtitle: 'Visual sections with @FieldGroup',
            onTap: () => _pushPage(context, const GroupedFormPage()),
          ),
          _ExampleTile(
            title: 'Advanced Fields',
            subtitle: '@RatingInput, @Slider, @ChipsInput, @ColorPicker, @DateRange, @RichText',
            onTap: () => _pushPage(context, const AdvancedFieldsPage()),
          ),
        ],
      ),
    );
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _ExampleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExampleTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ==================== Login Form Page ====================
class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final controller = LoginFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LoginFormWidget(controller: controller),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => FilledButton(
                onPressed: controller.isSubmitting
                    ? null
                    : () => controller.submit((data) async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged in as ${data.email}'),
                            ),
                          );
                        }),
                child: controller.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Sign Up Form Page ====================
class SignUpFormPage extends StatefulWidget {
  const SignUpFormPage({super.key});

  @override
  State<SignUpFormPage> createState() => _SignUpFormPageState();
}

class _SignUpFormPageState extends State<SignUpFormPage> {
  final controller = SignUpFormController();

  @override
  void initState() {
    super.initState();
    // Register async validator for email
    controller.registerAsyncValidator('email', (value) async {
      await Future.delayed(const Duration(seconds: 1));
      final email = value as String;
      if (email == 'taken@example.com') {
        return 'This email is already registered';
      }
      return null;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SignUpFormWidget(controller: controller),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => FilledButton(
                onPressed: controller.isSubmitting
                    ? null
                    : () => controller.submit((data) async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Welcome, ${data.name}!'),
                            ),
                          );
                        }),
                child: controller.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Profile Form Page ====================
class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final controller = ProfileFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileFormWidget(controller: controller),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: controller.reset,
                  child: const Text('Reset'),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => FilledButton(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => controller.submit((data) async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Profile saved: ${data.displayName}, age ${data.age}',
                                  ),
                                ),
                              );
                            }),
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Wizard Form Page ====================
class WizardFormPage extends StatefulWidget {
  const WizardFormPage({super.key});

  @override
  State<WizardFormPage> createState() => _WizardFormPageState();
}

class _WizardFormPageState extends State<WizardFormPage> {
  final controller = WizardFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wizard Form')),
      body: WizardFormWidget(controller: controller),
    );
  }
}

// ==================== Grouped Form Page ====================
class GroupedFormPage extends StatefulWidget {
  const GroupedFormPage({super.key});

  @override
  State<GroupedFormPage> createState() => _GroupedFormPageState();
}

class _GroupedFormPageState extends State<GroupedFormPage> {
  final controller = GroupedFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grouped Form')),
      body: SingleChildScrollView(
        child: GroupedFormWidget(controller: controller),
      ),
    );
  }
}

// ==================== Advanced Fields Page ====================
class AdvancedFieldsPage extends StatefulWidget {
  const AdvancedFieldsPage({super.key});

  @override
  State<AdvancedFieldsPage> createState() => _AdvancedFieldsPageState();
}

class _AdvancedFieldsPageState extends State<AdvancedFieldsPage> {
  final controller = AdvancedFieldsFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Fields')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AdvancedFieldsFormWidget(controller: controller),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => FilledButton(
                onPressed: () {
                  final json = controller.toJson();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Form data: $json')),
                  );
                },
                child: const Text('Show JSON'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

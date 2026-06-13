import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle sign-up button press.
  ///
  /// Calls the viewmodel's signUp() method, then navigates to /home
  /// on success. Navigation is done here (not in the viewmodel) to
  /// keep the viewmodel free of UI dependencies like GoRouter.
  Future<void> _handleSignUp(
    BuildContext context,
    SignUpViewModel viewModel,
  ) async {
    await viewModel.signUp();

    // After signUp completes, check the watched state for success.
    // Navigate to /home so the user sees the main app.
    final state = ref.read(signUpViewModelProvider);
    if (context.mounted && state.isSuccess) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);
    final viewModel = ref.read(signUpViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: Theme.of(context).colorScheme.primary),
                    Text('UniSwap', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Create account', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 6),
              Text('Use your UTM email to join UniSwap.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              TextField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: viewModel.updateFullName,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                  helperText: '3-20 characters, letters, numbers, or _.',
                ),
                onChanged: viewModel.updateUsername,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'UTM email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onChanged: viewModel.updateEmail,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                onChanged: viewModel.updatePhone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !state.isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(state.isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: viewModel.togglePasswordVisibility,
                  ),
                ),
                onChanged: viewModel.updatePassword,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: state.faculty.isEmpty ? null : state.faculty,
                items: state.facultiesList
                    .map((faculty) => DropdownMenuItem(value: faculty, child: Text(faculty)))
                    .toList(),
                onChanged: (value) => viewModel.updateFaculty(value ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Faculty',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              if (state.isFacultiesLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 16),
              Text('Campus', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Johor', label: Text('Johor')),
                  ButtonSegment(value: 'UTM KL', label: Text('UTM KL')),
                ],
                selected: {state.campus},
                onSelectionChanged: (values) => viewModel.updateCampus(values.first),
              ),
              if (state.isSuccess) ...[
                const SizedBox(height: 12),
                const Text('Account created successfully! You can now sign in.'),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.isLoading ? null : () => _handleSignUp(context, viewModel),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

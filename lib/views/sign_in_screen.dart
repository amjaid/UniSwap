import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle sign-in button press.
  ///
  /// Calls the viewmodel's signIn() method, then navigates to /home
  /// on success. Navigation is done here (not in the viewmodel) to
  /// keep the viewmodel free of UI dependencies like GoRouter.
  Future<void> _handleSignIn(
    BuildContext context,
    SignInViewModel viewModel,
  ) async {
    await viewModel.signIn();

    // After signIn completes, check the watched state for errors.
    // Navigate to /home so the user sees the main app.
    final state = ref.read(signInViewModelProvider);
    if (context.mounted && state.errorMessage == null) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);
    final viewModel = ref.read(signInViewModelProvider.notifier);

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
              const SizedBox(height: 28),
              Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 6),
              Text('Sign in with your UTM email', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onChanged: viewModel.updateEmail,
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: state.isLoading ? null : () => _handleSignIn(context, viewModel),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New here?'),
                  TextButton(
                    onPressed: () => context.go('/sign-up'),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

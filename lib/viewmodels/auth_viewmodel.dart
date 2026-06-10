import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/services/django_auth_service.dart';
import 'package:uniswap/services/providers.dart';

/// Auth state provider — emits the current user data or null.
///
/// Unlike a FutureProvider (which re-evaluates on every dependency change),
/// this is a StateProvider that only fetches from the API:
/// 1. On first access (app startup)
/// 2. After explicit login (via SignInViewModel)
/// 3. After explicit registration (via SignUpViewModel)
/// 4. After profile update (via DjangoAuthService.updateProfile)
/// 5. After logout
///
/// This prevents excessive GET /api/users/me/ calls that cause rate limiting.
final authStateProvider = StateProvider<Map<String, dynamic>?>((ref) {
  // Initial value is null — the AuthGuard in routes.dart will trigger
  // a one-time fetch via ref.read(authServiceProvider).fetchCurrentUser()
  // on app startup.
  return null;
});

/// Initialize auth state by checking stored tokens and fetching user profile.
///
/// Call this once on app startup (e.g., in main.dart or a splash screen).
/// Returns the current user data, or null if not authenticated.
Future<Map<String, dynamic>?> initializeAuthState(Ref ref) async {
  final authService = ref.read(djangoAuthServiceProvider);
  final isAuth = await authService.isAuthenticated();
  if (isAuth) {
    final user = authService.currentUser;
    ref.read(authStateProvider.notifier).state = user;
    return user;
  }
  ref.read(authStateProvider.notifier).state = null;
  return null;
}

/// Refresh auth state by re-fetching the current user profile.
///
/// Call this after login, registration, or profile updates.
Future<void> refreshAuthState(Ref ref) async {
  final authService = ref.read(djangoAuthServiceProvider);
  final response = await authService.fetchCurrentUser();
  if (response.isSuccess && response.data != null) {
    ref.read(authStateProvider.notifier).state = response.data;
  }
}

/// Clear auth state (on logout or token expiry).
void clearAuthState(Ref ref) {
  ref.read(authStateProvider.notifier).state = null;
}

final signInViewModelProvider =
    StateNotifierProvider<SignInViewModel, SignInState>((ref) {
  return SignInViewModel(ref.read(djangoAuthServiceProvider), ref);
});

final signUpViewModelProvider =
    StateNotifierProvider<SignUpViewModel, SignUpState>((ref) {
  return SignUpViewModel(ref.read(djangoAuthServiceProvider), ref);
});

final forgotPasswordViewModelProvider =
    StateNotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>((ref) {
  return ForgotPasswordViewModel(ref.read(djangoAuthServiceProvider));
});

// ──────────────────────────────────────────────
// Sign In
// ──────────────────────────────────────────────

class SignInState extends Equatable {
  const SignInState({
    required this.email,
    required this.password,
    required this.isLoading,
    required this.errorMessage,
    required this.isPasswordVisible,
  });

  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordVisible;

  factory SignInState.initial() {
    return const SignInState(
      email: '',
      password: '',
      isLoading: false,
      errorMessage: null,
      isPasswordVisible: false,
    );
  }

  SignInState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordVisible,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, isLoading, errorMessage, isPasswordVisible];
}

class SignInViewModel extends StateNotifier<SignInState> {
  SignInViewModel(this._authService, this._ref) : super(SignInState.initial());

  final DjangoAuthService _authService;
  final Ref _ref;

  void updateEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  void updatePassword(String password) =>
      state = state.copyWith(password: password, errorMessage: null);

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signIn() async {
    final email = state.email.trim();
    final password = state.password.trim();

    if (!_isUniversityEmail(email)) {
      state = state.copyWith(
          errorMessage: 'Please use your university email address.');
      return;
    }

    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password is required.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      if (response.isSuccess) {
        // Refresh auth state with the newly fetched user profile
        await refreshAuthState(_ref);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? 'Sign in failed.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error. Please try again.',
      );
    }
  }
}

// ──────────────────────────────────────────────
// Sign Up
// ──────────────────────────────────────────────

class SignUpState extends Equatable {
  const SignUpState({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.faculty,
    required this.campus,
    required this.isLoading,
    required this.errorMessage,
    required this.isPasswordVisible,
    required this.isSuccess,
    required this.isFacultiesLoading,
    required this.facultiesList,
  });

  final String fullName;
  final String username;
  final String email;
  final String password;
  final String phone;
  final String faculty;
  final String campus;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordVisible;
  final bool isSuccess;
  final bool isFacultiesLoading;
  final List<String> facultiesList;

  factory SignUpState.initial() {
    return const SignUpState(
      fullName: '',
      username: '',
      email: '',
      password: '',
      phone: '',
      faculty: '',
      campus: 'Johor',
      isLoading: false,
      errorMessage: null,
      isPasswordVisible: false,
      isSuccess: false,
      isFacultiesLoading: true,
      facultiesList: [
        'Engineering',
        'Computing',
        'Built Environment',
        'Science',
        'Management',
        'Education',
        'Social Sciences and Humanities',
        'Islamic Studies',
        'MJIIT',
      ],
    );
  }

  SignUpState copyWith({
    String? fullName,
    String? username,
    String? email,
    String? password,
    String? phone,
    String? faculty,
    String? campus,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordVisible,
    bool? isSuccess,
    bool? isFacultiesLoading,
    List<String>? facultiesList,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      faculty: faculty ?? this.faculty,
      campus: campus ?? this.campus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isSuccess: isSuccess ?? this.isSuccess,
      isFacultiesLoading: isFacultiesLoading ?? this.isFacultiesLoading,
      facultiesList: facultiesList ?? this.facultiesList,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        username,
        email,
        password,
        phone,
        faculty,
        campus,
        isLoading,
        errorMessage,
        isPasswordVisible,
        isSuccess,
        isFacultiesLoading,
        facultiesList,
      ];
}

class SignUpViewModel extends StateNotifier<SignUpState> {
  SignUpViewModel(this._authService, this._ref) : super(SignUpState.initial());

  final DjangoAuthService _authService;
  final Ref _ref;

  void updateFullName(String fullName) =>
      state = state.copyWith(fullName: fullName, errorMessage: null);

  void updateUsername(String username) =>
      state = state.copyWith(username: username, errorMessage: null);

  void updateEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  void updatePassword(String password) =>
      state = state.copyWith(password: password, errorMessage: null);

  void updatePhone(String phone) =>
      state = state.copyWith(phone: phone, errorMessage: null);

  void updateFaculty(String faculty) =>
      state = state.copyWith(faculty: faculty, errorMessage: null);

  void updateCampus(String campus) =>
      state = state.copyWith(campus: campus, errorMessage: null);

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signUp() async {
    final email = state.email.trim();
    final password = state.password.trim();
    final fullName = state.fullName.trim();
    final username = state.username.trim();
    final phone = state.phone.trim();
    final faculty = state.faculty.trim();

    if (fullName.isEmpty || username.isEmpty || phone.isEmpty || faculty.isEmpty) {
      state = state.copyWith(errorMessage: 'Please complete all fields.');
      return;
    }

    if (!_isValidUsername(username)) {
      state = state.copyWith(
          errorMessage: 'Username must be 3-20 characters, letters, numbers, or _.');
      return;
    }

    if (!_isUniversityEmail(email)) {
      state = state.copyWith(
          errorMessage: 'Please use your university email address.');
      return;
    }

    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'Password must be at least 6 characters.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // DjangoAuthService.register() expects: email, name, password, passwordConfirm
      // We map fullName -> name, and use password for both password fields
      final response = await _authService.register(
        email: email,
        name: fullName,
        password: password,
        passwordConfirm: password,
      );

      if (response.isSuccess) {
        // Refresh auth state with the newly registered user
        await refreshAuthState(_ref);
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? 'Registration failed.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error. Please try again.',
      );
    }
  }
}

// ──────────────────────────────────────────────
// Forgot Password
// ──────────────────────────────────────────────

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    required this.email,
    required this.isLoading,
    required this.errorMessage,
    required this.isSuccess,
  });

  final String email;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  factory ForgotPasswordState.initial() {
    return const ForgotPasswordState(
      email: '',
      isLoading: false,
      errorMessage: null,
      isSuccess: false,
    );
  }

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [email, isLoading, errorMessage, isSuccess];
}

class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordViewModel(this._authService) : super(ForgotPasswordState.initial());

  final DjangoAuthService _authService;

  void updateEmail(String email) =>
      state = state.copyWith(email: email, errorMessage: null);

  Future<void> submit() async {
    final email = state.email.trim();

    if (!_isUniversityEmail(email)) {
      state = state.copyWith(
          errorMessage: 'Please use your university email address.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final response = await _authService.sendPasswordReset(email);
      if (response.isSuccess) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? 'Password reset request failed.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error. Please try again.',
      );
    }
  }
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

bool _isUniversityEmail(String email) {
  // Check for common university email domains
  return email.toLowerCase().contains('utm.my') ||
      email.toLowerCase().contains('um.edu.my') ||
      email.toLowerCase().contains('ukm.edu.my') ||
      email.toLowerCase().contains('upm.edu.my') ||
      email.toLowerCase().contains('usm.my') ||
      email.toLowerCase().contains('uim.edu.my') ||
      email.toLowerCase().contains('.edu');
}

bool _isValidUsername(String username) {
  final trimmed = username.trim();
  return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(trimmed);
}

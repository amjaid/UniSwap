import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/services/auth_service.dart';
import 'package:uniswap/services/firestore_service.dart';
import 'package:uniswap/services/storage_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(firebaseAuthProvider));
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.read(firebaseFirestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(firebaseStorageProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

final signInViewModelProvider = StateNotifierProvider<SignInViewModel, SignInState>((ref) {
  return SignInViewModel(ref.read(authServiceProvider));
});

final signUpViewModelProvider = StateNotifierProvider<SignUpViewModel, SignUpState>((ref) {
  return SignUpViewModel(
    ref.read(authServiceProvider),
    ref.read(firestoreServiceProvider),
  );
});

final forgotPasswordViewModelProvider = StateNotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>((ref) {
  return ForgotPasswordViewModel(ref.read(authServiceProvider));
});

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
  List<Object?> get props => [email, password, isLoading, errorMessage, isPasswordVisible];
}

class SignInViewModel extends StateNotifier<SignInState> {
  SignInViewModel(this._authService) : super(SignInState.initial());

  final AuthService _authService;

  void updateEmail(String email) => state = state.copyWith(email: email, errorMessage: null);

  void updatePassword(String password) => state = state.copyWith(password: password, errorMessage: null);

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signIn() async {
    final email = state.email.trim();
    final password = state.password.trim();

    if (!_isUtmEmail(email)) {
      state = state.copyWith(errorMessage: 'Email must contain utm.my.');
      return;
    }

    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password is required.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _authService.signIn(email: email, password: password);
      final user = credential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _authService.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please verify your email. We sent you a link.',
        );
        return;
      }

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _authErrorMessage(error));
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign in failed.');
    }
  }
}

class SignUpState extends Equatable {
  const SignUpState({
    required this.fullName,
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
  SignUpViewModel(this._authService, this._firestoreService) : super(SignUpState.initial()) {
    _loadFaculties();
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  Future<void> _loadFaculties() async {
    try {
      final faculties = await _firestoreService.fetchFaculties();
      if (faculties.isNotEmpty) {
        state = state.copyWith(facultiesList: faculties, isFacultiesLoading: false);
        return;
      }
    } catch (_) {}

    state = state.copyWith(isFacultiesLoading: false);
  }

  void updateFullName(String fullName) => state = state.copyWith(fullName: fullName, errorMessage: null);

  void updateEmail(String email) => state = state.copyWith(email: email, errorMessage: null);

  void updatePassword(String password) => state = state.copyWith(password: password, errorMessage: null);

  void updatePhone(String phone) => state = state.copyWith(phone: phone, errorMessage: null);

  void updateFaculty(String faculty) => state = state.copyWith(faculty: faculty, errorMessage: null);

  void updateCampus(String campus) => state = state.copyWith(campus: campus, errorMessage: null);

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signUp() async {
    final email = state.email.trim();
    final password = state.password.trim();
    final fullName = state.fullName.trim();
    final phone = state.phone.trim();
    final faculty = state.faculty.trim();
    final campus = state.campus.trim();

    if (fullName.isEmpty || phone.isEmpty || faculty.isEmpty) {
      state = state.copyWith(errorMessage: 'Please complete all fields.');
      return;
    }

    if (!_isUtmEmail(email)) {
      state = state.copyWith(errorMessage: 'Email must contain utm.my.');
      return;
    }

    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'Password must be at least 6 characters.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _authService.signUp(email: email, password: password);
      await credential.user?.sendEmailVerification();
      await _firestoreService.createUserProfile(
        userId: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        faculty: faculty,
        campus: campus,
      );
      await _authService.signOut();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _authErrorMessage(error));
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign up failed.');
    }
  }
}

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

  final AuthService _authService;

  void updateEmail(String email) => state = state.copyWith(email: email, errorMessage: null);

  Future<void> submit() async {
    final email = state.email.trim();

    if (!_isUtmEmail(email)) {
      state = state.copyWith(errorMessage: 'Email must contain utm.my.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      await _authService.sendPasswordReset(email);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _authErrorMessage(error));
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Request failed.');
    }
  }
}

bool _isUtmEmail(String email) {
  return email.toLowerCase().contains('utm.my');
}

String _authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'operation-not-allowed':
      return 'Email/password sign-in is disabled in Firebase Auth.';
    case 'email-already-in-use':
      return 'That email is already registered.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    default:
      if (error.message == null) {
        return 'Authentication failed (${error.code}).';
      }
      return '${error.message} (${error.code}).';
  }
}

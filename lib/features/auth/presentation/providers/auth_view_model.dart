import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/models/user.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    getIt<SignInWithGoogleUseCase>(),
    getIt<SignOutUseCase>(),
    getIt<GetCurrentUserUseCase>(),
  );
});

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isInitializing,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthViewModel(
    this._signInWithGoogleUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
  ) : super(AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isInitializing: true);
    
    try {
      // 3초 타임아웃 설정
      final result = await _getCurrentUserUseCase()
          .timeout(const Duration(seconds: 5));
      
      result.fold(
        (error) => state = state.copyWith(
          isInitializing: false,
          isLoading: false,
          error: error,
        ),
        (user) => state = state.copyWith(
          isInitializing: false,
          isLoading: false,
          user: user,
        ),
      );
    } catch (e) {
      // 모든 예외 상황에서도 초기화 완료 처리
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _signInWithGoogleUseCase();
    
    result.fold(
      (error) => state = state.copyWith(
        isLoading: false,
        error: error,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
      ),
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _signOutUseCase();
    
    result.fold(
      (error) => state = state.copyWith(
        isLoading: false,
        error: error,
      ),
      (_) => state = AuthState(isInitializing: false),
    );
  }
}
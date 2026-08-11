import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  Future<void> signUpAdoptant({
    required String email,
    required String password,
    required String fullName,
    required File avatarFile,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signUpAdoptant(
        email: email,
        password: password,
        fullName: fullName,
        avatarFile: avatarFile,
      );
      state = state.copyWith(status: AuthStatus.registered);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  Future<void> signUpShelter({
    required String email,
    required String password,
    required String shelterName,
    required String address,
    required File avatarFile,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signUpShelter(
        email: email,
        password: password,
        shelterName: shelterName,
        address: address,
        avatarFile: avatarFile,
      );
      state = state.copyWith(status: AuthStatus.registered);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  void resetState() {
    state = const AuthState();
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (error.contains('Email already registered') ||
        error.contains('already been registered')) {
      return 'Este correo ya está registrado';
    }
    if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (error.contains('Unable to validate email address')) {
      return 'El correo ingresado no es válido';
    }
    if (error.contains('over_email_send_rate_limit')) {
      return 'Demasiados intentos, espera unos minutos';
    }
    if (error.contains('network')) {
      return 'Error de conexión, verifica tu internet';
    }
    return 'Ocurrió un error, intenta de nuevo';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
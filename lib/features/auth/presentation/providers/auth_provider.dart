import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── State ─────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  String? _backendToken;
  String? _errorMessage;

  String? _tempEmail;
  String? _tempPassword;

  // ─── Getters ───────────────────────────────────
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  String? get backendToken => _backendToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      await _firebaseUser?.updateDisplayName(name);
      await _firebaseUser?.sendEmailVerification();

      _tempEmail = email;
      _tempPassword = password;

      _status = AuthStatus.emailNotVerified;
      notifyListeners();

      return true;
  }

  // Verify email
  Future<bool> loginAfterEmailVerification() async {
    _setLoading();

    await _firebaseUser?.reload();
    _firebaseUser = _auth.currentUser;

    if (!(_firebaseUser?.emailVerified ?? false)) {
      _status = AuthStatus.emailNotVerified;
      notifyListeners();
      return false;
    }

    final credential =
        await _auth.signInWithEmailAndPassword(
      email: _tempEmail!,
      password: _tempPassword!,
    );

    _firebaseUser = credential.user;
    _tempEmail = null;
    _tempPassword = null;

    return await _verifyTokenToBackend();
  }

  // Verify Token ke Backend
  Future<bool> _verifyTokenToBackend() async {
      final firebaseToken =
          await _firebaseUser?.getIdToken();

      final response = await DioClient.instance.post(
        ApiConstants.verifyToken,
        data: {'firebase_token': firebaseToken},
      );

      final data =
          response.data['data'] as Map<String, dynamic>;

      final backendToken =
          data['access_token'] as String;

      await SecureStorageService.saveToken(
          backendToken);

      _backendToken = backendToken;

      _status = AuthStatus.authenticated;
      notifyListeners();

      return true;
    }

  //Login dengan email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      return await _verifyTokenToBackend();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  //Login dengan Google
  Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      final googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }

      final googleAuth =
          await googleUser.authentication;

      final credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await _auth.signInWithCredential(
              credential);

      _firebaseUser = userCred.user;

      return await _verifyTokenToBackend();
    } catch (e) {
      _setError('Gagal login dengan Google');
      return false;
    }
  }
  
  //Resend email verifikasi
  Future<void> resendVerificationEmail() async {
    await _firebaseUser?.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    await _firebaseUser?.reload();
    _firebaseUser = _auth.currentUser;

    if (_firebaseUser?.emailVerified ?? false) {
      return await _verifyTokenToBackend();
    }

    return false;
  }
}
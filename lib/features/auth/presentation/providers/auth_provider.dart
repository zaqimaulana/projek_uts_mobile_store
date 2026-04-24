import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:beer_store_app/core/services/dio_client.dart';
import 'package:beer_store_app/core/services/secure_storage_service.dart';
import 'package:beer_store_app/core/constants/api_constants.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "497918096590-1nok3qn97fvjj2ga4227rhc0q1vlpctu.apps.googleusercontent.com",
    scopes: ['email'],
  );

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
  try {
    print("STEP 1 - ambil firebase token");

    final firebaseToken =
        await _firebaseUser?.getIdToken();

    print("TOKEN: $firebaseToken");

    print("STEP 2 - kirim ke backend");

    final response = await DioClient.instance.post(
      ApiConstants.verifyToken,
      data: {'firebase_token': firebaseToken},
    );

    print("STEP 3 - response backend");
    print(response.data);

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
  } catch (e) {
    print("ERROR VERIFY TOKEN:");
    print(e);

    _setError("Gagal verifikasi backend");
    return false;
  }
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
  } catch (e) {
    _setError("Login gagal");
    return false;
  }
}

  //Login dengan Google
  Future<bool> loginWithGoogle() async {
    _setLoading();

    try {
      /// STEP 1: pilih akun google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }

      /// STEP 2: ambil auth data
      final googleAuth = await googleUser.authentication;

      /// STEP 3: convert ke firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// STEP 4: login ke firebase
      final userCredential =
          await _auth.signInWithCredential(credential);

      _firebaseUser = userCredential.user;

      /// STEP 5: kirim ke backend
      return await _verifyTokenToBackend();

    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
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

  //Logout & Clear Session
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await SecureStorageService.clearAll();

    _firebaseUser = null;
    _backendToken = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFirebaseError(String code) => switch (code) {
        'email-already-in-use' =>
          'Email sudah terdaftar',
        'user-not-found' =>
          'Akun tidak ditemukan',
        'wrong-password' =>
          'Password salah',
        'invalid-email' =>
          'Format email tidak valid',
        'weak-password' =>
          'Password terlalu lemah',
        'network-request-failed' =>
          'Tidak ada koneksi internet',
        _ => 'Terjadi kesalahan'
      };
}

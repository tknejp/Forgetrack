import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _auth = GoogleAuthService.instance;

  GoogleSignInAccount? _user;
  bool _isLoading = false;
  String? _error;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _auth.onAuthChanged.listen((account) {
      _user = account;
      notifyListeners();
    });
    // Pokus o tiché přihlášení při startu
    _trySilentSignIn();
  }

  Future<void> _trySilentSignIn() async {
    _user = await _auth.signInSilently();
    notifyListeners();
  }

  Future<void> signIn() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.signIn();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}

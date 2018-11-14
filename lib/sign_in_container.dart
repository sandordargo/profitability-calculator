import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class SignInContainer {
  GoogleSignIn _googleSignIn = new GoogleSignIn(
    scopes: <String>['https://www.googleapis.com/auth/drive.file'],
//    scopes: <String>[],
  );

  static final SignInContainer _singleton = new SignInContainer._internal();

  factory SignInContainer() {
    return _singleton;
  }

  GoogleSignInAccount _currentUser;
  bool _isSignedIn = false;

  SignInContainer._internal();

  void listen(Function callback) {
    _currentUser =  _googleSignIn.currentUser;
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      callback(account);
      _currentUser =  _googleSignIn.currentUser;
      print('cb called');
    });
    _googleSignIn.signInSilently();

  }

  GoogleSignInAccount getCurrentUser() {
    return _currentUser;
  }

  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }


  Future<Null> handleSignIn() async {
    print("sign in");
    try {
      var bla = await _googleSignIn.signIn();
      print(bla);
      print("sign in fin");
      var iss = await _googleSignIn.isSignedIn();
      print(iss);
    } catch (error) {
      print(error);
    }
  }

  Future<Null> handleSignOut() async {
    print("sign out");
    _googleSignIn.disconnect();
  }
}


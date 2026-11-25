import 'package:flutter/foundation.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController(LoginUserModel loginUser)
    : _profile = UserProfile.fromLogin(loginUser);

  UserProfile _profile;
  bool _isCleared = false;

  UserProfile get profile => _profile;
  bool get isCleared => _isCleared;

  void update(UserProfile profile) {
    _profile = profile;
    _isCleared = false;
    notifyListeners();
  }

  void clear() {
    _profile = const UserProfile();
    _isCleared = true;
    notifyListeners();
  }
}

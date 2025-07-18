// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';

LoginResponse loginResponseFromJson(String str) {
  final jsonData = json.decode(str);
  return LoginResponse.fromJson(jsonData);
}

String loginResponseToJson(LoginResponse data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class LoginResponse {
  String massage;
  String token;

  LoginResponse({required this.massage, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      new LoginResponse(massage: json["massage"], token: json["token"]);

  Map<String, dynamic> toJson() => {"massage": massage, "token": token};
}

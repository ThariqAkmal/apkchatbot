class MeResponse {
  String message;
  List<UserData> data;

  MeResponse({required this.message, required this.data});

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
    message: json["message"],
    data: List<UserData>.from(json["data"].map((x) => UserData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };

  @override
  String toString() => 'MeResponse(message: $message, data: $data)';
}

class UserData {
  int id;
  String namaDepan;
  String namaBelakang;
  String email;
  String password;

  UserData({
    required this.id,
    required this.namaDepan,
    required this.namaBelakang,
    required this.email,
    required this.password,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json["id"],
    namaDepan: json["nama_depan"],
    namaBelakang: json["nama_belakang"],
    email: json["email"],
    password: json["password"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nama_depan": namaDepan,
    "nama_belakang": namaBelakang,
    "email": email,
    "password": password,
  };

  @override
  String toString() =>
      'UserData(id: $id, namaDepan: $namaDepan, namaBelakang: $namaBelakang, email: $email)';
}

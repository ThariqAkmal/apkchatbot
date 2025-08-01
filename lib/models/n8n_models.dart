// To parse this JSON data, do
//
//     final n8NModels = n8NModelsFromJson(jsonString);

import 'dart:convert';

N8NModels n8NModelsFromJson(String str) {
  final jsonData = json.decode(str);
  return N8NModels.fromJson(jsonData);
}

String n8NModelsToJson(N8NModels data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class N8NModels {
  bool succes;
  String chatInput;
  String response;

  N8NModels({
    required this.succes,
    required this.chatInput,
    required this.response,
  });

  factory N8NModels.fromJson(Map<String, dynamic> json) => new N8NModels(
    succes: json["succes"],
    chatInput: json["chatInput"],
    response: json["response"],
  );

  Map<String, dynamic> toJson() => {
    "succes": succes,
    "chatInput": chatInput,
    "response": response,
  };
}

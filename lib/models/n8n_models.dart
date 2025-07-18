class N8nWorkflowResponse {
  final String workflowId;
  final String executionId;
  final String status; // 'success', 'error', 'running', 'stopped'
  final Map<String, dynamic>? result;
  final DateTime executedAt;
  final String? error;

  N8nWorkflowResponse({
    required this.workflowId,
    required this.executionId,
    required this.status,
    this.result,
    required this.executedAt,
    this.error,
  });

  factory N8nWorkflowResponse.fromJson(Map<String, dynamic> json) {
    return N8nWorkflowResponse(
      workflowId: json['workflow_id'] ?? '',
      executionId: json['execution_id'] ?? '',
      status: json['status'] ?? 'unknown',
      result: json['result'],
      executedAt: DateTime.parse(
        json['executed_at'] ?? DateTime.now().toIso8601String(),
      ),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workflow_id': workflowId,
      'execution_id': executionId,
      'status': status,
      'result': result,
      'executed_at': executedAt.toIso8601String(),
      'error': error,
    };
  }
}

class N8nWebhookPayload {
  final String trigger;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  N8nWebhookPayload({
    required this.trigger,
    required this.userId,
    required this.data,
    required this.timestamp,
  });

  factory N8nWebhookPayload.fromJson(Map<String, dynamic> json) {
    return N8nWebhookPayload(
      trigger: json['trigger'] ?? '',
      userId: json['user_id'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      'user_id': userId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class N8nCallbackData {
  final String workflowId;
  final String executionId;
  final String callbackType; // 'completion', 'error', 'progress'
  final Map<String, dynamic> result;
  final DateTime receivedAt;

  N8nCallbackData({
    required this.workflowId,
    required this.executionId,
    required this.callbackType,
    required this.result,
    required this.receivedAt,
  });

  factory N8nCallbackData.fromJson(Map<String, dynamic> json) {
    return N8nCallbackData(
      workflowId: json['workflow_id'] ?? '',
      executionId: json['execution_id'] ?? '',
      callbackType: json['callback_type'] ?? 'completion',
      result: json['result'] ?? {},
      receivedAt: DateTime.parse(
        json['received_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workflow_id': workflowId,
      'execution_id': executionId,
      'callback_type': callbackType,
      'result': result,
      'received_at': receivedAt.toIso8601String(),
    };
  }
}

# Instruksi Integrasi Dify & n8n untuk Chatbot Flutter

## Informasi yang Dibutuhkan dari Teman Anda:

### 1. **Dify Configuration**

- **API Key**: Key untuk mengakses Dify API
- **Base URL**: URL endpoint Dify (contoh: `https://api.dify.ai/v1` atau self-hosted)
- **App ID**: ID aplikasi yang dibuat di Dify
- **Model Settings**: Konfigurasi model yang digunakan

### 2. **n8n Webhook Configuration**

- **Webhook URL**: URL endpoint n8n untuk menerima trigger dari Flutter
- **Authentication**: Token atau key jika diperlukan
- **Expected Payload**: Format data yang diharapkan n8n

### 3. **API Endpoints yang Perlu Disediakan:**

#### A. Chat Endpoint

```
POST /v1/chat-messages
Headers:
- Authorization: Bearer [API_KEY]
- Content-Type: application/json

Body:
{
  "inputs": {},
  "query": "user message",
  "user": "user_id",
  "conversation_id": "conversation_id_optional",
  "response_mode": "blocking"
}

Response:
{
  "answer": "AI response",
  "conversation_id": "conversation_id",
  "message_id": "message_id",
  "created_at": "timestamp"
}
```

#### B. Conversation History

```
GET /v1/messages?conversation_id={id}&user={user_id}
Headers:
- Authorization: Bearer [API_KEY]

Response:
{
  "data": [
    {
      "id": "message_id",
      "query": "user message",
      "answer": "ai response",
      "created_at": "timestamp"
    }
  ]
}
```

### 4. **n8n Workflow Requirements:**

#### A. Chat Workflow (Webhook: `/webhook/chat`)

```json
{
  "trigger": "chat_message",
  "user_id": "user123",
  "message": "Hello AI",
  "conversation_id": "conv123",
  "timestamp": "2024-01-01T10:00:00Z",
  "metadata": {
    "app_version": "1.0.0",
    "platform": "flutter"
  }
}
```

#### B. User Activity Workflow (Webhook: `/webhook/user-activity`)

```json
{
  "trigger": "user_activity",
  "user_id": "user123",
  "activity": "login|logout|chat_start|chat_end|ai_response_received|error_occurred",
  "timestamp": "2024-01-01T10:00:00Z",
  "data": {
    "additional_info": "any_relevant_data"
  }
}
```

#### C. Feedback Workflow (Webhook: `/webhook/feedback`)

```json
{
  "trigger": "feedback",
  "user_id": "user123",
  "message_id": "msg123",
  "feedback_type": "like|dislike|report",
  "comment": "optional_comment",
  "timestamp": "2024-01-01T10:00:00Z"
}
```

#### D. Workflow Response Format (jika ada response balik):

```json
{
  "workflow_id": "workflow123",
  "execution_id": "exec123",
  "status": "success|error|running",
  "result": {
    "processed_data": "any_result_data"
  },
  "executed_at": "2024-01-01T10:00:00Z"
}
```

### 5. **Testing Endpoints:**

Berikan URL testing untuk:

- Development environment
- Staging environment
- Production environment

### 6. **Authentication:**

- Bagaimana cara mendapatkan API key?
- Apakah ada rate limiting?
- Bagaimana cara refresh token jika diperlukan?

### 7. **Error Handling:**

- Format error response yang konsisten
- Status codes yang digunakan
- Pesan error yang user-friendly

## Files yang Perlu Diupdate Setelah Mendapat Info:

1. **lib/services/dify_service.dart** - Update URL dan API key
2. **lib/services/n8n_service.dart** - Update URL dan webhook endpoints
3. **lib/models/dify_models.dart** - Sesuaikan dengan response format
4. **lib/models/n8n_models.dart** - Sesuaikan dengan n8n workflow format
5. **lib/screens/home_screen.dart** - Testing integrasi end-to-end

## Langkah Testing:

1. Pastikan Dify API berjalan
2. Test manual dengan curl/Postman
3. Update konfigurasi di Flutter
4. Test end-to-end dari Flutter ke Dify
5. Integrate dengan n8n jika diperlukan

## Security Considerations:

- Jangan hardcode API key di kode
- Gunakan environment variables
- Implement proper error handling
- Add request timeout
- Validate input/output data

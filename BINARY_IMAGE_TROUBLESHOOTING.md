# 🐛 Troubleshooting Binary Image Display

## Masalah yang Ditemukan

Response dari N8N Image Generator mengembalikan **binary file** (`.jpg`) bukan base64 string, sehingga aplikasi tidak dapat menampilkan gambar.

## 🔧 Solusi yang Diimplementasi

### 1. **Enhanced API Response Handling**

**File**: `lib/services/n8n/prompt_api_service.dart`

```dart
if (response.statusCode == 200) {
  // Check Content-Type header 
  final contentType = response.headers['content-type'] ?? '';
  
  if (contentType.startsWith('image/')) {
    // Binary image response - convert to base64
    final imageBase64 = base64Encode(response.bodyBytes);
    final n8nResponse = N8NModels(
      succes: true,
      chatInput: model,
      response: imageBase64, // Store as base64 string
    );
    return n8nResponse;
  } else {
    // JSON response - parse normally
    return N8NModels.fromJson(json.decode(response.body));
  }
}
```

### 2. **Improved Image Parsing**

**File**: `lib/screens/chatpage_screen.dart`

```dart
Uint8List? _tryParseImageResponse(String response) {
  // Case 1: Pure base64 string (most common)
  if (response.length > 100 && !response.contains('{')) {
    final bytes = base64Decode(response);
    return Uint8List.fromList(bytes);
  }
  
  // Case 2: Data URL format
  // Case 3: JSON wrapped
  // Case 4: Quoted base64
}
```

### 3. **Enhanced Debug Logging**

```dart
print("Response success: ${promptResponse.succes}");
print("Response content type: ${promptResponse.response.runtimeType}");
print("Response length: ${promptResponse.response.length}");
```

## 📋 Format Response yang Didukung

### ✅ Sekarang Didukung:

1. **Binary Image Response** (N8N Img Respond node)
   ```
   Content-Type: image/jpeg
   Body: [binary image data]
   ```

2. **Base64 String** (Pure)
   ```
   "iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB..."
   ```

3. **Data URL Format**
   ```
   "data:image/jpeg;base64,iVBORw0KGgoAAAA..."
   ```

4. **JSON Wrapped**
   ```json
   {"image": "base64_string", "data": "base64_string"}
   ```

## 🔍 Debug Steps

### 1. Check Console Logs
```dart
print("Response success: ${promptResponse.succes}");
print("Response length: ${promptResponse.response.length}");
print("Response preview: ${promptResponse.response.substring(0, 50)}...");
```

### 2. Verify Content-Type
```dart
final contentType = response.headers['content-type'] ?? '';
if (contentType.startsWith('image/')) {
  // Binary image detected
}
```

### 3. Test Image Parsing
```dart
imageData = _tryParseImageResponse(promptResponse.response);
if (imageData != null && imageData.isNotEmpty) {
  print('Image parsed successfully, size: ${imageData.length} bytes');
  isImageGenerated = true;
}
```

## 🎯 Expected Behavior Sekarang

1. **User**: Kirim prompt ke "TSEL-Image-Generator"
2. **N8N**: Return binary image dengan Content-Type: image/jpeg
3. **App**: Detect binary response → Convert to base64
4. **Parser**: Decode base64 → Create Uint8List
5. **UI**: Display image dalam chat bubble

## 🚨 Common Issues & Solutions

### Issue: "Gambar tidak dapat dimuat"
**Solution**: Check console logs untuk error parsing
```dart
print('Error parsing image response: $e');
```

### Issue: Response adalah string tapi bukan gambar
**Solution**: Verify Content-Type header di N8N response

### Issue: Base64 decode error
**Solution**: Check if response contains valid base64 data
```dart
try {
  final bytes = base64Decode(response);
} catch (e) {
  print('Invalid base64: $e');
}
```

## 🛠️ N8N Configuration

Pastikan N8N "Img Respond" node dikonfigurasi dengan:

- **Respond With**: Binary File
- **Response Data Source**: Specify Myself
- **Input Field Name**: data
- **Options**: Set proper Content-Type header

## 📱 Testing

1. Send prompt: "Generate image of a cat"
2. Check logs untuk binary response detection
3. Verify image displays dalam chat bubble
4. Test tap untuk full screen view

Dengan implementasi ini, aplikasi sekarang dapat menampilkan gambar binary dari N8N Image Generator response! 🎉

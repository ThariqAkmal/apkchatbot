# 📄 Flutter PDF Upload Methods Comparison

## 🔄 **Method 1: Multipart Form Data (Seperti Postman)**

### ✅ **Kelebihan:**
- **Sama seperti Postman** - tidak perlu base64 encoding
- **Lebih efisien** - file langsung dikirim sebagai binary
- **Standar web** - format yang umum digunakan di web development
- **Ukuran lebih kecil** - tidak ada overhead base64 (biasanya +33%)

### ❌ **Kekurangan:**
- **Backend harus support multipart** - N8N perlu dikonfigurasi untuk menerima multipart
- **Struktur request berbeda** - bukan JSON murni

### 📝 **Implementasi:**
```dart
// Multipart request - seperti form-data di Postman
var request = http.MultipartRequest('POST', url);
request.fields['model'] = model;
request.fields['prompt'] = prompt;

// File langsung sebagai binary
var multipartFile = http.MultipartFile.fromBytes(
  'file', 
  file.bytes!, 
  filename: file.name
);
request.files.add(multipartFile);
```

---

## 📦 **Method 2: Base64 JSON (Current Implementation)**

### ✅ **Kelebihan:**
- **JSON murni** - mudah diparse di backend
- **Kompatibel luas** - semua backend bisa terima JSON
- **Debugging mudah** - bisa lihat struktur data dengan jelas

### ❌ **Kekurangan:**
- **Ukuran besar** - file bertambah ~33% karena base64 encoding
- **Memory intensive** - perlu load seluruh file ke memory
- **Processing overhead** - encode/decode base64

### 📝 **Implementasi:**
```dart
// Base64 JSON - current method
String base64Data = base64Encode(fileBytes);
Map<String, dynamic> requestBody = {
  'model': model,
  'prompt': prompt,
  'file': {
    'name': file.name,
    'data': base64Data, // File as base64 string
    'type': 'pdf'
  }
};
```

---

## 🚀 **Method 3: Direct Binary Upload**

### ✅ **Kelebihan:**
- **Paling efisien** - file raw binary tanpa encoding
- **Ukuran minimal** - tidak ada overhead sama sekali
- **Streaming support** - bisa upload file besar

### ❌ **Kekurangan:**
- **Backend khusus** - perlu endpoint terpisah untuk file
- **Metadata terpisah** - prompt dan metadata harus dikirim terpisah

### 📝 **Implementasi:**
```dart
// Direct binary upload
var response = await http.put(
  Uri.parse('$url/upload-file'),
  headers: {'Content-Type': 'application/pdf'},
  body: file.bytes,
);
```

---

## 🎯 **Rekomendasi untuk N8N:**

### **Pilihan 1: Multipart Form Data (RECOMMENDED)**
```dart
// Di chatpage_screen.dart, ganti pemanggilan API:
final promptResponse = await _promptApiService.postPromptWithMultipart(
  model: _selectedModel,
  prompt: userMessage,
  file: tempFile,
);
```

**Kenapa?**
- ✅ Seperti Postman - familiar untuk backend developer
- ✅ Efisien - tidak ada base64 overhead
- ✅ N8N support multipart form data
- ✅ File tetap dalam format asli

### **Pilihan 2: Hybrid Approach**
- **File kecil (<1MB)**: gunakan base64 JSON
- **File besar (>1MB)**: gunakan multipart

```dart
if (fileSize < 1024 * 1024) { // < 1MB
  return postPromptWithModel(); // Base64 method
} else {
  return postPromptWithMultipart(); // Multipart method
}
```

---

## 🔧 **Konfigurasi N8N untuk Multipart:**

Di N8N webhook node, pastikan:
1. **Content Type**: `application/x-www-form-urlencoded` atau `multipart/form-data`
2. **Binary Data**: Enable binary data processing
3. **File Field**: Access file dengan `$binary.file`

---

## 📊 **Perbandingan Ukuran:**

| Method | PDF 1MB | PDF 5MB | PDF 10MB |
|--------|---------|---------|----------|
| **Multipart** | 1MB | 5MB | 10MB |
| **Base64** | 1.33MB | 6.67MB | 13.33MB |
| **Binary** | 1MB | 5MB | 10MB |

**Kesimpulan:** Multipart dan Binary lebih efisien untuk file besar.

---

## 🎪 **Testing:**

1. Coba gunakan `postPromptWithMultipart()` 
2. Monitor di N8N apakah file diterima
3. Jika tidak work, fallback ke base64 method
4. Check N8N logs untuk debugging

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Untuk format tanggal (tambahkan di pubspec.yaml jika belum ada)

// Class helper untuk Autentikasi HTTP (Dibutuhkan oleh Google API)
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return _client.send(request);
  }
}

class ScheduleResultScreen extends StatelessWidget {
  final String scheduleResult;

  const ScheduleResultScreen({super.key, required this.scheduleResult});

  // Fungsi utama untuk Ekspor ke Google Calendar
  Future<void> _exportToGoogleCalendar(BuildContext context) async {
    try {
      // 1. Login Google
      final googleSignIn = GoogleSignIn(
        clientId:
            "867542259770-aujo8elrhm2as5osk8ek5tj36mkbl4bo.apps.googleusercontent.com",
        scopes: [calendar.CalendarApi.calendarEventsScope],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User membatalkan login
        return;
      }

      // 2. Ambil Auth Headers
      final authHeaders = await account.authHeaders;

      // 3. Buat Authenticated Client
      final client = GoogleAuthClient(authHeaders);
      final calendarApi = calendar.CalendarApi(client);

      // 4. Parsing Data Jadwal dari Markdown (String)
      // CATATAN: Parsing ini disesuaikan dengan format output AI Anda.
      // Di sini saya contohkan membuat 1 event. Jika ada banyak jadwal, gunakan loop/regex.
      // Misal format AI: "**Judul**: Meeting\n**Waktu**: 10:00
      final eventTitle = _extractTitle(scheduleResult);
      final eventDescription =
          scheduleResult; // Masukkan seluruh hasil sebagai deskripsi
      // Untuk demo, kita set waktu sekarang + 1 jam. Sebaiknya parsing waktu dari string 'scheduleResult'.
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 1));
      final endTime = startTime.add(const Duration(hours: 1));

      // 5. Buat Objek Event
      final event = calendar.Event(
        summary: eventTitle,
        description: eventDescription,
        start: calendar.EventDateTime(
          dateTime: startTime,
          timeZone: "Asia/Jakarta", // Sesuaikan timezone
        ),
        end: calendar.EventDateTime(
          dateTime: endTime,
          timeZone: "Asia/Jakarta",
        ),
      );

      // 6. Insert ke Calendar Primary
      await calendarApi.events.insert(event, 'primary');

      // 7. Notifikasi Sukses
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil diekspor ke Google Calendar!"),
          ),
        );
      }
    } catch (e) {
      print("Error Export Calendar: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ekspor: ${e.toString()}")),
        );
      }
    }
  }

  // Helper sederhana untuk ekstrak judul (Anda bisa buat parser regex yang lebih kompleks)
  String _extractTitle(String markdown) {
    // Coba cari baris pertama yang terlihat seperti judul
    final lines = markdown.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('## '))
        return line.replaceFirst('## ', '').replaceAll('*', '');
      if (line.startsWith('# '))
        return line.replaceFirst('# ', '').replaceAll('*', '');
      if (line.startsWith('**')) return line.replaceAll('*', '');
    }
    return "Jadwal Optimal AI"; // Default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hasil Jadwal Optimal"),
        actions: [
          // TOMBOL EXPORT BARU
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: "Export ke Calendar",
            onPressed: () => _exportToGoogleCalendar(context),
          ),
          // TOMBOL COPY LAMA
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Salin Jadwal",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: scheduleResult));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Jadwal berhasil disalin!")),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // HEADER INFORMASI
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.indigo),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Jadwal ini disusun otomatis oleh AI berdasarkan prioritas Anda.",
                        style: TextStyle(color: Colors.indigo, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // AREA HASIL (MARKDOWN)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Markdown(
                      data: scheduleResult,
                      selectable: true,
                      padding: const EdgeInsets.all(20),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                        h1: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                        h2: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigoAccent,
                        ),
                        tableBorder: TableBorder.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                        tableHeadAlign: TextAlign.center,
                        tablePadding: const EdgeInsets.all(8),
                      ),
                      builders: {'table': TableBuilder()},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // TOMBOL KEMBALI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Buat Jadwal Baru"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TableBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return null;
  }
}

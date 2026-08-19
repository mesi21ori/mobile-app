import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'ethiopian_date.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

class ReportKind {
  const ReportKind(this.id, this.label, {this.hint = ''});
  final String id;
  final String label;
  final String hint;
}

class ReportDoc {
  static Widget button(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: const Text(S.exportDoc),
    );
  }

  static Future<void> share({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? subtitle,
  }) async {
    final base = await PdfGoogleFonts.notoSansEthiopicRegular();
    final bold = await PdfGoogleFonts.notoSansEthiopicBold();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (context) => [
          pw.Text('የሰንበት ትምህርት ቤት', style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.Text('ንብረትና አልባሳት መቆጣጠሪያ', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 16)),
          pw.Text(subtitle ?? 'ቀን: ${EthDate.now().label}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('መረጃ የለም')
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(font: bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F1FE)),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 16),
          pw.Text('ጠቅላላ መስመር: ${rows.length}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
    final bytes = await doc.save();
    const filename = 'senbet-report.pdf';
    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    } on MissingPluginException {
      // Native printing plugin is missing until a full rebuild (not hot restart).
    } catch (_) {}

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
      return;
    } on MissingPluginException {
      // Fall through and save the file locally.
    } catch (_) {}

    if (!kIsWeb) {
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      throw Exception(
        'PDF ተፈጥሯል፣ ግን ማጋራት አልተጫነም። መተግበሪያውን ሙሉ በሙሉ ያቁሙ (Stop) ከዚያ እንደገና Run ያድርጉ። Hot restart በቂ አይደለም።\n${file.path}',
      );
    }
    throw Exception(
      'PDF ማጋራት አልተጫነም። መተግበሪያውን ሙሉ በሙሉ ያቁሙ (Stop) ከዚያ እንደገና Run ያድርጉ።',
    );
  }

  static Future<String?> pickKind(
    BuildContext context, {
    required String title,
    required List<ReportKind> kinds,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          height: 380,
          child: Column(
            children: [
              const Text(
                'የትኛውን ሪፖርት ወደ ሰነድ (PDF) እንደሚልኩ ይምረጡ',
                style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: kinds
                      .map(
                        (k) => ListTile(
                          title: Text(k.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: k.hint.isEmpty ? null : Text(k.hint),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(ctx, k.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(S.cancel)),
        ],
      ),
    );
  }

  static Future<void> run(BuildContext context, Future<void> Function() build) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await build();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showMsg(context, e.toString(), error: true);
        return;
      }
    }
    if (context.mounted) Navigator.pop(context);
  }
}

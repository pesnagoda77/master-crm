import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'share_service.dart';

class PdfService {
  static Future<String> generateMonthlyReport(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    
    final stats = await DatabaseHelper.instance.getFinanceSummaryForPeriod(start, end);
    final appointments = await DatabaseHelper.instance.getAppointmentsForRange(start, end);
    final expenses = await DatabaseHelper.instance.getExpensesForRange(start, end);
    
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy', 'ru').format(start);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Отчет за $monthName',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              _buildSummaryRow('Доход:', stats['income']),
              _buildSummaryRow('Расходы:', stats['expenses']),
              _buildSummaryRow('Материалы:', stats['materials']),
              _buildSummaryRow('Прибыль:', stats['net']),
              _buildSummaryRow('Визитов:', stats['appointmentCount'].toDouble(), isInt: true),
              pw.SizedBox(height: 30),
              pw.Text('Записи', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Дата', 'Клиент', 'Услуга', 'Цена', 'Статус'],
                data: appointments.map((a) => [
                  DateFormat('dd.MM').format(a.dateTime),
                  a.clientName,
                  a.service,
                  '${a.price.toStringAsFixed(0)} ₽',
                  _statusText(a.status),
                ]).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Расходы', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Дата', 'Категория', 'Сумма', 'Примечание'],
                data: expenses.map((e) => [
                  DateFormat('dd.MM').format(DateTime.parse(e.date)),
                  e.category,
                  '${e.amount.toStringAsFixed(0)} ₽',
                  e.notes ?? '',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${year}_${month}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }
  
  static pw.Widget _buildSummaryRow(String label, double value, {bool isInt = false}) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 14))),
        pw.Text(
          isInt ? '${value.toInt()}' : '${NumberFormat('#,###').format(value.toInt())} ₽',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
  
  static String _statusText(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: return 'Запланировано';
        case 1: return 'Выполнено, долг';
        case 2: return 'Выполнено, оплачено';
        case 3: return 'Отменено';
      }
    }
    return 'Неизвестно';
  }
}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../data/models/customer.dart';
import '../../../../../data/models/offer.dart';
import '../../../../../utils/app_constants.dart';

part 'pdf_event.dart';
part 'pdf_state.dart';

class PdfBloc extends Bloc<PdfEvent, PdfState> {
  PdfBloc() : super(PdfInitial()) {
    on<PdfEvent>((event, emit) {});
    on<PdfCreateEvent>(_onCreate);
  }

  Future _onCreate(PdfCreateEvent event, Emitter<PdfState> emit) async {
    emit(PdfCreateInitialState());
    final pw.Font font = await AppConstants().getFont();
    final pw.Font fontRegular = await AppConstants().getFontRegular();
    final pw.MemoryImage logo = await AppConstants().getLogo();
    final pw.MemoryImage kase = await AppConstants().getKase();
    final pw.MemoryImage backgroundImage = await AppConstants().getBackground();
    ///
    DateTime parseDate = DateFormat("yyyy-MM-dd").parse(event.offer[0].createdDate!);
    var inputDate = DateTime.parse(parseDate.toString());
    var outputFormat = DateFormat('dd/MM/yyyy');
    var outputDate = outputFormat.format(inputDate);
    ///
    try {
      var pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: event.offer.length > 1
                    ? pw.Container()
                    : pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xffffffff),
                          image: pw.DecorationImage(
                            image: backgroundImage,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
              );
            },
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.max,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(
                      width: double.infinity,
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.max,
                        children: [
                          pw.SizedBox(child: pw.Image(logo, alignment: pw.Alignment.centerLeft, height: 50)),
                          pw.SizedBox(width: 10),
                          pw.SizedBox(child: pw.Image(kase, alignment: pw.Alignment.centerLeft, height: 50)),
                          pw.Expanded(
                            flex: 20,
                            child: pw.Column(
                              mainAxisSize: pw.MainAxisSize.max,
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text("FİYAT TEKLİF FORMU",
                                    style: pw.TextStyle(fontSize: 12, font: fontRegular), textAlign: pw.TextAlign.right),
                                pw.SizedBox(height: 10),
                                pw.Text(
                                  "Tarih: $outputDate",
                                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(color: PdfColor.fromInt(0xffe0e0e0), height: 0.1, width: double.infinity),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("FİRMA", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text(
                            event.customer.name != null
                                ? event.customer.name!.length > 40
                                    ? '${event.customer.name!.substring(0, 40)}...'
                                    : event.customer.name!
                                : "",
                            style: pw.TextStyle(fontSize: 10, font: font),
                            textAlign: pw.TextAlign.left),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("ADRES", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text(
                            event.customer.address != null
                                ? event.customer.address!.length > 100
                                    ? '${event.customer.address!.substring(0, 100)}...'
                                    : event.customer.address!
                                : " - ",
                            style: pw.TextStyle(fontSize: 10, font: font),
                            textAlign: pw.TextAlign.left),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("E-MAİL", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text(event.customer.email ?? " - ",
                            style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("KONUSU", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("Akaryakıt Satışı", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("SEVK YERİ İL", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text(
                          event.offer[0].destinationCity!.name != null ? event.offer[0].destinationCity!.name!.capitalize() : "",
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("SEVK YERİ İLÇE", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text(
                          event.offer[0].destinationDistrict!.name != null ? event.offer[0].destinationDistrict!.name!.capitalize() : "",
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("SEVK TARİHİ", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                    pw.Expanded(
                      flex: 20,
                      child: pw.Container(
                        color: PdfColor.fromInt(0xfff5f5f5),
                        padding: pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        margin: pw.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 0),
                        child: pw.Text("-", style: pw.TextStyle(fontSize: 10, font: font), textAlign: pw.TextAlign.left),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Padding(
                        padding: pw.EdgeInsets.only(left: 10),
                        child: pw.Text(
                            event.offer.length > 1
                                ? "Sizin için hazırlamış olduğumuz teklifler aşağıda bilgilerinize sunulmuştur."
                                : "Sizin için hazırlamış olduğumuz teklif aşağıda bilgilerinize sunulmuştur.",
                            style: pw.TextStyle(fontSize: 8, font: font))),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  color: PdfColor.fromInt(0xFFF44336),
                  height: 15,
                  width: double.infinity,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 20,
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(left: 10),
                          child: pw.Text("Ürün Tipi",
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: fontRegular,
                                color: PdfColor.fromInt(0xFFFFFFFF),
                              ),
                              textAlign: pw.TextAlign.left),
                        ),
                      ),
                      pw.Expanded(
                        flex: 20,
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(left: 10),
                          child: pw.Text("Vade",
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: fontRegular,
                                color: PdfColor.fromInt(0xFFFFFFFF),
                              ),
                              textAlign: pw.TextAlign.left),
                        ),
                      ),
                      pw.Expanded(
                        flex: 15,
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(left: 10),
                          child: pw.Text("Miktar",
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: fontRegular,
                                color: PdfColor.fromInt(0xFFFFFFFF),
                              ),
                              textAlign: pw.TextAlign.left),
                        ),
                      ),
                      pw.Expanded(
                        flex: 15,
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(left: 10),
                          child: pw.Text("Birim Fiyat",
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: fontRegular,
                                color: PdfColor.fromInt(0xFFFFFFFF),
                              ),
                              textAlign: pw.TextAlign.left),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.ListView.builder(
                  itemCount: event.offer.length,
                  itemBuilder: (context, index) {
                    return pw.Container(
                      padding: pw.EdgeInsets.only(left: 0, right: 0, top: 5, bottom: 5),
                      margin: pw.EdgeInsets.only(left: 0, right: 0, top: 1, bottom: 0),
                      color: index % 2 == 0 ? PdfColor.fromInt(0xfff5f5f5) : PdfColor.fromInt(0xffffffff),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 20,
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(left: 10),
                              child: pw.Text(
                                "Motorin",
                                textAlign: pw.TextAlign.left,
                                style: pw.TextStyle(fontSize: 10, font: font),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 20,
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(left: 10),
                              child: pw.Text(
                                event.offer[index].maturity.toString() == "-1" ? "Kredi Kartı" : "${event.offer[index].maturity} Gün",
                                textAlign: pw.TextAlign.left,
                                style: pw.TextStyle(fontSize: 10, font: font),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 15,
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(left: 10),
                              child: pw.Text(
                                "${NumberFormat.currency(locale: 'tr_TR', decimalDigits: 0, symbol: "").format(int.parse(event.offer[0].liter.toString()))} Lt",
                                textAlign: pw.TextAlign.left,
                                style: pw.TextStyle(fontSize: 10, font: font),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 15,
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(left: 10),
                              child: pw.Text(
                                "${(event.offer[index].totalPrice ?? 0).toStringAsFixed(2).toString().replaceAll(".", ",")} ₺",
                                textAlign: pw.TextAlign.left,
                                style: pw.TextStyle(fontSize: 10, font: font),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                event.offer.length > 1 ? pw.SizedBox(height: 10) : pw.SizedBox(height: 30),
                pw.Text("SATIŞ VE TESLİM KOŞULLARI",
                    style: pw.TextStyle(fontSize: 10, font: fontRegular, color: PdfColor.fromInt(0xFFF44336)),
                    textAlign: pw.TextAlign.left),
                pw.SizedBox(height: 10),
                pw.Text("•  Fiyatlarımıza Nakliye ve KDV Dahildir.",
                    style: pw.TextStyle(fontSize: 8, font: font), textAlign: pw.TextAlign.left),
                pw.Text("•  Teklif tarihinden sonra gelecek indirim veya zamlar tarafınıza yansıtılacaktır.",
                    style: pw.TextStyle(fontSize: 8, font: font), textAlign: pw.TextAlign.left),
                event.offer.length > 1 ? pw.SizedBox(height: 10) : pw.SizedBox(height: 20),
                pw.Text("Bizi tercih ettiğiniz için teşekkür eder",
                    style: pw.TextStyle(fontSize: 8, font: font), textAlign: pw.TextAlign.left),
                pw.Text("iyi çalışmalar dileriz.", style: pw.TextStyle(fontSize: 8, font: font), textAlign: pw.TextAlign.left),
                event.offer.length > 1 ? pw.Container() : pw.SizedBox(height: 40),
                event.offer.length > 1
                    ? pw.Container()
                    : pw.Text("ONAY", style: pw.TextStyle(fontSize: 8, font: fontRegular), textAlign: pw.TextAlign.left),
                event.offer.length > 1
                    ? pw.Container()
                    : pw.Text("KAŞE & İMZA", style: pw.TextStyle(fontSize: 8, font: fontRegular), textAlign: pw.TextAlign.left),
              ],
            );
          },
        ),
      ); // Pag
      Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Teklif.pdf',
        format: PdfPageFormat.a4,
        dynamicLayout: true,
        usePrinterSettings: true,
      );
      emit(PdfCreateSuccessState());
    } catch (e) {
      emit(PdfCreateFailureState(message: e.toString()));
    }
  }
}

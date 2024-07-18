
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/customer.dart';
import '../../../../data/models/offer.dart';
import 'dart:core';

import '../bloc/pdf/pdf_bloc.dart';

BlocBuilder<PdfBloc, PdfState> pdfOpenButton(
  Customer customer,
  List<Offer> offer,
  String buttonName,
  BuildContext context,
) {
  return BlocBuilder<PdfBloc, PdfState>(
    builder: (context, state) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(buttonName, style: TextStyle(color: Colors.white, fontSize: 12)),
        onPressed: () {
          BlocProvider.of<PdfBloc>(context).add(PdfCreateEvent(customer, offer, context));
        },
      );
    },
  );
}

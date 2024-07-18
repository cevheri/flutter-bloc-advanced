part of 'pdf_bloc.dart';

@immutable
abstract class PdfState {}

class PdfInitial extends PdfState {}

class PdfCreateInitialState extends PdfState {}

class PdfCreateSuccessState extends PdfState {}

class PdfCreateFailureState extends PdfState {
  final String message;

  PdfCreateFailureState({required this.message});
}

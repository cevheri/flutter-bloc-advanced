part of 'pdf_bloc.dart';

@immutable
abstract class PdfEvent {}

class PdfCreateEvent extends PdfEvent {
  final BuildContext context;
  final Customer customer;
  final List<Offer> offer;
  PdfCreateEvent(this.customer, this.offer, this.context);
}

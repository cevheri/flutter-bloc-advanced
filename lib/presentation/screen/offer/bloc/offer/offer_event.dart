part of 'offer_bloc.dart';

class OfferEvent extends Equatable {
  const OfferEvent();

  @override
  List<Object> get props => [];
}

class OfferCreate extends OfferEvent {
  const OfferCreate({
    required this.offer,
  });

  final List<Offer> offer;

  @override
  List<Object> get props => [];
}

class OfferStatusUpdate extends OfferEvent {
  const OfferStatusUpdate({
    required this.statusChange,
  });

  final StatusChange statusChange;

  @override
  List<Object> get props => [];
}

class OfferList extends OfferEvent {
  const OfferList({
    // ignore: avoid_unused_constructor_parameters
    required this.startIndex,
    // ignore: avoid_unused_constructor_parameters
    required this.limit,
    // ignore: avoid_unused_constructor_parameters
    this.status,
    // ignore: avoid_unused_constructor_parameters
    this.user,
    // ignore: avoid_unused_constructor_parameters
    this.customer,
  });

  final int startIndex;
  final int limit;
  final Status? status;
  final User? user;
  final Customer? customer;

  @override
  List<Object> get props => [];
}

class OfferSearch extends OfferEvent {
  const OfferSearch({
    required this.startDateTime,
    required this.endDateTime,
    required this.startIndex,
    required this.limit,
    this.user,
  });

  final String startDateTime;
  final String endDateTime;
  final User? user;
  final int startIndex;
  final int limit;

  @override
  List<Object> get props => [];
}

class OfferUpdate extends OfferEvent {
  const OfferUpdate({
    required this.offer,
  });

  final Offer offer;

  @override
  List<Object> get props => [];
}

class OfferUpdateDescription extends OfferEvent {
  const OfferUpdateDescription({
    required this.offer,
  });

  final Offer offer;

  @override
  List<Object> get props => [];
}

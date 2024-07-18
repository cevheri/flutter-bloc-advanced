part of 'offer_bloc.dart';

enum OfferStatus { none, loading, loaded, failure, success }

class OfferState {}

class OfferCreateInitialState extends OfferState {
  OfferCreateInitialState(this.length);

  final int length;
}

class OfferCreateSuccessState extends OfferState {
  OfferCreateSuccessState({
    required this.offer,
  });

  final List<Offer> offer;
}

class OfferCreateFailureState extends OfferState {
  OfferCreateFailureState({required this.message});

  final String message;
}

class OfferStatusUpdateInitialState extends OfferState {}

class OfferStatusUpdateSuccessState extends OfferState {
  OfferStatusUpdateSuccessState({
    required this.offer,
  });

  final Offer offer;
}

class OfferStatusUpdateFailureState extends OfferState {
  OfferStatusUpdateFailureState({required this.message});

  final String message;
}

class OfferListInitialState extends OfferState {}

class OfferListSuccessState extends OfferState {
  OfferListSuccessState({
    required this.offer,
    required this.limit,
    required this.startIndex,
  });

  final List<Offer> offer;
  final int limit;
  final int startIndex;
}

class OfferListFailureState extends OfferState {
  OfferListFailureState({required this.message});

  final String message;
}

class OfferSearchInitialState extends OfferState {}

class OfferSearchSuccessState extends OfferState {
  OfferSearchSuccessState({
    this.user,
    required this.offer,
    required this.pageCounter,
    required this.limit,
    required this.startIndex,
  });

  final int pageCounter;
  final List<Offer> offer;
  final int limit;
  final int startIndex;
  final User? user;
}

class OfferSearchFailureState extends OfferState {
  OfferSearchFailureState({required this.message});

  final String message;
}

class OfferUpdateInitialState extends OfferState {}

class OfferUpdateSuccessState extends OfferState {
  OfferUpdateSuccessState({
    required this.offer,
  });

  final Offer offer;
}

class OfferUpdateFailureState extends OfferState {
  OfferUpdateFailureState({required this.message});

  final String message;
}

class OfferUpdateOfferDescriptionInitialState extends OfferState {}

class OfferUpdateOfferDescriptionSuccessState extends OfferState {
  OfferUpdateOfferDescriptionSuccessState({
    required this.offer,
  });

  final Offer offer;
}

class OfferUpdateOfferDescriptionFailureState extends OfferState {
  OfferUpdateOfferDescriptionFailureState({required this.message});

  final String message;
}

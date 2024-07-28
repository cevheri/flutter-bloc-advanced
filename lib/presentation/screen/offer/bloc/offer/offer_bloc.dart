import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/OfferingConstants.dart';
import 'package:flutter_bloc_advance/data/repository/offer_repository.dart';
import 'package:flutter_bloc_advance/utils/OfferingStatusType.dart';

import '../../../../../data/models/customer.dart';
import '../../../../../data/models/offer.dart';
import '../../../../../data/models/status.dart';
import '../../../../../data/models/status_change.dart';
import '../../../../../data/models/user.dart';

part 'offer_event.dart';
part 'offer_state.dart';

/// Bloc responsible for managing the Offers.
class OfferBloc extends Bloc<OfferEvent, OfferState> {
  OfferBloc({
    required OfferRepository offerRepository,
  })  : _offerRepository = offerRepository,
        super(OfferState()) {
    on<OfferEvent>((event, emit) {});
    on<OfferCreate>(_onCreate);
    on<OfferStatusUpdate>(_onStatusUpdate);
    on<OfferList>(_onList);
    on<OfferSearch>(_onSearch);
    on<OfferUpdateDescription>(_onUpdateOfferDescription);
  }

  final OfferRepository _offerRepository;

  FutureOr<void> _onCreate(OfferCreate event, Emitter<OfferState> emit) async {
    emit(OfferCreateInitialState(event.offer.length));
    List<Offer> finalOffer = [];
    try {
      for (var i = 0; i < event.offer.length; i++) {
        Future.delayed(Duration(milliseconds: 50));
        var offer = await _offerRepository.createOffer(event.offer[i]);
        if (offer == null) {
          emit(OfferCreateFailureState(message: "Teklif oluşturulamadı"));
          return;
        }
        if (OfferingConstants.autoCalculateStatus) {
          finalOffer.add(await autoCalculateStatusChange(offer, emit));
        }
      }
      emit(OfferCreateSuccessState(offer: finalOffer));
    } catch (e) {
      emit(OfferCreateFailureState(message: e.toString()));
    }
  }

  Future<Offer> autoCalculateStatusChange(Offer offer, Emitter<OfferState> emit) async {
    Future.delayed(Duration(milliseconds: 50));
    var calculatedOffer = await _offerRepository.updateOfferStatus(StatusChange(
      offeringId: offer.id,
      statusId: OfferingStatusType.CALCULATED,
      comment: OfferingStatusType.CALCULATED_DEFAULT_COMMENT,
    ));
    if (calculatedOffer == null) {
      emit(OfferCreateFailureState(message: "Teklif Hesaplanamadı"));
    }
    return calculatedOffer!;
  }

  FutureOr<void> _onStatusUpdate(OfferStatusUpdate event, Emitter<OfferState> emit) async {
    emit(OfferStatusUpdateInitialState());
    try {
      var offer = await _offerRepository.updateOfferStatus(event.statusChange);
      emit(OfferStatusUpdateSuccessState(offer: offer!));
    } catch (e) {
      emit(OfferStatusUpdateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onList(OfferList event, Emitter<OfferState> emit) async {
    emit(OfferListInitialState());
    try {
      var offer = await _offerRepository.getOffers(
        limit: event.limit,
        startIndex: event.startIndex,
      );
      emit(OfferListSuccessState(
        offer: offer,
        limit: event.limit,
        startIndex: event.startIndex,
      ));
    } catch (e) {
      emit(OfferListFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onSearch(OfferSearch event, Emitter<OfferState> emit) async {
    emit(OfferSearchInitialState());
    try {
      if (event.user?.id == 0 || event.user == null) {
        var pageCounter = await _offerRepository.getOffersHeaders();
        var offer = await _offerRepository.getOffers(
          limit: event.limit,
          startIndex: event.startIndex,
        );
        emit(OfferSearchSuccessState(
          offer: offer,
          pageCounter: pageCounter,
          limit: event.limit,
          startIndex: event.startIndex,
          user: event.user,
        ));
        return;
      }
      //user dolu ise
      else {
        var pageCounter = await _offerRepository.getOffersHeaders();
        var offer = await _offerRepository.getOffersWithUser(event.user!, limit: event.limit, startIndex: event.startIndex);
        emit(OfferSearchSuccessState(
            offer: offer, pageCounter: pageCounter, limit: event.limit, startIndex: event.startIndex, user: event.user));
        return;
      }
    } catch (e) {
      emit(OfferSearchFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onUpdateOfferDescription(OfferUpdateDescription event, Emitter<OfferState> emit) async {
    emit(OfferUpdateOfferDescriptionInitialState());
    try {
      var result = await _offerRepository.updateOffer(event.offer);
      emit(OfferUpdateOfferDescriptionSuccessState(offer: result ?? Offer()));
    } catch (e) {
      emit(OfferUpdateOfferDescriptionFailureState(message: e.toString()));
    }
  }
}

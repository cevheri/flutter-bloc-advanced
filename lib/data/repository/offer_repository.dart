import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';

import '../../presentation/screen/offer/offer_screen_const.dart';
import '../http_utils.dart';
import '../models/offer.dart';
import '../models/status_change.dart';
import '../models/user.dart';

/// offer repository
///
/// This class is responsible for all the offer related operations
/// list, create, update, delete etc.
class OfferRepository {
  /// Retrieve all offers method that retrieves all the offers

  Future<List<Offer>> getOffers({
    required int startIndex,
    required int limit,
  }) async {
    ConstOfferStationMaturity.statusList = [
      ConstOfferStationMaturity.calculatedOfferSelectedValue == true
          ? "statusId.in=12&"
          : "",
      ConstOfferStationMaturity.approvedOfferSelectedValue == true
          ? "statusId.in=3&"
          : "", // buna geri çekildi de eklenecek.
      ConstOfferStationMaturity.cancelledOfferSelectedValue == true
          ? "statusId.in=2&"
          : "",
      ConstOfferStationMaturity.rejectOfferSelectedValue == true
          ? "statusId.in=4&"
          : "",
      ConstOfferStationMaturity.confirmationOfferSelectedValue == true
          ? "statusId.in=9&"
          : "",
      ConstOfferStationMaturity.completedOfferSelectedValue == true
          ? "statusId.in=11&"
          : "",
    ];
    ConstOfferStationMaturity.urlString =
        ConstOfferStationMaturity.statusList[0].toString() +
            ConstOfferStationMaturity.statusList[1].toString() +
            ConstOfferStationMaturity.statusList[2].toString() +
            ConstOfferStationMaturity.statusList[3].toString() +
            ConstOfferStationMaturity.statusList[4].toString() +
            ConstOfferStationMaturity.statusList[5].toString();
    //final offersHeaderRequest = await HttpUtils.getRequestHeader("/offerings?createdDate.greaterThanOrEqual=${ConstOfferStationMaturity.startDate}&createdDate.lessThanOrEqual=${ConstOfferStationMaturity.endDate}&${ConstOfferStationMaturity.urlString}page=$startIndex&size=$limit&sort=id%2Cdesc");

    // ConstOfferStationMaturity.page = offersHeaderRequest;
    //final offersRequest = await HttpUtils.getRequest("/offerings?createdDate.greaterThanOrEqual=${ConstOfferStationMaturity.startDate}&createdDate.lessThanOrEqual=${ConstOfferStationMaturity.endDate}&${ConstOfferStationMaturity.urlString}page=$startIndex&size=$limit&sort=id%2Cdesc");
    return JsonMapper.deserialize<List<Offer>>(
        await rootBundle.loadString('mock/offers.json'))!;
  }


  Future<int> getOffersHeaders([int startIndex = 0, int limit = 10]) async {
    final offersRequest = await HttpUtils.getRequestHeader(
        "/offerings?createdDate.greaterThanOrEqual=${ConstOfferStationMaturity.startDate}&createdDate.lessThanOrEqual=${ConstOfferStationMaturity.endDate}&${ConstOfferStationMaturity.urlString}page=0&size=10&sort=id%2Cdesc");

    return offersRequest;
  }

  /// Retrieve all offer with User method that retrieves all the offers
  Future<List<Offer>> getOffersWithUser(User user,
      {required int startIndex, required int limit}) async {
    ConstOfferStationMaturity.statusList = [
      ConstOfferStationMaturity.calculatedOfferSelectedValue == true
          ? "statusId.in=12&"
          : "",
      ConstOfferStationMaturity.approvedOfferSelectedValue == true
          ? "statusId.in=3&"
          : "", // buna geri çekildi de eklenecek.
      ConstOfferStationMaturity.cancelledOfferSelectedValue == true
          ? "statusId.in=2&"
          : "",
      ConstOfferStationMaturity.rejectOfferSelectedValue == true
          ? "statusId.in=4&"
          : "",
      ConstOfferStationMaturity.confirmationOfferSelectedValue == true
          ? "statusId.in=9&"
          : "",
      ConstOfferStationMaturity.completedOfferSelectedValue == true
          ? "statusId.in=11&"
          : "",
    ];
    ConstOfferStationMaturity.urlString =
        ConstOfferStationMaturity.statusList[0].toString() +
            ConstOfferStationMaturity.statusList[1].toString() +
            ConstOfferStationMaturity.statusList[2].toString() +
            ConstOfferStationMaturity.statusList[3].toString() +
            ConstOfferStationMaturity.statusList[4].toString() +
            ConstOfferStationMaturity.statusList[5].toString();
    final offersHeaderRequest = await HttpUtils.getRequestHeader(
        "/offerings?createdDate.greaterThanOrEqual=${ConstOfferStationMaturity.startDate}&createdDate.lessThanOrEqual=${ConstOfferStationMaturity.endDate}&${ConstOfferStationMaturity.urlString}createdBy.equals=${user.login}&page=0&size=10&sort=id%2Cdesc");
    print(offersHeaderRequest);
    print(user.login);
    ConstOfferStationMaturity.page = offersHeaderRequest;

    final offersRequest = await HttpUtils.get(
        "/offerings?createdDate.greaterThanOrEqual=${ConstOfferStationMaturity.startDate}&createdDate.lessThanOrEqual=${ConstOfferStationMaturity.endDate}&${ConstOfferStationMaturity.urlString}createdBy.equals=${user.login}&page=0&size=10&sort=id%2Cdesc");
    return JsonMapper.deserialize<List<Offer>>(offersRequest)!;
  }

  /// Create offer method that creates a new offer
  ///
  /// @param offer the offer object
  Future<Offer?> createOffer(Offer offer) async {
    //api/offerings
    final saveRequest = await HttpUtils.postRequest<Offer>("/offerings", offer);
    String? result;

    if (saveRequest.statusCode != 201) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result == HttpUtils.successResult
        ? JsonMapper.deserialize<Offer>(saveRequest.body)
        : null;
  }

  /// Update offer method that updates a offer
  ///
  ///  @param offer the offer object
  Future<Offer?> updateOfferStatus(StatusChange statusChange) async {
    final saveRequest = await HttpUtils.postRequest<StatusChange>(
        "/offerings/${statusChange.offeringId}/change-status", statusChange);
    String? result;
    if (saveRequest.statusCode != 200) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result == HttpUtils.successResult
        ? JsonMapper.deserialize<Offer>(saveRequest.body)
        : Offer();
  }

  /// Update offer method that updates a offer
  ///
  /// @param offer the offer object
  Future<Offer?> updateOffer(Offer offer) async {
    final saveRequest =
        await HttpUtils.patchRequest<Offer>("/offerings/${offer.id}", offer);
    String? result;

    if (saveRequest.statusCode != 200) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }
    return result == HttpUtils.successResult
        ? JsonMapper.deserialize<Offer>(saveRequest.body)
        : null;
  }
}

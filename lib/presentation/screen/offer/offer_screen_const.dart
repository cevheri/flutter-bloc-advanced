import 'package:flutter/material.dart';

import '../../../data/models/corporation.dart';
import '../../../data/models/corporation_maturity.dart';
import '../../../data/models/refinery.dart';
import '../../../data/models/station.dart';
import '../../../data/models/station_maturity.dart';

class ConstOfferStationMaturity {
  static Refinery refinery = Refinery();
  static Corporation corporation = Corporation();
  static List<CorporationMaturity> corporationMaturity = [];
  static Station station = Station();
  static StationMaturity stationMaturity = StationMaturity();
  static List<String> statusList = [];
  static String urlString = "";
  static bool rejectOfferSelectedValue = false;
  static bool completedOfferSelectedValue = false;
  static bool approvedOfferSelectedValue = false;
  static bool confirmationOfferSelectedValue = false;
  static bool calculatedOfferSelectedValue = false;
  static bool cancelledOfferSelectedValue = false;
  static String startDate = "${DateTime.now().subtract(Duration(days: 7)).toIso8601String().replaceAll(":", "%3A")}Z";
  static String endDate = "${DateTime.now().toIso8601String().replaceAll(":", "%3A")}Z";
  static int page = 0;

  static List<StationMaturity> stationMaturityAllList = [];
  static double stationRate = 0;
  static int stationMaturityId = 0;
  static int selectCorporationId = 0;


  void stationRateCalc(int stationMaturity) {
    int counter = 0;
    for (var i = 0; i < ConstOfferStationMaturity.stationMaturityAllList.length; i++) {
      if (ConstOfferStationMaturity.stationMaturityAllList[i].maturity == stationMaturity) {
        ConstOfferStationMaturity.stationMaturityId = ConstOfferStationMaturity.stationMaturityAllList[i].maturity!;
        ConstOfferStationMaturity.stationRate = ConstOfferStationMaturity.stationMaturityAllList[i].rate!;
        ConstOfferStationMaturity.stationMaturity = ConstOfferStationMaturity.stationMaturityAllList[i];
        counter = counter + 1;
      }
    }
    if (counter == 0) {
      for (var i = 0; i < ConstOfferStationMaturity.stationMaturityAllList.length; i++) {
        if (ConstOfferStationMaturity.stationMaturityAllList[i].maturity! > stationMaturity) {
          ConstOfferStationMaturity.stationMaturityId = ConstOfferStationMaturity.stationMaturityAllList[i].maturity!;
          ConstOfferStationMaturity.stationRate = ConstOfferStationMaturity.stationMaturityAllList[i].rate!;
          ConstOfferStationMaturity.stationMaturity = ConstOfferStationMaturity.stationMaturityAllList[i];
          break;
        }
      }
    }
  }
}

class RowWidget extends StatelessWidget {
  const RowWidget({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 0),
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(width: 50),
            Expanded(
              flex: 3,
              child: Text(
                content,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(width: 0),
          ],
        ),
      ],
    );
  }
}

BoxDecoration backColor(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return BoxDecoration(color: Colors.black26);
  } else {
    return BoxDecoration(color: Colors.blueGrey[50]);
  }
}

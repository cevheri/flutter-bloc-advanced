import '../../../data/models/maturity.dart';
import '../../../data/models/station_maturity.dart';

class ConstStationMaturity {
  static List<Maturity> maturityAllList = [];
  static List<Maturity> maturityRemainderList = [];
  static List<int> stationMaturityTypeList = [];
}

void maturityRemainderCalc(List<StationMaturity> stationMaturity) {
  ConstStationMaturity.maturityRemainderList = [];
  ConstStationMaturity.stationMaturityTypeList =
      stationMaturity.map((e) => e.maturity).toSet().toList().cast<int>();
  for (var i = -1; i < 181; i++) {
    if (ConstStationMaturity.stationMaturityTypeList.indexOf(i) != -1) {
    } else {
      if (i == 0) {
      } else if (i == -1)
        ConstStationMaturity.maturityRemainderList
            .add(Maturity(name: "Kredi Kartı", type: i));
      else
        ConstStationMaturity.maturityRemainderList
            .add(Maturity(name: "$i Gün", type: i));
    }
  }
}

void maturityUsedCalc(StationMaturity stationMaturity) {
  ConstStationMaturity.maturityAllList = [];
  ConstStationMaturity.stationMaturityTypeList = [];
  for (var i = -1; i < 181; i++) {
    if (i == 0) {
    } else if (i == -1)
      ConstStationMaturity.maturityAllList
          .add(Maturity(name: "Kredi Kartı", type: i));
    else
      ConstStationMaturity.maturityAllList
          .add(Maturity(name: "$i Gün", type: i));
  }
}

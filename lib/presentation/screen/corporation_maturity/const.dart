import '../../../data/models/maturity.dart';
import '../../../data/models/corporation_maturity.dart';

class ConstCorporationMaturity {
  static List<Maturity> maturityAllList = [];
  static List<Maturity> maturityRemainderList = [];
  static List<int> corporationMaturityTypeList = [];
}

void maturityRemainderCalc(List<CorporationMaturity> corporationMaturity) {
  ConstCorporationMaturity.maturityRemainderList = [];
  ConstCorporationMaturity.corporationMaturityTypeList =
      corporationMaturity.map((e) => e.maturity).toSet().toList().cast<int>();
  for (var i = -1; i < 181; i++) {
    if (ConstCorporationMaturity.corporationMaturityTypeList.indexOf(i) != -1) {
    } else {
      if (i == 0) {
      } else if (i == -1)
        ConstCorporationMaturity.maturityRemainderList
            .add(Maturity(name: "Kredi Kartı", type: i));
      else
        ConstCorporationMaturity.maturityRemainderList
            .add(Maturity(name: "$i Gün", type: i));
    }
  }
}


void maturityUsedCalc(CorporationMaturity corporationMaturity) {
  ConstCorporationMaturity.maturityAllList = [];
  ConstCorporationMaturity.corporationMaturityTypeList = [];
  for (var i = -1; i < 181; i++) {
    if (i == 0) {
    } else if (i == -1)
      ConstCorporationMaturity.maturityAllList
          .add(Maturity(name: "Kredi Kartı", type: i));
    else
      ConstCorporationMaturity.maturityAllList
          .add(Maturity(name: "$i Gün", type: i));
  }
}

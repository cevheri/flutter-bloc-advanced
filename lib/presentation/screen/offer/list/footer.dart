import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/offer/offer_bloc.dart';
import '../offer_screen_const.dart';
import 'list_widget.dart';

class OfferListFooterWidget extends StatelessWidget {
  final OfferSearchSuccessState state;

  const OfferListFooterWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    int pageCount = ConstOfferStationMaturity.page ~/ 10;
    return pageCount != 0
        ? Padding(
            padding: const EdgeInsets.all(30.0),
            child: Container(
              decoration: BoxDecoration(
                color: buildTableRowDecoration(0, context).color,
              ),
              height: 75,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Toplam: ${pageCount} sayfa içerisinde ${state.startIndex + 1}. sayfayı görmektesiniz.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      itemCount: pageCount,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              if (index == state.startIndex) {
                                return;
                              }
                              BlocProvider.of<OfferBloc>(context).add(
                                OfferSearch(
                                  startDateTime: ConstOfferStationMaturity.startDate,
                                  endDateTime: ConstOfferStationMaturity.endDate,
                                  user: state.user,
                                  limit: state.limit,
                                  startIndex: index,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: index == state.startIndex ? Color(0xFF8498aa) : Colors.blueGrey[50],
                                border: Border.all(
                                  color: index == state.startIndex ? Color(0xFF8498aa) : Colors.blueGrey[200]!,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              height: 20,
                              width: 25,
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: index == state.startIndex ? Colors.white : Color(0xFF006783),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../../data/repository/maturity_calculate.dart';

part 'maturity_calculate_event.dart';
part 'maturity_calculate_state.dart';




class MaturityCalculateBloc extends Bloc<MaturityCalculateEvent, MaturityCalculateState> {
  MaturityCalculateBloc({
    required MaturityCalculateRepository maturityCalculateRepository,
  })  : _maturityCalculateRepository = maturityCalculateRepository,
        super(MaturityCalculateState()) {
    on<MaturityCalculateEvent>((event, emit) {});

  }

  final MaturityCalculateRepository _maturityCalculateRepository;
}


  


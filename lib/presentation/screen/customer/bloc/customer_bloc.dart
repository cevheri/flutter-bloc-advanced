import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/customer.dart';
import '../../../../data/repository/customer_repository.dart';

part 'customer_event.dart';
part 'customer_state.dart';

/// Bloc responsible for managing the Customers.
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc({
    required CustomerRepository customerRepository,
  })  : _customerRepository = customerRepository,
        super(CustomerState()) {
    on<CustomerEvent>((event, emit) {});
    on<CustomerSearch>(_onSearch);
  }

  final CustomerRepository _customerRepository;



  FutureOr<void> _onSearch(CustomerSearch event, Emitter<CustomerState> emit) async {
    emit(CustomerFindInitialState());
    try {
      if (event.name == "") {
        List<Customer> customer =
            await _customerRepository.listCustomer(0,100);
        emit(CustomerSearchSuccessState(customerList: customer));
      }
      if(event.name != ""){
        List<Customer> customer = await _customerRepository.findCustomerByName(event.name);
        emit(CustomerSearchSuccessState(customerList: customer));
      }

    } catch (e) {
      emit(CustomerSearchFailureState(message: e.toString()));
    }
  }
}

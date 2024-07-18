part of 'customer_bloc.dart';

enum CustomerStatus { initial, loading, success, failure }

class CustomerState {
  final Customer? customer;
  final CustomerStatus status;

  const CustomerState({
    this.customer,
    this.status = CustomerStatus.initial,
  });

  CustomerState copyWith({
    Customer? customer,
    CustomerStatus? status,
  }) {
    return CustomerState(status: status ?? this.status, customer: customer ?? this.customer);
  }
}

class CustomerInitialState extends CustomerState {}

class CustomerFindInitialState extends CustomerState {}

class CustomerLoadInProgressState extends CustomerState {}

class CustomerLoadSuccessState extends CustomerState {
  final Customer customer;

  const CustomerLoadSuccessState({required this.customer});
}

class CustomerSearchSuccessState extends CustomerState {
  final List<Customer> customerList;

  const CustomerSearchSuccessState({required this.customerList});
}

class CustomerLoadFailureState extends CustomerState {
  final String message;

  const CustomerLoadFailureState({required this.message});
}

class CustomerSearchFailureState extends CustomerState {
  final String message;

  const CustomerSearchFailureState({required this.message});
}

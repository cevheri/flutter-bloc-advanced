part of 'customer_bloc.dart';

class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class CustomerSearch extends CustomerEvent {

  final String name;

  const CustomerSearch(

    this.name,
  );
}

class CustomerCreate extends CustomerEvent {
  const CustomerCreate({
    required this.customer,
  });

  final Customer customer;

  @override
  List<Object> get props => [customer];
}

class CustomerUpdate extends CustomerEvent {
  const CustomerUpdate({
    required this.customer,
  });

  final Customer customer;

  @override
  List<Object> get props => [customer];
}

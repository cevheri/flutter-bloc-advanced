part of 'sales_people_bloc.dart';

class SalesPersonEvent extends Equatable {
  const SalesPersonEvent();

  @override
  List<Object> get props => [];
}

class SalesPersonLoad extends SalesPersonEvent {
  const SalesPersonLoad();

  @override
  List<Object> get props => [];
}

class SalesPersonLoadDefault extends SalesPersonEvent {
  const SalesPersonLoadDefault();

  @override
  List<Object> get props => [];
}

class SalesPersonEditAuthority extends SalesPersonEvent {
  const SalesPersonEditAuthority({
    required this.getSalesPersonId,
  });

  final String getSalesPersonId;

  @override
  List<Object> get props => [getSalesPersonId];
}

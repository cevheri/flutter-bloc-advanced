part of 'price_bloc.dart';

@immutable
abstract class PriceState {}

class PriceInitial extends PriceState {}

class PriceUpdatedInitial extends PriceState {}
class PriceUpdatedSuccess extends PriceState {
  final double price;

  PriceUpdatedSuccess(this.price);
}

class PriceUpdatedFailure extends PriceState {
  final String message;

  PriceUpdatedFailure(this.message);
}
part of 'price_bloc.dart';

@immutable
abstract class PriceEvent {}

class PriceUpdateEvent extends PriceEvent {
  final double price;

  PriceUpdateEvent(this.price);
}
part of 'drawer_bloc.dart';

class DrawerState extends Equatable {
  final bool isLogout;

  const DrawerState({
    this.isLogout = false,
  });

  DrawerState copyWith({
    bool? isLogout,
  }) {
    return DrawerState(
      isLogout: isLogout ?? this.isLogout,
    );
  }

  @override
  List<Object> get props => [isLogout];

  @override
  bool get stringify => true;
}

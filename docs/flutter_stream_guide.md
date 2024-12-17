# Flutter StreamSubscription Usage Guide

This guide covers the correct usage of `StreamSubscription` in Flutter, along with best practices and examples for various use cases.

---

## 1. Basic Stream Subscription Pattern

Understanding the basics of stream subscriptions is crucial for Flutter developers because streams are at the heart of asynchronous programming in Flutter. Whether you are listening for real-time updates, user interactions, or managing complex data streams, knowing how to properly use and manage subscriptions will help you write clean, efficient, and bug-free applications.

```dart
late StreamSubscription<DataType> subscription;

subscription = context.stream.listen((data) {
    // Handle data
  },
  onError: (error) {
    // Handle error
  },
  onDone: () {
    // Handle completion
  },
);

subscription.cancel(); // Cancel when done
```

- **`onError`**: Handles any errors that occur during the stream.
- **`onDone`**: Called when the stream finishes.
- **`cancel()`**: Always cancel the subscription to prevent memory leaks.

---

## 2. Using StreamSubscription in a StatefulWidget

Ensure you cancel the subscription in the `dispose` method.

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final StreamSubscription<DataType> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // Prevent memory leaks
    super.dispose();
  }
}
```

---

## 3. Common Use Cases

### 3.1 Firebase Realtime Updates

Listen to Firestore real-time updates using `StreamSubscription`:

```dart
late StreamSubscription<QuerySnapshot> _firebaseSubscription;

void listenToFirestore() {
  _firebaseSubscription = FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .listen((snapshot) {
        // Handle realtime updates
      });
}
```

---

### 3.2 WebSocket Connection

Handle WebSocket streams with error and completion listeners:

```dart
late StreamSubscription<dynamic> _socketSubscription;

void connectToWebSocket() {
  final socket = WebSocketChannel.connect(Uri.parse('wss://your-socket-url'));

  _socketSubscription = socket.stream.listen(
    (data) {
      // Handle incoming data
    },
    onError: (error) => print('Error: $error'),
    onDone: () => print('Connection closed'),
  );
}
```

---

### 3.3 Location Updates

Track location updates with `Geolocator`:

```dart
late StreamSubscription<Position> _locationSubscription;

void trackLocation() {
  _locationSubscription = Geolocator.getPositionStream().listen(
    (Position position) {
      // Handle location updates
    },
  );
}
```

---

## 4. Advanced Usage with BLoC Pattern

### Events

```dart
abstract class UserEvent {}
class FetchUserData extends UserEvent {}
class UpdateUserData extends UserEvent {
  final User user;
  UpdateUserData(this.user);
}
```

### States

```dart
abstract class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final User user;
  UserLoaded(this.user);
}
class UserError extends UserState {
  final String error;
  UserError(this.error);
}
```

### BLoC Implementation

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _repository;

  UserBloc({required UserRepository repository})
      : _repository = repository,
        super(UserInitial()) {
    on<FetchUserData>(_onFetchUser);
    on<UpdateUserData>(_onUpdateUser);
  }

  Future<void> _onFetchUser(FetchUserData event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await _repository.getUser();
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUserData event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      await _repository.updateUser(event.user);
      emit(UserLoaded(event.user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

---

### Using StreamSubscription with BLoC

```dart
class UserScreen extends StatefulWidget {
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late StreamSubscription<UserState> _userSubscription;

  @override
  void initState() {
    super.initState();
    _setupUserSubscription();
  }

  void _setupUserSubscription() {
    _userSubscription = context.read<UserBloc>().stream.listen(
      (userState) {
        if (userState is UserLoaded) {
          _handleUserLoaded(userState.user);
        } else if (userState is UserError) {
          _showError(userState.error);
        }
      },
    );
  }

  void _handleUserUpdate(User user) {
    late StreamSubscription<UserState> updateSubscription;

    context.read<UserBloc>().add(UpdateUserData(user));
    updateSubscription = context.read<UserBloc>().stream.listen((state) {
      if (state is UserLoaded) {
        context.read<ProfileBloc>().add(RefreshProfile());
        updateSubscription.cancel(); // Cancel after handling
      }
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Container(); // Build UI based on state
      },
    );
  }
}
```

---

## 5. Best Practices

### StreamSubscription Checklist

1. **Always Cancel Subscriptions**
    - ✅ Cancel subscriptions in `dispose()` for `StatefulWidgets`.
    - ✅ Use `cancel()` after one-time operations to prevent memory leaks.

2. **Error Handling**
    - ✅ Add `onError` listeners to handle errors gracefully.
    - ✅ Show user-friendly error messages and log errors appropriately.

3. **State Management**
    - ✅ Use clear state classes, such as `Loading`, `Loaded`, and `Error`.
    - ✅ Properly display loading indicators and handle error states in the UI.

4. **Context Safety**
    - ✅ Check `mounted` before accessing `context` in asynchronous callbacks.
    - ✅ Cancel subscriptions during lifecycle events like widget disposal.

5. **Memory Management**
    - ✅ Avoid creating unnecessary subscriptions.
    - ✅ Clean up subscriptions to prevent memory leaks.

---

This guide ensures effective and clean usage of `StreamSubscription` in Flutter applications, particularly when integrating with Firebase, WebSockets, location services, or state management libraries like BLoC.

Experiment with these examples in your own projects and remember to adopt the best practices discussed here to build robust and efficient applications. Happy coding!

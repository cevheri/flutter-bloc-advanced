/// Circuit breaker states following the standard state machine pattern.
enum CircuitBreakerState { closed, open, halfOpen }

/// A per-endpoint circuit breaker that prevents cascading failures.
///
/// State machine:
/// ```
/// CLOSED ──(failures >= threshold)──► OPEN
/// OPEN ──(cooldown elapsed)──► HALF_OPEN
/// HALF_OPEN ──(probe succeeds)──► CLOSED
/// HALF_OPEN ──(probe fails)──► OPEN
/// ```
///
/// Pure Dart class with no Flutter dependencies.
class CircuitBreaker {
  /// Number of consecutive failures before the circuit opens.
  final int failureThreshold;

  /// How long the circuit stays open before allowing a probe request.
  final Duration cooldownDuration;

  CircuitBreaker({this.failureThreshold = 5, this.cooldownDuration = const Duration(seconds: 30)});

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  /// Current state of the circuit breaker.
  CircuitBreakerState get state {
    if (_state == CircuitBreakerState.open && _cooldownElapsed) {
      _state = CircuitBreakerState.halfOpen;
    }
    return _state;
  }

  /// Whether a request is allowed to proceed.
  ///
  /// - [closed]: always allows requests.
  /// - [open]: blocks requests until cooldown elapses, then transitions to [halfOpen].
  /// - [halfOpen]: allows exactly one probe request.
  bool get allowRequest {
    switch (state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        return false;
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  /// Record a successful request. Resets the circuit to [closed].
  void recordSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
  }

  /// Record a failed request. May transition to [open] if threshold is reached.
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitBreakerState.halfOpen) {
      // Probe failed — reopen the circuit.
      _state = CircuitBreakerState.open;
    } else if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// Reset the circuit breaker to its initial [closed] state.
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
  }

  /// The number of consecutive failures recorded.
  int get failureCount => _failureCount;

  /// The time of the last recorded failure.
  DateTime? get lastFailureTime => _lastFailureTime;

  bool get _cooldownElapsed {
    if (_lastFailureTime == null) return true;
    return DateTime.now().difference(_lastFailureTime!) >= cooldownDuration;
  }
}

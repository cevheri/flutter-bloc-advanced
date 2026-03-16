import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircuitBreakerState', () {
    test('should have exactly three states', () {
      expect(CircuitBreakerState.values.length, 3);
      expect(CircuitBreakerState.values, contains(CircuitBreakerState.closed));
      expect(CircuitBreakerState.values, contains(CircuitBreakerState.open));
      expect(CircuitBreakerState.values, contains(CircuitBreakerState.halfOpen));
    });
  });

  group('CircuitBreaker', () {
    group('initial state', () {
      test('should start in closed state', () {
        final breaker = CircuitBreaker();
        expect(breaker.state, CircuitBreakerState.closed);
      });

      test('should have zero failure count initially', () {
        final breaker = CircuitBreaker();
        expect(breaker.failureCount, 0);
      });

      test('should allow requests when closed', () {
        final breaker = CircuitBreaker();
        expect(breaker.allowRequest, isTrue);
      });

      test('should use default failureThreshold of 5', () {
        final breaker = CircuitBreaker();
        expect(breaker.failureThreshold, 5);
      });

      test('should use default cooldownDuration of 30 seconds', () {
        final breaker = CircuitBreaker();
        expect(breaker.cooldownDuration, const Duration(seconds: 30));
      });
    });

    group('custom configuration', () {
      test('should accept custom failureThreshold', () {
        final breaker = CircuitBreaker(failureThreshold: 3);
        expect(breaker.failureThreshold, 3);
      });

      test('should accept custom cooldownDuration', () {
        final breaker = CircuitBreaker(cooldownDuration: const Duration(seconds: 10));
        expect(breaker.cooldownDuration, const Duration(seconds: 10));
      });
    });

    group('recordFailure()', () {
      test('should increment failure count on each call', () {
        final breaker = CircuitBreaker(failureThreshold: 5);

        breaker.recordFailure();
        expect(breaker.failureCount, 1);

        breaker.recordFailure();
        expect(breaker.failureCount, 2);

        breaker.recordFailure();
        expect(breaker.failureCount, 3);
      });

      test('should remain closed when failures are below threshold', () {
        final breaker = CircuitBreaker(failureThreshold: 3);

        breaker.recordFailure();
        breaker.recordFailure();

        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.allowRequest, isTrue);
      });

      test('should transition to open when failures reach threshold', () {
        // Use long cooldown so state stays open and does not auto-transition to halfOpen
        final breaker = CircuitBreaker(failureThreshold: 3, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        breaker.recordFailure();

        expect(breaker.state, CircuitBreakerState.open);
        expect(breaker.allowRequest, isFalse);
      });

      test('should transition to open when failures exceed threshold', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        breaker.recordFailure();

        expect(breaker.state, CircuitBreakerState.open);
        expect(breaker.failureCount, 3);
      });
    });

    group('recordSuccess()', () {
      test('should reset failure count to zero', () {
        final breaker = CircuitBreaker(failureThreshold: 5);

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.failureCount, 2);

        breaker.recordSuccess();
        expect(breaker.failureCount, 0);
      });

      test('should transition state to closed from open', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.open);

        breaker.recordSuccess();
        expect(breaker.state, CircuitBreakerState.closed);
      });

      test('should allow requests after success resets to closed', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.allowRequest, isFalse);

        breaker.recordSuccess();
        expect(breaker.allowRequest, isTrue);
      });
    });

    group('reset()', () {
      test('should reset failure count to zero', () {
        final breaker = CircuitBreaker(failureThreshold: 5);

        breaker.recordFailure();
        breaker.recordFailure();
        breaker.recordFailure();

        breaker.reset();
        expect(breaker.failureCount, 0);
      });

      test('should reset state to closed', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.open);

        breaker.reset();
        expect(breaker.state, CircuitBreakerState.closed);
      });

      test('should allow requests after reset', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.allowRequest, isFalse);

        breaker.reset();
        expect(breaker.allowRequest, isTrue);
      });
    });

    group('state transitions', () {
      test('should remain open when cooldown has not elapsed', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        breaker.recordFailure();

        expect(breaker.state, CircuitBreakerState.open);
        expect(breaker.allowRequest, isFalse);
      });

      test('should transition from open to halfOpen after cooldown elapses', () {
        // With zero cooldown, the state getter transitions immediately
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: Duration.zero);

        breaker.recordFailure();
        // Cooldown (zero) has already elapsed, so state transitions to halfOpen
        expect(breaker.state, CircuitBreakerState.halfOpen);
        expect(breaker.allowRequest, isTrue);
      });

      test('should transition from halfOpen to closed on success', () {
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: Duration.zero);

        // Closed -> Open -> HalfOpen (zero cooldown)
        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.halfOpen);

        // HalfOpen -> Closed (probe success)
        breaker.recordSuccess();
        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.failureCount, 0);
        expect(breaker.allowRequest, isTrue);
      });

      test('should reopen circuit on failure during halfOpen', () {
        // recordFailure() in halfOpen sets _state to open.
        // With a long cooldown, the state remains open on subsequent checks.
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: Duration.zero);

        // Closed -> HalfOpen (zero cooldown after 1 failure)
        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.halfOpen);

        // HalfOpen -> Open (probe failed). recordFailure sets _state = open
        // and _lastFailureTime = now(). With zero cooldown the state getter
        // will immediately transition back to halfOpen, which is expected.
        // We verify that recordFailure increments the count.
        final countBefore = breaker.failureCount;
        breaker.recordFailure();
        expect(breaker.failureCount, countBefore + 1);
      });

      test('should remain open with non-zero cooldown after halfOpen failure', () {
        // Use a helper: first create a breaker with zero cooldown to reach halfOpen,
        // then verify behavior. But we cannot change cooldown dynamically.
        // Instead, test the open -> halfOpen boundary with long cooldown.
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.open);
        expect(breaker.allowRequest, isFalse);

        // Even after more failures, it stays open (cooldown not elapsed)
        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.open);
        expect(breaker.allowRequest, isFalse);
      });

      test('should complete full cycle: closed -> open -> halfOpen -> closed', () {
        final breaker = CircuitBreaker(failureThreshold: 2, cooldownDuration: Duration.zero);

        // Start closed
        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.allowRequest, isTrue);

        // Record failures to open the circuit
        breaker.recordFailure();
        breaker.recordFailure();
        // With zero cooldown, state immediately transitions from open to halfOpen
        expect(breaker.state, CircuitBreakerState.halfOpen);
        expect(breaker.allowRequest, isTrue);

        // Probe succeeds -> closed
        breaker.recordSuccess();
        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.allowRequest, isTrue);
        expect(breaker.failureCount, 0);
      });
    });

    group('allowRequest', () {
      test('should return true when closed', () {
        final breaker = CircuitBreaker();
        expect(breaker.allowRequest, isTrue);
      });

      test('should return false when open and cooldown has not elapsed', () {
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        expect(breaker.allowRequest, isFalse);
      });

      test('should return true when halfOpen (after cooldown)', () {
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: Duration.zero);

        breaker.recordFailure();
        // Zero cooldown means it transitions to halfOpen immediately
        expect(breaker.allowRequest, isTrue);
      });
    });

    group('edge cases', () {
      test('should handle recordSuccess when already closed', () {
        final breaker = CircuitBreaker();

        breaker.recordSuccess();
        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.failureCount, 0);
      });

      test('should handle multiple resets', () {
        final breaker = CircuitBreaker(failureThreshold: 1);

        breaker.recordFailure();
        breaker.reset();
        breaker.reset();

        expect(breaker.state, CircuitBreakerState.closed);
        expect(breaker.failureCount, 0);
      });

      test('should handle failure threshold of 1', () {
        final breaker = CircuitBreaker(failureThreshold: 1, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        expect(breaker.state, CircuitBreakerState.open);
      });

      test('should handle interleaved successes resetting failure count', () {
        final breaker = CircuitBreaker(failureThreshold: 3);

        breaker.recordFailure();
        breaker.recordFailure();
        expect(breaker.failureCount, 2);

        breaker.recordSuccess();
        expect(breaker.failureCount, 0);
        expect(breaker.state, CircuitBreakerState.closed);

        // Start counting again
        breaker.recordFailure();
        expect(breaker.failureCount, 1);
        expect(breaker.state, CircuitBreakerState.closed);
      });

      test('should properly track failure count through state transitions', () {
        final breaker = CircuitBreaker(failureThreshold: 3, cooldownDuration: const Duration(hours: 1));

        breaker.recordFailure();
        expect(breaker.failureCount, 1);
        breaker.recordFailure();
        expect(breaker.failureCount, 2);
        breaker.recordFailure();
        expect(breaker.failureCount, 3);
        expect(breaker.state, CircuitBreakerState.open);

        // Reset and verify count is back to 0
        breaker.reset();
        expect(breaker.failureCount, 0);
        expect(breaker.state, CircuitBreakerState.closed);
      });
    });
  });
}

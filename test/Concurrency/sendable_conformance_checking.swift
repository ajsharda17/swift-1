// RUN: %target-typecheck-verify-swift
// REQUIRES: concurrency

@available(SwiftStdlib 5.1, *)
class NotSendable { // expected-note 9{{class 'NotSendable' does not conform to the 'Sendable' protocol}}
}

@available(SwiftStdlib 5.1, *)
@available(*, unavailable)
extension NotSendable: Sendable { }

@available(SwiftStdlib 5.1, *)
protocol IsolatedWithNotSendableRequirements: Actor {
  func f() -> NotSendable
  var prop: NotSendable { get }

  func fAsync() async -> NotSendable
}

// Okay, everything is isolated the same way
@available(SwiftStdlib 5.1, *)
actor A1: IsolatedWithNotSendableRequirements {
  func f() -> NotSendable { NotSendable() }
  var prop: NotSendable { NotSendable() }
  func fAsync() async -> NotSendable { NotSendable() }
}

// Okay, sendable checking occurs when calling through the protocol
// and also inside the bodies.
@available(SwiftStdlib 5.1, *)
actor A2: IsolatedWithNotSendableRequirements {
  nonisolated func f() -> NotSendable { NotSendable() }
  nonisolated var prop: NotSendable { NotSendable() }

  nonisolated func fAsync() async -> NotSendable { NotSendable() }
  // expected-warning@-1{{non-sendable type 'NotSendable' returned by nonisolated instance method 'fAsync()' satisfying protocol requirement cannot cross actor boundary}}
}

@available(SwiftStdlib 5.1, *)
protocol AsyncProtocolWithNotSendable {
  func f() async -> NotSendable
  var prop: NotSendable { get async }
}

// Sendable checking required because calls through protocol cross into the
// actor's domain.
@available(SwiftStdlib 5.1, *)
actor A3: AsyncProtocolWithNotSendable {
  func f() async -> NotSendable { NotSendable() } // expected-warning{{non-sendable type 'NotSendable' returned by actor-isolated instance method 'f()' satisfying protocol requirement cannot cross actor boundary}}

  var prop: NotSendable { // expected-warning{{non-sendable type 'NotSendable' in conformance of actor-isolated property 'prop' to protocol requirement cannot cross actor boundary}}
    get async {
      NotSendable()
    }
  }
}

// Sendable checking required because calls through protocol cross into the
// actor's domain.
@available(SwiftStdlib 5.1, *)
actor A4: AsyncProtocolWithNotSendable {
  func f() -> NotSendable { NotSendable() } // expected-warning{{non-sendable type 'NotSendable' returned by actor-isolated instance method 'f()' satisfying protocol requirement cannot cross actor boundary}}

  var prop: NotSendable { // expected-warning{{non-sendable type 'NotSendable' in conformance of actor-isolated property 'prop' to protocol requirement cannot cross actor boundary}}
    get {
      NotSendable()
    }
  }
}

// Sendable checking not required because we never cross into the actor's
// domain.
@available(SwiftStdlib 5.1, *)
actor A5: AsyncProtocolWithNotSendable {
  nonisolated func f() async -> NotSendable { NotSendable() }

  nonisolated var prop: NotSendable {
    get async {
      NotSendable()
    }
  }
}

// Sendable checking not required because we never cross into the actor's
// domain.
@available(SwiftStdlib 5.1, *)
actor A6: AsyncProtocolWithNotSendable {
  nonisolated func f() -> NotSendable { NotSendable() }

  nonisolated var prop: NotSendable {
    get {
      NotSendable()
    }
  }
}

@available(SwiftStdlib 5.1, *)
protocol AsyncThrowingProtocolWithNotSendable {
  func f() async throws -> NotSendable
  var prop: NotSendable { get async throws }
}

// Sendable checking required because calls through protocol cross into the
// actor's domain.
@available(SwiftStdlib 5.1, *)
actor A7: AsyncThrowingProtocolWithNotSendable {
  func f() async -> NotSendable { NotSendable() } // expected-warning{{non-sendable type 'NotSendable' returned by actor-isolated instance method 'f()' satisfying protocol requirement cannot cross actor boundary}}

  var prop: NotSendable { // expected-warning{{non-sendable type 'NotSendable' in conformance of actor-isolated property 'prop' to protocol requirement cannot cross actor boundary}}
    get async {
      NotSendable()
    }
  }
}

// Sendable checking required because calls through protocol cross into the
// actor's domain.
@available(SwiftStdlib 5.1, *)
actor A8: AsyncThrowingProtocolWithNotSendable {
  func f() -> NotSendable { NotSendable() } // expected-warning{{non-sendable type 'NotSendable' returned by actor-isolated instance method 'f()' satisfying protocol requirement cannot cross actor boundary}}

  var prop: NotSendable { // expected-warning{{non-sendable type 'NotSendable' in conformance of actor-isolated property 'prop' to protocol requirement cannot cross actor boundary}}
    get {
      NotSendable()
    }
  }
}

// Sendable checking not required because we never cross into the actor's
// domain.
@available(SwiftStdlib 5.1, *)
actor A9: AsyncThrowingProtocolWithNotSendable {
  nonisolated func f() async -> NotSendable { NotSendable() }

  nonisolated var prop: NotSendable {
    get async {
      NotSendable()
    }
  }
}

// Sendable checking not required because we never cross into the actor's
// domain.
@available(SwiftStdlib 5.1, *)
actor A10: AsyncThrowingProtocolWithNotSendable {
  nonisolated func f() -> NotSendable { NotSendable() }

  nonisolated var prop: NotSendable {
    get {
      NotSendable()
    }
  }
}

// rdar://86653457 - Crash due to missing Sendable conformances.
// expected-warning@+1{{non-final class 'Klass' cannot conform to 'Sendable'; use '@unchecked Sendable'}}
class Klass<Output: Sendable>: Sendable {}
final class SubKlass: Klass<[S]> {}
public struct S {}

// rdar://88700507 - redundant conformance of @MainActor-isolated subclass to 'Sendable'
@MainActor class MainSuper {}
class MainSub: MainSuper, @unchecked Sendable {}

class SendableSuper: @unchecked Sendable {}
class SendableSub: SendableSuper, @unchecked Sendable {}

class SendableExtSub: SendableSuper {}
extension SendableExtSub: @unchecked Sendable {}

// Still want to know about same-class redundancy
class MultiConformance: @unchecked Sendable {} // expected-note {{'MultiConformance' declares conformance to protocol 'Sendable' here}}
extension MultiConformance: @unchecked Sendable {} // expected-error {{redundant conformance of 'MultiConformance' to protocol 'Sendable'}}

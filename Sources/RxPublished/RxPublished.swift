import Combine
import Foundation
import RxRelay
import RxSwift

/// `@RxPublished` is a drop-in replacement for Combine's `@Published` and is intended to be used in ObservableObject View Models.
///
///  Its projected value (using `$` operator like `$example`) provides access to an observable stream, mirroring the functionality of the stock `@Published`. Usage within SwiftUI Bindings also works as expected (like for TextField).
///
///  If your source of truth lives elsewhere, you can also bind to an external Observable.
///
/// Example usage:
///
/// ```swift
/// @RxPublished private(set) var example: String = "hello world"
/// ```
///
/// Use the underscored accessor to bind to an Observable that lives elsewhere
/// ```swift
/// @RxPublished private(set) var example: String = ""
///
/// init(someObservable: Observable<String>) {
///     someObservable.bind(to: _example)
/// }
/// ```
///
/// Observe value changes:
/// ```swift
/// $example
///     .distinctUntilChanged()
///     .subscribe {
///         print("value changed: \($0)")
///     }
///     .disposed(by: disposeBag)
/// ```
@propertyWrapper
public final class RxPublished<Value> {
    let behaviorRelay: BehaviorRelay<Value>

    lazy var externalObservationDisposable: SerialDisposable = {
        let serialDisposable = SerialDisposable()
        serialDisposable.disposed(by: disposeBag)
        return serialDisposable
    }()

    lazy var internalObservationDisposable: SerialDisposable = {
        let serialDisposable = SerialDisposable()
        serialDisposable.disposed(by: disposeBag)
        return serialDisposable
    }()

    var externalObservationNeedsSetup: Bool = false
    var isObservingExternalValue: Bool = false
    let disposeBag = DisposeBag()

    public var projectedValue: Observable<Value> {
        behaviorRelay.asObservable()
    }

    public init(wrappedValue: Value) {
        self.behaviorRelay = .init(value: wrappedValue)
    }

    func bind(from observable: Observable<Value>) {
        isObservingExternalValue = true
        externalObservationNeedsSetup = true
        externalObservationDisposable.disposable = observable
            .subscribe(onNext: { [weak self] in
                self?.behaviorRelay.accept($0)
            })
    }

    func setup<Instance: ObservableObject>(_ enclosingInstance: Instance) where Instance.ObjectWillChangePublisher == ObservableObjectPublisher {
        internalObservationDisposable.disposable = behaviorRelay
            .skip(1) // we skip the first one, because its read directly by the layout system on the first pass. if you don't have this line, you'll get the warning "Publishing changes from within view updates is not allowed, this will cause undefined behavior."
            .observe(on: MainScheduler.instance)
            .subscribe { [weak enclosingInstance] _ in
                enclosingInstance?.objectWillChange.send()
            }
    }

    public static subscript<Instance: ObservableObject>(
        _enclosingInstance instance: Instance,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Instance, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Instance, RxPublished>
    ) -> Value where Instance.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            if instance[keyPath: storageKeyPath].externalObservationNeedsSetup {
                instance[keyPath: storageKeyPath].setup(instance)
                instance[keyPath: storageKeyPath].externalObservationNeedsSetup = false
            }
            return instance[keyPath: storageKeyPath].behaviorRelay.value
        }
        set {
            guard !instance[keyPath: storageKeyPath].isObservingExternalValue else {
                assertionFailure("Mutation is invalid when observing remote source! Instead mutate your source of truth")
                return
            }
            instance.objectWillChange.send()
            let relay = instance[keyPath: storageKeyPath].behaviorRelay
            relay.accept(newValue)
        }
    }

    /// This wrapped value is only used in non-class contexts, which does not make sense for this.
    @available(*, unavailable, message: "Property wrapper only valid on class types")
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable:next unused_setter_value
        set { fatalError() }
    }
}

extension Observable {
    /// Binds Observable stream to RxPublished property wrapper
    ///
    /// Use the underscored accessor to bind to an Observable that lives elsewhere
    /// ```swift
    /// @RxPublished private(set) var example: String = ""
    ///
    /// init(someObservable: Observable<String>) {
    ///     someObservable.bind(to: _example)
    /// }
    /// ```
    public func bind(to: RxPublished<Element>) {
        to.bind(from: self)
    }
}

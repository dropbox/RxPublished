import Combine
@testable import RxPublished
import RxRelay
import RxSwift
import XCTest
import CwlPreconditionTesting

private let initialValue = "initial"

private final class CombineViewModel: ObservableObject {
    @Published var example: String = initialValue
}

private final class RxViewModel: ObservableObject {
    @RxPublished var example: String = initialValue

    init(exampleObservable: Observable<String>? = nil) {
        exampleObservable?.bind(to: _example)
    }
}

final class RxPublishedTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = .init()

    func testGetterSetter() {
        let combine = CombineViewModel()
        let combineExpectation = expectation(description: "CombineViewModel.objectWillChange")
        let rx = RxViewModel()
        let rxExpectation = expectation(description: "RxViewModel.objectWillChange")

        combine.objectWillChange.sink {
            print("CombineViewModel.objectWillChange")
            combineExpectation.fulfill()
        }.store(in: &cancellables)
        rx.objectWillChange.sink {
            print("RxViewModel.objectWillChange")
            rxExpectation.fulfill()
        }.store(in: &cancellables)

        XCTAssertEqual(combine.example, initialValue)
        XCTAssertEqual(rx.example, initialValue)

        let testString = "test"
        combine.example = testString
        rx.example = testString

        XCTAssertEqual(rx.example, testString)
        XCTAssertEqual(combine.example, testString)

        wait(for: [combineExpectation, rxExpectation])
    }

    func testExternalObservation() {
        let initalRelayValue = "initial_relay"
        let relay: BehaviorRelay<String> = .init(value: initalRelayValue)

        let rx = RxViewModel(exampleObservable: relay.asObservable())

        XCTAssertEqual(rx.example, initalRelayValue)

        let nextValue = "next"
        relay.accept(nextValue)
        XCTAssertEqual(rx.example, nextValue)
    }

    func testProjectedValue() {
        let disposeBag = DisposeBag()
        let rx = RxViewModel()
        let rxExpectation = expectation(description: "projectedValue")
        let nextValue = "next"

        rx.$example
            .take(2)
            .toArray()
            .subscribe({ value in
                switch value {
                case .success(let values):
                    XCTAssertEqual(values, [initialValue, nextValue])
                case .failure(let error):
                    XCTFail("\(error)")
                }
                rxExpectation.fulfill()
            }).disposed(by: disposeBag)

        rx.example = nextValue

        wait(for: [rxExpectation])
    }

    func testAssertionFailureOnExternalObservation() {
        let relay = BehaviorRelay<String>(value: "initial")
        let rx = RxViewModel(exampleObservable: relay.asObservable())
        
        // Verify we're observing the external value
        XCTAssertEqual(rx.example, "initial")

        let e = catchBadInstruction {
            // Attempt to mutate the property directly
            // This will print an assertion failure message but continue execution
            rx.example = "new value"
        }
        XCTAssertNotNil(e, "Expected an assertion failure to be caught")

        // The value should remain unchanged since the mutation was prevented
        XCTAssertEqual(rx.example, "initial")
        
        // Verify that the external binding still works
        let nextValue = "next from relay"
        relay.accept(nextValue)
        XCTAssertEqual(rx.example, nextValue)
    }
}

# RxPublished

`@RxPublished` is a drop-in replacement for Combine's `@Published` and is intended to be used in ObservableObject View Models. Under the hood it utilizes [RxSwift](https://github.com/ReactiveX/RxSwift) instead of Combine, allowing pre-existing RxSwift code to be used more seamlessly in SwiftUI.

 Its projected value (using `$` operator like `$example`) provides access to an observable stream, mirroring the functionality of the stock `@Published`. Usage within SwiftUI Bindings also works as expected (like for TextField).

 If your source of truth lives elsewhere, you can also bind to an external Observable.
 
 ## Installation
 
 ### Swift Package Manager
 
Add the following to your `Package.swift` file:

```swift
.package(url: "https://github.com/dropbox/RxPublished.git", .upToNextMajor(from: "1.0.0")),
```

## Usage

```swift
@RxPublished private(set) var example: String = "hello world"
```

Use the underscored accessor to bind to an Observable that lives elsewhere
```swift
@RxPublished private(set) var example: String = ""

init(someObservable: Observable<String>) {
    someObservable.bind(to: _example)
}
```

Observe value changes:

```swift
$example
    .distinctUntilChanged()
    .subscribe {
        print("value changed: \($0)")
    }
    .disposed(by: disposeBag)
```

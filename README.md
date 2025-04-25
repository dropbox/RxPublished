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

## License

    Copyright (c) 2025 Dropbox, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

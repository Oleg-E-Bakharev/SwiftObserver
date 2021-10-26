import Cocoa

@propertyWrapper
final class Once<Parameter, Result> {
    typealias Block = (Parameter) -> Result

    private var block: Block!

    var wrappedValue: Block {
        get {
            defer { block = nil }
            return block
        }
        set {
            fatalError("Unsupported")
        }
    }

    init(_ block: @escaping Block) {
        wrappedValue = block
    }

    deinit {
        guard block == nil else {
            fatalError("Block must be called once")
        }
    }
}

func testOnce(@Once completion: () -> Void) {
    completion()
}

testOnce {
    print("Complete")
}

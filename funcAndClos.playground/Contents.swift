
typealias VoidBlock = () -> Void

var v1: VoidBlock = { print("v1") }
var v2: VoidBlock = { print("v2") }
var v3 = v1

func foo(_ vb: inout VoidBlock) {
    vb = v2
}

v3()
foo(&v3)
v3()

// Erros:

//struct Composite: Equatable {
//    let v: VoidBlock
//}

// print(v1 == v2) error


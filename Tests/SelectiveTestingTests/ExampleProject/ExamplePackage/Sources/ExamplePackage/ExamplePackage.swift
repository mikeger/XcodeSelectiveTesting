import ExampleSubpackage

public struct ExamplePackage {
    static public func exampleText() -> String {
        return "Package: example text \(ExampleSubpackage.subpackageText())"
    }
}

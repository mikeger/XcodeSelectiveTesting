import ExampleSubpackage

public enum ExamplePackage {
    public static func exampleText() -> String {
        return "Package: example text \(ExampleSubpackage.subpackageText())"
    }
}

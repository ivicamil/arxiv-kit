
/// Utilites used for library development and debugging.
public enum Utilities {
    
    /// Prints human-readable list of all subjects.
    public static func printSubjects() {
        ArxivSubject.print()
    }
    
    /// Generates `ArxivSubjects` namespace enum and all the constants.
    public static func generateSubjectSwiftConstants() -> String {
        return ArxivSubject.generateSwiftConstants()
    }
}


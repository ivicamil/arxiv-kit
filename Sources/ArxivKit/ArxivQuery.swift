import Foundation

/**
 Specifies search criteria for arXiv request.
 
 `ArxivQuery` represents either a search term in specified article field,
 a date intervarl in which desired articles were published or updated or an arXive subject.
 
 Queries can be combined to construct arbitrarily complex queries by using `allOf` and `anyOf` combinators.
 It is also possible to exclude articles matching a query by using `excluding` combinator.
 */
public struct ArxivQuery: Codable {
    
    private var tree: ArxivQueryTree
    
    private init(_ tree: ArxivQueryTree) {
        self.tree = tree
    }
    
    /**
     Used to restrict term search to specific article field.
     
     To search given term in any field, use `ArxivQuery.Field.any`.
     */
    public struct Field: Codable {
        
        let rawValue: Value
        
        private init(_ field: Value) {
            self.rawValue = field
        }
        
        /// Search sor a term inside the title.
        public static var title = Field(.title)
        
        /// Search sor a term inside the abstract (summary).
        public static var abstract = Field(.abstract)
        
        /// Search sor a term inside the authors' names.
        public static var author = Field(.authors)
        
        /// Search sor a term inside in the comment.
        public static var comment = Field(.comment)
        
        /// Search sor a term inside the journal reference.
        public static var journalReference = Field(.journalReference)
        
        /// Search sor a term inside the report number.
        public static var reportNumber = Field(.reportNumber)
        
        /// Search sor a term inside any field.
        public static var any = Field(.any)
    }
}

public extension ArxivQuery {
    
    /**
     Returns a query for retrieving the articles containing provided term in the specified field.
     
        - Parameter term: A string to search for.
        - Parameter field: An article field to be searched for provided term.
     
     Default value of `field` parameter isis `.any`.
     
     From [arxiv API manual](https://arxiv.org/help/api/user-manual):
     
    **Wildcards:**

    - Use ? to replace a single character or * to replace any number of characters.
     Can be used in any field, but not in the first character position. See Journal References tips for exceptions.
     
     **Expressions:**
     
     - TeX expressions can be searched, enclosed in single $ characters.

     **Phrases:**

     - Enclose phrases in double quotes for exact matches in title, abstract, and comments.
     
     **Journal References:**

     - If a journal reference search contains a wildcard, matches will be made using wildcard matching as expected. For example, math* will match math, maths, mathematics.
     - If a journal reference search does not contain a wildcard, only exact phrases entered will be matched. For example, math would match math or math and science but not maths or mathematics.
     - All journal reference searches that do not contain a wildcard are literal searches: a search for Physica A will match all papers with journal references containing Physica A, but a search for Physica A, 245 (1997) 181 will only return the paper with journal reference Physica A, 245 (1997) 181.
     
     */
    static func term(_ term: String, in field: Field = .any) -> ArxivQuery {
        let tree: ArxivQueryTree
        
        switch field.rawValue  {
        case .title:
            tree = .title(contains: term)
        case .abstract:
            tree = .abstract(contains: term)
        case .authors:
            tree = .authors(contains: term)
        case .comment:
            tree = .comment(contains: term)
        case .journalReference:
            tree = .journalReference(contains: term)
        case .reportNumber:
            tree = .reportNumber(contains: term)
        case .any:
            tree = .anyField(contains: term)
        }
        
        return ArxivQuery(tree)
    }
    
    /**
     Returns a query for retrieving  the articles categorised under provided arXiv subject.
     
     - Parameter subject: An arXive subject. Possible values are defined under `ArxivSubjects` namespace.
    */
    static func subject(_ subject: ArxivSubject) -> ArxivQuery {
        return ArxivQuery(.subject(subject))
    }
    
    /**
     Returns a query for retrieving the articles whose first version was published in provided date interval.
     
     - Parameter interval: Desired time interval.
    */
    static func sumbitted(in interval: DateInterval) -> ArxivQuery {
        return ArxivQuery(.submitted(in: interval))
    }
    
    /**
     Returns a query for retrieving the articles whose first version was published in provided date interval.
     
     - Parameter interval: Desired time interval.
    */
    static func sumbitted(in interval: DateInterval?) -> ArxivQuery? {
        guard let interval = interval else {
            return nil
        }
        return ArxivQuery(.submitted(in: interval))
    }
    
    /**
     Returns a query for retrieving the articles whose most recent version was published in provided date interval.
     
     - Parameter interval: Desired time interval.
    */
    static func lastUpdated(in interval: DateInterval) -> ArxivQuery {
        return ArxivQuery(.lastUpdated(in: interval))
    }
    
    /**
     Returns a query for retrieving the articles whose most recent version was published in provided date interval.
     
     - Parameter interval: Desired time interval.
    */
    static func lastUpdated(in interval: DateInterval?) -> ArxivQuery? {
        guard let interval = interval else {
            return nil
        }
        return ArxivQuery(.lastUpdated(in: interval))
    }
}

public extension ArxivQuery {
    
    /**
     Returns a new query for retrieving the articles matching the query **AND NOT** the provided argument query.
    
     - Parameter anotherQuery:A query that retrieved articles do not match.
     */
    func excluding(_ anotherQuery: ArxivQuery) -> ArxivQuery {
        return ArxivQuery(.firstAndNotSecond(tree, anotherQuery.tree))
    }
    
    /**
     Returns a new query for retrieving the articles matching **ALL** of the provided subqueries.
    
     - Parameter firstQuery: The first subquery.
     
     - Parameter secondQuery: The second subquery.
     
     - Parameter otherQueries: Additional optional subqueries.
     */
    static func allOf(_ firstQuery: ArxivQuery, _ secondQuery: ArxivQuery,_ otherQueries: ArxivQuery...) -> ArxivQuery {
        return otherQueries.reduce(firstQuery.and(secondQuery)) { $0.and($1) }
    }
    
    /**
     Returns a query for retrieving the articles matching **ANY** of the provided subqueries.
    
     - Parameter firstQuery: The first subquery.
     
     - Parameter secondQuery: The second subquery.
     
     - Parameter otherQueries: Additional optional subqueries.
     */
    static func anyOf(_ firstQuery: ArxivQuery, _ secondQuery: ArxivQuery,_ otherQueries: ArxivQuery...) -> ArxivQuery {
        return otherQueries.reduce(firstQuery.or(secondQuery)) { $0.or($1) }
    }
}

public extension ArxivQuery {
    
    /// Returns a string representation of the query.
    var string: String {
        return tree.string
    }
}

extension ArxivQuery {
    
    private func and(_ anotherQuery: ArxivQuery) -> ArxivQuery {
        return ArxivQuery(.both(tree, anotherQuery.tree))
    }
    
    private func or(_ anotherQuery: ArxivQuery) -> ArxivQuery {
        return ArxivQuery(.either(tree, anotherQuery.tree))
    }
}

extension ArxivQuery {
    
    static var empty: ArxivQuery {
        return ArxivQuery(.empty)
    }
}


extension ArxivQuery {
    
    var isEmpty: Bool {
        return tree.isEmpty
    }
}

extension ArxivQuery.Field {
    
    enum Value: String, Codable {
        case title
        case abstract
        case authors
        case comment
        case journalReference
        case reportNumber
        case any
    }
}

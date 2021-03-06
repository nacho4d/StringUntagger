import Foundation

public extension String {
    func attributedString(attributter: [String: [NSAttributedString.Key: Any]]) -> NSAttributedString {
        return StringUntagger().attributedString(from: self, attributer: attributter)
    }
}

public class StringUntagger: NSObject {
    
    class Element: CustomStringConvertible  {
        var name: String
        var attributes: [NSAttributedString.Key: Any] = [:]
        var children = [Element]()
        weak var parent: Element?

        init(name: String) {
            self.name = name
        }

        var description: String {
            return "name:\(name) attributes:\(attributes)"
        }
    }
    
    public init(rootName: String = "root") {
        self.rootName = rootName
    }

    private var stack = [Element]()
    private var rootName: String
    
    /// Either is required
    private var attributterDictionary: [String: [NSAttributedString.Key: Any]]?
    private var attributterBlock: ((String, [String]) -> [NSAttributedString.Key: Any])?
    
    private var result: NSMutableAttributedString?
    
    private func findAttributes(newElement: Element) -> [NSAttributedString.Key: Any] {
        if let attributter = attributterDictionary {
            // Get attributes from dictionary
            return attributter[newElement.name] ?? [:]
        } else if let attributter = attributterBlock {
            // Get attributed from block. Also provide array of previous items
            var parent: Element? = newElement.parent
            var parents: [String] = [newElement.name]
            while parent != nil {
                parents.insert(parent!.name, at: 0)
                parent = parent!.parent
            }
            return attributter(newElement.name, parents)
        } else {
            return [:]
        }
    }
    
    private func attributedString(from string: String, attributerDictionary: [String: [NSAttributedString.Key: Any]]?, attributerBlock: ((String, [String]) -> [NSAttributedString.Key: Any])?) -> NSAttributedString {
        let wrapped = "<\(rootName)>\(string)</\(rootName)>"
        guard let data = wrapped.data(using: .utf8) else {
            print("StringUntagger abnormal end. Data could not be created.")
            return NSMutableAttributedString(string: string)
        }
        self.attributterDictionary = attributerDictionary
        self.attributterBlock = attributerBlock
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let parseError = parser.parserError {
            print("StringUntagger abnormal end. parseError: \(parseError).")
            return NSMutableAttributedString(string: string)
        }
        guard let result = result else {
            print("StringUntagger abnormal end. result: <NULL>.")
            return NSMutableAttributedString(string: string)
        }
        print("StringUntagger succeed.")
        return result
    }
        
    /// `attributer` block is executed various times depending on how many tags there is in the string. It is executed synchronously.
    public func attributedString(from string: String, attributer: [String: [NSAttributedString.Key: Any]]) -> NSAttributedString {
        return attributedString(from: string, attributerDictionary: attributer, attributerBlock: nil)
    }
        
    public func attributedString(from string: String, attributer: ((String, [String]) -> [NSAttributedString.Key: Any])?) -> NSAttributedString {
        return attributedString(from: string, attributerDictionary: nil, attributerBlock: attributer)
    }
}

extension StringUntagger: XMLParserDelegate {
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        print("StringUntagger parserDidStartDocument \(parser)")
        result = NSMutableAttributedString()
        //stack.append(root)
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        print("StringUntagger parserDidEndDocument \(parser)")
        //stack.removeLast()
    }
    
    // func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?)

    
    // func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?)

    
    // func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?)

    
    // func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String)

    
    // func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?)

    
    // func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?)

    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print("StringUntagger didStartElement \(elementName) (calling attributer)")
        let newElement = Element(name: elementName)
        let parent = stack.last
        newElement.parent = parent
        parent?.children.append(newElement)
        stack.append(newElement)
        newElement.attributes = findAttributes(newElement: newElement)
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("StringUntagger didEndElement \(elementName)")
        stack.removeLast()
    }

    
    // func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String)

    
    // func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String)

    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("StringUntagger foundCharacters \(string)")
        guard let element = stack.last else {
            print("StringUntagger early exit")
            return
        }
        // Merge current element attributes with parents' attributes (preserving child attributtes)
        var attrs = element.attributes
        var e: Element? = element
        while e?.parent != nil {
            let parentAttributes = e!.parent!.attributes
            attrs.merge(parentAttributes) { (current, _) in current }
            e = e!.parent
        }
     
        // If value is NSNull() then set the value from root.
        // Remove all pairs that contain NSNull as value
        for key in attrs.keys {
            let value = attrs[key]
            if (value as? NSObject) == NSNull() {
                if let rootValue = stack.first?.attributes[key] {
                    // root value found: set root value
                    attrs[key] = rootValue
                } else {
                    // root value not found: remove it
                    attrs.removeValue(forKey: key)
                }
            }
        }

        result?.append(NSAttributedString(string: string, attributes: attrs))
    }

    
    // func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String)

    
    // func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?)

    
    public func parser(_ parser: XMLParser, foundComment comment: String) {
        print("StringUntagger foundComment \(comment)")
    }

    
    // func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data)

    
    // func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data?

    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("StringUntagger parseErrorOccurred \(parseError)")
    }

    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("StringUntagger validationErrorOccurred \(validationError)")
    }
}



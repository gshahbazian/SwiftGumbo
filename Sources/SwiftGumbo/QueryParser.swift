//
//  QueryParser.swift
//  Created by Gabe Shahbazian 2020
//

import CGumboParser

public class QueryParser {
    public enum ParseError: Error {
        case invalidInput
        case escapingUnimplemented
        case pseudoClassUnimplemented
    }

    private let input: String
    private var offset: String.Index

    public init(_ input: String) {
        self.input = input
        self.offset = input.startIndex
    }

    public func parse() throws -> QuerySelector {
        return try parseSelectorGroup()
    }

    private func parseSelectorGroup() throws -> QuerySelector {
        var selector = try parseSelector()
        while offset < input.endIndex {
            if input[offset] != "," {
                return selector
            }

            offset = input.index(after: offset)
            let unionSelector = try parseSelector()
            selector = BinarySelector(op: .union, first: selector, second: unionSelector)
        }
        return selector
    }

    private func parseSelector() throws -> QuerySelector {
        skipWhitespace()
        let selector = try parseSimpleSelectorSequence()
        while true {
            var combinator: Character?
            if skipWhitespace() {
                combinator = " "
            }

            if offset >= input.endIndex {
                return selector
            }

            let char = input[offset]

            if char == "+" || char == ">" || char == "~" {
                combinator = char
                offset = input.index(after: offset)
                skipWhitespace()
            } else if char == "," || char == ")" {
                return selector
            }

            let combinedSelector = try parseSimpleSelectorSequence()
            switch combinator {
            case " ": return BinarySelector(op: .descendant, first: selector, second: combinedSelector)
            case ">": return BinarySelector(op: .child, first: selector, second: combinedSelector)
            case "+": return BinarySelector(op: .adjacent, first: selector, second: combinedSelector)
            case "~": return BinarySelector(op: .sibling, first: selector, second: combinedSelector)
            default: break
            }
        }
    }

    private func parseSimpleSelectorSequence() throws -> QuerySelector {
        guard offset < input.endIndex else { return EmptySelector()}

        var selector: QuerySelector?

        let char = input[offset]
        if char == "*" {
            offset = input.index(after: offset)
        } else if !(char == "#" || char == "." || char == "[" || char == ":") {
            selector = try parseTypeSelector()
        }

        while offset < input.endIndex {
            let char = input[offset]
            let intersectionSelector: QuerySelector

            if char == "#" { intersectionSelector = try parseIDSelector() }
            else if char == "." { intersectionSelector = try parseClassSelector() }
            else if char ==  "[" { intersectionSelector = try parseAttributeSelector() }
            else if char ==  ":" { intersectionSelector = try parsePseudoclassSelector() }
            else { break }

            if let currentSelector = selector {
                selector = BinarySelector(op: .intersection, first: currentSelector, second: intersectionSelector)
            } else {
                selector = intersectionSelector
            }
        }

        if let selector = selector {
            return selector
        } else {
            return EmptySelector()
        }
    }

    private func parseTypeSelector() throws -> QuerySelector {
        let tag = try parseIdentifier()
        let gumboTag = gumbo_tagn_enum(tag, tag.utf8.count)
        return TagSelector(tag: gumboTag)
    }

    private func parseIDSelector() throws -> QuerySelector {
        offset = input.index(after: offset)
        let id = try parseName()
        return AttributeSelector(op: .equals, name: "id", value: id)
    }

    private func parseClassSelector() throws -> QuerySelector {
        offset = input.index(after: offset)
        let `class` = try parseIdentifier()
        return AttributeSelector(op: .listed, name: "class", value: `class`)
    }

    private func parseAttributeSelector() throws -> QuerySelector {
        offset = input.index(after: offset)
        skipWhitespace()
        let name = try parseIdentifier()
        skipWhitespace()

        guard offset < input.endIndex else {
            throw ParseError.invalidInput
        }

        if input[offset] == "]" {
            offset = input.index(after: offset)
            return AttributeSelector(op: .exists, name: name)
        }

        guard let twoAhead = input.index(offset, offsetBy: 2, limitedBy: input.endIndex), twoAhead < input.endIndex else {
            throw ParseError.invalidInput
        }

        var operation = input[offset..<twoAhead]
        if operation.first == "=" {
            operation = "="
        }

        offset = input.index(offset, offsetBy: operation.count)
        skipWhitespace()

        guard offset < input.endIndex else {
            throw ParseError.invalidInput
        }

        let char = input[offset]
        let value: String
        if char == "\'" || char == "\"" {
            value = try parseString()
        } else {
            value = try parseIdentifier()
        }

        skipWhitespace()

        guard offset < input.endIndex, input[offset] == "]" else {
            throw ParseError.invalidInput
        }

        offset = input.index(after: offset)

        let attributeOp: AttributeSelector.Operator
        switch operation {
        case "=": attributeOp = .equals
        case "~=": attributeOp = .listed
        case "^=": attributeOp = .prefix
        case "$=": attributeOp = .suffix
        case "*=": attributeOp = .contains
        default: throw ParseError.invalidInput
        }

        return AttributeSelector(op: attributeOp, name: name, value: value)
    }

    private func parsePseudoclassSelector() throws -> QuerySelector {
        offset = input.index(after: offset)
        let name = try parseIdentifier().lowercased()
        switch name {
        case "not":
            guard consumeOpeningParenthesis() else { throw ParseError.invalidInput }
            let group = try parseSelectorGroup()
            guard consumeClosingParenthesis() else { throw ParseError.invalidInput }

            return NotSelector(notMatching: group)
        case "nth-child", "nth-last-child", "nth-of-type", "nth-last-of-type": fallthrough
        case "first-child", "last-child", "first-of-type", "last-of-type", "only-child", "only-of-type":
            throw ParseError.pseudoClassUnimplemented
        default:
            throw ParseError.invalidInput
        }
    }

    private func parseIdentifier() throws -> String {
        var startingDash = false
        if offset < input.endIndex, input[offset] == "-" {
            startingDash = true
            offset = input.index(after: offset)
        }

        guard offset < input.endIndex else {
            throw ParseError.invalidInput
        }

        let char = input[offset]
        guard char.isValidIdentifierStart || char == "\\" else {
            throw ParseError.invalidInput
        }

        let name = try parseName()
        return startingDash ? "-\(name)" : name
    }

    private func parseName() throws -> String {
        var offset = self.offset
        var name = ""
        while offset < input.endIndex {
            let char = input[offset]
            if char.isValidIdentifierCharacter {
                let start = offset
                while offset < input.endIndex, input[offset].isValidIdentifierCharacter {
                    offset = input.index(after: offset)
                }
                name += input[start..<offset]
            } else if char == "\\" {
                self.offset = offset
                name += try parseEscape()
                offset = self.offset
            } else {
                break
            }
        }

        if name.isEmpty {
            throw ParseError.invalidInput
        }

        self.offset = offset
        return name
    }

    private func parseString() throws -> String {
        guard let twoAhead = input.index(offset, offsetBy: 2, limitedBy: input.endIndex), twoAhead < input.endIndex else {
            throw ParseError.invalidInput
        }

        let quoteChar = input[offset]
        var offset = input.index(after: self.offset)
        var value = ""

        while offset < input.endIndex {
            let char = input[offset]
            if char == "\\" {
                throw ParseError.escapingUnimplemented
            } else if char == quoteChar {
                break
            } else if char.isNewline {
                throw ParseError.invalidInput
            } else {
                let start = offset
                while offset < input.endIndex {
                    let char = input[offset]
                    if char == quoteChar || char == "\\" || char.isNewline {
                        break
                    }
                    offset = input.index(after: offset)
                }
                value += input[start..<offset]
            }
        }

        if offset >= input.endIndex {
            throw ParseError.invalidInput
        }

        self.offset = input.index(after: offset)
        return value
    }

    private func parseEscape() throws -> String {
        throw ParseError.escapingUnimplemented
    }

    private func consumeOpeningParenthesis() -> Bool {
        guard offset < input.endIndex, input[offset] == "(" else {
            return false
        }

        offset = input.index(after: offset)
        skipWhitespace()
        return true
    }

    private func consumeClosingParenthesis() -> Bool {
        let offset = self.offset
        skipWhitespace()
        guard offset < input.endIndex, input[offset] == ")" else {
            self.offset = offset
            return false
        }

        self.offset = input.index(after: offset)
        return true
    }

    @discardableResult
    private func skipWhitespace() -> Bool {
        var offset = self.offset
        while offset < input.endIndex {
            let char = input[offset]
            if char.isWhitespace {
                offset = input.index(after: offset)
                continue
            }

            if char == "/",
                let nextOffset = input.index(offset, offsetBy: 1, limitedBy: input.endIndex),
                input[nextOffset] == "*",
                let searchOffset = input.index(nextOffset, offsetBy: 1, limitedBy: input.endIndex),
                let search = input.range(of: "*/", range: searchOffset..<input.endIndex) {
                offset = search.upperBound
                continue
            }

            break
        }

        if offset > self.offset {
            self.offset = offset
            return true
        }

        return false
    }
}

fileprivate extension Character {
    var isValidIdentifierStart: Bool {
        isLetter || self == "_"
    }

    var isValidIdentifierCharacter: Bool {
        isValidIdentifierStart || isNumber || self == "-"
    }
}

//
//  QuerySelector.swift
//  Created by Gabe Shahbazian 2020
//

import CGumboParser

public protocol QuerySelector {
    func match(node: Node) -> Bool
}

public extension Node {
    func findAll(matching: QuerySelector) -> [Node] {
        var matches = [Node]()
        var queue: [Node] = [self]

        while !queue.isEmpty {
            let currentNode = queue.removeFirst()

            if matching.match(node: currentNode) {
                matches.append(currentNode)
            }

            switch currentNode.type {
            case .element(let element):
                queue.append(contentsOf: element.children)
            default: break
            }
        }

        return matches
    }

    func findFirst(matching: QuerySelector) -> Node? {
        var queue: [Node] = [self]

        while !queue.isEmpty {
            let currentNode = queue.removeFirst()

            if matching.match(node: currentNode) {
                return currentNode
            }

            switch currentNode.type {
            case .element(let element):
                queue.append(contentsOf: element.children)
            default: break
            }
        }

        return nil
    }
}

struct BinarySelector: QuerySelector {
    enum Operator {
        case union
        case intersection
        case child
        case descendant
        case adjacent
        case sibling
    }

    let op: Operator
    let first: QuerySelector
    let second: QuerySelector

    func match(node: Node) -> Bool {
        switch op {
        case .union:
            return first.match(node: node) || second.match(node: node)
        case .intersection:
            return first.match(node: node) && second.match(node: node)
        case .child:
            guard let parent = node.parent else { return false }
            return first.match(node: parent) && second.match(node: node)
        case .descendant:
            if !second.match(node: node) { return false }

            var nextParent = node.parent
            while let parent = nextParent {
                if first.match(node: parent) { return true}
                nextParent = parent.parent
            }
            return false
        case .adjacent, .sibling:
            if !second.match(node: node) { return false }
            guard let parentElement = node.parent?.element else { return false }

            let siblingEnd = parentElement.children.index(parentElement.children.startIndex, offsetBy: node.indexWithinParent)

            for siblingNode in parentElement.children[parentElement.children.startIndex..<siblingEnd].reversed() {
                guard siblingNode.element != nil else { continue }
                if op == .adjacent {
                    return first.match(node: siblingNode)
                } else if first.match(node: siblingNode) {
                    return true
                }
            }

            return false
        }
    }
}

struct TagSelector: QuerySelector {
    let tag: GumboTag

    func match(node: Node) -> Bool {
        node.element?.element.tag == tag
    }
}

struct AttributeSelector: QuerySelector {
    enum Operator {
        case exists
        case equals
        case listed
        case prefix
        case suffix
        case contains
    }

    let op: Operator
    let name: String
    let value: String

    init(op: Operator, name: String, value: String = "") {
        self.op = op
        self.name = name
        self.value = value
    }

    func match(node: Node) -> Bool {
        guard let element = node.element else { return false }
        guard let attribute = element.attributes.first(where: { $0.name == name }) else { return false }

        switch op {
        case .exists:
            return true
        case .equals:
            return attribute.value == value
        case .listed:
            let splitValue = attribute.value.components(separatedBy: .whitespacesAndNewlines)
            return splitValue.contains(value)
        case .prefix:
            guard !value.isEmpty else { return false }
            return attribute.value.hasPrefix(value)
        case .suffix:
            guard !value.isEmpty else { return false }
            return attribute.value.hasSuffix(value)
        case .contains:
            guard !value.isEmpty else { return false }
            return attribute.value.contains(value)
        }
    }
}

struct NotSelector: QuerySelector {
    let notMatching: QuerySelector

    func match(node: Node) -> Bool {
        guard node.isElement else { return false }
        return !notMatching.match(node: node)
    }
}

struct EmptySelector: QuerySelector {
    func match(node: Node) -> Bool {
        node.isElement
    }
}

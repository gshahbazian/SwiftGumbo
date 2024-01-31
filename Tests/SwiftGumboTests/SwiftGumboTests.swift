//
//  SwiftGumboTests.swift
//  Created by Gabe Shahbazian 2020
//

import CGumboParser
import SwiftGumbo
import XCTest

final class SwiftGumboTests: XCTestCase {
    func testParsingDom() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="fun">HEY &lt; WHATS UP</h1></body></html>"#)

        XCTAssertNotNil(g.document)
        XCTAssertNotNil(g.root)

        let rootElement = g.root.element
        XCTAssertEqual(rootElement?.tag, Element.Tag.html)

        let body = rootElement?.children.last
        XCTAssertNotNil(body)

        let bodyElement = body?.element
        XCTAssertEqual(bodyElement?.tag, Element.Tag.body)

        let h1 = bodyElement?.children.last
        XCTAssertNotNil(h1)

        let h1Element = h1?.element
        XCTAssertEqual(h1Element?.tag, Element.Tag.h1)

        let text = h1Element?.children.last
        XCTAssertNotNil(text)

        switch text?.type {
        case .text(let textElement):
            XCTAssertEqual(textElement.value, "HEY < WHATS UP")
        default: XCTFail()
        }
    }

    func testTextContent() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY <span>WHATS</span> UP</h1><p>Nothing</p></body></html>"#)
        let text = g.root.textContent
        XCTAssertEqual(text, "HEY WHATS UPNothing")
    }

    func testAllTagsQuery() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><h1>WHATS UP</h1></body></html>"#)

        let selector = try! QueryParser("h1").parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 2)
    }

    func testFirstTagQuery() {
        let g = SwiftGumbo(html: #"<html><body><div>HEY <div>WHATS</div></div><p>Nothing</p></body></html>"#)

        let selector = try! QueryParser("div").parse()
        let match = g.root.findFirst(matching: selector)

        let element = match?.element
        XCTAssertEqual(element?.tag, Element.Tag.div)
        XCTAssertEqual(match?.textContent, "HEY WHATS")
    }

    func testGroupQuery() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY</h1><p>Nothing</p></body></html>"#)

        let selector = try! QueryParser("h1, p").parse()
        let match = g.root.findAll(matching: selector)
        XCTAssertEqual(match.count, 2)
    }

    func testDescendantQuery() {
        let g = SwiftGumbo(html: #"<html><body><div><h1>HEY <span>NOTHING</span></h1></div></body></html>"#)

        let selector = try! QueryParser("div span").parse()
        let match = g.root.findAll(matching: selector)
        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.first?.element?.tag, Element.Tag.span)
    }

    func testChildQuery() {
        let g = SwiftGumbo(html: #"<html><body><div><h1>HEY <span>NOTHING</span></h1></div></body></html>"#)

        let zeroSelector = try! QueryParser("div > span").parse()
        let nonMatching = g.root.findAll(matching: zeroSelector)
        XCTAssertEqual(nonMatching.count, 0)

        let matchingSelector = try! QueryParser("h1 > span").parse()
        let match = g.root.findAll(matching: matchingSelector)
        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.first?.element?.tag, Element.Tag.span)
    }

    func testSiblingQuery() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY</h1><p>Nothing</p><b>Lol</b><p>Woo</p></body></html>"#)

        let selector = try! QueryParser("h1 ~ p").parse()
        let match = g.root.findAll(matching: selector)
        XCTAssertEqual(match.count, 2)
    }

    func testAdjacentSiblingQuery() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY</h1><p>Nothing</p><p>Woo</p></body></html>"#)

        let selector = try! QueryParser("h1 + p").parse()
        let match = g.root.findAll(matching: selector)
        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.first?.element?.tag, Element.Tag.p)
    }

    func testIdSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><h2 id="try">WHATS UP</h2></body></html>"#)

        let selector = try! QueryParser("#try").parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.first?.element?.tag, Element.Tag.h2)
    }

    func testClassSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><h2 id="try">WHATS UP</h2><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(".h").parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 2)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.h3)
    }

    func testHasAttributeSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><h2 title="try">WHATS UP</h2><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser("[title]").parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.h2)
    }

    func testMatchingAttributeSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><h2 title="try">WHATS UP</h2><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"[title="try"]"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.h2)
    }

    func testAttributeContainsSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><a href="http://gabeshahbazian.com">WHATS UP</a><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"a[href*="gabeshahbazian"]"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.a)
    }

    func testAttributeSuffixSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><a href="http://gabeshahbazian.com">WHATS UP</a><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"a[href$=".com"]"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.a)
    }

    func testAttributePrefixSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1 class="h">HEY</h1><a href="http://gabeshahbazian.com">WHATS UP</a><h3 class="h j">NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"a[href^="http"]"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.last?.element?.tag, Element.Tag.a)
    }

    func testGlobalSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY</h1><h3>NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"*"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 5)
    }

    func testNotSelector() {
        let g = SwiftGumbo(html: #"<html><body><h1>HEY</h1><h3>NOTHING</h3></body></html>"#)

        let selector = try! QueryParser(#"*:not(h1)"#).parse()
        let match = g.root.findAll(matching: selector)

        XCTAssertEqual(match.count, 4)
    }

    func testMaxTreeDepthOption() {
        var options = kGumboDefaultOptions
        options.max_tree_depth = 2
        let g = SwiftGumbo(html: #"<html><body><h1>node too deep</h1></body></html>"#, options: options)

        XCTAssertEqual(g.status, GUMBO_STATUS_TREE_TOO_DEEP)
    }

    static var allTests = [
        ("testParsingDom", testParsingDom),
        ("testTextContent", testTextContent),
        ("testAllTagsQuery", testAllTagsQuery),
        ("testFirstTagQuery", testFirstTagQuery),
        ("testGroupQuery", testGroupQuery),
        ("testDescendantQuery", testDescendantQuery),
        ("testChildQuery", testChildQuery),
        ("testSiblingQuery", testSiblingQuery),
        ("testAdjacentSiblingQuery", testAdjacentSiblingQuery),
        ("testIdSelector", testIdSelector),
        ("testClassSelector", testClassSelector),
        ("testHasAttributeSelector", testHasAttributeSelector),
        ("testMatchingAttributeSelector", testMatchingAttributeSelector),
        ("testAttributeContainsSelector", testAttributeContainsSelector),
        ("testAttributeSuffixSelector", testAttributeSuffixSelector),
        ("testAttributePrefixSelector", testAttributePrefixSelector),
        ("testGlobalSelector", testGlobalSelector),
        ("testNotSelector", testNotSelector),
        ("testMaxTreeDepthOption", testMaxTreeDepthOption),
    ]
}

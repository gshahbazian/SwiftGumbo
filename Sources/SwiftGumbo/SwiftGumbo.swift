//
//  SwiftGumbo.swift
//  Created by Gabe Shahbazian 2020
//

import Foundation
import CGumboParser

public class SwiftGumbo {
    private let htmlBuffer: [CChar]
    let gumboOutput: UnsafeMutablePointer<GumboOutput>

    public init(html: String) {
        // CGumboParser and the types returned by SwiftGumbo all share the same buffer in memory.
        // The class holds it strongly to ensure it has the same lifetime as the parser.
        htmlBuffer = html.cString(using: .utf8) ?? []
        gumboOutput = gumbo_parse(htmlBuffer)
    }

    deinit {
        _ = withUnsafePointer(to: kGumboDefaultOptions) { (pointer) -> Result<Void, Never> in
            gumbo_destroy_output(pointer, gumboOutput)
            return .success(())
        }
    }

    public var document: Document {
        Document(owner: self, document: gumboOutput.pointee.document!.pointee.v.document)
    }

    public var root: Node {
        Node(owner: self, pointer: gumboOutput.pointee.root!)
    }
}

public struct Document {
    let owner: SwiftGumbo
    let document: GumboDocument

    init(owner: SwiftGumbo, document: GumboDocument) {
        self.owner = owner
        self.document = document
    }

    public var children: AnyRandomAccessCollection<Node> {
        AnyRandomAccessCollection(Vector(owner: owner, vector: document.children))
    }

    public var doctype: (name: String, publicIdentifier: String, systemIdentifier: String)? {
        guard document.has_doctype else { return nil }
        return (name: String(cString: document.name), publicIdentifier: String(cString: document.public_identifier), systemIdentifier: String(cString: document.system_identifier))
    }
}

public struct Node: Hashable, VectorElement, CustomDebugStringConvertible {
    let owner: SwiftGumbo
    let nodePointer: UnsafeMutablePointer<GumboNode>

    init(owner: SwiftGumbo, pointer: UnsafeMutablePointer<GumboNode>) {
        self.owner = owner
        self.nodePointer = pointer
    }

    public var debugDescription: String {
        "Node<\(type)>"
    }

    public enum NodeType {
        case document(Document)
        case element(Element)
        case text(Text)
        case whiteSpace(Text)
        case other(Text)
    }

    public var type: NodeType {
        switch nodePointer.pointee.type {
        case GUMBO_NODE_DOCUMENT:
            return .document(Document(owner: owner, document: nodePointer.pointee.v.document))
        case GUMBO_NODE_ELEMENT, GUMBO_NODE_TEMPLATE:
            return .element(Element(owner: owner, element: nodePointer.pointee.v.element))
        case GUMBO_NODE_TEXT:
            return .text(Text(owner: owner, text: nodePointer.pointee.v.text))
        case GUMBO_NODE_WHITESPACE:
            return .whiteSpace(Text(owner: owner, text: nodePointer.pointee.v.text))
        case GUMBO_NODE_COMMENT, GUMBO_NODE_CDATA:
            return .other(Text(owner: owner, text: nodePointer.pointee.v.text))
        default:
            assertionFailure("Unsupported node type")
            return .other(Text(owner: owner, text: nodePointer.pointee.v.text))
        }
    }

    public var parent: Node? {
        guard nodePointer.pointee.parent != nil else { return nil }
        return Node(owner: owner, pointer: nodePointer.pointee.parent)
    }

    public var indexWithinParent: Int {
        nodePointer.pointee.index_within_parent
    }

    public var textContent: String {
        switch type {
        case .element(let element):
            var value = ""
            for child in element.children {
                value += child.textContent
            }
            return value
        case .text(let text): return text.value
        default: return ""
        }
    }

    public var isElement: Bool {
        nodePointer.pointee.type == GUMBO_NODE_ELEMENT || nodePointer.pointee.type == GUMBO_NODE_TEMPLATE
    }

    public var element: Element? {
        switch type {
        case .element(let element): return element
        default: return nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        nodePointer.hash(into: &hasher)
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.nodePointer == rhs.nodePointer
    }
}

public struct Element: CustomDebugStringConvertible {
    let owner: SwiftGumbo
    let element: GumboElement

    init(owner: SwiftGumbo, element: GumboElement) {
        self.owner = owner
        self.element = element
    }

    public var debugDescription: String {
        element.original_tag.value
    }

    public var children: AnyRandomAccessCollection<Node> {
        AnyRandomAccessCollection(Vector(owner: owner, vector: element.children))
    }

    public enum Tag: Hashable {
        case html
        case head
        case title
        case base
        case link
        case meta
        case style
        case script
        case noscript
        case template
        case body
        case article
        case section
        case nav
        case aside
        case h1
        case h2
        case h3
        case h4
        case h5
        case h6
        case hgroup
        case header
        case footer
        case address
        case p
        case hr
        case pre
        case blockquote
        case ol
        case ul
        case li
        case dl
        case dt
        case dd
        case figure
        case figcaption
        case main
        case div
        case a
        case em
        case strong
        case small
        case s
        case cite
        case q
        case dfn
        case abbr
        case data
        case time
        case code
        case `var`
        case samp
        case kbd
        case sub
        case sup
        case i
        case b
        case u
        case mark
        case ruby
        case rt
        case rp
        case bdi
        case bdo
        case span
        case br
        case wbr
        case ins
        case del
        case image
        case img
        case iframe
        case embed
        case object
        case param
        case video
        case audio
        case source
        case track
        case canvas
        case map
        case area
        case math
        case mi
        case mo
        case mn
        case ms
        case mtext
        case mglyph
        case malignmark
        case annotation_xml
        case svg
        case foreignobject
        case desc
        case table
        case caption
        case colgroup
        case col
        case tbody
        case thead
        case tfoot
        case tr
        case td
        case th
        case form
        case fieldset
        case legend
        case label
        case input
        case button
        case select
        case datalist
        case optgroup
        case option
        case textarea
        case keygen
        case output
        case progress
        case meter
        case details
        case summary
        case menu
        case menuitem
        case applet
        case acronym
        case bgsound
        case dir
        case frame
        case frameset
        case noframes
        case isindex
        case listing
        case xmp
        case nextid
        case noembed
        case plaintext
        case rb
        case strike
        case basefont
        case big
        case blink
        case center
        case font
        case marquee
        case multicol
        case nobr
        case spacer
        case tt
        case rtc
        case unknown(String)
    }

    public var tag: Tag {
        switch element.tag {
        case GUMBO_TAG_HTML: return .html
        case GUMBO_TAG_HEAD: return .head
        case GUMBO_TAG_TITLE: return .title
        case GUMBO_TAG_BASE: return .base
        case GUMBO_TAG_LINK: return .link
        case GUMBO_TAG_META: return .meta
        case GUMBO_TAG_STYLE: return .style
        case GUMBO_TAG_SCRIPT: return .script
        case GUMBO_TAG_NOSCRIPT: return .noscript
        case GUMBO_TAG_TEMPLATE: return .template
        case GUMBO_TAG_BODY: return .body
        case GUMBO_TAG_ARTICLE: return .article
        case GUMBO_TAG_SECTION: return .section
        case GUMBO_TAG_NAV: return .nav
        case GUMBO_TAG_ASIDE: return .aside
        case GUMBO_TAG_H1: return .h1
        case GUMBO_TAG_H2: return .h2
        case GUMBO_TAG_H3: return .h3
        case GUMBO_TAG_H4: return .h4
        case GUMBO_TAG_H5: return .h5
        case GUMBO_TAG_H6: return .h6
        case GUMBO_TAG_HGROUP: return .hgroup
        case GUMBO_TAG_HEADER: return .header
        case GUMBO_TAG_FOOTER: return .footer
        case GUMBO_TAG_ADDRESS: return .address
        case GUMBO_TAG_P: return .p
        case GUMBO_TAG_HR: return .hr
        case GUMBO_TAG_PRE: return .pre
        case GUMBO_TAG_BLOCKQUOTE: return .blockquote
        case GUMBO_TAG_OL: return .ol
        case GUMBO_TAG_UL: return .ul
        case GUMBO_TAG_LI: return .li
        case GUMBO_TAG_DL: return .dl
        case GUMBO_TAG_DT: return .dt
        case GUMBO_TAG_DD: return .dd
        case GUMBO_TAG_FIGURE: return .figure
        case GUMBO_TAG_FIGCAPTION: return .figcaption
        case GUMBO_TAG_MAIN: return .main
        case GUMBO_TAG_DIV: return .div
        case GUMBO_TAG_A: return .a
        case GUMBO_TAG_EM: return .em
        case GUMBO_TAG_STRONG: return .strong
        case GUMBO_TAG_SMALL: return .small
        case GUMBO_TAG_S: return .s
        case GUMBO_TAG_CITE: return .cite
        case GUMBO_TAG_Q: return .q
        case GUMBO_TAG_DFN: return .dfn
        case GUMBO_TAG_ABBR: return .abbr
        case GUMBO_TAG_DATA: return .data
        case GUMBO_TAG_TIME: return .time
        case GUMBO_TAG_CODE: return .code
        case GUMBO_TAG_VAR: return .var
        case GUMBO_TAG_SAMP: return .samp
        case GUMBO_TAG_KBD: return .kbd
        case GUMBO_TAG_SUB: return .sub
        case GUMBO_TAG_SUP: return .sup
        case GUMBO_TAG_I: return .i
        case GUMBO_TAG_B: return .b
        case GUMBO_TAG_U: return .u
        case GUMBO_TAG_MARK: return .mark
        case GUMBO_TAG_RUBY: return .ruby
        case GUMBO_TAG_RT: return .rt
        case GUMBO_TAG_RP: return .rp
        case GUMBO_TAG_BDI: return .bdi
        case GUMBO_TAG_BDO: return .bdo
        case GUMBO_TAG_SPAN: return .span
        case GUMBO_TAG_BR: return .br
        case GUMBO_TAG_WBR: return .wbr
        case GUMBO_TAG_INS: return .ins
        case GUMBO_TAG_DEL: return .del
        case GUMBO_TAG_IMAGE: return .image
        case GUMBO_TAG_IMG: return .img
        case GUMBO_TAG_IFRAME: return .iframe
        case GUMBO_TAG_EMBED: return .embed
        case GUMBO_TAG_OBJECT: return .object
        case GUMBO_TAG_PARAM: return .param
        case GUMBO_TAG_VIDEO: return .video
        case GUMBO_TAG_AUDIO: return .audio
        case GUMBO_TAG_SOURCE: return .source
        case GUMBO_TAG_TRACK: return .track
        case GUMBO_TAG_CANVAS: return .canvas
        case GUMBO_TAG_MAP: return .map
        case GUMBO_TAG_AREA: return .area
        case GUMBO_TAG_MATH: return .math
        case GUMBO_TAG_MI: return .mi
        case GUMBO_TAG_MO: return .mo
        case GUMBO_TAG_MN: return .mn
        case GUMBO_TAG_MS: return .ms
        case GUMBO_TAG_MTEXT: return .mtext
        case GUMBO_TAG_MGLYPH: return .mglyph
        case GUMBO_TAG_MALIGNMARK: return .malignmark
        case GUMBO_TAG_ANNOTATION_XML: return .annotation_xml
        case GUMBO_TAG_SVG: return .svg
        case GUMBO_TAG_FOREIGNOBJECT: return .foreignobject
        case GUMBO_TAG_DESC: return .desc
        case GUMBO_TAG_TABLE: return .table
        case GUMBO_TAG_CAPTION: return .caption
        case GUMBO_TAG_COLGROUP: return .colgroup
        case GUMBO_TAG_COL: return .col
        case GUMBO_TAG_TBODY: return .tbody
        case GUMBO_TAG_THEAD: return .thead
        case GUMBO_TAG_TFOOT: return .tfoot
        case GUMBO_TAG_TR: return .tr
        case GUMBO_TAG_TD: return .td
        case GUMBO_TAG_TH: return .th
        case GUMBO_TAG_FORM: return .form
        case GUMBO_TAG_FIELDSET: return .fieldset
        case GUMBO_TAG_LEGEND: return .legend
        case GUMBO_TAG_LABEL: return .label
        case GUMBO_TAG_INPUT: return .input
        case GUMBO_TAG_BUTTON: return .button
        case GUMBO_TAG_SELECT: return .select
        case GUMBO_TAG_DATALIST: return .datalist
        case GUMBO_TAG_OPTGROUP: return .optgroup
        case GUMBO_TAG_OPTION: return .option
        case GUMBO_TAG_TEXTAREA: return .textarea
        case GUMBO_TAG_KEYGEN: return .keygen
        case GUMBO_TAG_OUTPUT: return .output
        case GUMBO_TAG_PROGRESS: return .progress
        case GUMBO_TAG_METER: return .meter
        case GUMBO_TAG_DETAILS: return .details
        case GUMBO_TAG_SUMMARY: return .summary
        case GUMBO_TAG_MENU: return .menu
        case GUMBO_TAG_MENUITEM: return .menuitem
        case GUMBO_TAG_APPLET: return .applet
        case GUMBO_TAG_ACRONYM: return .acronym
        case GUMBO_TAG_BGSOUND: return .bgsound
        case GUMBO_TAG_DIR: return .dir
        case GUMBO_TAG_FRAME: return .frame
        case GUMBO_TAG_FRAMESET: return .frameset
        case GUMBO_TAG_NOFRAMES: return .noframes
        case GUMBO_TAG_ISINDEX: return .isindex
        case GUMBO_TAG_LISTING: return .listing
        case GUMBO_TAG_XMP: return .xmp
        case GUMBO_TAG_NEXTID: return .nextid
        case GUMBO_TAG_NOEMBED: return .noembed
        case GUMBO_TAG_PLAINTEXT: return .plaintext
        case GUMBO_TAG_RB: return .rb
        case GUMBO_TAG_STRIKE: return .strike
        case GUMBO_TAG_BASEFONT: return .basefont
        case GUMBO_TAG_BIG: return .big
        case GUMBO_TAG_BLINK: return .blink
        case GUMBO_TAG_CENTER: return .center
        case GUMBO_TAG_FONT: return .font
        case GUMBO_TAG_MARQUEE: return .marquee
        case GUMBO_TAG_MULTICOL: return .multicol
        case GUMBO_TAG_NOBR: return .nobr
        case GUMBO_TAG_SPACER: return .spacer
        case GUMBO_TAG_TT: return .tt
        case GUMBO_TAG_RTC: return .rtc
        case GUMBO_TAG_UNKNOWN:
            var originalTag = element.original_tag
            let originalTagName = withUnsafeMutablePointer(to: &originalTag) { pointer -> Result<String, Never> in
                gumbo_tag_from_original_text(pointer)
                return .success(pointer.pointee.value)
            }

            switch originalTagName {
            case .success(let t): return .unknown(t)
            }
        default: return .unknown("")
        }
    }

    public var attributes: AnyRandomAccessCollection<Attribute> {
        AnyRandomAccessCollection(Vector(owner: owner, vector: element.attributes))
    }
}

public struct Attribute: VectorElement {
    let owner: SwiftGumbo
    let attribute: UnsafeMutablePointer<GumboAttribute>

    init(owner: SwiftGumbo, pointer: UnsafeMutablePointer<GumboAttribute>) {
        self.owner = owner
        self.attribute = pointer
    }

    public var name: String {
        String(cString: attribute.pointee.name)
    }

    public var value: String {
        String(cString: attribute.pointee.value)
    }

    public enum QuoteType {
        case singleQuote
        case doubleQuote
        case other

        public var character: String {
            switch self {
            case .singleQuote: return "\'"
            case .doubleQuote: return "\""
            case .other: return ""
            }
        }
    }

    public var quotedBy: QuoteType {
        switch attribute.pointee.original_value.value.first {
        case "\'": return .singleQuote
        case "\"": return .doubleQuote
        default: return .other
        }
    }
}

public struct Text: CustomDebugStringConvertible {
    let owner: SwiftGumbo
    let text: GumboText

    init(owner: SwiftGumbo, text: GumboText) {
        self.owner = owner
        self.text = text
    }

    public var debugDescription: String {
        value
    }

    public var value: String {
        String(cString: text.text)
    }
}

extension GumboStringPiece {
    var value: String {
        guard data != nil, length > 0 else { return "" }
        return String(data: Data(bytes: data, count: length), encoding: .utf8) ?? ""
    }
}

fileprivate struct Vector<E: VectorElement>: RandomAccessCollection {
    let owner: SwiftGumbo
    let vector: GumboVector

    init(owner: SwiftGumbo, vector: GumboVector) {
        self.owner = owner
        self.vector = vector
    }

    func index(after i: Int) -> Int { i + 1 }
    var startIndex: Int { 0 }
    var endIndex: Int { Int(vector.length) }

    subscript(index: Int) -> E {
        let gumboType = vector.data[index]!.assumingMemoryBound(to: E.GumboType.self)
        return E(owner: owner, pointer: gumboType)
    }
}

fileprivate protocol VectorElement {
    associatedtype GumboType
    init(owner: SwiftGumbo, pointer: UnsafeMutablePointer<GumboType>)
}

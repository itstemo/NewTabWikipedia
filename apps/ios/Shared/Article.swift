import Foundation

struct Article: Codable, Identifiable {
    let pageId: Int
    let title: String
    let description: String
    let extract: String
    let url: URL
    let imageURL: URL?

    var id: Int { pageId }
}

// MARK: - API shapes

struct WikiQueryResponse: Decodable {
    struct Query: Decodable {
        let pages: [Page]?
        let categorymembers: [Member]?
    }
    struct Page: Decodable {
        let pageid: Int?
        let title: String?
        let description: String?
        let extract: String?
        let fullurl: String?
        let thumbnail: Thumb?
        let original: Thumb?
    }
    struct Member: Decodable {
        let pageid: Int?
    }
    struct Thumb: Decodable {
        let source: String?
        let width: Int?
    }
    let query: Query?
}

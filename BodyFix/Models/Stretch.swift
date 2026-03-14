import Foundation

struct Stretch: Identifiable, Codable {
    let id: String
    let name: String
    let targetRegions: [String]
    let difficulty: String
    let holdDuration: Int
    let repScheme: String
    let description: String
    let imageAssetName: String
}

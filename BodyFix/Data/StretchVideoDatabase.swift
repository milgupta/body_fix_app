import Foundation

struct StretchVideo: Decodable, Hashable {
    let uid: String
    let filename: String?
    let name: String?
    let hlsURL: String?
}

enum StretchVideoDatabase {
    private struct Manifest: Decodable {
        let provider: String?
        let customerCode: String?
        let videos: [String: StretchVideo]
    }

    private static let manifest: Manifest? = {
        guard let url = Bundle.main.url(forResource: "stretch_videos", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? JSONDecoder().decode(Manifest.self, from: data)
    }()

    static func video(for stretchId: String) -> StretchVideo? {
        manifest?.videos[stretchId]
    }

    static func hlsURL(for stretchId: String) -> URL? {
        guard let video = video(for: stretchId) else { return nil }

        if let hlsURL = video.hlsURL,
           let url = URL(string: hlsURL) {
            return url
        }

        guard let customerCode = manifest?.customerCode,
              !customerCode.isEmpty
        else {
            return nil
        }

        return URL(string: "https://customer-\(customerCode).cloudflarestream.com/\(video.uid)/manifest/video.m3u8")
    }

    static func thumbnailURL(for stretchId: String) -> URL? {
        if let hlsURL = video(for: stretchId)?.hlsURL {
            let thumbnailURL = hlsURL.replacingOccurrences(
                of: "/manifest/video.m3u8",
                with: "/thumbnails/thumbnail.jpg?time=1s"
            )
            if let url = URL(string: thumbnailURL) {
                return url
            }
        }

        guard let video = video(for: stretchId),
              let customerCode = manifest?.customerCode,
              !customerCode.isEmpty
        else {
            return nil
        }

        return URL(string: "https://customer-\(customerCode).cloudflarestream.com/\(video.uid)/thumbnails/thumbnail.jpg?time=1s")
    }
}

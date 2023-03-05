import Foundation

extension String: Error {}

func draw(dot: String) async throws -> String {
    var components = URLComponents(string: "https://dot-to-ascii.ggerganov.com/dot-to-ascii.php")!
    components.queryItems = [URLQueryItem(name: "src", value: dot),
                             URLQueryItem(name: "boxart", value: "1")]
    
    let request = URLRequest(url: components.url!)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    guard let string = String(data: data, encoding: .utf8) else {
        throw "data == nil"
    }
    
    return string
}

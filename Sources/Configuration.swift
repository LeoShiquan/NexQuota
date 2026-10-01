import Foundation

struct SiteConfiguration {
    let siteURL: URL

    enum ConfigurationError: LocalizedError {
        case missingFile, invalidAddress

        var errorDescription: String? {
            switch self {
            case .missingFile: return "缺少站点配置。请复制 Config.example.plist 为 Config.local.plist，填写账户用量页地址后重新编译。"
            case .invalidAddress: return "站点地址必须是有效的 HTTPS 网页地址，且不能包含用户名、密码或片段标识。"
            }
        }
    }

    static func validate(_ address: String) throws -> URL {
        let value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil,
              url.fragment == nil else { throw ConfigurationError.invalidAddress }
        return url
    }

    static func decode(_ data: Data) throws -> SiteConfiguration {
        guard let object = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let address = object["SiteURL"] as? String else { throw ConfigurationError.invalidAddress }
        return SiteConfiguration(siteURL: try validate(address))
    }

    static func load(bundle: Bundle = .main) throws -> SiteConfiguration {
        guard let path = bundle.url(forResource: "SiteConfig", withExtension: "plist") else {
            throw ConfigurationError.missingFile
        }
        return try decode(Data(contentsOf: path))
    }
}

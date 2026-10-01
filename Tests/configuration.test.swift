import Foundation

@main struct ConfigurationTests {
    static func main() throws {
        var passed = 0
        func check(_ label: String, _ condition: Bool) {
            precondition(condition, label); passed += 1; print("PASS \(label)")
        }
        func rejects(_ value: String) -> Bool { (try? SiteConfiguration.validate(value)) == nil }
        let url = try SiteConfiguration.validate("https://panel.example.com/Shadowsockes.aspx?view=usage")
        check("接受有效的 HTTPS 账户页面并保留查询参数", url.query == "view=usage")
        check("清理配置地址首尾空白", try SiteConfiguration.validate("  https://panel.example.com/ \n").host == "panel.example.com")
        check("拒绝 HTTP", rejects("http://panel.example.com/"))
        check("拒绝缺少主机名的地址", rejects("https:///"))
        check("拒绝普通文本", rejects("not a URL"))
        check("拒绝在 URL 中嵌入用户名", rejects("https://demo@panel.example.com/"))
        check("拒绝在 URL 中嵌入密码", rejects("https://demo:placeholder@panel.example.com/"))
        check("拒绝 URL 片段标识", rejects("https://panel.example.com/#usage"))
        let data = try PropertyListSerialization.data(fromPropertyList: ["SiteURL": url.absoluteString], format: .xml, options: 0)
        check("读取 plist 配置", try SiteConfiguration.decode(data).siteURL == url)
        let missing = try PropertyListSerialization.data(fromPropertyList: ["Unknown": "example"], format: .xml, options: 0)
        check("缺少 SiteURL 时拒绝配置", (try? SiteConfiguration.decode(missing)) == nil)
        print("\(passed) configuration tests passed")
    }
}

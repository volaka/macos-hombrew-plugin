import Foundation

public struct BrewPackage: Identifiable, Decodable {
    public var id: String { name }
    public let name: String
    public let installedVersions: [String]
    public let currentVersion: String

    enum CodingKeys: String, CodingKey {
        case name
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
    }
}

public struct BrewOutdatedResponse: Decodable {
    public let formulae: [BrewPackage]
    public let casks: [BrewCask]
}

public struct BrewCask: Identifiable, Decodable {
    public var id: String { name }
    public let name: String
    public let installedVersions: [String]   // fixed: brew returns an array, not a plain string
    public let currentVersion: String

    enum CodingKeys: String, CodingKey {
        case name
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
    }
}

public protocol BrewPackageProtocol {
    var name: String { get }
    var installedVersions: [String] { get }
    var currentVersion: String { get }
}
extension BrewPackage: BrewPackageProtocol {}
extension BrewCask: BrewPackageProtocol {}

/// Carried as NSMenuItem.representedObject so the upgrade popup knows what to upgrade.
public final class PackageMenuInfo: NSObject {
    public let name: String
    public let installed: String
    public let current: String

    public init(name: String, installed: String, current: String) {
        self.name = name
        self.installed = installed
        self.current = current
    }
}

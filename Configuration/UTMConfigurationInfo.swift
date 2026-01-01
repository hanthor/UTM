//
// Copyright © 2022 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Basic information and icon
public struct UTMConfigurationInfo: Codable {
    /// VM Name
    public var name: String = ""
    
    /// Path to icon
    public var iconURL: URL?
    
    /// Use custom icon
    public var isIconCustom: Bool = false
    
    /// User selected icon
    public var selectedCustomIconPath: URL?
    
    /// Notes
    public var notes: String?
    
    /// UUID
    public var uuid: UUID = UUID()
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case icon = "Icon"
        case isIconCustom = "IconCustom"
        case notes = "Notes"
        case uuid = "UUID"
    }
    
    public init() {
    }
    
    public init(from decoder: Decoder) throws {
        guard let dataURL = decoder.userInfo[.dataURL] as? URL else {
            throw UTMConfigurationError.invalidDataURL
        }
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        isIconCustom = try values.decode(Bool.self, forKey: .isIconCustom)
        if isIconCustom {
            if let iconName = try values.decodeIfPresent(String.self, forKey: .icon) {
                iconURL = dataURL.appendingPathComponent(iconName)
            } else {
                isIconCustom = false
            }
        }
        if !isIconCustom {
            if let iconName = try values.decodeIfPresent(String.self, forKey: .icon) {
                iconURL = Self.builtinIcon(named: iconName)
            }
        }
        notes = try values.decodeIfPresent(String.self, forKey: .notes)
        uuid = try values.decode(UUID.self, forKey: .uuid)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if isIconCustom {
            try container.encodeIfPresent(iconURL?.lastPathComponent, forKey: .icon)
        } else {
            try container.encodeIfPresent(Self.builtinIconName(from: iconURL), forKey: .icon)
        }
        try container.encode(isIconCustom, forKey: .isIconCustom)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(uuid, forKey: .uuid)
    }
    
    private static func builtinIcon(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Icons") {
            return url
        } else {
            return Bundle.main.url(forResource: name, withExtension: "png")
        }
    }
    
    private static func builtinIconName(from url: URL?) -> String? {
        if let url = url {
            return url.deletingPathExtension().lastPathComponent
        } else {
            return nil
        }
    }
}

// MARK: - Conversion of old config format

extension UTMConfigurationInfo {
    #if os(macOS)
    init(migrating oldConfig: UTMLegacyQemuConfiguration) {
        self.init()
        name = oldConfig.name
        notes = oldConfig.notes
        if let uuidString = oldConfig.systemUUID, let uuid = UUID(uuidString: uuidString) {
            self.uuid = uuid
        }
        isIconCustom = oldConfig.iconCustom
        if isIconCustom {
            if let name = oldConfig.icon, let dataURL = oldConfig.existingPath {
                iconURL = dataURL.appendingPathComponent(name)
            } else {
                isIconCustom = false
            }
        }
        if !isIconCustom, let name = oldConfig.icon {
            iconURL = Self.builtinIcon(named: name)
        }
    }
    #endif
    
    #if os(macOS)
    init(migrating oldConfig: UTMLegacyAppleConfiguration, dataURL: URL) {
        self.init()
        name = oldConfig.name
        notes = oldConfig.notes
        uuid = UUID()
        isIconCustom = oldConfig.iconCustom
        if isIconCustom {
            if let name = oldConfig.icon {
                iconURL = dataURL.appendingPathComponent(name)
            } else {
                isIconCustom = false
            }
        }
        if let name = oldConfig.icon {
            iconURL = Self.builtinIcon(named: name)
        }
    }
    #endif
}

// MARK: - Saving data

extension UTMConfigurationInfo {
    @MainActor mutating func saveData(to dataURL: URL) async throws -> [URL] {
        // save new icon
        if isIconCustom, let iconURL = iconURL {
            let newIconURL = try await UTMQemuConfiguration.copyItemIfChanged(from: iconURL, to: dataURL)
            self.iconURL = newIconURL
            return [newIconURL]
        }
        return []
    }
}

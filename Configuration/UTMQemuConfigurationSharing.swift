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

/// Directory and clipboard sharing settings
public struct UTMQemuConfigurationSharing: Codable {
    /// SPICE or virtfs sharing.
    public var directoryShareMode: QEMUFileShareMode = .none
    
    /// Path to the directory to share.
    public var directoryShareUrl: URL?
    
    /// Read only setting for the directory share.
    public var isDirectoryShareReadOnly: Bool = false
    
    /// SPICE clipboard sharing.
    public var hasClipboardSharing: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case directoryShareMode = "DirectoryShareMode"
        case isDirectoryShareReadOnly = "DirectoryShareReadOnly"
        case hasClipboardSharing = "ClipboardSharing"
    }
    
    public init() {
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        directoryShareMode = try values.decode(QEMUFileShareMode.self, forKey: .directoryShareMode)
        isDirectoryShareReadOnly = try values.decode(Bool.self, forKey: .isDirectoryShareReadOnly)
        hasClipboardSharing = try values.decode(Bool.self, forKey: .hasClipboardSharing)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(directoryShareMode, forKey: .directoryShareMode)
        try container.encode(isDirectoryShareReadOnly, forKey: .isDirectoryShareReadOnly)
        try container.encode(hasClipboardSharing, forKey: .hasClipboardSharing)
    }
}

// MARK: - Default construction

extension UTMQemuConfigurationSharing {
    public init(forArchitecture architecture: QEMUArchitecture, target: any QEMUTarget) {
        self.init()
        let rawTarget = target.rawValue
        if !architecture.hasAgentSupport {
            hasClipboardSharing = false
        }
        if !architecture.hasSharingSupport {
            directoryShareMode = .none
        }
        // overrides for specific configurations
        if rawTarget.hasPrefix("pc") || rawTarget.hasPrefix("q35") {
            directoryShareMode = .webdav
            hasClipboardSharing = true
        } else if (architecture == .arm || architecture == .aarch64) && (rawTarget.hasPrefix("virt-") || rawTarget == "virt") {
            directoryShareMode = .webdav
            hasClipboardSharing = true
        } else if architecture == .m68k && rawTarget == QEMUTarget_m68k.q800.rawValue {
            directoryShareMode = .virtfs
        } else if [.ppc, .ppc64].contains(architecture) && rawTarget == QEMUTarget_ppc.mac99.rawValue {
            directoryShareMode = .virtfs
        }
    }
}

// MARK: - Conversion of old config format

extension UTMQemuConfigurationSharing {
    #if os(macOS)
    init(migrating oldConfig: UTMLegacyQemuConfiguration) {
        self.init()
        if oldConfig.shareDirectoryEnabled {
            directoryShareMode = .webdav
        }
        isDirectoryShareReadOnly = oldConfig.shareDirectoryReadOnly
        hasClipboardSharing = oldConfig.shareClipboardEnabled
    }
    #endif
}

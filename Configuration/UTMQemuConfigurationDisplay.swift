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

/// Settings for a single display.
public struct UTMQemuConfigurationDisplay: Codable, Identifiable {
    /// Hardware card to emulate.
    public var hardware: any QEMUDisplayDevice = QEMUDisplayDevice_x86_64.virtio_vga
    
    /// Only used for VGA devices.
    var vgaRamMib: Int?
    
    /// If true, the display should be dynamically resized to the window size.
    public var isDynamicResolution: Bool = true
    
    /// if true, the display is native to the host.
    public var isNativeGUI: Bool = false
    
    /// Scaling filter.
    public var upscalingFilter: QEMUScaler = .linear
    
    /// Scaling filter.
    public var downscalingFilter: QEMUScaler = .linear
    
    /// If true, the display is retina.
    public var isRetina: Bool = false
    /// If true, use the true (retina) resolution of the display. Otherwise, use the percieved resolution.
    var isNativeResolution: Bool = false
    
    public var id: String = UUID().uuidString
    
    enum CodingKeys: String, CodingKey {
        case hardware = "Hardware"
        case vgaRamMib = "VgaRamMib"
        case isDynamicResolution = "DynamicResolution"
        case upscalingFilter = "UpscalingFilter"
        case downscalingFilter = "DownscalingFilter"
        case isRetina = "Retina"
        case isNativeResolution = "NativeResolution"
        case isNativeGUI = "NativeGUI"
        case identifier = "Identifier"
    }
    
    public init() {
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hardware = try values.decode(AnyQEMUConstant.self, forKey: .hardware)
        vgaRamMib = try values.decodeIfPresent(Int.self, forKey: .vgaRamMib)
        if let isDynamicResolution = try values.decodeIfPresent(Bool.self, forKey: .isDynamicResolution) {
            self.isDynamicResolution = isDynamicResolution
        }
        if let isNativeGUI = try values.decodeIfPresent(Bool.self, forKey: .isNativeGUI) {
            self.isNativeGUI = isNativeGUI
        }
        upscalingFilter = try values.decode(QEMUScaler.self, forKey: .upscalingFilter)
        downscalingFilter = try values.decode(QEMUScaler.self, forKey: .downscalingFilter)
        isRetina = try values.decode(Bool.self, forKey: .isRetina)
        isNativeResolution = try values.decode(Bool.self, forKey: .isNativeResolution)
        id = try values.decode(String.self, forKey: .identifier)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hardware.asAnyQEMUConstant(), forKey: .hardware)
        try container.encodeIfPresent(vgaRamMib, forKey: .vgaRamMib)
        try container.encode(isDynamicResolution, forKey: .isDynamicResolution)
        try container.encode(upscalingFilter, forKey: .upscalingFilter)
        try container.encode(downscalingFilter, forKey: .downscalingFilter)
        try container.encode(isNativeResolution, forKey: .isNativeResolution)
    }
}

// MARK: - Default construction

extension UTMQemuConfigurationDisplay {
    public init?(forArchitecture architecture: QEMUArchitecture, target: any QEMUTarget) {
        self.init()
        let rawTarget = target.rawValue
        if !architecture.hasAgentSupport || rawTarget.hasPrefix("pc") || rawTarget == "isapc" {
            isDynamicResolution = false
        }
        if rawTarget.hasPrefix("pc") {
            hardware = QEMUDisplayDevice_i386.cirrus_vga
        } else if rawTarget.hasPrefix("q35") {
            hardware = QEMUDisplayDevice_x86_64.virtio_vga
        } else if rawTarget == "isapc" {
            hardware = QEMUDisplayDevice_x86_64.isa_vga
        } else if rawTarget.hasPrefix("virt-") || rawTarget == "virt" {
            hardware = QEMUDisplayDevice_aarch64.virtio_ramfb
        } else if architecture == .m68k && rawTarget == QEMUTarget_m68k.q800.rawValue {
            hardware = QEMUDisplayDevice_m68k.nubus_macfb
        } else {
            let cards = architecture.displayDeviceType.allRawValues
            if cards.contains("VGA") {
                hardware = AnyQEMUConstant(rawValue: "VGA")!
            } else if let first = cards.first {
                hardware = AnyQEMUConstant(rawValue: first)!
            } else {
                return nil
            }
        }
    }
}

// MARK: - Conversion of old config format

extension UTMQemuConfigurationDisplay {
    #if os(macOS)
    init?(migrating oldConfig: UTMLegacyQemuConfiguration) {
        self.init()
        guard !oldConfig.displayConsoleOnly else {
            return nil
        }
        if let hardwareStr = oldConfig.displayCard {
            hardware = AnyQEMUConstant(rawValue: hardwareStr)!
        }
        isDynamicResolution = oldConfig.displayFitScreen
        isNativeResolution = oldConfig.displayRetina
        if let upscaler = convertScaler(from: oldConfig.displayUpscaler) {
            upscalingFilter = upscaler
        }
        if let downscaler = convertScaler(from: oldConfig.displayDownscaler) {
            downscalingFilter = downscaler
        }
    }
    #endif
    
    private func convertScaler(from str: String?) -> QEMUScaler? {
        if str == "linear" {
            return .linear
        } else if str == "nearest" {
            return .nearest
        } else {
            return nil
        }
    }
}

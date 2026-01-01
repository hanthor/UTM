import Adwaita
import Configuration

struct VMSettingsView: View {
    @Binding var config: UTMQemuConfiguration
    @Binding var isPresented: Bool
    
    struct Category: Identifiable {
        let id: String
        var name: String { id }
    }
    
    let categories = [
        Category(id: "Information"),
        Category(id: "System"),
        Category(id: "QEMU"),
        Category(id: "Drives"),
        Category(id: "Display"),
        Category(id: "Network"),
        Category(id: "Input"),
        Category(id: "Sharing")
    ]
    
    @State private var selection: String = "Information"
    
    @MainActor var view: Body {
        NavigationSplitView(sidebar: {
            List(categories, selection: $selection) { item in
                Label(item.name)
            }
            .sidebarStyle()
            .navigationTitle("Settings")
        }, content: {
            ScrollView {
                switch selection {
                case "Information":
                        Form {
                            FormSection("Information") {
                                EntryRow("Name", text: $config.information.name)
                                EntryRow("Notes", text: Binding(
                                    get: { config.information.notes ?? "" },
                                    set: { config.information.notes = $0.isEmpty ? nil : $0 }
                                ))
                            }
                        }
                        .padding()
                case "System":
                        Form {
                            FormSection("System") {
                                ComboRow(
                                    "Architecture",
                                    selection: Binding(
                                        get: { config.system.architecture.rawValue },
                                        set: { config.system.architecture = QEMUArchitecture(rawValue: $0) ?? .x86_64 }
                                    ),
                                    values: QEMUArchitecture.allCases
                                )
                                SpinRow("Memory", value: $config.system.memorySize, min: 32, max: 65536)
                                    .subtitle("MB")
                                SpinRow("CPU Count", value: $config.system.cpuCount, min: 0, max: 128)
                                    .subtitle("0 for default")
                            }
                        }
                        .padding()
                case "Drives":
                        Form {
                            FormSection("Drives") {
                                ForEach(config.drives) { drive in
                                    ExpanderRow()
                                        .title(drive.imageURL?.lastPathComponent ?? "New Drive")
                                        .subtitle(drive.interface.prettyValue)
                                        .rows {
                                            ComboRow(
                                                "Interface",
                                                selection: Binding(
                                                    get: { drive.interface.rawValue },
                                                    set: { newValue in
                                                        if let index = config.drives.firstIndex(where: { $0.id == drive.id }) {
                                                            config.drives[index].interface = QEMUDriveInterface(rawValue: newValue) ?? .virtio
                                                        }
                                                    }
                                                ),
                                                values: QEMUDriveInterface.allCases
                                            )
                                            ComboRow(
                                                "Image Type",
                                                selection: Binding(
                                                    get: { drive.imageType.rawValue },
                                                    set: { newValue in
                                                        if let index = config.drives.firstIndex(where: { $0.id == drive.id }) {
                                                            config.drives[index].imageType = QEMUDriveImageType(rawValue: newValue) ?? .disk
                                                        }
                                                    }
                                                ),
                                                values: QEMUDriveImageType.allCases
                                            )
                                            ActionRow("Remove Drive")
                                                .subtitle("Delete this drive permanently")
                                                .suffix {
                                                    Button(icon: .default(icon: .userTrash)) {
                                                        config.drives.removeAll(where: { $0.id == drive.id })
                                                    }
                                                    .style("destructive-action")
                                                }
                                        }
                                }
                            }
                            .headerSuffix {
                                Button(icon: .default(icon: .listAdd)) {
                                    let newDrive = UTMQemuConfigurationDrive(
                                        forArchitecture: config.system.architecture,
                                        target: config.system.target
                                    )
                                    config.drives.append(newDrive)
                                }
                                .style("flat")
                            }
                        }
                        .padding()
                case "QEMU":
                        Form {
                            FormSection("Tweaks") {
                                SwitchRow("UEFI Boot", isOn: $config.qemu.hasUefiBoot)
                                SwitchRow("RNG Device", isOn: $config.qemu.hasRNGDevice)
                                SwitchRow("Hypervisor", isOn: $config.qemu.hasHypervisor)
                                SwitchRow("Balloon Device", isOn: $config.qemu.hasBalloonDevice)
                                SwitchRow("TPM Device", isOn: $config.qemu.hasTPMDevice)
                                SwitchRow("Local Time", isOn: $config.qemu.hasRTCLocalTime)
                                SwitchRow("Debug Log", isOn: $config.qemu.hasDebugLog)
                            }
                        }
                        .padding()
                case "Display":
                        Form {
                             if config.displays.indices.contains(0) {
                                FormSection("Scaling") {
                                    ComboRow("Upscaling", selection: Binding(
                                        get: { config.displays[0].upscalingFilter.rawValue },
                                        set: { config.displays[0].upscalingFilter = QEMUScaler(rawValue: $0) ?? .linear }
                                    ), values: QEMUScaler.allCases)
                                    ComboRow("Downscaling", selection: Binding(
                                        get: { config.displays[0].downscalingFilter.rawValue },
                                        set: { config.displays[0].downscalingFilter = QEMUScaler(rawValue: $0) ?? .linear }
                                    ), values: QEMUScaler.allCases)
                                    SwitchRow("Retina Mode", isOn: Binding(
                                        get: { config.displays[0].isRetina },
                                        set: { config.displays[0].isRetina = $0 }
                                    ))
                                    SwitchRow("Dynamic Resolution", isOn: Binding(
                                        get: { config.displays[0].isDynamicResolution },
                                        set: { config.displays[0].isDynamicResolution = $0 }
                                    ))
                                }
                             } else {
                                 StatusPage()
                                    .title("No Display")
                             }
                        }
                        .padding()
                case "Network":
                        Form {
                             if config.networks.indices.contains(0) {
                                FormSection("Network") {
                                    ComboRow("Mode", selection: Binding(
                                        get: { config.networks[0].mode.rawValue },
                                        set: { config.networks[0].mode = QEMUNetworkMode(rawValue: $0) ?? .emulated }
                                    ), values: QEMUNetworkMode.allCases)
                                    EntryRow("MAC Address", text: Binding(
                                        get: { config.networks[0].macAddress },
                                        set: { config.networks[0].macAddress = $0 }
                                    ))
                                    SwitchRow("Isolate from Host", isOn: Binding(
                                        get: { config.networks[0].isIsolateFromHost },
                                        set: { config.networks[0].isIsolateFromHost = $0 }
                                    ))
                                    if config.networks[0].mode == .bridged {
                                        EntryRow("Bridge Interface", text: Binding(
                                            get: { config.networks[0].bridgeInterface ?? "" },
                                            set: { config.networks[0].bridgeInterface = $0.isEmpty ? nil : $0 }
                                        ))
                                    }
                                }
                             } else {
                                 StatusPage()
                                    .title("No Network")
                             }
                        }
                        .padding()
                case "Input":
                        Form {
                            FormSection("USB") {
                                ComboRow("USB Support", selection: Binding(
                                    get: { config.input.usbBusSupport.rawValue },
                                    set: { config.input.usbBusSupport = QEMUUSBBus(rawValue: $0) ?? .usb2_0 }
                                ), values: QEMUUSBBus.allCases)
                                SwitchRow("USB Sharing", isOn: $config.input.hasUsbSharing)
                                SpinRow("Max Shared Devices", value: $config.input.maximumUsbShare, min: 0, max: 32)
                            }
                        }
                        .padding()
                case "Sharing":
                        Form {
                             FormSection("Sharing") {
                                ComboRow("Directory Share", selection: Binding(
                                    get: { config.sharing.directoryShareMode.rawValue },
                                    set: { config.sharing.directoryShareMode = QEMUFileShareMode(rawValue: $0) ?? .none }
                                ), values: QEMUFileShareMode.allCases)
                                SwitchRow("Read Only", isOn: $config.sharing.isDirectoryShareReadOnly)
                                SwitchRow("Clipboard Sharing", isOn: $config.sharing.hasClipboardSharing)
                             }
                        }
                        .padding()
                default:
                        StatusPage()
                            .title(selection)
                            .description("Not implemented yet.")
                }
            }
        })
        .topToolbar(visible: true) {
             HeaderBar()
                .showEndTitleButtons(true) // Should be false for modal? Or use Cancel/Save
                .start {
                    Button(icon: .default(icon: .goPrevious)) {
                        isPresented = false
                    }
                }
                .end {
                    Button("Save") {
                        VMStore.shared.add(config)
                        isPresented = false
                    }
                    .style("suggested-action")
                }
        }
    }
}

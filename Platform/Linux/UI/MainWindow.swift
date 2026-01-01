import Adwaita
import Configuration
import Foundation

struct MainWindow: View {
    @State private var selection: UTMQemuConfiguration.ID? = nil
    @State private var showContent = false
    
    @State private var showingSettings = false
    
    private let logger = Logger(subsystem: "com.utmapp.UTM", category: "MainWindow")

    @MainActor var view: Body {
        let safeSelection = Binding<UTMQemuConfiguration.ID>(
            get: {
                if let id = selection, VMStore.shared.vms.contains(where: { $0.id == id }) {
                    return id
                }
                return VMStore.shared.vms.first?.id ?? UUID()
            },
            set: { newValue in
                selection = newValue
                showingSettings = false // Close settings if selection changes
            }
        )

        NavigationSplitView(sidebar: {
            Box(spacing: 10).append {
                if VMStore.shared.vms.isEmpty {
                    Label("No VMs")
                        .style("title-2")
                        .padding()
                } else {
                    List(VMStore.shared.vms, selection: safeSelection) { vm in
                        Box(spacing: 5).append {
                            Label(vm.information.name)
                                .style("heading")
                            Label(vm.system.target.prettyValue)
                                .style("body")
                        }
                        .padding(12)
                    }
                    .sidebarStyle()
                }
            }
            .navigationTitle("UTM")
            .bottomToolbar {
                HeaderBar.end {
                    Button(icon: .default(icon: .documentOpen)) {
                        logger.info("Import VM - Not implemented")
                    }
                    .tooltip("Import VM")
                    
                    Button(icon: .default(icon: .listAdd)) {
                        createNewVM()
                    }
                    .tooltip("Create New VM")
                }
            }
        }, content: {
            if let selectedId = selection, let index = VMStore.shared.vms.firstIndex(where: { $0.id == selectedId }) {
                if showingSettings {
                     let configBinding = Binding(
                        get: { VMStore.shared.vms[index] },
                        set: { VMStore.shared.vms[index] = $0 }
                     )
                     VMSettingsView(config: configBinding, isPresented: $showingSettings)
                } else {
                     VMDetailsView(vm: VMStore.shared.vms[index], showContent: $showContent, showSettings: $showingSettings)
                }
            } else {
                StatusPage()
                    .iconName("computer-symbolic")
                    .title("No VM Selected")
                    .description("Select a VM from the sidebar to view details.")
            }
        })
        .showContent($showContent)
    }
    
    @MainActor func createNewVM() {
        logger.info("Creating new VM...")
        let config = UTMQemuConfiguration()
        config.information.name = "New VM \(Int(Date().timeIntervalSince1970))"
        config.system.architecture = QEMUArchitecture.x86_64
        config.system.target = QEMUTarget_x86_64.q35
        if let display = UTMQemuConfigurationDisplay(forArchitecture: config.system.architecture, target: config.system.target) {
            config.displays.append(display)
        }
        if let network = UTMQemuConfigurationNetwork(forArchitecture: config.system.architecture, target: config.system.target) {
            config.networks.append(network)
        }
        let drive = UTMQemuConfigurationDrive(forArchitecture: config.system.architecture, target: config.system.target, isExternal: true)
        config.drives.append(drive)
        VMStore.shared.add(config)
        logger.info("Created VM: \(config.information.name)")
        selection = config.id
        showingSettings = true
        showContent = true // Ensure content area is shown
    }
}

extension View {
    func sidebarToolbar(action: @escaping () -> Void) -> View {
        return self // Placeholder, Adwaita needs specific sidebar toolbar handling
        // Adwaita's NavigationSplitView doesn't easily expose sidebar toolbar area via modifier on Content?
        // Actually, logic: Put the toolbar inside the Sidebar closure!
    }
}

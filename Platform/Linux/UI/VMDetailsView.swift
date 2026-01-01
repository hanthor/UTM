import Adwaita
import Configuration
import Foundation

struct VMDetailsView: View {
    
    var vm: UTMQemuConfiguration
    @Binding var showContent: Bool
    @Binding var showSettings: Bool

    
    private let logger = Logger(subsystem: "com.utmapp.UTM", category: "VMDetailsView")
    
    var view: Body {
        ToolbarView()
            .content {
                Box(spacing: 20).append {
                    // Header
                    Box(spacing: 16).append {
                        if let iconURL = vm.information.iconURL, let iconData = try? Data(contentsOf: iconURL) {
                             Picture()
                                .alternativeText(vm.information.name)
                                .data(iconData)
                                .style("icon-64")
                        } else {
                            // Fallback using StatusPage-like appearance or just Label
                            Label(vm.information.name)
                                .style("title-1")
                        }
                    }
                    .halign(.center)
                    .padding()
                    
                    // Info Group
                    PreferencesGroup()
                        .child {
                            ActionRow("Status")
                                .subtitle("Stopped")
                            ActionRow("Architecture")
                                .subtitle(vm.system.architecture.prettyValue)
                            ActionRow("Memory")
                                .subtitle("\(vm.system.memorySize) MB")
                        }
                    
                    // Drives Group
                    PreferencesGroup()
                        .title("Drives")
                        .child {
                            ForEach(vm.drives) { drive in
                                 ActionRow(drive.imageURL?.lastPathComponent ?? "New Drive")
                                    .subtitle(drive.interface.prettyValue)
                            }
                        }
                }
                .padding()
                .valign(.start)
            }
            .top {
                HeaderBar()
                    .end {
                         Button(icon: .default(icon: .mediaPlaybackStart)) {
                            Task { @MainActor in
                                logger.info("Start VM requested for \(vm.information.name)")
                                QEMURunner.shared.start(vm)
                            }
                        }
                        .tooltip("Start VM")
                        .style("suggested-action")
                        
                        Button(icon: .default(icon: .editCopy)) {
                            logger.info("Clone VM requested for \(vm.information.name) - Not implemented")
                        }
                        .tooltip("Clone")
                        
                        Button(icon: .default(icon: .documentSend)) {
                            logger.info("Share VM requested for \(vm.information.name) - Not implemented")
                        }
                        .tooltip("Share")
                        
                        Button(icon: .default(icon: .userTrash)) {
                            Task { @MainActor in
                                logger.info("Deleting VM: \(vm.information.name)")
                                VMStore.shared.remove(vm)
                            }
                        }
                        .tooltip("Delete")
                        .style("destructive-action")
                        
                        Button(icon: .default(icon: .preferencesSystem)) {
                            showSettings = true
                        }
                        .tooltip("Settings")
                    }
            }
    }
}

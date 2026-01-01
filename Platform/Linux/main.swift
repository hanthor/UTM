import Adwaita

struct UTMApp: App {
    let id = "com.utmapp.linux"
    var app: GTUIApp!

    var scene: Scene {
        Window(id: "main") { _ in
            MainWindow()
        }
    }
}

UTMApp.main()

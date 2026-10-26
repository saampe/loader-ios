import UIKit

@_silgen_name("UnboundSimulatorAttachMarkedGlass")
private func attachMarkedGlass(_ identifier: UnsafePointer<CChar>) -> Int32
@_silgen_name("UnboundSimulatorDetachMarkedGlass")
private func detachMarkedGlass(_ identifier: UnsafePointer<CChar>)
@_silgen_name("UnboundSimulatorAttachGlass")
private func attachActualGlass(_ host: UnsafeMutableRawPointer, _ clear: Int32, _ overrideBackground: Int32) -> Int32
@_silgen_name("UnboundSimulatorDetachGlass")
private func detachActualGlass(_ host: UnsafeMutableRawPointer)
@_silgen_name("UnboundSimulatorIsGlassAttached")
private func isActualGlassAttached(_ host: UnsafeMutableRawPointer) -> Int32

@main
final class GlassDemo: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: UIScreen.main.bounds)
        window.frame = scene?.coordinateSpace.bounds ?? UIScreen.main.bounds
        let args = ProcessInfo.processInfo.arguments
        let controller: UIViewController = args.contains("--actual-host") ? ActualHostProofController() :
            (args.contains("--tabs") ? NativeTabsProofController() : GlassDemoViewController())
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class DeferredGlassView: UIVisualEffectView {
    var pendingGlass: UIGlassEffect?
    override func layoutSubviews() {
        super.layoutSubviews()
        if window != nil, let pendingGlass, effect !== pendingGlass {
            effect = pendingGlass
        }
    }
}

final class GlassDemoViewController: UIViewController {
    private let background = UIView()
    private let colorful = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)

        background.translatesAutoresizingMaskIntoConstraints = false
        colorful.colors = [UIColor.systemIndigo.cgColor, UIColor.systemTeal.cgColor,
                           UIColor.systemOrange.cgColor, UIColor.systemPink.cgColor]
        colorful.startPoint = CGPoint(x: 0.0, y: 0.0)
        colorful.endPoint = CGPoint(x: 1.0, y: 1.0)
        background.layer.addSublayer(colorful)
        view.addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            background.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            background.widthAnchor.constraint(equalToConstant: 330),
            background.heightAnchor.constraint(equalToConstant: 320)
        ])

        let title = UILabel()
        title.text = "UIKit Liquid Glass simulator proof"
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        if !ProcessInfo.processInfo.arguments.contains("--baseline") {
            addGlass(.regular, label: "Regular UIGlassEffect", y: 95)
            addGlass(.clear, label: "Clear UIGlassEffect", y: 200)
        }

        let dark = UIView()
        dark.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        dark.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dark)
        NSLayoutConstraint.activate([
            dark.topAnchor.constraint(equalTo: background.bottomAnchor, constant: 32),
            dark.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dark.widthAnchor.constraint(equalToConstant: 330),
            dark.heightAnchor.constraint(equalToConstant: 120)
        ])
        guard !ProcessInfo.processInfo.arguments.contains("--baseline") else { return }
        let effect = DeferredGlassView(effect: nil)
        effect.pendingGlass = UIGlassEffect(style: .clear)
        effect.frame = CGRect(x: 45, y: 20, width: 240, height: 70)
        effect.cornerConfiguration = .capsule()
        let text = UILabel(frame: effect.bounds)
        text.text = "Clear on a dark surface"
        text.textColor = .label
        text.textAlignment = .center
        effect.contentView.addSubview(text)
        dark.addSubview(effect)

        // React Native-like hierarchy proof: a native material is inserted
        // behind the target content rather than over a complete app window.
        // The solid sibling demonstrates why transparent host backgrounds matter.
        let dock = UIView()
        dock.translatesAutoresizingMaskIntoConstraints = false
        dock.backgroundColor = .clear
        view.addSubview(dock)
        NSLayoutConstraint.activate([
            dock.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            dock.widthAnchor.constraint(equalToConstant: 330),
            dock.heightAnchor.constraint(equalToConstant: 78)
        ])

        let dockMaterial = DeferredGlassView(effect: nil)
        dockMaterial.pendingGlass = UIGlassEffect(style: .regular)
        dockMaterial.cornerConfiguration = .capsule()
        dockMaterial.translatesAutoresizingMaskIntoConstraints = false
        dockMaterial.isUserInteractionEnabled = false
        dock.insertSubview(dockMaterial, at: 0)
        NSLayoutConstraint.activate([
            dockMaterial.topAnchor.constraint(equalTo: dock.topAnchor),
            dockMaterial.leadingAnchor.constraint(equalTo: dock.leadingAnchor),
            dockMaterial.trailingAnchor.constraint(equalTo: dock.trailingAnchor),
            dockMaterial.bottomAnchor.constraint(equalTo: dock.bottomAnchor)
        ])

        let dockContent = UILabel()
        dockContent.text = "Discord-like native glass dock"
        dockContent.textColor = .label
        dockContent.font = .systemFont(ofSize: 15, weight: .semibold)
        dockContent.textAlignment = .center
        dockContent.translatesAutoresizingMaskIntoConstraints = false
        dock.addSubview(dockContent)
        NSLayoutConstraint.activate([
            dockContent.centerXAnchor.constraint(equalTo: dock.centerXAnchor),
            dockContent.centerYAnchor.constraint(equalTo: dock.centerYAnchor)
        ])

        let opaqueComparison = UILabel()
        opaqueComparison.text = "Opaque sibling (glass hidden)"
        opaqueComparison.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.19, alpha: 1)
        opaqueComparison.textColor = .white
        opaqueComparison.font = .systemFont(ofSize: 12)
        opaqueComparison.textAlignment = .center
        opaqueComparison.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(opaqueComparison)
        NSLayoutConstraint.activate([
            opaqueComparison.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            opaqueComparison.bottomAnchor.constraint(equalTo: dock.topAnchor, constant: -10),
            opaqueComparison.widthAnchor.constraint(equalToConstant: 290),
            opaqueComparison.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorful.frame = background.bounds
    }

    private func addGlass(_ style: UIGlassEffect.Style, label: String, y: CGFloat) {
        let effect = DeferredGlassView(effect: nil)
        effect.pendingGlass = UIGlassEffect(style: style)
        effect.frame = CGRect(x: 45, y: y, width: 240, height: 70)
        effect.cornerConfiguration = .capsule()
        let text = UILabel(frame: effect.bounds)
        text.text = label
        text.textColor = .label
        text.font = .systemFont(ofSize: 15, weight: .semibold)
        text.textAlignment = .center
        effect.contentView.addSubview(text)
        background.addSubview(effect)
    }
}

    
// Native RNSTabsHostIOS / RNSTabBarController ultimately uses UITabBarController.
// Prove Apple glass material and native tab hit targets independently of Discord.
final class NativeTabsProofController: UITabBarController {
    private var explicitGlass: DeferredGlassView?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !ProcessInfo.processInfo.arguments.contains("--tabs-baseline") else { return }
        if explicitGlass == nil {
            let material = DeferredGlassView(effect: nil)
            material.pendingGlass = UIGlassEffect(style: .regular)
            material.cornerConfiguration = .capsule()
            material.isUserInteractionEnabled = false
            view.insertSubview(material, belowSubview: tabBar)
            explicitGlass = material
        }
        explicitGlass?.frame = tabBar.frame
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        func screen(_ title: String, symbol: String, color: UIColor) -> UIViewController {
            let controller = UIViewController()
            controller.view.backgroundColor = color
            // Strong spatial variation behind the floating bar reveals whether
            // the actual material refracts/colors the backdrop.
            let colorBands: [UIColor] = [.systemIndigo, .systemTeal, .systemPink,
                .systemOrange, .systemPurple, .systemGreen]
            for (idx, band) in colorBands.enumerated() {
                let stripe = UIView()
                stripe.backgroundColor = band.withAlphaComponent(0.85)
                stripe.translatesAutoresizingMaskIntoConstraints = false
                controller.view.addSubview(stripe)
                NSLayoutConstraint.activate([
                    stripe.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                    stripe.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                    stripe.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor,
                                                   constant: -CGFloat(idx) * 42),
                    stripe.heightAnchor.constraint(equalToConstant: 42)
                ])
            }
            let heading = UILabel()
            heading.text = title + " — native UIKit tabs"
            heading.textColor = .white
            heading.font = .systemFont(ofSize: 22, weight: .semibold)
            heading.translatesAutoresizingMaskIntoConstraints = false
            controller.view.addSubview(heading)
            NSLayoutConstraint.activate([
                heading.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
                heading.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
            ])
            controller.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), tag: 0)
            return controller
        }
        viewControllers = [
            screen("Servers", symbol: "square.grid.2x2", color: UIColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 1)),
            screen("Messages", symbol: "bubble.left.and.bubble.right", color: UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1)),
            screen("Activity", symbol: "bell", color: UIColor(red: 0.12, green: 0.18, blue: 0.24, alpha: 1)),
            screen("You", symbol: "person.crop.circle", color: UIColor(red: 0.20, green: 0.22, blue: 0.29, alpha: 1))
        ]
        selectedIndex = 1
        let appearance = UITabBarAppearance()
        if ProcessInfo.processInfo.arguments.contains("--tabs-baseline") {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
        } else {
            // Clear native bar to expose a real UIGlassEffect behind its icons.
            // UITabBarAppearance.backgroundEffect accepts UIBlurEffect only.
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
    }
}


// Runs precisely sources/NativeGlassHost.m through a tiny C shim. This tests
// the deployed Objective-C implementation rather than an analogous Swift view.
final class ActualHostProofController: UIViewController {
    private let target = UIView()
    private let status = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1)

        let bands: [UIColor] = [.systemIndigo, .systemTeal, .systemOrange, .systemPurple, .systemPink]
        for (index, color) in bands.enumerated() {
            let band = UIView()
            band.backgroundColor = color
            band.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(band)
            NSLayoutConstraint.activate([
                band.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                band.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                band.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -CGFloat(index) * 105),
                band.heightAnchor.constraint(equalToConstant: 105)
            ])
        }

        // Regression fixture: Discord's Fabric view tree can contain more
        // than 4096 nodes before its floating profile background appears.
        // All marker candidates must still be inspected without guessing
        // screen geometry. These empty nodes are non-interactive and zero-size.
        for _ in 0..<4200 {
            let placeholder = UIView(frame: .zero)
            placeholder.isUserInteractionEnabled = false
            view.addSubview(placeholder)
        }

        target.translatesAutoresizingMaskIntoConstraints = false
        target.backgroundColor = UIColor(red: 0.11, green: 0.14, blue: 0.20, alpha: 1)
        target.isOpaque = true
        target.accessibilityIdentifier = "unbound.glass.youbar.background"
        view.addSubview(target)
        NSLayoutConstraint.activate([
            target.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            target.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -26),
            target.widthAnchor.constraint(equalToConstant: 320),
            target.heightAnchor.constraint(equalToConstant: 72)
        ])

        status.text = "Actual ObjC native glass host"
        status.textAlignment = .center
        status.textColor = .white
        status.font = .systemFont(ofSize: 15, weight: .semibold)
        status.translatesAutoresizingMaskIntoConstraints = false
        target.addSubview(status)
        NSLayoutConstraint.activate([
            status.centerXAnchor.constraint(equalTo: target.centerXAnchor),
            status.centerYAnchor.constraint(equalTo: target.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !ProcessInfo.processInfo.arguments.contains("--actual-host-baseline") else {
            status.text = "Opaque baseline (no native glass)"
            return
        }
        let pointer = Unmanaged.passUnretained(target).toOpaque()
        let attached = "unbound.glass.youbar.background".withCString { attachMarkedGlass($0) != 0 }
        let confirmed = isActualGlassAttached(pointer) != 0
        status.text = attached && confirmed ? "Actual ObjC UIGlassEffect" : "GLASS HOST FAILED"
        // Fail test if a native material cannot be attached to a *known* view.
        NSLog("[GlassHostSimulator] exact marker attach=%d confirmed=%d window=%@ scene=%@", attached ? 1 : 0, confirmed ? 1 : 0, String(describing: target.window), String(describing: target.window?.windowScene))
        let state = attached && confirmed ? "PASS" : "FAIL"
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? state.write(to: documents.appendingPathComponent("native-glass-marker-result.txt"),
                             atomically: true, encoding: .utf8)
        }
    }
}

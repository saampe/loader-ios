import UIKit

@main
final class GlassDemo: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = GlassDemoViewController()
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

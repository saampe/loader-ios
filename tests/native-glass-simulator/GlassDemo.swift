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

        addGlass(.regular, label: "Regular UIGlassEffect", y: 95)
        addGlass(.clear, label: "Clear UIGlassEffect", y: 200)

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
        let effect = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
        effect.frame = CGRect(x: 45, y: 20, width: 240, height: 70)
        let text = UILabel(frame: effect.bounds)
        text.text = "Clear on a dark surface"
        text.textColor = .label
        text.textAlignment = .center
        effect.contentView.addSubview(text)
        dark.addSubview(effect)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorful.frame = background.bounds
    }

    private func addGlass(_ style: UIGlassEffect.Style, label: String, y: CGFloat) {
        let effect = UIVisualEffectView(effect: UIGlassEffect(style: style))
        effect.frame = CGRect(x: 45, y: y, width: 240, height: 70)
        let text = UILabel(frame: effect.bounds)
        text.text = label
        text.textColor = .label
        text.font = .systemFont(ofSize: 15, weight: .semibold)
        text.textAlignment = .center
        effect.contentView.addSubview(text)
        background.addSubview(effect)
    }
}

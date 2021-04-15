import UIKit

class TopBarController: UIViewController {

    let viewControllers: [UIViewController]
    
    var viewControllerNow: UIViewController?
    
    var topBar: TopBar?
    
    convenience init(_ viewControllers: UIViewController...) {
        self.init(viewControllers: viewControllers)
    }

    init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        view = UIView()
        let topBar = TopBar(frame: CGRect(), mainController: self)
        var tag = 0
        var topBarButtons: [TopBarButton] = []
        for child in viewControllers {
            topBarButtons.append(TopBarButton(frame: CGRect(), topBar: topBar, text: (child.topBarItem?.title ?? "nil"), image: (child.topBarItem?.icon ?? UIImage()), tag: tag))
            tag += 1
        }
        
        addChild(viewControllers[0])
        view.addSubview(viewControllers[0].view)
        viewControllerNow = viewControllers[0]
        viewControllers[0].didMove(toParent: self)
        
        topBar.buttons = topBarButtons
        view.addSubview(topBar)
        self.topBar = topBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func buttonAction(_ tag: Int) {
        let viewControllerWill = viewControllers[tag]
        if viewControllerNow != viewControllerWill {
            viewControllerNow?.willMove(toParent: nil)
            viewControllerNow?.view.removeFromSuperview()
            viewControllerNow?.removeFromParent()
            addChild(viewControllerWill)
            view.insertSubview(viewControllerWill.view, at: 0)
            viewControllerWill.didMove(toParent: self)
        }
        viewControllerNow = viewControllerWill
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewControllerNow?.view.frame = view.bounds
        topBar?.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY + view.safeAreaInsets.top, width: view.bounds.width, height: CGFloat(50))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopBar: UIView {
    var buttons: [TopBarButton]
    let mainController: TopBarController
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var x = Int(bounds.minX)
        let y = Int(bounds.minY)
        let dx: Int
        if buttons.count == 0 {
            dx = 0
        } else {
            dx = Int(bounds.width) / buttons.count
        }
        for button in buttons {
            if (button.superview == nil) {
                self.addSubview(button)
            }
            button.frame = CGRect(x: x, y: y, width: dx, height: Int(bounds.height))
            x += dx
        }
    }
    
    func buttonAction(_ tag: Int) {
        mainController.buttonAction(tag)
    }
    
    init(frame: CGRect, mainController: TopBarController) {
        buttons = []
        self.mainController = mainController
        super.init(frame: frame)
        self.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class TopBarButton: UIControl {
    var icon = UIImageView()
    var label = UILabel()
    let topBar: TopBar
    
    override var isHighlighted: Bool {
        willSet {
            self.backgroundColor = newValue ? .gray : .clear
            self.alpha = newValue ? 0.5 : 1
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if icon.superview == nil {
            self.addSubview(icon)
        }
        
        if label.superview == nil {
            self.addSubview(label)
        }
        
        icon.sizeToFit()
        icon.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        label.font = UIFont(name: label.font.fontName, size: label.font.pointSize - 2)
        label.textColor = icon.tintColor
        label.sizeToFit()
        label.center = CGPoint(x: self.bounds.midX, y: self.bounds.maxY - label.frame.height / 2)
    }
    
    @objc func buttonDidTap(button: UIButton) {
        topBar.buttonAction(button.tag)
    }
    
    init(frame: CGRect, topBar: TopBar, text: String, image: UIImage, tag: Int) {
        self.topBar = topBar
        super.init(frame: frame)
        self.label.text = text
        self.icon.image = image
        self.tag = tag
        self.addTarget(self, action: #selector(buttonDidTap), for: .touchUpInside)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


import SwiftUI

class CustomHostingController<Content: View>: UIHostingController<Content> {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                self.view.alpha = 0
            }) { _ in
                super.dismiss(animated: false, completion: completion)
            }
        } else {
            super.dismiss(animated: false, completion: completion)
        }
    }
}

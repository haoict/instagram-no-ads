import UIKit
import LocalAuthentication

@objc public class SecurityViewController: UIViewController {

  public override func viewDidLoad() {
    super.viewDidLoad()

    let blurEffect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = view.bounds
    view.addSubview(blurView)

    let authenticateButton = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    authenticateButton.setTitle("Authenticate", for: .normal)
    authenticateButton.center = view.center
    authenticateButton.addTarget(self, action: #selector(self.authenticateButtonTapped), for: .touchUpInside)
    view.addSubview(authenticateButton)

    self.authenticate()
  }

  @objc func authenticateButtonTapped(_ sender: Any) {
    self.authenticate()
  }

  func authenticate() {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
      let reason = "Identify yourself!"

      context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
        [weak self] success, authenticationError in

        DispatchQueue.main.async {
          if success {
            self?.dismiss(animated: true, completion: nil);
          } else {
            // error
          }
        }
      }
    } else {
      // no biometry
    }
  }
}

import SwiftUI
import UIKit

extension Notification.Name {
    static let reelDeviceDidShake = Notification.Name("reelDeviceDidShake")
}

extension UIWindow {
    /// Shake to spin. UIKit only reports shakes to the responder chain, so the
    /// window forwards them as a notification SwiftUI can listen for.
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .reelDeviceDidShake, object: nil)
        }
    }
}

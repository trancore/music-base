import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  static weak var flutterViewController: FlutterViewController?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    MainFlutterWindow.flutterViewController = flutterViewController
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    (NSApp.delegate as? AppDelegate)?.registerPlatformChannels(with: flutterViewController)

    super.awakeFromNib()
  }
}

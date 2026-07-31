import AppKit

// SwiftPM does not provide the Xcode application lifecycle wiring that normally
// instantiates an @main AppDelegate. Wire it explicitly so the delegate is retained
// and applicationDidFinishLaunching always runs in the packaged menu-bar app.
let application = NSApplication.shared
let applicationDelegate = AppDelegate()
application.delegate = applicationDelegate
application.run()

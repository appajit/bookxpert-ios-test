
import UIKit
import FirebaseCore
import GoogleSignIn


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let appCoordinator = AppCoordinator(
            window: window,
            dependencies: DependencyProvider()
        )
        self.appCoordinator = appCoordinator
        appCoordinator.start()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Foreground notification handler
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound])
        }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}



import UIKit
import OneSignalFramework
@preconcurrency import Alamofire

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = "https://kinetichaus-app.pro"

        OneSignal.initialize(IntegrationKeys.oneSignalAppID, withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)

        application.registerForRemoteNotifications()

        return true
    }
}

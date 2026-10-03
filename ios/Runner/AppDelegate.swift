import Flutter
import UIKit
import UserNotifications
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusFlowReminders") else { return }
    let channel = FlutterMethodChannel(name: "focus_flow/reminders", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let center = UNUserNotificationCenter.current()
      if call.method == "playSound" {
        AudioServicesPlaySystemSound(1007)
        result(nil)
      } else if call.method == "requestPermission" {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { allowed, error in
          DispatchQueue.main.async {
            if let error = error { result(FlutterError(code: "permission", message: error.localizedDescription, details: nil)) }
            else { result(allowed) }
          }
        }
      } else if call.method == "clear" {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        center.getPendingNotificationRequests { pending in
          center.getDeliveredNotifications { delivered in
            DispatchQueue.main.async {
              if pending.isEmpty && delivered.isEmpty { result(nil) }
              else { result(FlutterError(code: "clear_failed", message: "Could not clear local reminders", details: nil)) }
            }
          }
        }
      } else if call.method == "schedule", let args = call.arguments as? [String: Any] {
        center.removePendingNotificationRequests(withIdentifiers: ["daily", "streak"])
        center.removeDeliveredNotifications(withIdentifiers: ["daily", "streak"])
        var requests: [UNNotificationRequest] = []
        if args["daily"] as? Bool == true {
          var date = DateComponents()
          date.hour = args["hour"] as? Int ?? 19
          date.minute = args["minute"] as? Int ?? 0
          requests.append(Self.request(id: "daily", title: "Time for a little focus", date: date, repeats: true))
        }
        // A one-shot reminder for the day after the last successful session.
        // Completing another session replaces it, so today's reminder is cancelled.
        if args["streak"] as? Bool == true, let last = args["lastFocusDate"] as? String {
          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "en_US_POSIX")
          formatter.dateFormat = "yyyy-MM-dd"
          if let day = formatter.date(from: last),
             let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: day),
             let fire = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: tomorrow), fire > Date() {
            let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            requests.append(Self.request(id: "streak", title: "Keep your focus streak growing", date: date, repeats: false))
          }
        }
        let group = DispatchGroup()
        let lock = NSLock()
        var schedulingError: Error?
        for request in requests {
          group.enter()
          center.add(request) { error in
            lock.lock()
            if let error = error { schedulingError = error }
            lock.unlock()
            group.leave()
          }
        }
        group.notify(queue: .main) {
          if let error = schedulingError { result(FlutterError(code: "schedule", message: error.localizedDescription, details: nil)) }
          else { result(nil) }
        }
      } else { result(FlutterMethodNotImplemented) }
    }
  }
  private static func request(id: String, title: String, date: DateComponents, repeats: Bool) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = "Protect a few minutes for meaningful work. Your garden is waiting."
    content.sound = .default
    return UNNotificationRequest(identifier: id, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: repeats))
  }
}

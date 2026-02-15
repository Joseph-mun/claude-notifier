import Cocoa
import UserNotifications

// MARK: - Argument Parser

struct NotifierArgs {
    var command: String = ""
    var title: String = "Claude Code"
    var message: String = ""
    var subtitle: String = ""
    var sound: String = "default"
    var group: String = "default"
    var projectDir: String = ""
    var all: Bool = false

    static func parse(_ args: [String]) -> NotifierArgs {
        var result = NotifierArgs()
        guard args.count > 1 else { return result }

        result.command = args[1]
        var i = 2
        while i < args.count {
            switch args[i] {
            case "--title":     i += 1; if i < args.count { result.title = args[i] }
            case "--message":   i += 1; if i < args.count { result.message = args[i] }
            case "--subtitle":  i += 1; if i < args.count { result.subtitle = args[i] }
            case "--sound":     i += 1; if i < args.count { result.sound = args[i] }
            case "--group":     i += 1; if i < args.count { result.group = args[i] }
            case "--project-dir": i += 1; if i < args.count { result.projectDir = args[i] }
            case "--all":       result.all = true
            default: break
            }
            i += 1
        }
        return result
    }
}

// MARK: - App Delegate

class NotifierDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private var parsedArgs = NotifierArgs()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        parsedArgs = NotifierArgs.parse(CommandLine.arguments)

        switch parsedArgs.command {
        case "send":
            sendNotification()
        case "remove":
            removeNotification()
        case "setup":
            requestPermissions()
        case "help", "--help", "-h":
            printUsage()
            exit(0)
        case "":
            // 알림 클릭으로 실행됨 — delegate callback 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                NSApp.terminate(nil)
            }
        default:
            fputs("Unknown command: \(parsedArgs.command)\n", stderr)
            printUsage()
            exit(1)
        }
    }

    // MARK: - Send

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = parsedArgs.title
        content.body = parsedArgs.message
        if !parsedArgs.subtitle.isEmpty {
            content.subtitle = parsedArgs.subtitle
        }

        // Sound
        switch parsedArgs.sound.lowercased() {
        case "default":
            content.sound = .default
        case "none", "":
            content.sound = nil
        default:
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: parsedArgs.sound))
        }

        // userInfo: 클릭 시 VS Code 프로젝트 창 포커싱에 사용
        content.userInfo = [
            "projectDir": parsedArgs.projectDir,
            "group": parsedArgs.group
        ]

        let request = UNNotificationRequest(
            identifier: parsedArgs.group,
            content: content,
            trigger: nil  // 즉시 전송
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Remove

    private func removeNotification() {
        let center = UNUserNotificationCenter.current()

        if parsedArgs.all {
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
        } else if !parsedArgs.group.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: [parsedArgs.group])
            center.removePendingNotificationRequests(withIdentifiers: [parsedArgs.group])
        }

        // 처리 시간 확보 후 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Setup (권한 요청)

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications authorized")
            } else {
                print("Notifications denied: \(error?.localizedDescription ?? "unknown")")
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Notification Click Handler

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let vscodeURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        if let projectDir = userInfo["projectDir"] as? String, !projectDir.isEmpty {
            // macOS Launch Services로 해당 프로젝트 폴더를 VS Code에서 열기
            // 이미 열려있는 창이면 해당 창으로 포커싱됨
            let folderURL = URL(fileURLWithPath: projectDir)
            NSWorkspace.shared.open([folderURL], withApplicationAt: vscodeURL, configuration: config) { _, error in
                if error != nil {
                    // fallback: VS Code 앱만 활성화
                    NSWorkspace.shared.open(vscodeURL, configuration: config)
                }
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        } else {
            NSWorkspace.shared.open(vscodeURL, configuration: config) { _, _ in
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        }

        completionHandler()
    }

    // 앱이 foreground일 때도 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Usage

    private func printUsage() {
        print("""
        ClaudeNotifier - macOS notification tool for Claude Code hooks

        Usage: ClaudeNotifier <command> [options]

        Commands:
          send      Send a notification
          remove    Remove a delivered notification
          setup     Request notification permissions (run once)
          help      Show this help

        Send options:
          --title VALUE        Notification title
          --message VALUE      Notification body
          --subtitle VALUE     Notification subtitle
          --sound VALUE        Sound name (default, Glass, none)
          --group VALUE        Group ID (same group replaces previous)
          --project-dir VALUE  VS Code project path (for click-to-focus)

        Remove options:
          --group VALUE        Remove notification with this group ID
          --all                Remove all notifications

        Examples:
          ClaudeNotifier send --title "권한 필요" --message "Bash 권한" --group "perm-Bash"
          ClaudeNotifier remove --group "perm-Bash"
          ClaudeNotifier remove --all
        """)
    }
}

// MARK: - Entry Point

let delegate = NotifierDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)  // Dock 아이콘 없음
app.run()

import SwiftUI

struct SettingsView: View {
    @State private var storageSize = "0KB"
    @State private var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @State private var showClearConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var toastItem: ToastItem?

    var body: some View {
        List {
            Button(action: { showClearConfirm = true }) {
                HStack {
                    Text("清除缓存")
                    Spacer()
                    Text(storageSize)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("版本号")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }

            Button(action: { showDeleteAccountConfirm = true }) {
                Text("注销账户")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("设置")
        .toast($toastItem)
        .alert("提示", isPresented: $showClearConfirm, actions: {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                clearCache()
            }
        }, message: {
            Text("清理可能会导致重新登录,确定清理？")
        })
        .alert("确认注销账户", isPresented: $showDeleteAccountConfirm, actions: {
            Button("取消", role: .cancel) {}
            Button("确认", role: .destructive) {
                toastItem = ToastItem(message: "申请成功")
            }
        }, message: {
            Text("注销账户申请提交后将进入处理流程，确认提交申请？")
        })
        .onAppear {
            calculateStorageSize()
        }
    }

    private func calculateStorageSize() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        let size = dictionary.values.reduce(0) { sum, value in
            sum + String(describing: value).utf8.count
        }
        storageSize = "\(size / 1024)KB"
    }

    @MainActor
    private func clearCache() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach { key in
            if key != "AppleLanguages" && key != "AppleLocale" {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        KeychainManager.shared.clearAll()
        AuthManager.shared.logout()
    }
}

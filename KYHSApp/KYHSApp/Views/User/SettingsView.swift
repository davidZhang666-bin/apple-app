import SwiftUI

struct SettingsView: View {
    @State private var storageSize = "0KB"
    @State private var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @State private var showClearConfirm = false

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
        }
        .navigationTitle("设置")
        .alert("提示", isPresented: $showClearConfirm, actions: {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                clearCache()
            }
        }, message: {
            Text("清理可能会导致重新登录,确定清理？")
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

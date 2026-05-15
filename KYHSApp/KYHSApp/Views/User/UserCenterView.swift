import SwiftUI

struct UserCenterView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showScanner = false
    @State private var clockInResult: ClockInResult?
    @State private var showClockInSuccess = false
    @State private var scanError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Profile header
                    ZStack(alignment: .bottomLeading) {
                        Color(hex: "0A9200")
                            .ignoresSafeArea(edges: .top)

                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: authManager.userInfo?.avatar ?? "")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.userInfo?.name ?? "未登录")
                                    .foregroundColor(.white)
                                    .font(.system(size: 17, weight: .semibold))
                                Text("ID: \(authManager.userInfo?.phone ?? "")")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 12))
                            }
                            Spacer()
                        }
                        .padding(.bottom, 16)
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 130)

                    // Function list
                    List {
                        NavigationLink(destination: MyProfileView()) {
                            Label("我的资料", systemImage: "doc.text.fill")
                        }
                        NavigationLink(destination: SettingsView()) {
                            Label("设置", systemImage: "gearshape.fill")
                        }
                        Button(action: { showScanner = true }) {
                            Label("进店打卡", systemImage: "qrcode.viewfinder")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)

                    // Logout button
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("退出登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .background(Color(hex: "0A9200"))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .task {
                await authManager.fetchUserInfo()
            }
            .sheet(isPresented: $showScanner) {
                QRCodeScannerView { result in
                    handleScanResult(result)
                }
            }
            .sheet(isPresented: $showClockInSuccess) {
                if let result = clockInResult {
                    ClockInSuccessView(result: result)
                }
            }
            .alert("打卡失败", isPresented: Binding(
                get: { scanError != nil },
                set: { if !$0 { scanError = nil } }
            ), actions: {
                Button("确定") { scanError = nil }
            }, message: {
                Text(scanError ?? "")
            })
        }
    }

    private func handleScanResult(_ ruleId: String) {
        showScanner = false
        Task {
            do {
                let result: ClockInResult = try await NetworkService.shared.get("/signIn/userSignIn", params: ["ruleId": ruleId])
                await MainActor.run {
                    clockInResult = result
                    showClockInSuccess = true
                }
            } catch {
                await MainActor.run {
                    scanError = error.localizedDescription
                }
            }
        }
    }
}

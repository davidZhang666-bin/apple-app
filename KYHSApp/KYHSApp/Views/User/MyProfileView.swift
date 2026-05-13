import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    private var user: UserInfo? { authManager.userInfo }

    var body: some View {
        List {
            HStack {
                Text("头像")
                Spacer()
                AsyncImage(url: URL(string: user?.avatar ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }

            ProfileRow(title: "姓名", value: user?.name)
            ProfileRow(title: "性别", value: user?.sex == 1 ? "男" : "女")
            ProfileRow(title: "生日", value: user?.birthdate)
            ProfileRow(title: "手机号", value: user?.phone)
            ProfileRow(title: "地区", value: user?.remark)
            ProfileRow(title: "所属店铺", value: user?.shopName)
            ProfileRow(title: "所属店长", value: user?.shopUserName)
        }
        .navigationTitle("我的资料")
    }
}

struct ProfileRow: View {
    let title: String
    let value: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "-")
                .foregroundColor(.secondary)
        }
    }
}

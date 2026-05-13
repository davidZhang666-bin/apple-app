import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("康源华善 APP 隐私政策").font(.headline)
                        Text("版本更新日期：2025年7月3日").font(.caption).foregroundColor(.secondary)
                        Text("版本生效日期：2025年7月10日").font(.caption).foregroundColor(.secondary)

                        Text("康源华善（以下简称"我们"/"康源华善"）非常重视用户的隐私和个人信息保护，也感谢您对我们的信任。我们将按法律法规要求，采取相应安全保护措施，尽力保护您的个人信息安全可控，为您提供合理高效的隐私保护。")

                        Text("一、我们如何收集和使用您的信息").font(.subheadline).bold()
                        Text("我们根据合法、正当、必要的原则，为实现本政策下述的各项基本功能，收集和使用您的个人信息。")

                        Text("二、注册账号").font(.subheadline).bold()
                        Text("当您在创建康源华善账号时，您须提供您在中华人民共和国境内手机号码，设置、确认您的登录密码。收集手机号码是为了满足相关法律法规的网络实名制要求。")
                        Text("授权登录：我们可能会根据你的授权从微信处获取你的账号信息（包括微信昵称和头像），并与你的康源华善账号进行绑定。")

                        Text("三、我们如何委托处理、共享、转让、公开披露您的信息").font(.subheadline).bold()
                        Text("委托处理：对我们委托处理个人信息的公司、组织和个人，我们会与其签署严格的保密协定。")
                        Text("共享：与关联公司间共享及与授权合作伙伴共享，我们只会共享必要的个人信息。")
                        Text("转让：我们不会将您的个人信息转让给任何公司、组织和个人，但在获取明确同意的情况下或在公司发生合并、收购或破产清算情形时除外。")
                        Text("公开披露：我们仅会在获得您明确同意或基于法律的要求下，公开披露您的个人信息。")

                        Text("四、我们如何保护您的个人信息").font(.subheadline).bold()
                        Text("为保障您的信息安全，我们努力采取各种合理的物理、电子和管理方面的安全措施来保护您的信息，使您的信息不会被泄漏、毁损或者丢失，包括但不限于SSL、信息加密存储、数据中心的访问控制。")

                        Text("五、您的权利").font(.subheadline).bold()
                        Text("您可以在使用我们服务的过程中，访问、修改和删除您提供的注册信息和其他个人信息。您可以通过登录康源华善APP或联系客服来行使这些权利。")

                        Text("六、我们如何处理儿童的个人信息").font(.subheadline).bold()
                        Text("我们非常重视对未成年人个人信息的保护。根据相关法律法规的规定，如您为不满18周岁的未成年人，我们要求您在父母或监护人的指导下使用我们的产品或服务。")

                        Text("七、我们如何储存您的个人信息").font(.subheadline).bold()
                        Text("原则上，我们在中华人民共和国境内运营中收集和产生的个人信息，存储在中国境内。")

                        Text("八、如何联系我们").font(.subheadline).bold()
                        Text("公司名称：邯郸市丛台区华善贸易有限公司")
                        Text("注册地址：河北省邯郸市丛台区人民路219号国际商务中心20层2010")
                        Text("联系人：康源华善")
                        Text("客服电话：400-178-6862")
                    }
                    .font(.footnote)
                    .foregroundColor(.primary)
                }
                .padding()
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

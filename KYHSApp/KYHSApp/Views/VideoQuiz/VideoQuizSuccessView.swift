import SwiftUI

struct VideoQuizSuccessView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 50)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 98))
                .foregroundColor(Color(hex: "0A9200"))

            Text("恭喜您答题成功")
                .font(.system(size: 18, weight: .bold))

            Text("答题奖励由店长统一发放，请耐心等待")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)

            Spacer().frame(height: 40)

            Button(action: {
                // Navigate back to video quiz tab
            }) {
                Text("回到首页")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .background(Color(hex: "0A9200"))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .navigationTitle("答题成功")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClockInSuccessView: View {
    let result: ClockInResult

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 50)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 98))
                .foregroundColor(Color(hex: "0A9200"))

            Text("进店打卡成功")
                .font(.system(size: 18, weight: .bold))

            if result.rewardType == "integral" {
                Text("积分奖励+\(result.integralAmount ?? 0)")
                    .font(.system(size: 14, weight: .bold))
            } else {
                Text("实物奖励 \(result.physicalName ?? "")")
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer().frame(height: 40)

            Button(action: {
                // Navigate back to live center
            }) {
                Text("回到首页看直播")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .background(Color(hex: "0A9200"))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .navigationTitle("进店打卡")
        .navigationBarTitleDisplayMode(.inline)
    }
}

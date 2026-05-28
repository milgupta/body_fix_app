import SwiftUI

struct ReminderSoftPromptView: View {
    let onSetup: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0F172A").ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                Image(systemName: "bell.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color(hex: "#5EEAD4"))

                VStack(spacing: 12) {
                    Text("Want gentle reminders to stretch?")
                        .font(Typography.navTitle)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)

                    Text("Set your own days and time. Nothing is scheduled until you choose both.")
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    onSetup()
                } label: {
                    Text("Set Up Reminders")
                        .font(Typography.primaryCta)
                        .foregroundStyle(Color(hex: "#0F172A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#14B8A6")))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)

                Button {
                    onNotNow()
                } label: {
                    Text("Not now")
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color(hex: "#64748B"))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(28)
        }
    }
}

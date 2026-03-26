import SwiftUI

struct CoachChatMessage: Identifiable, Equatable {
    let id: UUID
    var isUser: Bool
    var text: String

    init(id: UUID = UUID(), isUser: Bool, text: String) {
        self.id = id
        self.isUser = isUser
        self.text = text
    }
}

struct CoachMessageBubble: View {
    let message: CoachChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(Typography.stretchDescription)
                .foregroundStyle(message.isUser ? Color.white : Color.bfTextSecondary)
                .padding(14)
                .background {
                    if message.isUser {
                        RoundedRectangle(cornerRadius: 18).fill(.bfGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 18).fill(Color.bfCard)
                    }
                }
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

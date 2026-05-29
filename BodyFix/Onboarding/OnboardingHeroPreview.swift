import SwiftUI

struct OnboardingHeroPreview: View {
    var body: some View {
        Group {
            if let image = Self.onboardingImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.2), radius: 24, y: 14)
            } else {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .aspectRatio(1857.0 / 3096.0, contentMode: .fit)
                    .overlay {
                        Text("Preview unavailable")
                            .font(Typography.caption)
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
            }
        }
        .frame(maxWidth: 360)
        .padding(.horizontal, 4)
    }

    private static var onboardingImage: UIImage? {
        if let url = Bundle.main.url(forResource: "onboarding_image", withExtension: "png", subdirectory: "images"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        guard let url = Bundle.main.url(forResource: "onboarding_image", withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingHeroPreview()
            .padding(.horizontal, 20)
    }
}

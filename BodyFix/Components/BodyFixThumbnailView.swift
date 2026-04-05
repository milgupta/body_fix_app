import SwiftUI
import UIKit

struct BodyFixThumbnailView: View {
    let stretch: Stretch?
    let routine: Routine?
    let muscleGroup: MuscleGroup?
    var size: CGFloat = 44
    var isFeatured: Bool = false

    init(stretch: Stretch?, size: CGFloat = 44, isFeatured: Bool = false) {
        self.stretch = stretch
        self.routine = nil
        self.muscleGroup = stretch?.muscle
        self.size = size
        self.isFeatured = isFeatured
    }

    init(routine: Routine?, size: CGFloat = 44, isFeatured: Bool = false) {
        self.stretch = nil
        self.routine = routine
        self.muscleGroup = routine?.relatedMuscleGroups.first.flatMap(MuscleGroup.init(rawValue:))
        self.size = size
        self.isFeatured = isFeatured
    }

    init(muscleGroup: MuscleGroup?, size: CGFloat = 44, isFeatured: Bool = false) {
        self.stretch = nil
        self.routine = nil
        self.muscleGroup = muscleGroup
        self.size = size
        self.isFeatured = isFeatured
    }

    private var resolvedImage: UIImage? {
        if let routine, let image = BodyFixImageResolver.image(for: routine) {
            return image
        }
        if let stretch, let image = BodyFixImageResolver.image(for: stretch) {
            return image
        }
        if let muscleGroup, let image = BodyFixImageResolver.image(for: muscleGroup) {
            return image
        }
        return nil
    }

    private var symbolName: String {
        switch muscleGroup {
        case .neck: return "figure.mind.and.body"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .chest: return "lungs.fill"
        case .upperBack: return "figure.cooldown"
        case .lowerBack: return "figure.flexibility"
        case .core: return "bolt.heart.fill"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "figure.strengthtraining.functional"
        case .forearms: return "hand.raised.fill"
        case .hips: return "figure.yoga"
        case .glutes: return "figure.walk"
        case .quads: return "figure.run"
        case .hamstrings: return "figure.stretch"
        case .knees: return "figure.step.training"
        case .calves: return "figure.hiking"
        case .none: return "figure.mobility"
        }
    }

    private var palette: [Color] {
        switch muscleGroup {
        case .neck: return [Color(hex: "#E8C9A3"), Color(hex: "#D89D6E")]
        case .shoulders: return [Color(hex: "#AFC6E8"), Color(hex: "#6F8DBA")]
        case .chest: return [Color(hex: "#E8BFB3"), Color(hex: "#C98C7E")]
        case .upperBack: return [Color(hex: "#BCD9D2"), Color(hex: "#6DAA9E")]
        case .lowerBack: return [Color(hex: "#E8BF97"), Color(hex: "#CB845B")]
        case .core: return [Color(hex: "#EFD99A"), Color(hex: "#CAA24F")]
        case .biceps: return [Color(hex: "#C0D0EA"), Color(hex: "#7C96C4")]
        case .triceps: return [Color(hex: "#D8CAE7"), Color(hex: "#9078B7")]
        case .forearms: return [Color(hex: "#C7DDCF"), Color(hex: "#7EA98C")]
        case .hips: return [Color(hex: "#A5D1CB"), Color(hex: "#4D9389")]
        case .glutes: return [Color(hex: "#E7C0CF"), Color(hex: "#B57991")]
        case .quads: return [Color(hex: "#E8D0A7"), Color(hex: "#BE9053")]
        case .hamstrings: return [Color(hex: "#C7D7EA"), Color(hex: "#7C97C2")]
        case .knees: return [Color(hex: "#D5DBE8"), Color(hex: "#8C98B8")]
        case .calves: return [Color(hex: "#D1E1BC"), Color(hex: "#85A164")]
        case .none: return [Color.bfSurfaceMuted, Color.bfAccent.opacity(0.35)]
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: palette,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let resolvedImage {
                Image(uiImage: resolvedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isFeatured ? 0.07 : 0.20))
                        .padding(size * 0.12)

                    Image(systemName: symbolName)
                        .font(.system(size: size * (isFeatured ? 0.38 : 0.34), weight: .semibold))
                        .foregroundStyle(isFeatured ? Color.white.opacity(0.92) : Color.bfHeroSurface)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(isFeatured ? Color.white.opacity(0.14) : Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isFeatured ? 0.18 : 0.06), radius: isFeatured ? 10 : 4, y: isFeatured ? 6 : 2)
    }
}

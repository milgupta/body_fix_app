import SwiftUI

struct BodySilhouetteView: View {
    var highlightedRegions: Set<OnboardingPainArea> = []
    var tintColor: Color = .bfTeal

    var body: some View {
        Canvas { context, size in
            drawSilhouette(in: &context, size: size)

            for region in highlightedRegions {
                let rect = regionRect(for: region, in: size)
                let glow = Path(ellipseIn: rect)
                context.fill(glow, with: .color(tintColor.opacity(0.35)))
                let innerRect = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15)
                let innerGlow = Path(ellipseIn: innerRect)
                context.fill(innerGlow, with: .color(tintColor.opacity(0.5)))
            }
        }
        .aspectRatio(0.4, contentMode: .fit)
    }

    private func drawSilhouette(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        var path = Path()

        // Head
        let headCenterX = w * 0.5
        let headCenterY = h * 0.07
        let headRadius = w * 0.08
        path.addEllipse(in: CGRect(
            x: headCenterX - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2.2
        ))

        // Neck
        path.addRect(CGRect(x: w * 0.46, y: h * 0.1, width: w * 0.08, height: h * 0.03))

        // Torso
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.13))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.13))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.35))
        path.closeSubpath()

        // Left arm
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.14))
        path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.35),
                          control: CGPoint(x: w * 0.25, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.42))
        path.addLine(to: CGPoint(x: w * 0.20, y: h * 0.42))
        path.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.18),
                          control: CGPoint(x: w * 0.28, y: h * 0.26))

        // Right arm
        path.move(to: CGPoint(x: w * 0.65, y: h * 0.14))
        path.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.35),
                          control: CGPoint(x: w * 0.75, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.42))
        path.addLine(to: CGPoint(x: w * 0.80, y: h * 0.42))
        path.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.18),
                          control: CGPoint(x: w * 0.72, y: h * 0.26))

        // Left leg
        path.move(to: CGPoint(x: w * 0.42, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.45))

        // Right leg
        path.move(to: CGPoint(x: w * 0.52, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.56, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.45))

        context.fill(path, with: .color(.white.opacity(0.15)))
        context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
    }

    private func regionRect(for region: OnboardingPainArea, in size: CGSize) -> CGRect {
        let w = size.width
        let h = size.height
        switch region {
        case .neck:
            return CGRect(x: w * 0.4, y: h * 0.09, width: w * 0.2, height: h * 0.05)
        case .biceps:
            return CGRect(x: w * 0.22, y: h * 0.16, width: w * 0.56, height: h * 0.08)
        case .triceps:
            return CGRect(x: w * 0.2, y: h * 0.21, width: w * 0.6, height: h * 0.08)
        case .chest:
            return CGRect(x: w * 0.36, y: h * 0.18, width: w * 0.28, height: h * 0.08)
        case .upperBack:
            return CGRect(x: w * 0.35, y: h * 0.17, width: w * 0.3, height: h * 0.1)
        case .core:
            return CGRect(x: w * 0.37, y: h * 0.24, width: w * 0.26, height: h * 0.09)
        case .lowerBack:
            return CGRect(x: w * 0.37, y: h * 0.3, width: w * 0.26, height: h * 0.1)
        case .hips:
            return CGRect(x: w * 0.35, y: h * 0.4, width: w * 0.3, height: h * 0.08)
        case .glutes:
            return CGRect(x: w * 0.36, y: h * 0.45, width: w * 0.28, height: h * 0.08)
        case .quads:
            return CGRect(x: w * 0.34, y: h * 0.5, width: w * 0.32, height: h * 0.1)
        case .hamstrings:
            return CGRect(x: w * 0.34, y: h * 0.55, width: w * 0.32, height: h * 0.12)
        case .knees:
            return CGRect(x: w * 0.34, y: h * 0.68, width: w * 0.32, height: h * 0.06)
        case .calves:
            return CGRect(x: w * 0.33, y: h * 0.75, width: w * 0.34, height: h * 0.12)
        case .ankles:
            return CGRect(x: w * 0.32, y: h * 0.88, width: w * 0.36, height: h * 0.06)
        case .wholeBody:
            return CGRect(x: w * 0.25, y: h * 0.1, width: w * 0.5, height: h * 0.8)
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        BodySilhouetteView(highlightedRegions: [.lowerBack, .neck, .hips])
            .frame(width: 200, height: 500)
    }
}

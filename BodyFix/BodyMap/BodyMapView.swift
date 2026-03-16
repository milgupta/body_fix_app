import SwiftUI

struct BodyMapView: View {
    @State private var cameraAngle: CameraAngle = .front
    @State private var selectedRegion: BodyRegion? = nil
    @State private var navigateToStretches = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 15/255, green: 23/255, blue: 42/255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body Map")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Tap a region to see stretches")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.bfTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // 3D Body Model
                    BodyModelView(
                        selectedRegions: selectedRegion.map { [$0] } ?? [],
                        cameraAngle: cameraAngle,
                        onRegionSelected: { region in
                            selectedRegion = region
                            navigateToStretches = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Selected region label
                    Group {
                        if let region = selectedRegion {
                            Text(region.displayName)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.bfTeal)
                                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        } else {
                            Text(" ") // placeholder to hold layout height
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: selectedRegion)
                    .padding(.bottom, 8)

                    // View angle toggle pills
                    BodyRegionPillsView(selectedAngle: $cameraAngle)
                        .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToStretches) {
                StretchListView(region: selectedRegion ?? .neck)
            }
        }
    }
}

#Preview {
    BodyMapView()
}

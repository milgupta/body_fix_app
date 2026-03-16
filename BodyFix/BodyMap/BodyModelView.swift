import SwiftUI
import SceneKit

// MARK: - CameraAngle

enum CameraAngle: CaseIterable, Equatable {
    case front, back, left, right

    var label: String {
        switch self {
        case .front: return "Front"
        case .back: return "Back"
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    var yRadians: Float {
        switch self {
        case .front: return 0
        case .right: return .pi / 2
        case .back: return .pi
        case .left: return 3 * .pi / 2
        }
    }
}

// MARK: - BodyModelView

struct BodyModelView: UIViewRepresentable {
    var selectedRegions: Set<BodyRegion>
    var cameraAngle: CameraAngle
    var onRegionSelected: (BodyRegion) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onRegionSelected: onRegionSelected)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        // #0F172A background matching navy theme
        scnView.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1)
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.showsStatistics = false
        scnView.rendersContinuously = false

        let scene = SCNScene()
        scnView.scene = scene
        context.coordinator.scene = scene
        context.coordinator.scnView = scnView

        context.coordinator.buildBody(in: scene)
        context.coordinator.setupLighting(in: scene)
        context.coordinator.addGroundShadow(to: scene)
        context.coordinator.setupCamera(in: scene)

        context.coordinator.updateMaterials(selected: selectedRegions)
        context.coordinator.setCamera(angle: cameraAngle, animated: false)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tap)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onRegionSelected = onRegionSelected
        context.coordinator.updateMaterials(selected: selectedRegions)
        context.coordinator.setCamera(angle: cameraAngle, animated: true)
    }
}

// MARK: - Coordinator

extension BodyModelView {
    final class Coordinator: NSObject {
        var onRegionSelected: (BodyRegion) -> Void
        weak var scnView: SCNView?
        var scene: SCNScene?
        var cameraArm: SCNNode?
        var regionNodes: [BodyRegion: SCNNode] = [:]

        init(onRegionSelected: @escaping (BodyRegion) -> Void) {
            self.onRegionSelected = onRegionSelected
        }

        // MARK: - Camera

        func setupCamera(in scene: SCNScene) {
            // Arm node rotates around Y axis — camera hangs off it at fixed distance
            let arm = SCNNode()
            arm.name = "cameraArm"
            arm.position = SCNVector3(0, 0.9, 0) // pivot at body mid-height
            scene.rootNode.addChildNode(arm)
            cameraArm = arm

            let camera = SCNCamera()
            camera.fieldOfView = 44
            camera.zNear = 0.1
            camera.zFar = 50

            let camNode = SCNNode()
            camNode.camera = camera
            // Default SCNNode orientation looks along -Z; placing at +Z puts body in frame
            camNode.position = SCNVector3(0, 0, 4.0)
            arm.addChildNode(camNode)
        }

        func setCamera(angle: CameraAngle, animated: Bool) {
            guard let arm = cameraArm else { return }
            arm.removeAllActions()
            if animated {
                let action = SCNAction.rotateTo(
                    x: 0, y: CGFloat(angle.yRadians), z: 0,
                    duration: 0.45,
                    usesShortestUnitArc: true
                )
                action.timingMode = .easeInEaseOut
                arm.runAction(action)
            } else {
                arm.eulerAngles = SCNVector3(0, angle.yRadians, 0)
            }
        }

        // MARK: - Body Building

        func buildBody(in scene: SCNScene) {
            // Try loading a user-provided .usdz or .obj asset first
            if let url = Bundle.main.url(forResource: "HumanBody", withExtension: "usdz")
                ?? Bundle.main.url(forResource: "HumanBody", withExtension: "obj"),
               let loaded = try? SCNScene(url: url, options: nil) {
                loadNamedScene(loaded, into: scene)
            } else {
                buildProceduralBody(in: scene)
            }
        }

        private func loadNamedScene(_ loaded: SCNScene, into scene: SCNScene) {
            let wrapper = SCNNode()
            wrapper.name = "bodyModel"
            for child in loaded.rootNode.childNodes {
                wrapper.addChildNode(child.clone())
            }
            scene.rootNode.addChildNode(wrapper)
            // Map named nodes in the asset to BodyRegion cases
            for region in BodyRegion.allCases {
                if let node = scene.rootNode.childNode(withName: region.rawValue, recursively: true) {
                    regionNodes[region] = node
                }
            }
        }

        private func buildProceduralBody(in scene: SCNScene) {
            let root = SCNNode()
            root.name = "body"

            // Non-interactive decoration: head
            let headNode = SCNNode(geometry: SCNSphere(radius: 0.115))
            headNode.name = "head"
            headNode.position = SCNVector3(0, 1.675, 0)
            headNode.geometry?.firstMaterial = decorativeMaterial()
            root.addChildNode(headNode)

            // Non-interactive decoration: arms
            root.addChildNode(makeArmNode(side: -1))
            root.addChildNode(makeArmNode(side: 1))

            // --- Interactive regions ---

            // Neck
            let neck = singleRegionNode(.neck, geometry: SCNCylinder(radius: 0.058, height: 0.10))
            neck.position = SCNVector3(0, 1.555, 0)
            root.addChildNode(neck)

            // Shoulders — wide band spanning both shoulder caps
            let shoulders = singleRegionNode(.shoulders, geometry: SCNBox(width: 0.50, height: 0.11, length: 0.19, chamferRadius: 0.05))
            shoulders.position = SCNVector3(0, 1.48, 0)
            root.addChildNode(shoulders)

            // Chest — front face of upper torso (offset forward)
            let chest = singleRegionNode(.chest, geometry: SCNBox(width: 0.34, height: 0.22, length: 0.10, chamferRadius: 0.03))
            chest.position = SCNVector3(0, 1.305, 0.06)
            root.addChildNode(chest)

            // Upper Back — rear face of upper torso (offset back); visible from back view
            let upperBack = singleRegionNode(.upperBack, geometry: SCNBox(width: 0.36, height: 0.22, length: 0.10, chamferRadius: 0.03))
            upperBack.position = SCNVector3(0, 1.305, -0.06)
            root.addChildNode(upperBack)

            // Lower Back — visible from back view
            let lowerBack = singleRegionNode(.lowerBack, geometry: SCNBox(width: 0.30, height: 0.20, length: 0.10, chamferRadius: 0.03))
            lowerBack.position = SCNVector3(0, 1.02, -0.05)
            root.addChildNode(lowerBack)

            // Hips — front of pelvis
            let hips = singleRegionNode(.hips, geometry: SCNBox(width: 0.34, height: 0.16, length: 0.14, chamferRadius: 0.03))
            hips.position = SCNVector3(0, 0.87, 0.04)
            root.addChildNode(hips)

            // Glutes — rear of pelvis; visible from back view
            let glutes = singleRegionNode(.glutes, geometry: SCNBox(width: 0.33, height: 0.17, length: 0.12, chamferRadius: 0.04))
            glutes.position = SCNVector3(0, 0.85, -0.09)
            root.addChildNode(glutes)

            // Quads — front of thighs (composite: two capsules)
            let quadsNode = compositeRegionNode(.quads, y: 0.625)
            for x: Float in [-0.115, 0.115] {
                quadsNode.addChildNode(capsuleChild(capRadius: 0.088, height: 0.35, x: x, z: 0.035))
            }
            root.addChildNode(quadsNode)

            // Hamstrings — rear of thighs; visible from back view (composite)
            let hamstringsNode = compositeRegionNode(.hamstrings, y: 0.625)
            for x: Float in [-0.115, 0.115] {
                hamstringsNode.addChildNode(capsuleChild(capRadius: 0.088, height: 0.35, x: x, z: -0.035))
            }
            root.addChildNode(hamstringsNode)

            // Calves — lower legs (composite)
            let calvesNode = compositeRegionNode(.calves, y: 0.21)
            for x: Float in [-0.085, 0.085] {
                calvesNode.addChildNode(capsuleChild(capRadius: 0.065, height: 0.32, x: x, z: 0))
            }
            root.addChildNode(calvesNode)

            scene.rootNode.addChildNode(root)
        }

        // Single-mesh region: geometry lives directly on the named node
        private func singleRegionNode(_ region: BodyRegion, geometry: SCNGeometry) -> SCNNode {
            let node = SCNNode(geometry: geometry)
            node.name = region.rawValue
            regionNodes[region] = node
            return node
        }

        // Composite region: named parent with no geometry; children hold the meshes
        private func compositeRegionNode(_ region: BodyRegion, y: Float) -> SCNNode {
            let node = SCNNode()
            node.name = region.rawValue
            node.position = SCNVector3(0, y, 0)
            regionNodes[region] = node
            return node
        }

        private func capsuleChild(capRadius: CGFloat, height: CGFloat, x: Float, z: Float) -> SCNNode {
            let node = SCNNode(geometry: SCNCapsule(capRadius: capRadius, height: height))
            node.position = SCNVector3(x, 0, z)
            return node
        }

        private func makeArmNode(side: Float) -> SCNNode {
            let arm = SCNNode()

            let upper = SCNNode(geometry: SCNCapsule(capRadius: 0.065, height: 0.28))
            upper.position = SCNVector3(side * 0.295, 1.325, 0)
            upper.eulerAngles = SCNVector3(0, 0, side * -0.28)
            upper.geometry?.firstMaterial = decorativeMaterial()
            arm.addChildNode(upper)

            let lower = SCNNode(geometry: SCNCapsule(capRadius: 0.055, height: 0.25))
            lower.position = SCNVector3(side * 0.408, 1.095, 0)
            lower.eulerAngles = SCNVector3(0, 0, side * -0.38)
            lower.geometry?.firstMaterial = decorativeMaterial()
            arm.addChildNode(lower)

            return arm
        }

        // MARK: - Lighting

        func setupLighting(in scene: SCNScene) {
            // Ambient — dark navy-blue tint keeps the scene moody
            let ambient = SCNLight()
            ambient.type = .ambient
            ambient.color = UIColor(red: 0.06, green: 0.09, blue: 0.18, alpha: 1)
            ambient.intensity = 450
            let ambientNode = SCNNode()
            ambientNode.light = ambient
            scene.rootNode.addChildNode(ambientNode)

            // Key light — soft diffuse from upper-front
            let key = SCNLight()
            key.type = .directional
            key.color = UIColor(white: 0.88, alpha: 1)
            key.intensity = 700
            key.castsShadow = false
            let keyNode = SCNNode()
            keyNode.light = key
            keyNode.eulerAngles = SCNVector3(-0.5, 0.3, 0)
            scene.rootNode.addChildNode(keyNode)

            // Rim light — cool blue from rear-top, wraps edges for definition
            let rim = SCNLight()
            rim.type = .directional
            rim.color = UIColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1)
            rim.intensity = 550
            rim.castsShadow = false
            let rimNode = SCNNode()
            rimNode.light = rim
            rimNode.eulerAngles = SCNVector3(-0.2, Float.pi + 0.4, 0)
            scene.rootNode.addChildNode(rimNode)

            // Fill light — faint upward bounce softens hard shadows
            let fill = SCNLight()
            fill.type = .directional
            fill.color = UIColor(red: 0.08, green: 0.12, blue: 0.22, alpha: 1)
            fill.intensity = 180
            let fillNode = SCNNode()
            fillNode.light = fill
            fillNode.eulerAngles = SCNVector3(0.9, 0, 0)
            scene.rootNode.addChildNode(fillNode)
        }

        // MARK: - Ground Shadow

        func addGroundShadow(to scene: SCNScene) {
            let plane = SCNPlane(width: 0.68, height: 0.50)
            plane.cornerRadius = 0.25
            let mat = SCNMaterial()
            mat.diffuse.contents = radialShadowImage()
            mat.lightingModel = .constant
            mat.isDoubleSided = true
            mat.transparencyMode = .rgbZero
            plane.materials = [mat]

            let shadowNode = SCNNode(geometry: plane)
            shadowNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // lie flat
            shadowNode.position = SCNVector3(0, 0.003, 0)
            scene.rootNode.addChildNode(shadowNode)
        }

        // MARK: - Materials

        func updateMaterials(selected: Set<BodyRegion>) {
            for (region, node) in regionNodes {
                applyMaterial(to: node, isSelected: selected.contains(region))
            }
        }

        private func applyMaterial(to node: SCNNode, isSelected: Bool) {
            let mat = isSelected ? selectedMaterial() : neutralMaterial()
            if node.geometry != nil {
                node.geometry?.firstMaterial = mat
            }
            // Composite nodes (quads, hamstrings, calves) have no own geometry —
            // apply material to each child mesh instead.
            node.enumerateChildNodes { child, _ in
                guard child.geometry != nil else { return }
                child.geometry?.firstMaterial = isSelected ? selectedMaterial() : neutralMaterial()
            }
        }

        private func neutralMaterial() -> SCNMaterial {
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(red: 0x64/255, green: 0x74/255, blue: 0x8B/255, alpha: 1)
            mat.lightingModel = .phong
            mat.specular.contents = UIColor(white: 0.25, alpha: 1)
            mat.shininess = 22
            return mat
        }

        private func selectedMaterial() -> SCNMaterial {
            let mat = SCNMaterial()
            // Diffuse: #3B82F6 (blue accent)
            mat.diffuse.contents = UIColor(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255, alpha: 1)
            // Emission: #5EEAD4 (teal glow) at low opacity
            mat.emission.contents = UIColor(red: 0x5E/255, green: 0xEA/255, blue: 0xD4/255, alpha: 1)
                .withAlphaComponent(0.28)
            mat.lightingModel = .phong
            mat.specular.contents = UIColor(white: 0.5, alpha: 1)
            mat.shininess = 50
            return mat
        }

        private func decorativeMaterial() -> SCNMaterial {
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(white: 0.40, alpha: 1)
            mat.lightingModel = .phong
            mat.specular.contents = UIColor(white: 0.18, alpha: 1)
            mat.shininess = 14
            return mat
        }

        // MARK: - Tap Handling

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: nil)
            guard let hit = hits.first else { return }

            // Walk up from the hit node to find the region-named ancestor
            var node: SCNNode? = hit.node
            while let current = node {
                if let name = current.name, let region = BodyRegion(rawValue: name) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    DispatchQueue.main.async { [weak self] in
                        self?.onRegionSelected(region)
                    }
                    return
                }
                node = current.parent
            }
        }

        // MARK: - Helpers

        private func radialShadowImage() -> UIImage {
            let size = CGSize(width: 128, height: 128)
            return UIGraphicsImageRenderer(size: size).image { ctx in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let colors = [
                    UIColor.black.withAlphaComponent(0.55).cgColor,
                    UIColor.black.withAlphaComponent(0).cgColor
                ] as CFArray
                let locations: [CGFloat] = [0, 1]
                guard let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors,
                    locations: locations
                ) else { return }
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: size.width / 2,
                    options: []
                )
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 15/255, green: 23/255, blue: 42/255).ignoresSafeArea()
        BodyModelView(
            selectedRegions: [.chest, .lowerBack],
            cameraAngle: .front,
            onRegionSelected: { _ in }
        )
    }
}

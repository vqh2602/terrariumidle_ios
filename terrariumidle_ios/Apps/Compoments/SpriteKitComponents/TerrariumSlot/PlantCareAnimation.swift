import SpriteKit

public enum PlantCareAction: Equatable {
    case water, fertilize, remove
}

public struct PlantCareAnimationRequest: Equatable {
    let id = UUID()
    let action: PlantCareAction
}

/// Tools and particles use scene coordinates, independently of the plant's scale.
final class PlantCareAnimation: SKNode {
    static let duration: TimeInterval = 2.3

    init(action: PlantCareAction, target: CGPoint, width: CGFloat,
         plant: SKNode?, completion: @escaping () -> Void) {
        super.init()
        zPosition = 200
        name = "plantCareAnimation"
        position = target

        let tool = SKSpriteNode(imageNamed: action == .water ? "water-can" : action == .fertilize ? "fertilizer" : "shovel")
        let textureSize = tool.texture?.size() ?? CGSize(width: 1, height: 1)
        let toolWidth = min(64, max(38, width * 0.48))
        tool.size = CGSize(width: toolWidth, height: toolWidth * textureSize.height / max(1, textureSize.width))
        tool.zPosition = 1
        tool.alpha = 0
        tool.position = CGPoint(x: width * 0.25, y: width * 0.72)
        addChild(tool)

        if action == .remove {
            animateShovel(tool, width: width, plant: plant)
        } else {
            if action == .water { tool.xScale = -1 }
            let tilt: CGFloat = action == .water ? 0.42 : .pi * 0.85
            tool.run(.sequence([
                .group([.fadeIn(withDuration: 0.2), .moveBy(x: 0, y: -width * 0.08, duration: 0.25)]),
                .rotate(toAngle: tilt, duration: 0.3),
                .run { [weak self, weak tool] in
                    guard let self, let tool else { return }
                    self.pour(from: tool, action: action, width: width)
                },
                .wait(forDuration: 1.05),
                .rotate(toAngle: 0, duration: 0.25),
                .group([.fadeOut(withDuration: 0.2), .moveBy(x: width * 0.1, y: width * 0.12, duration: 0.2)])
            ]))
        }
        run(.sequence([
            .wait(forDuration: Self.duration),
            .run { [weak self] in
                // Updating SwiftUI may tear down the scene immediately.
                self?.removeFromParent()
                completion()
            }
        ]))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func pour(from tool: SKSpriteNode, action: PlantCareAction, width: CGFloat) {
        // Match the bag opening / the mirrored watering can's spout.
        let opening = action == .water
            ? CGPoint(x: tool.size.width * 0.43, y: -tool.size.height * 0.04)
            : CGPoint(x: 0, y: tool.size.height * 0.46)
        let source = tool.convert(opening, to: self)
        run(.repeat(.sequence([
            .run { [weak self] in
                guard let self else { return }
                for _ in 0..<3 {
                    self.drop(from: source, to: CGPoint(x: .random(in: -width * 0.14...width * 0.14), y: 0),
                              water: action == .water, width: width)
                }
            },
            .wait(forDuration: 0.12)
        ]), count: 8))
    }

    private func drop(from source: CGPoint, to target: CGPoint, water: Bool, width: CGFloat) {
        let radius = max(1.3, width * (water ? 0.014 : 0.017))
        let particle = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * (water ? 3.4 : 2)))
        particle.fillColor = water ? SKColor(red: 0.3, green: 0.78, blue: 1, alpha: 0.9) : SKColor(red: 0.65, green: 0.39, blue: 0.15, alpha: 1)
        particle.strokeColor = water ? .white.withAlphaComponent(0.6) : .clear
        particle.lineWidth = 0.4
        particle.position = source
        addChild(particle)
        let path = CGMutablePath()
        path.move(to: source)
        path.addQuadCurve(to: target, control: CGPoint(x: (source.x + target.x) * 0.5, y: source.y * 0.75))
        particle.run(.sequence([
            .follow(path, asOffset: false, orientToPath: false, duration: .random(in: 0.32...0.45)),
            .group([.scale(to: water ? 1.8 : 0.5, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))
    }

    private func animateShovel(_ tool: SKSpriteNode, width: CGFloat, plant: SKNode?) {
        tool.run(.sequence([
            .fadeIn(withDuration: 0.15),
            .group([.move(to: CGPoint(x: width * 0.13, y: width * 0.16), duration: 0.35),
                    .rotate(toAngle: -0.35, duration: 0.35)]),
            .rotate(toAngle: 0.35, duration: 0.3),
            .run { [weak self, weak plant] in
                guard let self else { return }
                for _ in 0..<9 {
                    self.drop(from: .zero, to: CGPoint(x: .random(in: -width * 0.3...width * 0.3), y: -width * 0.1),
                              water: false, width: width)
                }
                guard let plant, let parent = plant.parent else { return }
                // Stop idle and tap actions before lifting the whole plant.
                plant.removeAllActions()
                plant.enumerateChildNodes(withName: "//*") { node, _ in node.removeAllActions() }
                let destination = self.convert(CGPoint(x: width * 0.32, y: width * 0.6), to: parent)
                plant.run(.group([
                    .move(to: destination, duration: 0.7),
                    .rotate(toAngle: -0.25, duration: 0.7),
                    .fadeOut(withDuration: 0.7)
                ]), withKey: "careRemoval")
            },
            .group([.moveBy(x: width * 0.25, y: width * 0.55, duration: 0.7),
                    .fadeOut(withDuration: 0.7)])
        ]))
    }
}

//
//  PestAgentNode.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SpriteKit
import UIKit

// MARK: - Pest Species

public enum PestSpecies: String, Codable, CaseIterable, Hashable {
    case bug1
    case grasshopper

    public var displayName: String {
        switch self {
        case .bug1: return "Sâu xanh".tr
        case .grasshopper: return "Châu chấu".tr
        }
    }

    public var previewImageName: String {
        switch self {
        case .bug1: return "bug1@2.083x"
        case .grasshopper: return "grasshopper@2.083x"
        }
    }
}

// MARK: - Part Spec

private enum PestPartRole {
    case segment(index: Int) // 0 (head) ... 5 (tail)
    case head
    case antenna
    case body
    case wing
    case leg(index: Int)
}

private struct PestPartSpec {
    let imageName: String
    let svgX: CGFloat
    let svgY: CGFloat
    let svgW: CGFloat
    let svgH: CGFloat
    let anchorX: CGFloat
    let anchorY: CGFloat
    let zPosition: CGFloat
    let role: PestPartRole
}

// MARK: - Pest Agent Node

/// Node SpriteKit lắp ghép Sâu (`bug1`) và Châu chấu (`grasshopper`) theo đúng tọa độ SVG chuẩn:
/// - `bug1`: SVG `281.651 x 189.078` (mặc định quay trái), bò uốn sóng sâu đo
/// - `grasshopper`: SVG `353.57 x 231.543` (mặc định quay phải), đạp chân nhún nhảy & phập phồng cánh
/// - Hỗ trợ quay trái/phải mượt mà khi bò trên tán lá, bay vào túi `Bugsnet`, hoặc rơi xuống đất biến mất.
public final class PestAgentNode: SKNode {

    public let pestId: String
    public let species: PestSpecies
    public let plantPositionKey: String
    public var displayWidth: CGFloat

    private let facingNode = SKNode()
    private let bodyRigNode = SKNode()

    private var segmentNodes: [(index: Int, node: SKNode)] = []
    private var headNodes: [SKNode] = []
    private var antennaNodes: [SKNode] = []
    private var wingNodes: [SKNode] = []
    private var legNodes: [(index: Int, node: SKNode)] = []

    public private(set) var isFacingRight: Bool = false
    public private(set) var isDisposed: Bool = false

    /// Kiểm tra điểm chạm (trong hệ tọa độ `parent` / `worldNode`) có trúng thân sâu hay không.
    public func containsWorldPoint(_ worldPoint: CGPoint, padding: CGFloat = 6.0) -> Bool {
        guard !isHidden, !isDisposed else { return false }
        let localPoint: CGPoint
        if let parent {
            localPoint = convert(worldPoint, from: parent)
        } else {
            localPoint = CGPoint(x: worldPoint.x - position.x, y: worldPoint.y - position.y)
        }
        var bounds = facingNode.calculateAccumulatedFrame()
        if bounds.isEmpty {
            bounds = CGRect(
                x: -displayWidth * 0.5,
                y: -displayWidth * 0.35,
                width: displayWidth,
                height: displayWidth * 0.7
            )
        }
        return bounds.insetBy(dx: -padding, dy: -padding).contains(localPoint)
    }

    private var patrolCenter: CGPoint = .zero
    private var patrolSpreadX: CGFloat = 18.0
    private var patrolSpreadY: CGFloat = 6.0

    // MARK: - Init

    public init(
        pestId: String = UUID().uuidString,
        species: PestSpecies,
        plantPositionKey: String = "",
        displayWidth: CGFloat = 34.0
    ) {
        self.pestId = pestId
        self.species = species
        self.plantPositionKey = plantPositionKey
        self.displayWidth = displayWidth
        super.init()

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assembleParts()
        startCrawlAnimation()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.pestId = UUID().uuidString
        self.species = .bug1
        self.plantPositionKey = ""
        self.displayWidth = 34.0
        super.init(coder: aDecoder)

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assembleParts()
        startCrawlAnimation()
    }

    // MARK: - Orientation

    private var facesRightByDefault: Bool {
        switch species {
        case .bug1: return false       // bug1.svg quay đầu sang trái
        case .grasshopper: return true // grasshopper.svg quay đầu sang phải
        }
    }

    public func setFacingRight(_ facingRight: Bool, animated: Bool = true) {
        isFacingRight = facingRight
        let needsFlip = (facingRight != facesRightByDefault)
        let targetScale: CGFloat = needsFlip ? -1.0 : 1.0
        guard abs(facingNode.xScale - targetScale) > 0.01 else { return }

        facingNode.removeAction(forKey: "pest_turn")
        if animated {
            let turn = SKAction.scaleX(to: targetScale, duration: 0.14)
            turn.timingMode = .easeInEaseOut
            facingNode.run(turn, withKey: "pest_turn")
        } else {
            facingNode.xScale = targetScale
        }
    }

    // MARK: - SVG Assembly

    private func assembleParts() {
        bodyRigNode.removeAllChildren()
        segmentNodes.removeAll()
        headNodes.removeAll()
        antennaNodes.removeAll()
        wingNodes.removeAll()
        legNodes.removeAll()

        let canvas = Self.svgCanvasSize(for: species)
        let scale = displayWidth / canvas.width
        let specs = Self.specs(for: species)

        for spec in specs {
            let tex = PestTextureCache.shared.texture(named: "\(spec.imageName)@2.083x")
            let sprite = SKSpriteNode(texture: tex)
            sprite.size = CGSize(width: spec.svgW * scale, height: spec.svgH * scale)
            sprite.anchorPoint = CGPoint(x: spec.anchorX, y: spec.anchorY)
            sprite.zPosition = spec.zPosition
            sprite.position = skPosition(for: spec, canvas: canvas, scale: scale)
            sprite.restZRotation = 0.0
            bodyRigNode.addChild(sprite)

            switch spec.role {
            case .segment(let idx):
                segmentNodes.append((idx, sprite))
            case .head:
                headNodes.append(sprite)
            case .antenna:
                antennaNodes.append(sprite)
            case .wing:
                wingNodes.append(sprite)
            case .leg(let idx):
                legNodes.append((idx, sprite))
            case .body:
                break
            }
        }

        setFacingRight(Bool.random(), animated: false)
    }

    private func skPosition(for spec: PestPartSpec, canvas: CGSize, scale: CGFloat) -> CGPoint {
        let svgAnchorX = spec.svgX + spec.anchorX * spec.svgW
        let svgAnchorY = spec.svgY + (1.0 - spec.anchorY) * spec.svgH
        let skX = (svgAnchorX - canvas.width * 0.5) * scale
        let skY = (canvas.height * 0.5 - svgAnchorY) * scale
        return CGPoint(x: skX, y: skY)
    }

    // MARK: - Part Crawl Animation

    private func startCrawlAnimation() {
        bodyRigNode.removeAllActions()

        switch species {
        case .bug1:
            // Sâu đo uốn sóng từ đầu đến đuôi
            for (idx, seg) in segmentNodes {
                let phaseDelay = TimeInterval(idx) * 0.09
                let lift = SKAction.group([
                    SKAction.moveBy(x: 0, y: 1.4, duration: 0.24),
                    SKAction.rotate(toAngle: (idx % 2 == 0) ? 0.08 : -0.06, duration: 0.24)
                ])
                lift.timingMode = .easeInEaseOut
                let drop = SKAction.group([
                    SKAction.moveBy(x: 0, y: -1.4, duration: 0.24),
                    SKAction.rotate(toAngle: 0.0, duration: 0.24)
                ])
                drop.timingMode = .easeInEaseOut
                let seq = SKAction.sequence([lift, drop])
                seg.run(
                    SKAction.sequence([SKAction.wait(forDuration: phaseDelay), SKAction.repeatForever(seq)]),
                    withKey: "pest_seg"
                )
            }

            for head in headNodes {
                let nodUp = SKAction.rotate(toAngle: 0.08, duration: 0.30)
                nodUp.timingMode = .easeInEaseOut
                let nodDown = SKAction.rotate(toAngle: -0.06, duration: 0.30)
                nodDown.timingMode = .easeInEaseOut
                head.run(SKAction.repeatForever(SKAction.sequence([nodUp, nodDown])), withKey: "pest_head")
            }

            for (i, ant) in antennaNodes.enumerated() {
                let dir: CGFloat = (i % 2 == 0) ? 1.0 : -1.0
                let a = SKAction.rotate(toAngle: dir * 0.16, duration: 0.26)
                a.timingMode = .easeInEaseOut
                let b = SKAction.rotate(toAngle: -dir * 0.10, duration: 0.26)
                b.timingMode = .easeInEaseOut
                ant.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "pest_ant")
            }

            let squash = SKAction.group([
                SKAction.scaleX(to: 0.94, duration: 0.24),
                SKAction.scaleY(to: 1.06, duration: 0.24)
            ])
            squash.timingMode = .easeInEaseOut
            let stretch = SKAction.group([
                SKAction.scaleX(to: 1.04, duration: 0.24),
                SKAction.scaleY(to: 0.96, duration: 0.24)
            ])
            stretch.timingMode = .easeInEaseOut
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([squash, stretch])), withKey: "pest_body")

        case .grasshopper:
            // Châu chấu nhịp thở + đạp chân + râu vẫy + cánh khẽ rung
            for (idx, leg) in legNodes {
                let sign: CGFloat = (idx % 2 == 0) ? 1.0 : -1.0
                let amp: CGFloat = (idx == 1 || idx == 8) ? 0.11 : 0.20 // Chân sau bật nhẹ, chân trước bước nhanh
                let a = SKAction.rotate(toAngle: sign * amp, duration: 0.18)
                a.timingMode = .easeInEaseOut
                let b = SKAction.rotate(toAngle: -sign * amp, duration: 0.18)
                b.timingMode = .easeInEaseOut
                leg.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "pest_leg")
            }

            for wing in wingNodes {
                let up = SKAction.rotate(toAngle: -0.06, duration: 0.38)
                up.timingMode = .easeInEaseOut
                let down = SKAction.rotate(toAngle: 0.02, duration: 0.38)
                down.timingMode = .easeInEaseOut
                wing.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "pest_wing")
            }

            for (i, ant) in antennaNodes.enumerated() {
                let dir: CGFloat = (i % 2 == 0) ? 1.0 : -1.0
                let a = SKAction.rotate(toAngle: dir * 0.12, duration: 0.32)
                a.timingMode = .easeInEaseOut
                let b = SKAction.rotate(toAngle: -dir * 0.08, duration: 0.32)
                b.timingMode = .easeInEaseOut
                ant.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "pest_ant")
            }

            let bobUp = SKAction.group([
                SKAction.moveTo(y: 1.5, duration: 0.24),
                SKAction.rotate(toAngle: 0.04, duration: 0.24)
            ])
            bobUp.timingMode = .easeInEaseOut
            let bobDown = SKAction.group([
                SKAction.moveTo(y: 0.0, duration: 0.24),
                SKAction.rotate(toAngle: -0.02, duration: 0.24)
            ])
            bobDown.timingMode = .easeInEaseOut
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "pest_body")
        }
    }

    // MARK: - Plant Leaf Patrol (Quay trái/phải & bò qua lại trên cây)

    public func startPatrolOnPlant(center: CGPoint, spreadX: CGFloat = 18.0, spreadY: CGFloat = 7.0) {
        guard !isDisposed else { return }
        self.patrolCenter = center
        self.patrolSpreadX = spreadX
        self.patrolSpreadY = spreadY
        self.position = center

        removeAction(forKey: "pest_patrol")
        scheduleNextPatrolStep()
    }

    public func updatePatrolAnchor(center: CGPoint) {
        guard !isDisposed else { return }
        let dx = center.x - patrolCenter.x
        let dy = center.y - patrolCenter.y
        patrolCenter = center
        if hypot(dx, dy) > 0.5 {
            position = CGPoint(x: position.x + dx, y: position.y + dy)
        }
    }

    private func scheduleNextPatrolStep() {
        guard !isDisposed else { return }

        let targetX = patrolCenter.x + CGFloat.random(in: -patrolSpreadX...patrolSpreadX)
        let targetY = patrolCenter.y + CGFloat.random(in: -patrolSpreadY...patrolSpreadY)
        let dx = targetX - position.x
        if abs(dx) > 1.0 {
            setFacingRight(dx > 0, animated: true)
        }

        let dist = hypot(dx, targetY - position.y)
        let speed: CGFloat = (species == .grasshopper) ? 14.0 : 9.0
        let moveDuration = max(1.1, min(2.6, TimeInterval(dist / speed)))

        let moveAction: SKAction
        if species == .grasshopper && Bool.random() {
            // Châu chấu thỉnh thoảng bật nhảy một đoạn ngắn rồi bò tiếp
            let mid = CGPoint(x: (position.x + targetX) * 0.5, y: max(position.y, targetY) + 11.0)
            let path = CGMutablePath()
            path.move(to: position)
            path.addQuadCurve(to: CGPoint(x: targetX, y: targetY), control: mid)
            moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: moveDuration * 0.72)
        } else {
            moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: moveDuration)
        }
        moveAction.timingMode = .easeInEaseOut

        let pauseDuration = Double.random(in: 1.0...2.4)
        let next = SKAction.run { [weak self] in
            self?.scheduleNextPatrolStep()
        }

        run(SKAction.sequence([moveAction, SKAction.wait(forDuration: pauseDuration), next]), withKey: "pest_patrol")
    }

    // MARK: - Capture / Kill Outcomes

    /// Bắt sâu vào túi `Bugsnet`: bay theo đường cong về miệng túi lưới rồi thu nhỏ biến mất vào túi.
    public func animateFlyIntoBag(to bagPoint: CGPoint, completion: @escaping () -> Void) {
        guard !isDisposed else { return }
        isDisposed = true
        removeAction(forKey: "pest_patrol")
        setFacingRight(bagPoint.x >= position.x, animated: false)

        let start = position
        let dist = hypot(bagPoint.x - start.x, bagPoint.y - start.y)
        let dur = max(0.45, min(0.85, TimeInterval(dist / 360.0)))
        let ctrl = CGPoint(
            x: (start.x + bagPoint.x) * 0.5,
            y: max(start.y, bagPoint.y) + 46.0
        )
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: bagPoint, control: ctrl)

        let fly = SKAction.follow(path, asOffset: false, orientToPath: false, duration: dur)
        fly.timingMode = .easeInEaseOut
        let spin = SKAction.rotate(toAngle: .pi * 0.35, duration: dur)
        let shrink = SKAction.scale(to: 0.25, duration: dur)
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: dur * 0.7),
            SKAction.fadeOut(withDuration: dur * 0.3)
        ])

        run(SKAction.sequence([
            SKAction.group([fly, spin, shrink, fade]),
            SKAction.run(completion),
            SKAction.removeFromParent()
        ]))
    }

    /// Tiêu diệt sâu khi túi đầy / chưa có túi / xịt hóa chất: lộn ngược rơi xuống đất và biến mất.
    public func animateFallAndDisappear(isSpray: Bool = false, completion: @escaping () -> Void) {
        guard !isDisposed else { return }
        isDisposed = true
        removeAction(forKey: "pest_patrol")

        let side: CGFloat = Bool.random() ? 1.0 : -1.0
        let hopUp = SKAction.move(by: CGVector(dx: side * 8.0, dy: isSpray ? 6.0 : 14.0), duration: 0.14)
        hopUp.timingMode = .easeOut

        let fallDur: TimeInterval = isSpray ? Double.random(in: 0.65...0.95) : 0.62
        let fall = SKAction.move(by: CGVector(dx: side * CGFloat.random(in: 12...28), dy: -155.0), duration: fallDur)
        fall.timingMode = .easeIn
        let flip = SKAction.rotate(toAngle: side * .pi * 1.15, duration: fallDur)
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: fallDur * 0.45),
            SKAction.fadeOut(withDuration: fallDur * 0.55)
        ])
        let scale = SKAction.scale(to: 0.65, duration: fallDur)

        run(SKAction.sequence([
            hopUp,
            SKAction.group([fall, flip, fade, scale]),
            SKAction.run(completion),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Exact Sampled SVG Canvas & Specs

    private static func svgCanvasSize(for species: PestSpecies) -> CGSize {
        switch species {
        case .bug1:        return CGSize(width: 281.651, height: 189.078)
        case .grasshopper: return CGSize(width: 353.570, height: 231.543)
        }
    }

    private static func specs(for species: PestSpecies) -> [PestPartSpec] {
        switch species {
        case .bug1:
            return [
                PestPartSpec(imageName: "bug1-1", svgX: 213.461, svgY: 114.121, svgW: 68.186,  svgH: 74.956,  anchorX: 0.50, anchorY: 0.50, zPosition: 2,  role: .segment(index: 5)),
                PestPartSpec(imageName: "bug1-2", svgX: 175.309, svgY: 103.111, svgW: 74.612,  svgH: 82.463,  anchorX: 0.50, anchorY: 0.50, zPosition: 4,  role: .segment(index: 4)),
                PestPartSpec(imageName: "bug1-3", svgX: 128.541, svgY: 92.516,  svgW: 79.707,  svgH: 88.161,  anchorX: 0.50, anchorY: 0.50, zPosition: 6,  role: .segment(index: 3)),
                PestPartSpec(imageName: "bug1-4", svgX: 88.601,  svgY: 81.097,  svgW: 79.773,  svgH: 89.991,  anchorX: 0.50, anchorY: 0.50, zPosition: 8,  role: .segment(index: 2)),
                PestPartSpec(imageName: "bug1-5", svgX: 36.587,  svgY: 71.278,  svgW: 98.915,  svgH: 87.251,  anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .segment(index: 1)),
                PestPartSpec(imageName: "bug1-6", svgX: 0.032,   svgY: 14.543,  svgW: 110.855, svgH: 105.971, anchorX: 0.50, anchorY: 0.50, zPosition: 12, role: .head),
                PestPartSpec(imageName: "bug1-7", svgX: 55.354,  svgY: 0.003,   svgW: 7.185,   svgH: 18.186,  anchorX: 0.65, anchorY: 0.05, zPosition: 14, role: .antenna),
                PestPartSpec(imageName: "bug1-8", svgX: 5.179,   svgY: 20.369,  svgW: 11.483,  svgH: 12.861,  anchorX: 0.85, anchorY: 0.10, zPosition: 14, role: .antenna)
            ]

        case .grasshopper:
            return [
                PestPartSpec(imageName: "grasshopper-1",  svgX: 220.479, svgY: 141.603, svgW: 41.437,  svgH: 29.043,  anchorX: 0.20, anchorY: 0.80, zPosition: 2,  role: .leg(index: 0)),
                PestPartSpec(imageName: "grasshopper-2",  svgX: 76.958,  svgY: 25.513,  svgW: 105.844, svgH: 130.643, anchorX: 0.25, anchorY: 0.08, zPosition: 3,  role: .leg(index: 1)),
                PestPartSpec(imageName: "grasshopper-3",  svgX: 1.703,   svgY: 78.233,  svgW: 177.905, svgH: 55.233,  anchorX: 0.90, anchorY: 0.35, zPosition: 4,  role: .wing),
                PestPartSpec(imageName: "grasshopper-4",  svgX: 0.000,   svgY: 85.807,  svgW: 194.948, svgH: 74.599,  anchorX: 0.90, anchorY: 0.65, zPosition: 5,  role: .wing),
                PestPartSpec(imageName: "grasshopper-5",  svgX: 30.847,  svgY: 73.912,  svgW: 206.883, svgH: 131.148, anchorX: 0.50, anchorY: 0.50, zPosition: 7,  role: .body),
                PestPartSpec(imageName: "grasshopper-6",  svgX: 193.891, svgY: 51.270,  svgW: 98.113,  svgH: 112.077, anchorX: 0.35, anchorY: 0.45, zPosition: 9,  role: .head),
                PestPartSpec(imageName: "grasshopper-7",  svgX: 243.911, svgY: 0.005,   svgW: 90.816,  svgH: 57.555,  anchorX: 0.05, anchorY: 0.05, zPosition: 10, role: .antenna),
                PestPartSpec(imageName: "grasshopper-8",  svgX: 259.373, svgY: 31.501,  svgW: 94.196,  svgH: 30.388,  anchorX: 0.05, anchorY: 0.10, zPosition: 10, role: .antenna),
                PestPartSpec(imageName: "grasshopper-9",  svgX: 35.425,  svgY: 105.856, svgW: 142.370, svgH: 125.687, anchorX: 0.15, anchorY: 0.85, zPosition: 12, role: .leg(index: 8)),
                PestPartSpec(imageName: "grasshopper-10", svgX: 177.105, svgY: 138.252, svgW: 23.975,  svgH: 60.195,  anchorX: 0.35, anchorY: 0.90, zPosition: 13, role: .leg(index: 9)),
                PestPartSpec(imageName: "grasshopper-11", svgX: 205.065, svgY: 147.983, svgW: 29.718,  svgH: 41.740,  anchorX: 0.25, anchorY: 0.90, zPosition: 14, role: .leg(index: 10))
            ]
        }
    }
}

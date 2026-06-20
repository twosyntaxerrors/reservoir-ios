import SwiftUI
import SpriteKit

struct ReservoirSpriteView: UIViewRepresentable {
    let streak: Int
    let vessel: VesselSkin
    let tilt: MotionState
    let angularVelocity: Double
    let relapsePulse: Double

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        context.coordinator.scene.scaleMode = .resizeFill
        view.presentScene(context.coordinator.scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.configure(streak: streak, vessel: vessel, tilt: tilt, angularVelocity: angularVelocity, relapsePulse: relapsePulse)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        let scene = ReservoirScene(size: CGSize(width: 360, height: 520))
    }
}

final class ReservoirScene: SKScene {
    private let vesselNode = SKShapeNode()
    private let innerGlassNode = SKShapeNode()
    private let liquidCropNode = SKCropNode()
    private let liquidNode = SKShapeNode()
    private let liquidHighlightNode = SKShapeNode()
    private let glowNode = SKShapeNode(circleOfRadius: 150)
    private let crackNode = SKShapeNode()
    private let particleContainer = SKNode()
    private let bubbleContainer = SKNode()

    private var streak: Int = 0
    private var vessel: VesselSkin = .apprentice
    private var tilt = MotionState()
    private var angularVelocity: Double = 0
    private var relapsePulse: Double = 0
    private var lastSize: CGSize = .zero
    private var didBuildParticles = false

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupNodes()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupNodes()
    }

    func configure(streak: Int, vessel: VesselSkin, tilt: MotionState, angularVelocity: Double, relapsePulse: Double) {
        let vesselChanged = self.vessel != vessel
        let streakChanged = self.streak != streak
        self.streak = streak
        self.vessel = vessel
        self.tilt = tilt
        self.angularVelocity = angularVelocity
        self.relapsePulse = relapsePulse

        if vesselChanged || streakChanged || !didBuildParticles {
            rebuildParticles()
            rebuildBubbles()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        lastSize = size
        redrawStaticGeometry()
        rebuildParticles()
        rebuildBubbles()
    }

    override func update(_ currentTime: TimeInterval) {
        let t = CGFloat(currentTime)
        redrawLiquid(time: t)
        animateParticles(time: t)
        animateBubbles(time: t)
        redrawCracks()
    }

    private func setupNodes() {
        glowNode.zPosition = 0
        glowNode.fillColor = .cyan.withAlphaComponent(0.18)
        glowNode.strokeColor = .clear
        glowNode.blendMode = .add
        glowNode.glowWidth = 54
        addChild(glowNode)

        particleContainer.zPosition = 1
        addChild(particleContainer)

        liquidCropNode.zPosition = 3
        addChild(liquidCropNode)

        liquidNode.zPosition = 0
        liquidNode.strokeColor = .clear
        liquidNode.blendMode = .alpha
        liquidCropNode.addChild(liquidNode)

        bubbleContainer.zPosition = 4
        addChild(bubbleContainer)

        liquidHighlightNode.zPosition = 5
        liquidHighlightNode.strokeColor = .white.withAlphaComponent(0.58)
        liquidHighlightNode.lineWidth = 2
        liquidHighlightNode.fillColor = .clear
        liquidHighlightNode.blendMode = .add
        addChild(liquidHighlightNode)

        vesselNode.zPosition = 8
        vesselNode.fillColor = .white.withAlphaComponent(0.06)
        vesselNode.strokeColor = .white.withAlphaComponent(0.82)
        vesselNode.lineWidth = 2.2
        vesselNode.glowWidth = 1.5
        addChild(vesselNode)

        innerGlassNode.zPosition = 9
        innerGlassNode.fillColor = .clear
        innerGlassNode.strokeColor = .white.withAlphaComponent(0.18)
        innerGlassNode.lineWidth = 9
        innerGlassNode.blendMode = .add
        addChild(innerGlassNode)

        crackNode.zPosition = 10
        crackNode.fillColor = .clear
        crackNode.strokeColor = .white
        crackNode.lineWidth = 2
        crackNode.glowWidth = 4
        crackNode.alpha = 0
        addChild(crackNode)
    }

    private func redrawStaticGeometry() {
        let path = vesselPath(in: drawingRect())
        vesselNode.path = path
        innerGlassNode.path = path
        glowNode.position = CGPoint(x: 0, y: -size.height * 0.08)
        glowNode.xScale = 1.0 + CGFloat(glowStrength(for: streak)) * 0.28
        glowNode.yScale = 1.0 + CGFloat(glowStrength(for: streak)) * 0.22
    }

    private func redrawLiquid(time: CGFloat) {
        let rect = drawingRect()
        let fill = CGFloat(fillFraction(for: streak)) * CGFloat(max(0, 1 - relapsePulse * 0.92))
        let baseY = rect.minY + rect.height * fill
        let leftX = rect.minX + rect.width * 0.08
        let rightX = rect.maxX - rect.width * 0.08
        let slope = CGFloat(tilt.x) * rect.width * 0.09
        let wave = rect.height * (0.014 + CGFloat(angularVelocity) * 0.026)
        let phase = time * 2.35

        let path = CGMutablePath()
        var surfacePoints: [CGPoint] = []
        let segments = 32
        for i in 0...segments {
            let p = CGFloat(i) / CGFloat(segments)
            let x = leftX + (rightX - leftX) * p
            let y = baseY + slope * (p * 2 - 1) + sin(p * .pi * 3.6 + phase) * wave + sin(p * .pi * 8.0 - phase * 1.4) * wave * 0.28
            surfacePoints.append(CGPoint(x: x, y: y))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.addLine(to: CGPoint(x: rightX, y: rect.minY - 50))
        path.addLine(to: CGPoint(x: leftX, y: rect.minY - 50))
        path.closeSubpath()

        let mask = vesselPath(in: rect)
        let maskNode = SKShapeNode(path: mask)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        liquidCropNode.maskNode = maskNode
        liquidNode.path = path
        liquidNode.fillColor = vessel.liquidColors.first?.withAlphaComponent(0.88) ?? .cyan
        liquidNode.glowWidth = 18 * CGFloat(glowStrength(for: streak))

        let highlight = CGMutablePath()
        if let first = surfacePoints.first { highlight.move(to: first) }
        for point in surfacePoints.dropFirst() { highlight.addLine(to: point) }
        liquidHighlightNode.path = highlight
        liquidHighlightNode.alpha = 0.34 + CGFloat(glowStrength(for: streak)) * 0.34
    }

    private func redrawCracks() {
        guard relapsePulse > 0.02 || streak >= 180 else {
            crackNode.alpha = 0
            return
        }
        let rect = drawingRect()
        let pulse = CGFloat(max(relapsePulse, streak >= 180 ? 0.22 : 0))
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: 15, y: rect.maxY - rect.height * 0.28))
        path.addLine(to: CGPoint(x: -12, y: rect.maxY - rect.height * 0.45))
        path.addLine(to: CGPoint(x: 6, y: rect.maxY - rect.height * 0.58))
        path.addLine(to: CGPoint(x: -34 * pulse, y: rect.maxY - rect.height * 0.76))
        path.move(to: CGPoint(x: 13, y: rect.maxY - rect.height * 0.31))
        path.addLine(to: CGPoint(x: 58 * pulse, y: rect.maxY - rect.height * 0.38))
        path.move(to: CGPoint(x: -12, y: rect.maxY - rect.height * 0.49))
        path.addLine(to: CGPoint(x: -64 * pulse, y: rect.maxY - rect.height * 0.55))
        crackNode.path = path
        crackNode.alpha = CGFloat(relapsePulse > 0.02 ? relapsePulse : 0.28)
        crackNode.strokeColor = relapsePulse > 0.02 ? .white : (vessel.liquidColors.first ?? .cyan).withAlphaComponent(0.65)
    }

    private func rebuildParticles() {
        didBuildParticles = true
        particleContainer.removeAllChildren()
        let count: Int
        switch streak {
        case 365...: count = 44
        case 180...: count = 32
        case 90...: count = 26
        case 30...: count = 18
        case 7...: count = 10
        default: count = 4
        }
        for index in 0..<count {
            let radius = CGFloat(1.2 + Double(index % 4) * 0.55 + glowStrength(for: streak) * 1.2)
            let node = SKShapeNode(circleOfRadius: radius)
            node.fillColor = index % 3 == 0 ? .white.withAlphaComponent(0.75) : (vessel.liquidColors.first ?? .cyan).withAlphaComponent(0.76)
            node.strokeColor = .clear
            node.blendMode = .add
            node.userData = ["seed": CGFloat(index)]
            particleContainer.addChild(node)
        }
    }

    private func rebuildBubbles() {
        bubbleContainer.removeAllChildren()
        let count = min(22, 3 + streak / 12)
        for index in 0..<count {
            let node = SKShapeNode(circleOfRadius: CGFloat(2 + index % 4))
            node.fillColor = .white.withAlphaComponent(0.12)
            node.strokeColor = .white.withAlphaComponent(0.28)
            node.lineWidth = 0.6
            node.blendMode = .add
            node.userData = ["seed": CGFloat(index)]
            bubbleContainer.addChild(node)
        }
    }

    private func animateParticles(time: CGFloat) {
        let rect = drawingRect()
        let glow = CGFloat(glowStrength(for: streak))
        for child in particleContainer.children {
            let seed = child.userData?["seed"] as? CGFloat ?? 0
            let angle = seed * 1.77 + time / (2.4 + seed * 0.04)
            let orbit = rect.width * (0.2 + (seed.truncatingRemainder(dividingBy: 7) / 7.0) * 0.28)
            child.position = CGPoint(
                x: cos(angle) * orbit * (0.52 + glow * 0.46) + CGFloat(tilt.x) * 12,
                y: sin(angle * 0.82 + seed) * rect.height * 0.28 - rect.height * 0.03 + CGFloat(tilt.y) * 7
            )
            child.alpha = 0.22 + glow * 0.58
        }
        glowNode.fillColor = (vessel.liquidColors.first ?? .cyan).withAlphaComponent(0.16 + glow * 0.18)
    }

    private func animateBubbles(time: CGFloat) {
        let rect = drawingRect()
        let fill = CGFloat(fillFraction(for: streak))
        let liquidHeight = rect.height * fill
        guard liquidHeight > 18 else { return }
        for child in bubbleContainer.children {
            let seed = child.userData?["seed"] as? CGFloat ?? 0
            let cycle = (time * (0.07 + seed * 0.004) + seed * 0.13).truncatingRemainder(dividingBy: 1)
            let x = rect.minX + rect.width * (0.2 + ((seed * 37).truncatingRemainder(dividingBy: 60)) / 100.0) + CGFloat(tilt.x) * 18
            let y = rect.minY + cycle * liquidHeight
            child.position = CGPoint(x: x, y: min(y, rect.minY + liquidHeight - 8))
            child.alpha = 0.05 + CGFloat(glowStrength(for: streak)) * 0.28
        }
    }

    private func drawingRect() -> CGRect {
        let w = min(size.width * 0.82, 360)
        let h = min(size.height * 0.92, 540)
        return CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    }

    private func vesselPath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let cx = rect.midX
        let top = rect.maxY
        let neckW = vessel == .cosmic ? rect.width * 0.16 : rect.width * 0.2
        let shoulderY = rect.maxY - rect.height * 0.2
        let bodyTopW = vessel == .dragon ? rect.width * 0.56 : rect.width * 0.48
        let bodyMidW = vessel == .cosmic ? rect.width * 0.82 : rect.width * 0.7
        let bottomY = rect.minY + rect.height * 0.06
        let bottomW = vessel == .alchemist ? rect.width * 0.48 : rect.width * 0.56

        path.move(to: CGPoint(x: cx - neckW / 2, y: top))
        path.addLine(to: CGPoint(x: cx + neckW / 2, y: top))
        path.addCurve(to: CGPoint(x: cx + bodyTopW / 2, y: shoulderY), control1: CGPoint(x: cx + neckW / 2, y: top - 38), control2: CGPoint(x: cx + bodyTopW / 2, y: shoulderY + 22))
        path.addCurve(to: CGPoint(x: cx + bottomW / 2, y: bottomY + 30), control1: CGPoint(x: cx + bodyMidW / 2, y: rect.maxY - rect.height * 0.34), control2: CGPoint(x: cx + bodyMidW / 2, y: rect.minY + rect.height * 0.28))
        path.addQuadCurve(to: CGPoint(x: cx - bottomW / 2, y: bottomY + 30), control: CGPoint(x: cx, y: bottomY - 18))
        path.addCurve(to: CGPoint(x: cx - bodyTopW / 2, y: shoulderY), control1: CGPoint(x: cx - bodyMidW / 2, y: rect.minY + rect.height * 0.28), control2: CGPoint(x: cx - bodyMidW / 2, y: rect.maxY - rect.height * 0.34))
        path.addCurve(to: CGPoint(x: cx - neckW / 2, y: top), control1: CGPoint(x: cx - bodyTopW / 2, y: shoulderY + 22), control2: CGPoint(x: cx - neckW / 2, y: top - 38))
        path.closeSubpath()
        return path
    }
}

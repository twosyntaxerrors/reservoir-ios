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
    private let rimNode = SKShapeNode()
    private let sheenNode = SKShapeNode()
    private let tickContainer = SKNode()
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

    // Lab-glass palette from the HTML direction: dark measured glass, cyan liquid.
    private let glassLine = SKColor(red: 0.10, green: 0.11, blue: 0.12, alpha: 0.24)
    private let glassTick = SKColor(red: 0.10, green: 0.11, blue: 0.12, alpha: 0.18)
    private let deepCyan = SKColor(red: 0.13, green: 0.75, blue: 0.82, alpha: 1.0)

    private func setupNodes() {
        // The HTML keeps glow constrained to the liquid, so the base aura is subtle.
        glowNode.zPosition = 0
        glowNode.fillColor = deepCyan.withAlphaComponent(0.10)
        glowNode.strokeColor = .clear
        glowNode.blendMode = .add
        glowNode.glowWidth = 18
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
        liquidHighlightNode.strokeColor = SKColor(red: 0.78, green: 0.97, blue: 1.0, alpha: 0.95)
        liquidHighlightNode.lineWidth = 2
        liquidHighlightNode.fillColor = .clear
        liquidHighlightNode.blendMode = .add
        liquidHighlightNode.glowWidth = 3
        // Clip the surface highlight to the vessel so the wavy line never
        // extends beyond the glass (the source of the squiggle artifact).
        liquidCropNode.addChild(liquidHighlightNode)

        // Soft inner line gives the glass volume without changing the measured silhouette.
        innerGlassNode.zPosition = 7
        innerGlassNode.fillColor = .clear
        innerGlassNode.strokeColor = glassLine.withAlphaComponent(0.10)
        innerGlassNode.lineWidth = 5
        innerGlassNode.glowWidth = 0
        addChild(innerGlassNode)

        // Main graduated cylinder outline.
        vesselNode.zPosition = 8
        vesselNode.fillColor = .clear
        vesselNode.strokeColor = glassLine
        vesselNode.lineWidth = 2.0
        vesselNode.glowWidth = 0
        addChild(vesselNode)

        sheenNode.zPosition = 9
        sheenNode.fillColor = SKColor.white.withAlphaComponent(0.42)
        sheenNode.strokeColor = .clear
        addChild(sheenNode)

        tickContainer.zPosition = 10
        addChild(tickContainer)

        rimNode.zPosition = 11
        rimNode.fillColor = .clear
        rimNode.strokeColor = glassLine
        rimNode.lineWidth = 2.0
        rimNode.glowWidth = 0
        addChild(rimNode)

        crackNode.zPosition = 12
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
        rimNode.path = rimPath(in: drawingRect())
        sheenNode.path = sheenPath(in: drawingRect())
        redrawTicks(in: drawingRect())

        let rect = drawingRect()
        let glow = CGFloat(glowStrength(for: streak))
        glowNode.path = CGPath(ellipseIn: CGRect(x: rect.minX + rect.width * 0.16, y: rect.minY - rect.height * 0.03, width: rect.width * 0.68, height: rect.height * 0.10), transform: nil)
        glowNode.position = .zero
        glowNode.xScale = 1.0 + glow * 0.18
        glowNode.yScale = 1.0 + glow * 0.10

        vesselNode.strokeColor = glassLine
        innerGlassNode.strokeColor = glassLine.withAlphaComponent(0.10 + glow * 0.04)
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
        liquidNode.fillColor = (vessel.liquidColors.first ?? deepCyan).withAlphaComponent(0.86)
        liquidNode.glowWidth = 4 + 6 * CGFloat(glowStrength(for: streak))

        let highlight = CGMutablePath()
        if let first = surfacePoints.first { highlight.move(to: first) }
        for point in surfacePoints.dropFirst() { highlight.addLine(to: point) }
        liquidHighlightNode.path = highlight
        liquidHighlightNode.alpha = 0.24 + CGFloat(glowStrength(for: streak)) * 0.28
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
        let count = min(14, max(2, streak / 18))
        for index in 0..<count {
            let radius = CGFloat(0.9 + Double(index % 3) * 0.35)
            let node = SKShapeNode(circleOfRadius: radius)
            node.fillColor = index % 3 == 0 ? .white.withAlphaComponent(0.35) : (vessel.liquidColors.first ?? .cyan).withAlphaComponent(0.36)
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
            let orbit = rect.width * (0.08 + (seed.truncatingRemainder(dividingBy: 7) / 7.0) * 0.15)
            child.position = CGPoint(
                x: cos(angle) * orbit * (0.6 + glow * 0.4) + CGFloat(tilt.x) * 10,
                y: sin(angle * 0.82 + seed) * rect.height * 0.22 + rect.height * 0.06 + CGFloat(tilt.y) * 6
            )
            child.alpha = 0.2 + glow * 0.5
        }
        glowNode.fillColor = (vessel.liquidColors.first ?? deepCyan).withAlphaComponent(0.12 + glow * 0.12)
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
        let w = min(size.width * 0.58, 220)
        let h = min(size.height * 0.88, 330)
        return CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    }

    /// Precise lab-glass cylinder from the HTML direction: straight sides,
    /// open elliptical rim, and a rounded bottom.
    private func vesselPath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let left = rect.minX + rect.width * 0.27
        let right = rect.maxX - rect.width * 0.27
        let top = rect.maxY - rect.height * 0.04
        let bottom = rect.minY + rect.height * 0.10
        let baseControl = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.02)

        path.move(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left, y: bottom))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom), control: baseControl)
        path.addLine(to: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: left, y: top))
        path.closeSubpath()
        return path
    }

    private func rimPath(in rect: CGRect) -> CGPath {
        let width = rect.width * 0.54
        let height = rect.height * 0.034
        return CGPath(
            ellipseIn: CGRect(
                x: rect.midX - width / 2,
                y: rect.maxY - rect.height * 0.04 - height / 2,
                width: width,
                height: height
            ),
            transform: nil
        )
    }

    private func sheenPath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let left = rect.minX + rect.width * 0.36
        let top = rect.maxY - rect.height * 0.10
        let height = rect.height * 0.58
        path.addRoundedRect(
            in: CGRect(x: left, y: top - height, width: rect.width * 0.035, height: height),
            cornerWidth: rect.width * 0.02,
            cornerHeight: rect.width * 0.02
        )
        return path
    }

    private func redrawTicks(in rect: CGRect) {
        tickContainer.removeAllChildren()

        let right = rect.maxX - rect.width * 0.27
        let top = rect.maxY - rect.height * 0.14
        let bottom = rect.minY + rect.height * 0.21

        for index in 0...6 {
            let fraction = CGFloat(index) / 6
            let y = top - (top - bottom) * fraction
            let length = index.isMultiple(of: 2) ? rect.width * 0.08 : rect.width * 0.055
            let path = CGMutablePath()
            path.move(to: CGPoint(x: right - length, y: y))
            path.addLine(to: CGPoint(x: right, y: y))

            let tick = SKShapeNode(path: path)
            tick.strokeColor = glassTick
            tick.lineWidth = 1.4
            tickContainer.addChild(tick)
        }
    }
}

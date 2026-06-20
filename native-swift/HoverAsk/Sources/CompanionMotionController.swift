import AppKit
import Foundation

@MainActor
final class CompanionMotionController {
    var phaseProvider: (() -> OrbPhase)?
    var onVisualMotionChange: ((CompanionVisualMotion) -> Void)?

    private let settings: SettingsStore
    private weak var windowController: OrbWindowController?
    private var timer: Timer?
    private var lastTick = Date()
    private var pauseUntil = Date.distantPast
    private var velocity = CGVector(dx: 0, dy: 0)
    private var roamTarget: CGPoint?
    private var nextRoamTargetAt = Date.distantPast
    private var lastVisualMotion = CompanionVisualMotion.idle

    init(settings: SettingsStore) {
        self.settings = settings
    }

    deinit {
        timer?.invalidate()
    }

    func attach(windowController: OrbWindowController) {
        self.windowController = windowController
    }

    func start() {
        timer?.invalidate()
        lastTick = Date()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func pause(for seconds: TimeInterval) {
        pauseUntil = Date().addingTimeInterval(seconds)
        velocity = .zero
        publish(.idle)
    }

    private func tick() {
        let now = Date()
        let dt = min(max(now.timeIntervalSince(lastTick), 1.0 / 120.0), 1.0 / 12.0)
        lastTick = now

        guard let windowController,
              windowController.isVisible,
              settings.avatarStyle.isCompanion,
              settings.companionMovementMode != .stationary,
              phaseProvider?() == .idle,
              now >= pauseUntil
        else {
            velocity = .zero
            publish(.idle)
            return
        }

        switch settings.companionMovementMode {
        case .stationary:
            velocity = .zero
            publish(.idle)
        case .roam:
            stepRoam(windowController: windowController, now: now, dt: dt)
        case .chaseCursor:
            stepChaseCursor(windowController: windowController, dt: dt)
        }
    }

    private func stepRoam(windowController: OrbWindowController, now: Date, dt: TimeInterval) {
        let center = windowController.avatarCenter()
        let visibleFrame = windowController.visibleFrame(containing: center).insetBy(dx: 80, dy: 80)
        if roamTarget == nil || now >= nextRoamTargetAt || center.distance(to: roamTarget ?? center) < 36 {
            roamTarget = CGPoint(
                x: CGFloat.random(in: visibleFrame.minX...visibleFrame.maxX),
                y: CGFloat.random(in: visibleFrame.minY...visibleFrame.maxY)
            )
            nextRoamTargetAt = now.addingTimeInterval(Double.random(in: 3.8...7.2))
        }

        guard let roamTarget else {
            publish(.idle)
            return
        }
        move(windowController: windowController, toward: roamTarget, preferredSpeed: 96, dt: dt, stopRadius: 24)
    }

    private func stepChaseCursor(windowController: OrbWindowController, dt: TimeInterval) {
        let center = windowController.avatarCenter()
        let cursor = NSEvent.mouseLocation
        let distance = center.distance(to: cursor)
        guard distance > 112 else {
            velocity = velocity.scaled(by: 0.72)
            if abs(velocity.dx) < 2, abs(velocity.dy) < 2 {
                velocity = .zero
            }
            windowController.setAvatarCenter(center.offset(by: velocity.scaled(by: dt)))
            publish(CompanionVisualMotion(isRunning: false, facingRight: cursor.x > center.x))
            return
        }

        let direction = CGVector(from: center, to: cursor).normalized
        let standoffTarget = cursor.offset(by: direction.scaled(by: CGFloat(-94)))
        let speed = min(max(distance * 1.8, 150), 520)
        move(windowController: windowController, toward: standoffTarget, preferredSpeed: speed, dt: dt, stopRadius: 26)
    }

    private func move(windowController: OrbWindowController, toward target: CGPoint, preferredSpeed: CGFloat, dt: TimeInterval, stopRadius: CGFloat) {
        let center = windowController.avatarCenter()
        let vector = CGVector(from: center, to: target)
        let distance = vector.length
        guard distance > stopRadius else {
            velocity = velocity.scaled(by: 0.68)
            windowController.setAvatarCenter(center.offset(by: velocity.scaled(by: dt)))
            publish(CompanionVisualMotion(isRunning: velocity.length > 14, facingRight: target.x > center.x))
            return
        }

        let desired = vector.normalized.scaled(by: min(preferredSpeed, distance * 5.0))
        velocity = velocity.scaled(by: 0.78).adding(desired.scaled(by: 0.22))
        let nextCenter = center.offset(by: velocity.scaled(by: dt))
        windowController.setAvatarCenter(nextCenter)
        publish(CompanionVisualMotion(isRunning: true, facingRight: velocity.dx > 0))
    }

    private func publish(_ visualMotion: CompanionVisualMotion) {
        guard visualMotion != lastVisualMotion else {
            return
        }
        lastVisualMotion = visualMotion
        onVisualMotionChange?(visualMotion)
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(other.x - x, other.y - y)
    }

    func offset(by vector: CGVector) -> CGPoint {
        CGPoint(x: x + vector.dx, y: y + vector.dy)
    }
}

private extension CGVector {
    static let zero = CGVector(dx: 0, dy: 0)

    init(from start: CGPoint, to end: CGPoint) {
        self.init(dx: end.x - start.x, dy: end.y - start.y)
    }

    var length: CGFloat {
        hypot(dx, dy)
    }

    var normalized: CGVector {
        let length = max(length, 0.001)
        return CGVector(dx: dx / length, dy: dy / length)
    }

    func scaled(by factor: CGFloat) -> CGVector {
        CGVector(dx: dx * factor, dy: dy * factor)
    }

    func scaled(by factor: TimeInterval) -> CGVector {
        scaled(by: CGFloat(factor))
    }

    func adding(_ other: CGVector) -> CGVector {
        CGVector(dx: dx + other.dx, dy: dy + other.dy)
    }
}

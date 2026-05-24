import SwiftUI

/// 启动开屏：用分层三明治素材依次落下，组成完整早餐。
struct SandwichSplashView: View {
    var onFinished: () -> Void

    @State private var plateVisible = false
    @State private var visibleLayers: Set<SandwichSplashLayer> = []
    @State private var squashedLayers: Set<SandwichSplashLayer> = []
    @State private var splashOpacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            let sceneWidth = min(geo.size.width * 0.9, 430) * 0.504
            let sceneHeight = sceneWidth

            ZStack {
                Color(hex: "F8F7F2")
                    .ignoresSafeArea()

                sandwichScene(width: sceneWidth, height: sceneHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(splashOpacity)
            .onAppear(perform: startAnimation)
        }
    }

    private func sandwichScene(width: CGFloat, height: CGFloat) -> some View {
        let plateWidth = width * 0.94
        let plateHeight = plateWidth * (510.0 / 928.0)
        let plateY = height * 0.72 - 45
        let dropDistance = width * 0.86
        let sandwichScale: CGFloat = 1.2
        let sandwichYOffset: CGFloat = 20
        let breadWidth = width * 0.53

        return ZStack {
            Image("splashPlate")
                .resizable()
                .scaledToFit()
                .frame(width: plateWidth, height: plateHeight)
                .position(x: width / 2, y: plateY)
                .offset(x: plateVisible ? 0 : -width)

            splashLayer(
                .breadBottom,
                asset: "splashBreadBottom",
                imageWidth: breadWidth * sandwichScale,
                centerX: width / 2,
                y: plateY - width * 0.15 * sandwichScale + sandwichYOffset,
                dropDistance: dropDistance
            )

            splashLayer(
                .cheese,
                asset: "splashCheese",
                imageWidth: width * 0.52 * sandwichScale,
                centerX: width / 2,
                y: plateY - width * 0.2 * sandwichScale + sandwichYOffset,
                dropDistance: dropDistance
            )

            splashLayer(
                .tomato,
                asset: "splashTomato",
                imageWidth: width * 0.49 * sandwichScale,
                centerX: width / 2,
                y: plateY - width * 0.23 * sandwichScale + sandwichYOffset,
                dropDistance: dropDistance
            )

            splashLayer(
                .lettuce,
                asset: "splashLettuce",
                imageWidth: width * 0.56 * sandwichScale,
                centerX: width / 2,
                y: plateY - width * 0.28 * sandwichScale + sandwichYOffset,
                dropDistance: dropDistance
            )

            splashLayer(
                .breadTop,
                asset: "splashBreadTop",
                imageWidth: breadWidth * sandwichScale,
                centerX: width / 2,
                y: plateY - width * 0.36 * sandwichScale + sandwichYOffset,
                dropDistance: dropDistance
            )
        }
        .frame(width: width, height: height)
    }

    private func splashLayer(
        _ layer: SandwichSplashLayer,
        asset: String,
        imageWidth: CGFloat,
        centerX: CGFloat,
        y: CGFloat,
        dropDistance: CGFloat
    ) -> some View {
        let visible = visibleLayers.contains(layer)
        let squashed = squashedLayers.contains(layer)
        let squashScale = layer.landingSquashScale

        return Image(asset)
            .resizable()
            .scaledToFit()
            .frame(width: imageWidth)
            .opacity(visible ? 1 : 0)
            .position(x: centerX, y: y)
            .offset(y: visible ? 0 : -dropDistance)
            .scaleEffect(
                x: squashed ? squashScale.width : 1,
                y: squashed ? squashScale.height : 1,
                anchor: .center
            )
    }

    private func startAnimation() {
        plateVisible = false
        visibleLayers.removeAll()
        squashedLayers.removeAll()
        splashOpacity = 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            withAnimation(.easeOut(duration: 0.08)) {
                plateVisible = true
            }
        }

        show(.breadBottom, after: 0.02)
        show(.cheese, after: 0.06)
        show(.tomato, after: 0.10)
        show(.lettuce, after: 0.14)
        show(.breadTop, after: 0.18)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            withAnimation(.easeOut(duration: 0.42)) {
                splashOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.22) {
            onFinished()
        }
    }

    private func show(_ layer: SandwichSplashLayer, after delay: Double) {
        let fallDuration = 0.10

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: fallDuration)) {
                _ = visibleLayers.insert(layer)
            }
        }

        guard layer.shouldSquashOnLanding else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + fallDuration) {
            withAnimation(.easeOut(duration: 0.03)) {
                _ = squashedLayers.insert(layer)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + fallDuration + 0.03) {
            withAnimation(.spring(response: 0.11, dampingFraction: 0.5, blendDuration: 0.01)) {
                _ = squashedLayers.remove(layer)
            }
        }
    }
}

private enum SandwichSplashLayer: Hashable {
    case breadBottom
    case cheese
    case tomato
    case lettuce
    case breadTop

    var shouldSquashOnLanding: Bool {
        switch self {
        case .breadBottom, .breadTop:
            return true
        case .cheese, .tomato, .lettuce:
            return true
        }
    }

    var landingSquashScale: CGSize {
        switch self {
        case .breadBottom, .breadTop:
            return CGSize(width: 1.04, height: 0.94)
        case .cheese, .tomato, .lettuce:
            return CGSize(width: 1.12, height: 0.82)
        }
    }
}

#Preview {
    SandwichSplashView {}
}

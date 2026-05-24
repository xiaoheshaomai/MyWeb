import SwiftUI

/// Claude 生成的原型 UI：独立页面，仅用于对照/预览效果，不影响现有业务流
struct ClaudePrototypeView: View {
    @State private var showReward = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            ClaudeTabContainerView(selectedTab: $selectedTab, showReward: $showReward)
            if showReward {
                ClaudeRewardOverlayView(isPresented: $showReward)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showReward)
        .navigationTitle("Claude 原型预览")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ClaudeTabContainerView: View {
    @Binding var selectedTab: Int
    @Binding var showReward: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if selectedTab == 0 {
                    ClaudeTodayView(showReward: $showReward)
                } else if selectedTab == 1 {
                    ClaudeCollectionPlaceholderView()
                } else {
                    ClaudeSettingsPlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ClaudeBottomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct ClaudeTodayView: View {
    @Binding var showReward: Bool
    @State private var sandwichOffset: CGFloat = 40
    @State private var sandwichOpacity: Double = 0
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleOffset: CGFloat = -16
    @State private var sunScale: CGFloat = 0.5
    @State private var sunRayRotation: Double = 0
    let aa: CGFloat = 85
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    
                    
                    Rectangle()
                            .fill(Color.white)
                            .frame(width: 268, height: 249)
                            .offset(x: -100, y: 30) // 可调位置
                    Rectangle()
                            .fill(Color(red: 0.88, green: 0.87, blue: 0.82))
                            .frame(width: 268, height: 30)
                            .offset(x: -100, y: 250)

                    // 顶部改为 ZStack：太阳固定左上；气泡叠在上层（居中）
                    ZStack(alignment: .topLeading) {
                        ZStack {
                            ForEach(0..<18) { i in
                                ClaudeTriangleRay()
                                    .fill(Color(red: 1.0, green: 0.87, blue: 0.22))
                                    .frame(width: 10, height: 20)
                                    .offset(y: -57)
                                    .rotationEffect(.degrees(Double(i) * 20.0 + sunRayRotation))
                            }
                            Circle()
                                .fill(Color(red: 1, green: 0, blue: 0))
                                .frame(width: aa, height: aa)
                        }
                        .frame(width: 100, height: 100)
                        .scaleEffect(sunScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.1)) {
                                sunScale = 1.0
                            }
                            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false).delay(0.6)) {
                                sunRayRotation = 360
                            }
                        }
                        .padding(.leading, 30)
                        .offset(y: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("今天起床用了 5 分钟")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                            Text("好棒，小和！")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 45)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .opacity(0.6)
                        )
                        .offset(y:40)
                        .opacity(bubbleOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35)) {
                                bubbleOffset = 0
                                bubbleOpacity = 1
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    }
                    .padding(.top, 36)
                }

                

                ZStack(alignment: .bottom) {
                  

                    Image("Rectangle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .offset(y: 80)
        

                    Image("sand1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .offset(y: sandwichOffset - 80)
                        .opacity(sandwichOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.5)) {
                                sandwichOffset = 0
                                sandwichOpacity = 1
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }
        }
        .onTapGesture {
            withAnimation { showReward = true }
        }
    }
}

private struct ClaudeTriangleRay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ClaudeRewardOverlayView: View {
    @Binding var isPresented: Bool
    @State private var cardScale: CGFloat = 0.7
    @State private var cardOpacity: Double = 0
    @State private var rayRotation: Double = 0

    var body: some View {
        ZStack {
            ClaudeSunrayBackground(rotation: rayRotation)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rayRotation = 360
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 6) {
                    Text("验证成功")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.20, blue: 0.10))
                    Text("你真棒，小和！！")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.bottom, 24)

                VStack(spacing: 16) {
                    Text("好精神三明治")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Image("sand1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    VStack(spacing: 4) {
                        Text("新鲜番茄+薄荷叶")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                        Text("谁吃谁有精神！")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(red: 0.85, green: 0.10, blue: 0.10), lineWidth: 5)
                )
                .padding(.horizontal, 28)
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                        cardScale = 1.0
                        cardOpacity = 1.0
                    }
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }) {
                    Text("收下啦")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(Capsule().fill(Color.black))
                }
                .padding(.top, 28)

                Spacer()
            }
        }
    }
}

private struct ClaudeSunrayBackground: View {
    var rotation: Double

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = max(geo.size.width, geo.size.height) * 0.9
            let rayCount = 18

            ZStack {
                Color(red: 1.0, green: 0.96, blue: 0.70)

                Canvas { context, _ in
                    for i in 0..<rayCount {
                        let angle = Double(i) * (360.0 / Double(rayCount)) + rotation
                        let half = 8.0

                        var path = Path()
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(angle - half),
                            endAngle: .degrees(angle + half),
                            clockwise: false
                        )
                        path.closeSubpath()

                        context.fill(path, with: .color(Color(red: 1.0, green: 0.88, blue: 0.30).opacity(0.60)))
                    }
                }
            }
        }
    }
}

private struct ClaudeBottomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            ClaudeTabBarButton(title: "今天", isSelected: selectedTab == 0) { selectedTab = 0 }
            Spacer()
            ClaudeTabBarButton(title: "收集", isSelected: selectedTab == 1) { selectedTab = 1 }
            Spacer()
            ClaudeTabBarButton(title: "设置", isSelected: selectedTab == 2) { selectedTab = 2 }
        }
        .padding(.horizontal, 36)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(Color.white)
    }
}

private struct ClaudeTabBarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isSelected {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black))
            } else {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(white: 0.45))
            }
        }
    }
}

private struct ClaudeCollectionPlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("🧺 收集页面")
                .font(.system(size: 20))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
}

private struct ClaudeSettingsPlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("⚙️ 设置页面")
                .font(.system(size: 20))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
}

#Preview {
    NavigationStack {
        ClaudePrototypeView()
    }
}


import SwiftUI

/// 夜间反馈页：当前先与 DayRecapView 完全一致，后续可独立调整夜间视觉
struct NightRecapView: View {
    var minutesUsed: Int
    /// 保留参数兼容旧调用方，但弹窗现在走 fullScreenCover 原生盖满整屏，
    /// 不再需要通知父层去手动隐藏底部 tab bar
    @Binding var wishSheetCoversTabBar: Bool
    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""

    // MARK: - 原型参数（写死常数，和你发的代码一致）

    @State private var sandwichOffset: CGFloat = 40
    @State private var sandwichOpacity: Double = 0
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleOffset: CGFloat = -16
    @State private var sunScale: CGFloat = 0.5
    @State private var sunRayRotation: Double = 0
    @State private var showTomorrowSheet = false
    @State private var tomorrowWishLine1 = ""
    @State private var tomorrowWishLine2 = ""
    @State private var paperSparkleBurst = false
    @State private var showCalendarPopup = false

    private let aa: CGFloat = 85
    private let b: CGFloat = 270
    /// 与背景深蓝块一致，#414778
    private let tomorrowWishInk = Color(red: 0.25, green: 0.28, blue: 0.47)
    private var tomorrowWishFont: Font { .system(size: 18, weight: .semibold) }
    /// 相对纸图中心微调，可再对齐设计稿
    private let deskWishTextOffsetX: CGFloat = 30
    private let deskWishTextOffsetY: CGFloat = -10
    /// 只让**上面**那条蓝色假字左右微调；下面那条不要动就保持 `0`
    private let deskWishTopLineExtraX: CGFloat = 20

    private var deskWishHasContent: Bool {
        let t1 = tomorrowWishLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        let t2 = tomorrowWishLine2.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t1.isEmpty || !t2.isEmpty
    }

    private var displayName: String {
        let n = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return L10n.s("onboarding_name_placeholder", lang: appLanguage) }
        return n
    }

    var body: some View {
        ZStack {
            (Color(red: 0.72, green: 0.72, blue: 0.78))
                // 不铺满底部安全区，避免盖住底部导航栏
                .ignoresSafeArea(edges: [.top, .leading, .trailing])

            VStack(spacing: 0) {
                // 上半部分：左窗+月亮与 DayRecapView 同结构；右日历同一位置
                HStack(alignment: .top, spacing: 20) {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(red: 0.25, green: 0.28, blue: 0.47))
                            .frame(width: 268, height: 249)
                            .offset(x: -100, y: 30)

                        Rectangle()
                            .fill(Color(red: 0.88, green: 0.87, blue: 0.82))
                            .frame(width: 268, height: 30)
                            .offset(x: -100, y: 250)

                        ZStack(alignment: .topLeading) {
                            ZStack {
                                ForEach(0..<18, id: \.self) { i in
                                    TriangleRay()
                                        .fill(Color(red: 1.0, green: 0.87, blue: 0.22))
                                        .frame(width: 10, height: 20)
                                        .offset(y: 0)
                                        .rotationEffect(.degrees(Double(i) * 20.0 + sunRayRotation))
                                }
                                Circle()
                                    .fill(Color(red: 0.95, green: 0.92, blue: 0.07))
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

                            // 这段文字暂时用 false 隐藏，与 DayRecapView 一致；要显示改成 true
                            if false {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("小和！")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("明天有什么期待的事情？😊")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 45)
                                .padding(.vertical, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color.black)
                                        .opacity(0.85)
                                )
                                .offset(y: 40)
                                .opacity(showTomorrowSheet ? 0 : bubbleOpacity)
                                .allowsHitTesting(!showTomorrowSheet)
                                .onAppear {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35)) {
                                        bubbleOffset = 0
                                        bubbleOpacity = 1
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                            }
                        }
                        .padding(.top, 36)
                    }
                    .offset(x: 25, y: 0)

                    Button {
                        showCalendarPopup = true
                    } label: {
                        Image("Group28")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .padding(.top, 36)
                            .offset(x: -38, y: 43)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("日历")

                    Spacer(minLength: 0)
                }
                .padding(.trailing, 16)

                ZStack(alignment: .bottom) {
                    Image("Rectangle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        
                        .offset(y: 80)

                    if !showTomorrowSheet {
                        Button {
                            paperSparkleBurst = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showTomorrowSheet = true
                            }
                        } label: {
                            ZStack {
                                Image("word")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: b, height: b)
                                    .opacity(deskWishHasContent ? 0.92 : 1)

                                if deskWishHasContent {
                                    VStack(alignment: .leading, spacing: 14) {
                                        fakeWriting(width: b * 0.5)
                                            .offset(x: deskWishTopLineExtraX, y: -8)
                                        fakeWriting(width: b * 0.45)
                                            .offset(y: 4)
                                    }
                                    .offset(x: deskWishTextOffsetX, y: deskWishTextOffsetY)
                                    .allowsHitTesting(false)
                                }

                                if paperSparkleBurst && deskWishHasContent {
                                    DeskPaperSparkleLayer()
                                        .frame(width: b, height: b)
                                        .allowsHitTesting(false)
                                }
                            }
                            .offset(y: sandwichOffset - 80)
                            .offset(x: sandwichOffset + 40)
                            .opacity(sandwichOpacity)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.5)) {
                                sandwichOffset = 0
                                sandwichOpacity = 1
                            }
                        }
                    }
                    Image("pencil")
                        
                        .offset(y: sandwichOffset - 140)
                        .offset(x: sandwichOffset-120)
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
        .transparentFullScreenCover(isPresented: $showTomorrowSheet) {
            tomorrowSheetPlaceholder
                .transition(.opacity)
        }
        .overlay {
            if showCalendarPopup {
                RecapCalendarPopupLayer(isPresented: $showCalendarPopup)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCalendarPopup)
    }

    /// 占位弹窗：底层白纸 + 上层 VStack（文字与横线），样式你可再细调
    private var tomorrowSheetPlaceholder: some View {
        let paperW: CGFloat = 300
        let paperH: CGFloat = 400

        return ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    closeTomorrowSheet()
                }

            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: paperW, height: paperH)
                    .opacity(0.9)

                VStack(alignment: .center, spacing: 18) {
                    Text("明天我想🤔")
                        .lineLimit(1)
                        .font(tomorrowWishFont)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)

                    VStack(spacing: 20) {
                        tomorrowWishLineField(text: $tomorrowWishLine1)
                        tomorrowWishLineField(text: $tomorrowWishLine2)
                    }
                    .frame(maxWidth: 200)
                }
                .padding(.vertical, 100)
                .frame(width: paperW, height: paperH, alignment: .top)

                VStack {
                    Spacer(minLength: 0)
                    Button {
                        closeTomorrowSheet()
                    } label: {
                        Text("就这样")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(70)
                }
                .frame(width: paperW, height: paperH)
            }
        }
    }

    private func closeTomorrowSheet() {
        let hadContent = deskWishHasContent
        withAnimation(.easeInOut(duration: 0.2)) {
            showTomorrowSheet = false
        }
        if hadContent {
            paperSparkleBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation(.easeOut(duration: 0.35)) {
                    paperSparkleBurst = false
                }
            }
        }
    }

    private func tomorrowWishLineField(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("", text: text, axis: .vertical)
                .font(tomorrowWishFont)
                .foregroundStyle(tomorrowWishInk)
                .tint(tomorrowWishInk)
                .lineLimit(1...2)
                .fixedSize(horizontal: false, vertical: true)
                .submitLabel(.done)
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
    }

    /// 桌上纸张：简单折线「假字」；颜色 #414778，线宽与弹窗红横线一致（2）
    private func fakeWriting(width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 8))
            path.addLine(to: CGPoint(x: 8, y: 6))
            path.addLine(to: CGPoint(x: 16, y: 9))
            path.addLine(to: CGPoint(x: 24, y: 7))
            path.addLine(to: CGPoint(x: 32, y: 8))
            path.addLine(to: CGPoint(x: 40, y: 6))
            path.addLine(to: CGPoint(x: 48, y: 9))
            path.addLine(to: CGPoint(x: 56, y: 7))
            path.addLine(to: CGPoint(x: 64, y: 8))
        }
        .stroke(tomorrowWishInk, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: width, height: 14)
    }
}

/// 桌上纸张亮晶晶：关闭弹窗后短时闪烁，位置按纸面比例
private struct DeskPaperSparkleLayer: View {
    private let fx: [CGFloat] = [0.20, 0.33, 0.48, 0.62, 0.77, 0.25, 0.41, 0.58, 0.72, 0.86, 0.18, 0.36, 0.67, 0.82]
    private let fy: [CGFloat] = [0.34, 0.26, 0.32, 0.24, 0.36, 0.52, 0.46, 0.54, 0.48, 0.58, 0.70, 0.66, 0.72, 0.68]
    private let phase: [Double] = [0.0, 0.4, 0.9, 1.3, 1.7, 0.2, 0.8, 1.5, 2.0, 2.4, 0.6, 1.1, 1.9, 2.7]
    private let size: [CGFloat] = [22, 15, 19, 13, 21, 16, 24, 14, 18, 15, 20, 13, 23, 16]
    private let rotation: [Double] = [-14, 10, -4, 18, -20, 7, -9, 22, -16, 5, 15, -12, 8, -18]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    ForEach(fx.indices, id: \.self) { i in
                        let wave = 0.5 + 0.5 * sin(t * 7.0 + phase[i] * 3.2)
                        let blink = pow(wave, 2.4)
                        Image("star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size[i], height: size[i])
                            .rotationEffect(.degrees(rotation[i]))
                            .scaleEffect(0.74 + 0.36 * blink)
                            .offset(x: w * fx[i] - w * 0.5, y: h * fy[i] - h * 0.5)
                            .opacity(0.05 + 0.95 * blink)
                    }
                }
                .frame(width: w, height: h)
            }
        }
    }
}

private struct TriangleRay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Transparent fullScreenCover

/// fullScreenCover 默认底色是白色，会盖住我们自己画的半透明黑 dim。
/// 这个小工具把 presenting 后的那个 UIViewController 的背景 clear 掉，
/// 这样我们的弹窗内容（半透明黑 + 白纸卡片）就能在整个屏幕上浮出来，
/// 包括原本被 tab bar 占用的底部区域。
private extension View {
    func transparentFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            ZStack { content() }
                .background(TransparentCoverBackground())
        }
    }
}

private struct TransparentCoverBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        DispatchQueue.main.async {
            v.superview?.superview?.backgroundColor = .clear
        }
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    NightRecapView(minutesUsed: 5, wishSheetCoversTabBar: .constant(false))
}

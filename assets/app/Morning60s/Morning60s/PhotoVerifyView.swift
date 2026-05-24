import SwiftUI
import AVFoundation

/// 拍照验证页：千问/后端识图，判断是否为「人站在地上」
struct PhotoVerifyView: View {
    var onVerified: (_ capturePressedAt: Date?) -> Void
    var onBack: (() -> Void)? = nil
    var presentation: ChallengePresentation = .morning
    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""
    @State private var image: UIImage?
    @StateObject private var camera = EmbeddedCameraController()
    @State private var isVerifying = false
    @State private var poseErrorMessage: String?
    /// 用户点「我已起床，识别错误」后，用更高清图 + 更强模型再验一次
    @State private var retryWithHighQuality = false
    /// 验证进度（0 ~ 1）。因为真实耗时不可知，这里是基于经验的渐进式估计。
    @State private var verifyProgress: Double = 0
    @State private var verifyProgressTimer: Timer?
    @State private var verifyTipIndex: Int = 0
    /// 快门太阳呼吸缩放：轻微 1.0 ↔ 0.95，给可点击反馈
    @State private var shutterBreathing = false
    /// 快门太阳光芒旋转，让拍照按钮更有生命力。
    @State private var shutterRaysRotating = false
    /// 最近一次按下「拍照」按钮的时间；验证通过时用于计算“从打开 app 到按下拍照按钮”的用时
    @State private var lastCapturePressedAt: Date?
    /// 拍完照后，确认页里的照片从拍照框尺寸缩回预览框尺寸。
    @State private var capturedPhotoSettled = false
    /// 「就这样吗？」页提交按钮进场弹入。
    @State private var submitButtonPresented = false
    /// 提交按钮弹入后轻微呼吸。
    @State private var submitButtonBreathing = false
    /// 拍摄示例弹窗。
    @State private var showExampleCard = false
    @State private var exampleCardPresented = false
    /// 拍照页相机框底部到返回箭头顶部的距离；之前是 54，这次按需求再下移 30。
    private let photoArrowTopGapFromCamera: CGFloat = 84
    /// 拍照页主体内容整体上移量：标题 / 示例 / 相机框 / 快门 / 隐私提示都上移，返回箭头不动。
    private let photoCaptureContentLift: CGFloat = 30

    private var accentFill: Color {
        presentation == .nap ? AppTheme.sunYellow : AppTheme.accentOrange
    }

    private var accentTextOnFill: Color {
        presentation == .nap ? AppTheme.primaryDark : .white
    }

    private var accentForeground: Color {
        presentation == .nap ? AppTheme.primaryDark : AppTheme.accentOrange
    }

    var body: some View {
        GeometryReader { geo in
            let cameraFrameWidth = photoCameraFrameWidth(in: geo)
            let cameraFrameHeight = cameraFrameWidth * 1.30

            ZStack {
                AppTheme.background.ignoresSafeArea()

                if image == nil {
                    cameraCaptureContent(
                        in: geo,
                        cameraFrameWidth: cameraFrameWidth,
                        cameraFrameHeight: cameraFrameHeight
                    )
                } else if isVerifying {
                    verifyingContent(in: geo)
                } else {
                    photoSubmitContent(in: geo)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if image == nil { camera.startRunning() }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    shutterBreathing = true
                }
                withAnimation(.linear(duration: 10.5).repeatForever(autoreverses: false)) {
                    shutterRaysRotating = true
                }
            }
            .onChange(of: image) { _, newImage in
                if newImage == nil {
                    capturedPhotoSettled = false
                    submitButtonPresented = false
                    submitButtonBreathing = false
                    camera.startRunning()
                } else {
                    camera.stopRunning()
                    capturedPhotoSettled = false
                    submitButtonPresented = false
                    submitButtonBreathing = false
                    dismissExampleCard(immediate: true)
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.56, dampingFraction: 0.82)) {
                            capturedPhotoSettled = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        guard image != nil else { return }
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.66)) {
                            submitButtonPresented = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
                        guard image != nil else { return }
                        withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                            submitButtonBreathing = true
                        }
                    }
                }
            }
            .onDisappear {
                camera.stopRunning()
            }
            .overlay {
                if showExampleCard {
                    photoExampleOverlay(in: geo)
                }
            }
        }
    }

    private func presentExampleCard() {
        exampleCardPresented = false
        showExampleCard = true
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) {
                exampleCardPresented = true
            }
        }
    }

    private func dismissExampleCard(immediate: Bool = false) {
        if immediate {
            exampleCardPresented = false
            showExampleCard = false
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            exampleCardPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showExampleCard = false
        }
    }

    private func photoExampleOverlay(in geo: GeometryProxy) -> some View {
        ZStack {
            Color.black.opacity(exampleCardPresented ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissExampleCard() }
                .animation(.easeOut(duration: 0.18), value: exampleCardPresented)

            PhotoExampleCard(
                appLanguage: appLanguage,
                closeColor: accentForeground,
                onDismiss: { dismissExampleCard() }
            )
            .frame(width: min(geo.size.width - 92, 320))
            .scaleEffect(exampleCardPresented ? 1 : 0.68)
            .offset(y: exampleCardPresented ? -10 : 18)
            .opacity(exampleCardPresented ? 1 : 0)
            .animation(.spring(response: 0.46, dampingFraction: 0.72), value: exampleCardPresented)
        }
    }

    private func cameraCaptureContent(
        in geo: GeometryProxy,
        cameraFrameWidth: CGFloat,
        cameraFrameHeight: CGFloat
    ) -> some View {
        let cameraTopY = photoCameraTopY(in: geo, cameraFrameHeight: cameraFrameHeight)
        let liftedCameraTopY = cameraTopY - photoCaptureContentLift
        let liftedCameraBottomY = liftedCameraTopY + cameraFrameHeight
        let arrowCenterY = photoArrowCenterY(cameraTopY: cameraTopY, cameraFrameHeight: cameraFrameHeight)
        let titleTopY = max(46, min(cameraTopY - 110, geo.safeAreaInsets.top + 74) - photoCaptureContentLift)

        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: titleTopY)

                Text(L10n.s("photo_instruction_strong", lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 22, weight: .semibold, language: appLanguage))
                    .foregroundStyle(AppTheme.primaryDark)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)

                Button {
                    presentExampleCard()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "questionmark.circle")
                            .font(AppTheme.localizedFont(size: 14, weight: .bold, language: appLanguage))
                        Text(L10n.s("photo_example", lang: appLanguage))
                            .font(AppTheme.localizedFont(size: 14, weight: .semibold, language: appLanguage))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(accentForeground)
                .padding(.top, 15)

                poseErrorBlock

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(Color(hex: "C7C7C9"))
                .frame(width: cameraFrameWidth, height: cameraFrameHeight)
                .overlay {
                    if camera.isReady {
                        EmbeddedCameraPreview(session: camera.session)
                            .clipShape(Rectangle())
                    } else {
                        Text(camera.permissionDenied ? "请在设置中开启相机权限" : "正在准备相机...")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                .clipped()
                .position(x: geo.size.width / 2, y: liftedCameraTopY + cameraFrameHeight / 2)

            Button {
                poseErrorMessage = nil
                lastCapturePressedAt = Date()
                camera.capturePhoto { captured in
                    image = captured
                }
            } label: {
                CameraShutterSunButton(
                    size: 138,
                    title: L10n.s("take_photo", lang: appLanguage),
                    fillColor: accentFill,
                    textColor: accentTextOnFill,
                    sunScale: shutterBreathing ? 0.95 : 1.0,
                    rayRotation: shutterRaysRotating ? 360 : 0
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!camera.isReady)
            .opacity(camera.isReady ? 1 : 0.65)
            .position(x: geo.size.width / 2, y: liftedCameraBottomY - 11)

            Text(L10n.s("photo_privacy_note", lang: appLanguage))
                .font(AppTheme.localizedFont(size: 11, weight: .regular, language: appLanguage))
                .foregroundStyle(Color(hex: "878979"))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .position(x: geo.size.width / 2, y: liftedCameraBottomY + 68)

            if let onBack, !isVerifying {
                PhotoArrowCircleButton(action: onBack)
                    .position(x: geo.size.width / 2, y: arrowCenterY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func verifyingContent(in geo: GeometryProxy) -> some View {
        PhotoVerifyWaitingContent(
            progress: verifyProgress,
            nickname: userNickname,
            lang: appLanguage,
            accentColor: accentFill,
            tipIndex: verifyTipIndex
        )
    }

    private func photoSubmitContent(in geo: GeometryProxy) -> some View {
        let previewWidth = min(geo.size.width * 0.46, 180)
        let previewHeight = previewWidth * 1.30
        let submitSize = min(138, max(118, geo.size.width * 0.35))
        let cameraFrameWidth = photoCameraFrameWidth(in: geo)
        let cameraFrameHeight = cameraFrameWidth * 1.30
        let cameraTopY = photoCameraTopY(in: geo, cameraFrameHeight: cameraFrameHeight)
        let arrowCenterY = photoArrowCenterY(cameraTopY: cameraTopY, cameraFrameHeight: cameraFrameHeight)
        let capturedStartScale = min(2.05, max(1.0, cameraFrameWidth / previewWidth))
        let questionCenterY = max(106, geo.size.height * 0.15)
        let previewTopY = max(questionCenterY + 60, geo.size.height * 0.22)
        let baseSubmitCenterY = min(previewTopY + previewHeight + 92, arrowCenterY - submitSize / 2 - 34)
        let submitCenterY = min(baseSubmitCenterY + 30, arrowCenterY - submitSize / 2 - 4)

        return ZStack(alignment: .top) {
            Text(L10n.s("photo_submit_question", lang: appLanguage))
                .font(AppTheme.localizedFont(size: 18, weight: .semibold, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .position(x: geo.size.width / 2, y: questionCenterY)

            poseErrorBlock
                .position(x: geo.size.width / 2, y: questionCenterY + 48)

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: previewWidth, height: previewHeight)
                    .clipped()
                    .background(Color(hex: "D4D4D4"))
                    .scaleEffect(capturedPhotoSettled ? 1 : capturedStartScale)
                    .offset(y: capturedPhotoSettled ? 0 : -18)
                    .opacity(capturedPhotoSettled ? 1 : 0.92)
                    .animation(.spring(response: 0.56, dampingFraction: 0.82), value: capturedPhotoSettled)
                    .position(x: geo.size.width / 2, y: previewTopY + previewHeight / 2)
            }

            Button {
                submitAndVerify()
            } label: {
                Circle()
                    .fill(accentFill)
                    .frame(width: submitSize, height: submitSize)
                    .overlay {
                        Text(L10n.s("submit_photo", lang: appLanguage))
                            .font(AppTheme.localizedFont(size: 18, weight: .semibold, language: appLanguage))
                            .foregroundStyle(accentTextOnFill)
                    }
            }
            .buttonStyle(ScaleButtonStyle())
            .scaleEffect(submitButtonPresented ? (submitButtonBreathing ? 1.025 : 1) : 0.62)
            .opacity(submitButtonPresented ? 1 : 0)
            .position(x: geo.size.width / 2, y: submitCenterY)

            PhotoArrowCircleButton(action: retakePhoto)
                .accessibilityLabel(L10n.s("retake_photo", lang: appLanguage))
                .position(x: geo.size.width / 2, y: arrowCenterY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func photoCameraFrameWidth(in geo: GeometryProxy) -> CGFloat {
        let preferredWidth = min(geo.size.width - 82, 308)
        let maxWidthByHeight = (geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom - 300) / 1.30
        return min(preferredWidth, max(220, maxWidthByHeight))
    }

    private func photoCameraTopY(in geo: GeometryProxy, cameraFrameHeight: CGFloat) -> CGFloat {
        let desiredTop = max(204, geo.size.height * 0.27)
        let maxTopForArrow = geo.size.height - geo.safeAreaInsets.bottom - 140 - cameraFrameHeight
        return min(desiredTop, max(150, maxTopForArrow))
    }

    private func photoArrowCenterY(cameraTopY: CGFloat, cameraFrameHeight: CGFloat) -> CGFloat {
        cameraTopY + cameraFrameHeight + photoArrowTopGapFromCamera + 28
    }

    @ViewBuilder
    private var poseErrorBlock: some View {
        if let msg = poseErrorMessage {
            VStack(spacing: 8) {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                if !msg.contains("API") && !msg.contains("Key") {
                    Text(L10n.s("i_am_up_recognition_error", lang: appLanguage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(L10n.s("retry_with_better_image", lang: appLanguage)) {
                        poseErrorMessage = nil
                        retryWithHighQuality = true
                        submitAndVerify()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(accentForeground)
                }
            }
            .padding(.top, 14)
        }
    }

    private func retakePhoto() {
        poseErrorMessage = nil
        retryWithHighQuality = false
        capturedPhotoSettled = false
        submitButtonPresented = false
        submitButtonBreathing = false
        image = nil
        camera.startRunning()
    }

    private func submitAndVerify() {
        guard let img = image else { return }
        let backend = BackendVerifyService.backendURL

        if let url = backend {
            poseErrorMessage = nil
            startVerifyProgress()
            BackendVerifyService.verify(image: img, urlString: url) { passed in
                finishVerifyProgress()
                if passed {
                    onVerified(lastCapturePressedAt)
                } else {
                    poseErrorMessage = L10n.s("pose_no_legs_or_floor", lang: appLanguage)
                }
            }
            return
        }

        guard let qwenKey = QwenVerificationService.apiKey else {
            poseErrorMessage = L10n.s("verify_not_configured", lang: appLanguage)
            return
        }

        poseErrorMessage = nil
        startVerifyProgress()
        QwenVerificationService.verify(image: img, apiKey: qwenKey, useHighQuality: retryWithHighQuality) { passed, apiError in
            retryWithHighQuality = false
            finishVerifyProgress()
            if passed {
                onVerified(lastCapturePressedAt)
            } else if let err = apiError, !err.isEmpty {
                poseErrorMessage = L10n.s("verify_service_error", lang: appLanguage) + "（\(err)）"
            } else {
                poseErrorMessage = L10n.s("pose_no_legs_or_floor", lang: appLanguage)
            }
        }
    }

    /// 启动一个「预估式」进度条：前 15 秒大约走到 0.9，之后缓慢逼近 0.97，等真实回调到来再跳到 1.0。
    /// 这样即使服务有时更快 / 更慢，视觉上也不会卡住或突然结束。
    private func startVerifyProgress() {
        verifyProgressTimer?.invalidate()
        verifyProgress = 0
        verifyTipIndex = VerifyWaitingTip.randomIndex(for: appLanguage)
        isVerifying = true
        let tick: TimeInterval = 0.1
        let timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { t in
            let p = self.verifyProgress
            let target: Double = 0.97
            let speed: Double
            if p < 0.6 {
                speed = 0.06
            } else if p < 0.9 {
                speed = 0.03
            } else {
                speed = 0.008
            }
            let next = min(target, p + speed * tick)
            withAnimation(.linear(duration: tick)) {
                self.verifyProgress = next
            }
            if next >= target { t.invalidate() }
        }
        verifyProgressTimer = timer
    }

    private func finishVerifyProgress() {
        verifyProgressTimer?.invalidate()
        verifyProgressTimer = nil
        withAnimation(.easeOut(duration: 0.25)) {
            verifyProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isVerifying = false
            verifyProgress = 0
        }
    }
}

/// 拍摄示例卡片：黄框 + 白色内容区，展示双脚站在地上的参考画面。
private struct PhotoExampleCard: View {
    let appLanguage: String
    let closeColor: Color
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Text(L10n.s("photo_example_modal_title", lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 22, weight: .bold, language: appLanguage))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)

                VStack(spacing: 20) {
                    Text(L10n.s("photo_example_modal_body", lang: appLanguage))
                        .font(AppTheme.localizedFont(size: 17, weight: .semibold, language: appLanguage))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Image("example")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 164, height: 218)
                        .clipped()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(hex: "F9F8F4"))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .background(AppTheme.sunYellow)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(AppTheme.localizedFont(size: 18, weight: .heavy, language: appLanguage))
                    .foregroundStyle(closeColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.s("done", lang: appLanguage))
        }
    }
}

/// 拍照流程里统一使用的白色圆形小箭头：返回、重拍都保持同位置语言。
private struct PhotoArrowCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryDark)
            }
        }
        .buttonStyle(.plain)
    }
}

/// 验证等待页：黄色卡片的中心严格固定在可用屏幕的纵向中心。
private struct PhotoVerifyWaitingContent: View {
    let progress: Double
    let nickname: String
    let lang: String
    let accentColor: Color
    let tipIndex: Int

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width * 0.68, 312)
            let cardHeight = cardWidth / 0.78

            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 180)

                    Text(L10n.s("photo_verifying_title", lang: lang))
                        .font(AppTheme.localizedFont(size: 24, weight: .semibold, language: lang))
                        .foregroundStyle(.black)

                    VStack(spacing: 40) {
                        VerifyingTipCard(
                            nickname: nickname,
                            lang: lang,
                            tipIndex: tipIndex
                        )
                        .frame(width: cardWidth, height: cardHeight)

                        VerifyingProgressBar(progress: progress, accentColor: accentColor)
                            .frame(width: cardWidth, height: 25)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// 验证等待卡片：黄框提示卡，贴近手绘稿的极简白底版。
private struct VerifyingTipCard: View {
    let nickname: String
    let lang: String
    let tipIndex: Int

    var body: some View {
        let tip = VerifyWaitingTip.tip(index: tipIndex, lang: lang)

        GeometryReader { geo in
            let border: CGFloat = 10
            let cupWidth = geo.size.width * 0.32
            let verticalInset = geo.size.height * 0.12

            ZStack {
                AppTheme.sunYellow

                VStack(spacing: 0) {
                    Text(tip.message(for: displayName))
                        .font(AppTheme.localizedFont(size: 20, weight: .semibold, language: lang))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .lineLimit(3)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 18)

                    Spacer(minLength: 18)

                    VerifyingWaterCup()
                        .frame(width: cupWidth, height: cupWidth * 1.34)

                    Spacer(minLength: 18)

                    VStack(spacing: 4) {
                        Text(tip.fact1)
                        Text(tip.fact2)
                    }
                    .font(AppTheme.localizedFont(size: 14, weight: .regular, language: lang))
                    .foregroundStyle(Color(hex: "878979"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.86)
                    .padding(.horizontal, 18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, verticalInset)
                .background(Color.white)
                .padding(border)
            }
        }
    }

    private var displayName: String {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? L10n.s("onboarding_name_placeholder", lang: lang) : name
    }
}

private struct VerifyingProgressBar: View {
    let progress: Double
    let accentColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "D9D9D9"))
                Rectangle()
                    .fill(accentColor)
                    .frame(width: max(8, geo.size.width * CGFloat(min(max(progress, 0), 1))))
            }
        }
    }
}

private struct VerifyingWaterCup: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let waterTop = h * 0.42

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.76, y: h))
                    path.addLine(to: CGPoint(x: w * 0.24, y: h))
                    path.closeSubpath()
                }
                .fill(Color(hex: "D7D7D7"))

                Path { path in
                    path.move(to: CGPoint(x: w * 0.14, y: waterTop))
                    path.addLine(to: CGPoint(x: w * 0.86, y: waterTop))
                    path.addLine(to: CGPoint(x: w * 0.76, y: h))
                    path.addLine(to: CGPoint(x: w * 0.24, y: h))
                    path.closeSubpath()
                }
                .fill(Color(hex: "B8DDEA"))
            }
        }
    }
}

struct PhotoVerifyWaitingPreviewView: View {
    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""
    @State private var progress: Double = 0.28

    var body: some View {
        PhotoVerifyWaitingContent(
            progress: progress,
            nickname: previewName,
            lang: appLanguage,
            accentColor: AppTheme.accentOrange,
            tipIndex: 0
        )
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: true)) {
                progress = 0.86
            }
        }
    }

    private var previewName: String {
        let name = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "小和" : name
    }
}

private struct VerifyWaitingTip {
    let messageFormat: String
    let fact1: String
    let fact2: String

    func message(for name: String) -> String {
        let formatted = String(format: messageFormat, name)
        for separator in ["！", "!", ","] {
            let prefix = "\(name)\(separator)"
            if formatted.hasPrefix(prefix) {
                return prefix + "\n" + String(formatted.dropFirst(prefix.count))
            }
        }
        return formatted
    }

    static func randomIndex(for lang: String) -> Int {
        guard lang == "zh" else { return 0 }
        return Int.random(in: 0..<zhTips.count)
    }

    static func tip(index: Int, lang: String) -> VerifyWaitingTip {
        guard lang == "zh" else {
            return VerifyWaitingTip(
                messageFormat: L10n.s("verify_water_tip_fmt", lang: lang),
                fact1: L10n.s("verify_water_fact_1", lang: lang),
                fact2: L10n.s("verify_water_fact_2", lang: lang)
            )
        }

        return zhTips[index.clamped(to: 0...(zhTips.count - 1))]
    }

    private static let zhTips: [VerifyWaitingTip] = [
        VerifyWaitingTip(
            messageFormat: "%@！去喝一杯水吧！",
            fact1: "早晨轻度脱水常见",
            fact2: "补水有助于提升认知表现哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！把窗帘拉开吧！",
            fact1: "晨光能帮助身体停止分泌褪黑素",
            fact2: "让大脑更快进入清醒状态哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！站起来走两步吧！",
            fact1: "身体活动能快速提高心率和血液循环",
            fact2: "帮助大脑脱离“赖床模式”哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！伸个懒腰吧！",
            fact1: "拉伸可以激活肌肉与神经系统",
            fact2: "减少刚睡醒时的迟钝感哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！去洗把脸吧！",
            fact1: "冷水刺激能提高身体警觉度",
            fact2: "帮助你更快清醒哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！打开窗户呼吸一下吧！",
            fact1: "新鲜空气和氧气输入",
            fact2: "有助于提升清晨专注力哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！别急着刷手机哦！",
            fact1: "刚醒来时大脑最容易被信息占据",
            fact2: "延迟刷手机能减少注意力消耗哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！试着整理一下床铺吧！",
            fact1: "完成一个微小行动会带来“启动感”",
            fact2: "更容易进入接下来的一天哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！放一首喜欢的歌吧！",
            fact1: "熟悉的音乐能刺激多巴胺分泌",
            fact2: "让起床变得更轻松一点哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！去阳台看看天空吧！",
            fact1: "自然光和远距离视野",
            fact2: "能帮助大脑逐渐恢复清醒节奏哦！"
        ),
        VerifyWaitingTip(
            messageFormat: "%@！深呼吸三次吧！",
            fact1: "缓慢深呼吸能提高氧气交换效率",
            fact2: "帮助身体从睡眠状态切换出来哦！"
        )
    ]
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/// 自定义相机快门按钮：沿用「太阳 + 红圆」语言，保证与挑战页视觉统一
private struct CameraShutterSunButton: View {
    let size: CGFloat
    let title: String
    let fillColor: Color
    let textColor: Color
    let sunScale: CGFloat
    let rayRotation: Double

    var body: some View {
        ZStack {
            // 白色圆垫：略大于光芒外圈，做“托底”
            Circle()
                .fill(Color(hex: "F9F8F4"))
                .frame(width: size * 1.22, height: size * 1.22)
            ZStack {
                SunFullRingView(size: size, showTrack: false, yellowBreathe: false)
                    .rotationEffect(.degrees(rayRotation))
                Circle()
                    .fill(fillColor)
                    .frame(width: size * 0.62, height: size * 0.62)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .scaleEffect(sunScale)
        }
        .frame(width: size, height: size)
    }
}

/// 把 AVCaptureSession 画面嵌进 SwiftUI
private struct EmbeddedCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        v.videoPreviewLayer.session = session
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

/// 相机控制器：管理权限、session、拍照输出
@MainActor
private final class EmbeddedCameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "morning60s.camera.session")

    @Published var isReady = false
    @Published var permissionDenied = false

    private var configured = false
    private var captureHandler: ((UIImage) -> Void)?

    func startRunning() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureAndStartIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.permissionDenied = !granted
                    if granted { self.configureAndStartIfNeeded() }
                }
            }
        default:
            permissionDenied = true
            isReady = false
        }
    }

    func stopRunning() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto(_ completion: @escaping (UIImage) -> Void) {
        guard isReady else { return }
        captureHandler = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func configureAndStartIfNeeded() {
        if !configured {
            queue.async { [weak self] in
                guard let self else { return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                guard
                    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                    let input = try? AVCaptureDeviceInput(device: device),
                    self.session.canAddInput(input)
                else {
                    Task { @MainActor in
                        self.isReady = false
                    }
                    self.session.commitConfiguration()
                    return
                }
                self.session.addInput(input)

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                }

                self.session.commitConfiguration()
                self.configured = true

                if !self.session.isRunning {
                    self.session.startRunning()
                }
                Task { @MainActor in
                    self.permissionDenied = false
                    self.isReady = true
                }
            }
            return
        }

        queue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            Task { @MainActor in
                self.isReady = true
                self.permissionDenied = false
            }
        }
    }
}

extension EmbeddedCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation(), let uiImage = UIImage(data: data) else {
            return
        }
        Task { @MainActor in
            captureHandler?(uiImage)
        }
    }
}

#Preview("拍照验证页") {
    PhotoVerifyView(onVerified: { _ in })
}

#Preview("验证等待页") {
    NavigationStack {
        PhotoVerifyWaitingPreviewView()
    }
}

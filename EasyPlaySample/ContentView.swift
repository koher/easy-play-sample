import SwiftUI
import EasyPlay
import VideoToolbox

struct ContentView: View {
    @State var videoSource: VideoSource?
    
    var body: some View {
        VStack(spacing: 24) {
            Button("Back Camera") {
                videoSource = .backCamera
            }
            Button("Front Camera") {
                videoSource = .frontCamera
            }
            Button("Video") {
                videoSource = .video
            }
        }
        .fullScreenCover(item: $videoSource) { videoSource in
            switch videoSource {
            case .backCamera:
                PlayerView(isPresented: $videoSource.exists, videoSource: Camera(position: .back, focusMode: .continuousAutoFocus, sessionPreset: .hd1280x720, videoSettings: [:]))
            case .frontCamera:
                PlayerView(isPresented: $videoSource.exists, videoSource: Camera(position: .front, focusMode: .none, sessionPreset: .vga640x480, videoSettings: [:]))
            case .video:
                PlayerView(isPresented: $videoSource.exists, videoSource: Video(path: Bundle.main.path(forResource: "Video", ofType: "mov")!))
            }
        }
    }
    
    enum VideoSource: Hashable, Identifiable {
        case backCamera
        case frontCamera
        case video
        var id: Self { self }
    }
}

extension Optional {
    var exists: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}

struct PlayerView<VideoSource: EasyPlay.VideoSource>: View {
    @Binding var isPresented: Bool
    
    let player: VideoSource.Player

    @State private var image: UIImage?
    @State private var frameIndex: Int?
    @State private var time: TimeInterval?
    
    init(isPresented: Binding<Bool>, videoSource: VideoSource) {
        self._isPresented = isPresented
        self.player = try! videoSource.player()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                EmptyView()
            }

            HStack(spacing: 16) {
                if let frameIndex = self.frameIndex {
                    Text("\(frameIndex)")
                        .font(.system(.body, design: .monospaced))
                }
                if let time = self.time {
                    Text("\(time) [s]")
                        .font(.system(.body, design: .monospaced))
                }
                Button(action: { isPresented = false }, label: {
                    Image(systemName: "xmark.circle")
                })
            }
            .padding()
        }
        .onAppear {
            player.play { frame in
                self.frameIndex = frame.index
                self.time = frame.time
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(frame.pixelBuffer, options: nil, imageOut: &cgImage)
                if let cgImage = cgImage {
                    self.image = UIImage(cgImage: cgImage)
                }
            }
        }
        .onDisappear {
            player.pause()
        }
    }
}

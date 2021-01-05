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
                PlayerView(isPresented: $videoSource.exists, videoSource: .camera(position: .back, focusMode: .continuousAutoFocus, sessionPreset: .hd1280x720, videoSettings: [:]))
            case .frontCamera:
                PlayerView(isPresented: $videoSource.exists, videoSource: .camera(position: .front, focusMode: .none, sessionPreset: .vga640x480, videoSettings: [:]))
            case .video:
                PlayerView(isPresented: $videoSource.exists, videoSource: .video(path: Bundle.main.path(forResource: "Video", ofType: "mov")!))
            }
        }
    }
}

extension Optional {
    var exists: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}

enum VideoSource: Hashable, Identifiable {
    case backCamera
    case frontCamera
    case video
    var id: Self { self }
}

struct PlayerView: View {
    @Binding var isPresented: Bool
    
    let player: Player

    @State private var image: UIImage? = nil
    
    init(isPresented: Binding<Bool>, videoSource: Player.VideoSource) {
        self._isPresented = isPresented
        self.player = try! Player(videoSource: videoSource)
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
            
            Button(action: { isPresented = false }, label: {
                Image(systemName: "xmark.circle")
            })
                .padding()
        }
        .onAppear {
            player.play { frame in
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(frame, options: nil, imageOut: &cgImage)
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

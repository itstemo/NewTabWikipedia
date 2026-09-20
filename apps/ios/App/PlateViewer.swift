import SwiftUI

/// Full-size view of the plate — the extension's <dialog> viewer, on iOS.
/// Pinch to zoom, double-tap to toggle, drag down or tap the mark to close.
struct PlateViewer: View {
    let article: Article
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    private var palette: Palette { Palette.forScheme(scheme) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            palette.paper.ignoresSafeArea()

            if let image {
                ZoomableImage(image: image)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(alignment: .trailing, spacing: 0) {
                Button { dismiss() } label: {
                    Text("×")
                        .font(.serif(30))
                        .foregroundStyle(palette.muted)
                        .padding(16)
                }
                Spacer()
                Text(article.description.isEmpty ? article.title : article.description)
                    .font(.mono(10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(palette.paper.opacity(0.9))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .task { await load() }
    }

    private func load() async {
        guard let url = article.imageURL else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }
        image = UIImage(data: data)
    }
}

/// UIScrollView-backed pinch/double-tap zoom — the native gesture set.
private struct ZoomableImage: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.toggleZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.frame = scrollView.bounds
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        @objc func toggleZoom(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            let target: CGFloat = scrollView.zoomScale > 1 ? 1 : 2.5
            scrollView.setZoomScale(target, animated: true)
        }
    }
}

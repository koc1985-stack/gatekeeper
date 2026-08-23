import GoogleMobileAds
import SwiftUI
import UIKit

/// Wraps a Google AdMob adaptive banner for SwiftUI. Only ever shown to non-premium users —
/// that choice is made by the caller (e.g. HomeView), not here.
struct BannerAdView: View {
    private let adSize = largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)

    var body: some View {
        BannerViewRepresentable(adSize: adSize)
            .frame(width: adSize.size.width, height: adSize.size.height)
    }
}

private struct BannerViewRepresentable: UIViewRepresentable {
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AdsSupport.bannerAdUnitID
        banner.rootViewController = AdsSupport.topmostViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

//
//  AdBannerView.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 31/12/2025.
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

/// A SwiftUI view that displays a Google AdMob banner ad using Adaptive Banners
struct AdBannerView: UIViewControllerRepresentable {
    /// Banner Ad Unit ID
    let adUnitID = "ca-app-pub-2092028258025749/5257637398"
    
    func makeUIViewController(context: Context) -> AdaptiveBannerViewController {
        let bannerViewController = AdaptiveBannerViewController()
        bannerViewController.adUnitID = adUnitID
        return bannerViewController
    }
    
    func updateUIViewController(_ uiViewController: AdaptiveBannerViewController, context: Context) {
        // Update if needed
    }
}

/// UIViewController that hosts an adaptive banner ad
/// Uses GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth for proper sizing
class AdaptiveBannerViewController: UIViewController {
    var adUnitID: String = ""
    private var bannerView: BannerView?
    private var hasRequestedAd = false
    private var isViewReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        
        // Listen for ATT authorization changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleATTAuthorizationChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Only proceed if view has valid dimensions
        let viewWidth = getAdWidth()
        guard viewWidth > 0 else {
            print("AdBanner: viewDidLayoutSubviews - width is 0, waiting...")
            return
        }
        
        // Mark view as ready and load ad if not already done
        if !isViewReady {
            isViewReady = true
            print("AdBanner: View is ready with width: \(viewWidth)")
            loadBannerAdIfAuthorized()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Reload banner on orientation change to get proper adaptive size
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.hasRequestedAd = false // Allow reload
            self.loadBannerAdIfAuthorized()
        }
    }
    
    @objc private func handleATTAuthorizationChange() {
        // Reload ad when app becomes active (ATT status might have changed)
        if !hasRequestedAd && isViewReady {
            loadBannerAdIfAuthorized()
        }
    }
    
    /// Calculate the ad width based on the view's safe area
    private func getAdWidth() -> CGFloat {
        // Use the view's bounds width minus safe area insets
        let frame = view.frame.inset(by: view.safeAreaInsets)
        return frame.width
    }
    
    private func loadBannerAdIfAuthorized() {
        // Make sure view is ready
        guard isViewReady else {
            print("AdBanner: View not ready yet")
            return
        }
        
        // Check ATT authorization status before loading ads
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            
            switch status {
            case .notDetermined:
                // Wait for user to make a decision - don't load ads yet
                print("AdBanner: ATT status not determined, waiting...")
                return
            case .authorized:
                print("AdBanner: ATT authorized, loading personalized ads")
            case .denied, .restricted:
                print("AdBanner: ATT denied/restricted, loading non-personalized ads")
            @unknown default:
                print("AdBanner: Unknown ATT status")
            }
        }
        
        loadBannerAd()
    }
    
    private func loadBannerAd() {
        // Prevent multiple requests
        guard !hasRequestedAd else {
            print("AdBanner: Ad already requested")
            return
        }
        
        // Calculate adaptive banner width
        let adWidth = getAdWidth()
        
        // Ensure we have a valid width
        guard adWidth > 0 else {
            print("AdBanner: Invalid ad width: \(adWidth), skipping load")
            return
        }
        
        // Remove existing banner if any
        bannerView?.removeFromSuperview()
        bannerView = nil
        
        // Get the adaptive banner size for current orientation
        // Use the Swift-style adaptive banner API
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: adWidth)
        
        print("AdBanner: Creating adaptive banner - width: \(adWidth), adSize: \(adSize.size)")
        
        // Verify ad size is valid
        guard adSize.size.width > 0 && adSize.size.height > 0 else {
            print("AdBanner: ❌ Invalid adaptive ad size calculated: \(adSize.size)")
            return
        }
        
        // Create new banner with adaptive size
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = self
        banner.delegate = self
        
        // Add to view with Auto Layout
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        self.bannerView = banner
        
        // Create and load request
        let request = Request()
        banner.load(request)
        hasRequestedAd = true
        
        print("AdBanner: Loading ad with unit ID: \(adUnitID), size: \(adSize.size)")
    }
    
    /// Public method to force reload the ad (e.g., after ATT permission granted)
    func reloadAd() {
        hasRequestedAd = false
        loadBannerAdIfAuthorized()
    }
}

// MARK: - BannerViewDelegate
extension AdaptiveBannerViewController: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("AdBanner: ✅ Ad received successfully - size: \(bannerView.adSize.size)")
        
        // Animate banner appearing
        bannerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            bannerView.alpha = 1
        }
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("AdBanner: ❌ Failed to receive ad: \(error.localizedDescription)")
        
        // Allow retry on next opportunity
        hasRequestedAd = false
    }
    
    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        print("AdBanner: 📊 Impression recorded")
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        print("AdBanner: 👆 Click recorded")
    }
}

/// Container view for the ad banner with proper sizing
/// Uses a GeometryReader to ensure proper dimensions are passed
struct AdBannerContainerView: View {
    // Standard adaptive banner height is approximately 50-60 points
    private let bannerHeight: CGFloat = 60
    
    var body: some View {
        AdBannerView()
            .frame(height: bannerHeight)
            .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Content above banner")
        AdBannerContainerView()
    }
}

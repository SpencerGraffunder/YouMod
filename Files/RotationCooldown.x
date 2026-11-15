#import "Headers.h"

// Post-rotation swipe cooldown removal
//
// After rotating the device from landscape back to portrait while watching a
// video, YouTube blocks the swipe-down-to-minimize gesture on the portrait
// fullscreen player for roughly three seconds. The gate lives in
// YTWatchFullscreenViewController (isRotating state, flipped back by a
// settle/cooldown timer after the rotation animation) and in
// YTColdConfig's staged "fullscreen rotation fix" code paths
// (iosEnableFullscreenRotationFix / iosEnableIos27FullscreenRotationFix),
// which keep the watch fullscreen VC in its rotating state while the staged
// rotation transition runs.
//
// While the toggle is ON (registered default YES in Settings.x %ctor):
//   * report the fullscreen VC as not rotating, so gesture gates that poll
//     isRotating accept the swipe immediately, and
//   * force the staged-rotation config paths OFF so the rotation completes
//     like it did before those transition fixes existed (nothing to settle).
// Turning the toggle OFF restores stock behavior with no other side effects.

%group InstantSwipeAfterRotation

%hook YTWatchFullscreenViewController
- (BOOL)isRotating {
    return NO;
}
%end

%hook YTColdConfig
- (BOOL)iosEnableFullscreenRotationFix { return NO; }
- (BOOL)iosEnableIos27FullscreenRotationFix { return NO; }
%end

%end

static BOOL ymInstantSwipeEnabled(void) {
    // Register our own default first: %ctor order across .x files is
    // link-order dependent, and the Settings.x %ctor may run after ours.
    // registerDefaults never clobbers an explicit user toggle (application
    // domain wins over the registration domain).
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{InstantSwipeAfterRotation: @YES}];
    return IS_ENABLED(InstantSwipeAfterRotation);
}

%ctor {
    if (ymInstantSwipeEnabled()) {
        %init(InstantSwipeAfterRotation);
    }
}

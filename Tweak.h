#import <Foundation/Foundation.h>
#import <libhdev/HUtilities/HDownloadMediaWithProgress.h>
#import "instanoads-Swift.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import "lib/InstaZoomImageViewController.h"

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.instanoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.instanoadspref/PrefChanged"

@interface UIView (RCTViewUnmounting)
@property(retain, nonatomic) UIViewController *viewController;
- (UIView *)_rootView;
@end

@interface IGImageSpecifier : NSObject
@property(readonly, nonatomic) NSURL *url;
@end

@interface IGVideo : NSObject
@property(readonly, nonatomic) NSSet *allVideoURLs;
@end

@interface IGMedia : NSObject
@property(readonly) IGVideo *video;
@property long long likeCount;
@end

@interface IGFeedItem : NSObject
@property long long likeCount;
@property(readonly) IGVideo *video;
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
@end

@interface IGImageView : UIImageView
@property(retain, nonatomic) IGImageSpecifier *imageSpecifier;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGFeedItemMediaCell : UICollectionViewCell
@property(retain, nonatomic) IGMedia *post;
@end

@interface IGModernFeedVideoCell : IGFeedItemMediaCell
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGPanavisionFeedVideoCell : IGFeedItemMediaCell
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGFeedItemVideoView : UIView
@property(readonly, nonatomic) IGVideo *video;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGVideoPlayer : NSObject {
  IGVideo *_video;
}
@end

@interface IGTVVideoSectionController : UIViewController {
  IGVideoPlayer *_videoPlayer;
}
@end

@interface IGTVFullscreenVideoCell : UICollectionViewCell
@property(nonatomic) IGTVVideoSectionController *delegate;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end


/**
 * For download story photo/video
 */
@protocol IGStoryPlayerMediaViewType
@end

@interface IGImageProgressView : UIView
@property(retain, nonatomic) IGImageSpecifier *imageSpecifier;
@end

@interface IGStoryPhotoView : UIView<IGStoryPlayerMediaViewType>
@property(retain, nonatomic) IGImageSpecifier *mediaViewLastLoadedImageSpecifier;
@property(readonly, nonatomic) IGImageProgressView *photoView;
@end

@interface IGStoryVideoView : UIView<IGStoryPlayerMediaViewType>
@property(retain, nonatomic) IGVideoPlayer *videoPlayer;
@end

@interface IGStoryViewerContainerView : UIView
@property(retain, nonatomic) UIView<IGStoryPlayerMediaViewType> *mediaView;
@property(nonatomic, retain) UIButton *hDownloadButton; // new property
@end

/**
 * For download Reel
 */
@interface IGSundialVideoPlaybackView : UIView {
  IGFeedItem *_video;
}
@end


/**
 * For HD profile picture
 */
@interface IGUser : NSObject
@property(copy) NSString *username;
@property BOOL followsCurrentUser;
- (NSURL *)HDProfilePicURL;
- (BOOL)isUser;
@end

@interface IGProfilePictureImageView : UIView
@property(readonly, nonatomic) IGUser *user;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

/**
 * Determine If User Is Following You
 */
@interface IGProfileBioModel
@property(readonly, copy, nonatomic) IGUser *user;
@end

@interface IGProfileViewController : UIViewController {
  IGProfileBioModel *_bioModel;
}
@end

@interface IGProfileSimpleAvatarStatsCell : UICollectionViewCell
@property(nonatomic, retain) UIView *isFollowingYouBadge; // new property
@property(nonatomic, retain) UILabel *isFollowingYouLabel; // new property
- (void)addIsFollowingYouBadgeView; // new
@end

@interface IGUserSession : NSObject
@property(readonly, nonatomic) IGUser *user;
@end

@interface IGWindow : UIWindow
@property(nonatomic) __weak IGUserSession *userSession;
@end

@interface IGShakeWindow : UIWindow
@property(nonatomic) __weak IGUserSession *userSession;
@end

@interface IGStyledString : NSObject
@property(retain, nonatomic) NSMutableAttributedString *attributedString;
- (void)appendString:(id)arg1;
@end

@interface IGInstagramAppDelegate : NSObject <UIApplicationDelegate>
@end

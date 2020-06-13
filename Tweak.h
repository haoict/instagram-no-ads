#import <Foundation/Foundation.h>
#import <libhdev/HUtilities/HDownloadMediaWithProgress.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.instanoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.instanoadspref/PrefChanged"

@interface IGFeedItem : NSObject
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
@end

@interface IGImageSpecifier : NSObject
@property(readonly, nonatomic) NSURL *url;
@end

@interface IGVideo : NSObject
@property(readonly, nonatomic) NSSet *allVideoURLs;
@end

@interface IGImageView : UIImageView
@property(retain, nonatomic) IGImageSpecifier *imageSpecifier;
@property(retain, nonatomic) UIViewController *viewController;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGFeedItemVideoView : UIView
@property(readonly, nonatomic) IGVideo *video;
@property(retain, nonatomic) UIViewController *viewController;
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
@property(retain, nonatomic) UIViewController *viewController;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface IGStoryVideoView : UIView
@property(retain, nonatomic) IGVideoPlayer *videoPlayer;
@property(retain, nonatomic) UIViewController *viewController;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end
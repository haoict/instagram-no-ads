/**
 * @author Hao Nguyen
 */

#import "Tweak.h"

BOOL noads;
BOOL canSaveMedia;
BOOL canSaveHDProfilePicture;
BOOL showLikeCount;
BOOL disableDirectMessageSeenReceipt;
BOOL disableStorySeenReceipt;
BOOL unlimitedReplayDirectMessage;
BOOL determineIfUserIsFollowingYou;
BOOL likeConfirmation;
int appLockSetting;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveMedia = [[settings objectForKey:@"canSaveMedia"] ?: @(YES) boolValue];
  canSaveHDProfilePicture = [[settings objectForKey:@"canSaveHDProfilePicture"] ?: @(YES) boolValue];
  showLikeCount = [[settings objectForKey:@"showLikeCount"] ?: @(YES) boolValue];
  determineIfUserIsFollowingYou = [[settings objectForKey:@"determineIfUserIsFollowingYou"] ?: @(YES) boolValue];
  disableDirectMessageSeenReceipt = [[settings objectForKey:@"disableDirectMessageSeenReceipt"] ?: @(NO) boolValue];
  disableStorySeenReceipt = [[settings objectForKey:@"disableStorySeenReceipt"] ?: @(NO) boolValue];
  unlimitedReplayDirectMessage = [[settings objectForKey:@"unlimitedReplayDirectMessage"] ?: @(NO) boolValue];
  likeConfirmation = [[settings objectForKey:@"likeConfirmation"] ?: @(NO) boolValue];
  appLockSetting = [[settings objectForKey:@"appLockSetting"] intValue] ?: 0;
}

static NSArray* removeAdsItemsInList(NSArray *list) {
  NSMutableArray *orig = [list mutableCopy];
  [orig enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if (([obj isKindOfClass:%c(IGFeedItem)] && ([obj isSponsored] || [obj isSponsoredApp])) || [obj isKindOfClass:%c(IGAdItem)]) {
      [orig removeObjectAtIndex:idx];
    }
  }];
  return [orig copy];
}

static void showConfirmation(void (^okHandler)(void)) {
  __block UIWindow* topWindow;
  topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  topWindow.rootViewController = [UIViewController new];
  topWindow.windowLevel = UIWindowLevelAlert + 1;

  UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure?" preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    topWindow.hidden = YES;
    topWindow = nil;
    okHandler();
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    topWindow.hidden = YES;
    topWindow = nil;
  }]];

  [topWindow makeKeyAndVisible];

  [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

%group SecurityGroup
  %hook IGInstagramAppDelegate
    static BOOL isAuthenticationShowed = FALSE;
    - (void)applicationDidBecomeActive:(id)arg1 {
      %orig;

      if (appLockSetting != 0 && !isAuthenticationShowed) {
        UIViewController *rootController = [[self window] rootViewController];
        SecurityViewController *securityViewController = [SecurityViewController new];
        securityViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [rootController presentViewController:securityViewController animated:YES completion:nil];
        isAuthenticationShowed = TRUE;
      }
    }

    - (void)applicationWillEnterForeground:(id)arg1 {
      %orig;

      if (appLockSetting == 2) {
        isAuthenticationShowed = FALSE;
      }
    }
  %end
%end

%group ShowLikeCount
  %hook IGFeedItem
    - (id)buildLikeCellStyledStringWithIcon:(id)arg1 andText:(id)arg2 style:(id)arg3 {
      NSNumberFormatter *formatter = [NSNumberFormatter new];
      [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
      NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:self.likeCount]];

      NSString *newArg2 = [NSString stringWithFormat:@"%@ (%@)", arg2 ?: @"Liked:", formatted];
      return %orig(arg1, newArg2, arg3);
    }
  %end

  // for instagram v178.0
  %hook IGFeedItemLikeCountCell
    + (IGStyledString *)buildStyledStringWithMedia:(IGMedia *)arg1 feedItemRow:(id)arg2 pageCellState:(id)arg3 configuration:(id)arg4 feedConfiguration:(id)arg5 contentWidth:(double)arg6 textWidth:(double)arg7 combinedContextOptions:(long long)arg8 userSession:(id)arg9 {
      IGStyledString *orig = %orig;
      if (orig != nil
        && orig.attributedString != nil
        && orig.attributedString.string != nil
        && ![orig.attributedString.string containsString:@"("]
        && ![orig.attributedString.string containsString:@")"]) {
          NSNumberFormatter *formatter = [NSNumberFormatter new];
          [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
          NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:arg1.likeCount]];
          [orig appendString:[NSString stringWithFormat:@" (%@)", formatted]];
      }
      return orig;
    }
  %end
%end

%group UnlimitedReplayDirectMessage
  %hook IGStoryPhotoView
    - (void)progressImageView:(id)arg1 didLoadImage:(id)arg2 loadSource:(id)arg3 networkRequestSummary:(id)arg4 {

    }
  %end
%end

%group LikeConfirmation
  %hook IGUFIButtonBarView
    - (void)_onLikeButtonPressed:(id)arg1 {
      showConfirmation(^(void) { %orig; });
    }
  %end

  %hook IGFeedPhotoView
    - (void)_onDoubleTap:(id)arg1 {
      showConfirmation(^(void) { %orig; });
    }
  %end

  %hook IGFeedItemVideoView
    - (void)_handleOverlayDoubleTap {
      showConfirmation(^(void) { %orig; });
    }
  %end

  %hook IGSundialViewerVideoCell
    - (void)_handleDoubleTap:(id)arg1 {
      showConfirmation(^(void) { %orig; });
    }
  %end

  %hook IGSundialViewerLikeButton
    - (void)touchDetector:(id)arg1 touchesEnded:(id)arg2 withEvent:(id)arg3 {
      showConfirmation(^(void) { %orig; });
    }
  %end

  %hook IGCommentCell
    - (void)_didDoubleTap:(id)arg1 {
      showConfirmation(^(void) { %orig; });
    }

    - (void)contentView:(id)arg1 didTapOnLikeButton:(id)arg2 {
      showConfirmation(^(void) { %orig; });
    }
  %end
%end

%group NoAds
  %hook IGMainFeedListAdapterDataSource
    - (NSArray *)objectsForListAdapter:(id)arg1 {
      return removeAdsItemsInList(%orig);
    }
  %end

  %hook IGVideoFeedViewController
    - (NSArray *)objectsForListAdapter:(id)arg1 {
      return removeAdsItemsInList(%orig);
    }
  %end

  %hook IGChainingFeedViewController
    - (NSArray *)objectsForListAdapter:(id)arg1 {
      return removeAdsItemsInList(%orig);
    }
  %end

  %hook IGStoryAdPool
    - (id)initWithUserSession:(id)arg1 {
      return nil;
    }
  %end

  %hook IGStoryAdsManager
    - (id)initWithUserSession:(id)arg1 storyViewerLoggingContext:(id)arg2 storyFullscreenSectionLoggingContext:(id)arg3 viewController:(id)arg4 {
      return nil;
    }
  %end

  %hook IGStoryAdsFetcher
    - (id)initWithUserSession:(id)arg1 delegate:(id)arg2 {
      return nil;
    }
  %end

  // IG 148.0
  %hook IGStoryAdsResponseParser
    - (id)parsedObjectFromResponse:(id)arg1 {
      return nil;
    }

    - (id)initWithReelStore:(id)arg1 {
      return nil;
    }
  %end

  %hook IGStoryAdsOptInTextView
    - (id)initWithBrandedContentStyledString:(id)arg1 sponsoredPostLabel:(id)arg2 {
      return nil;
    }
  %end

  %hook IGSundialAdsResponseParser
    - (id)parsedObjectFromResponse:(id)arg1 {
      return nil;
    }

    - (id)initWithMediaStore:(id)arg1 userStore:(id)arg2 {
      return nil;
    }
  %end
%end

%group CanSaveMedia
  %hook IGImageView
    - (id)initWithFrame:(CGRect)arg1 shouldBackgroundDecode:(BOOL)arg2 shouldUseProgressiveJPEG:(BOOL)arg3 placeholderProvider:(id)arg4 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    - (id)initWithFrame:(CGRect)arg1 shouldUseProgressiveJPEG:(BOOL)arg2 placeholderProvider:(id)arg3 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        if ([self.viewController isKindOfClass:%c(IGStoryViewerViewController)]) { // don't show download alert if this photo is story, use download button instead
          return;
        }

        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          InstaZoomImageViewController *imageVC = [[%c(InstaZoomImageViewController) alloc] initWithSourceImage:self.image];

          if (imageVC)
          {
            imageVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
            imageVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            //AppDelegate *igDelegate = [UIApplication sharedApplication].delegate;
            [self.viewController presentViewController:imageVC animated:YES completion:nil];
          }
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Download photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:self.imageSpecifier.url appendExtension:nil mediaType:Image toAlbum:@"Instagram" view:self];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGModernFeedVideoCell
  - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
  }

  %new - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
  }
  %new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
          UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
          NSArray *videoURLArray = [self.post.video.allVideoURLs allObjects];
          
          [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
              AVPlayer *player = [AVPlayer playerWithURL:videoURLArray[videoURLArray.count - 1]];
              AVPlayerViewController *playerViewController = [AVPlayerViewController new];
              playerViewController.player = player;
              playerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
              [self.viewController presentViewController:playerViewController animated:YES completion:^{
                  [playerViewController.player play];
              }];
          }]];
          
          for (int i = 0; i < [videoURLArray count]; i++) {
              [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                  [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" view:self];
              }]];
          }
          [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
          [self.viewController presentViewController:alert animated:YES completion:nil];
      }
  }
  %end

  %hook IGPanavisionFeedVideoCell
  - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
  }

  %new - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
  }
  %new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
          UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
          NSArray *videoURLArray = [self.post.video.allVideoURLs allObjects];
          
          [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
              AVPlayer *player = [AVPlayer playerWithURL:videoURLArray[videoURLArray.count - 1]];
              AVPlayerViewController *playerViewController = [AVPlayerViewController new];
              playerViewController.player = player;
              playerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
              [self.viewController presentViewController:playerViewController animated:YES completion:^{
                  [playerViewController.player play];
              }];
          }]];
          
          for (int i = 0; i < [videoURLArray count]; i++) {
              [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                  [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" view:self];
              }]];
          }
          [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
          [self.viewController presentViewController:alert animated:YES completion:nil];
      }
  }
  %end

  %hook IGFeedItemVideoView
    - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        NSArray *videoURLArray = [self.video.allVideoURLs allObjects];

        [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            AVPlayer *player = [AVPlayer playerWithURL:videoURLArray[videoURLArray.count - 1]];
            AVPlayerViewController *playerViewController = [AVPlayerViewController new];
            playerViewController.player = player;
            playerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.viewController presentViewController:playerViewController animated:YES completion:^{
              [playerViewController.player play];
            }];
        }]];

        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" view:self];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGTVFullscreenVideoCell
    - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGVideoPlayer *_videoPlayer = MSHookIvar<IGVideoPlayer *>(self.delegate, "_videoPlayer");
        IGVideo *_video = MSHookIvar<IGVideo *>(_videoPlayer, "_video");
        NSArray *videoURLArray = [_video.allVideoURLs allObjects];

        [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            AVPlayer *player = [AVPlayer playerWithURL:videoURLArray[videoURLArray.count - 1]];
            AVPlayerViewController *playerViewController = [AVPlayerViewController new];
            playerViewController.player = player;
            playerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.viewController presentViewController:playerViewController animated:YES completion:^{
              [playerViewController.player play];
            }];
        }]];

        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" viewController:self.viewController];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGStoryViewerContainerView
    %property (nonatomic, retain) UIButton *hDownloadButton;
    - (id)initWithFrame:(CGRect)arg1 shouldCreateComposerBackgroundView:(BOOL)arg2 userSession:(id)arg3 bloksContext:(id)arg4 {
      self = %orig;

      self.hDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [self.hDownloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
      [self.hDownloadButton addTarget:self action:@selector(hDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
      // [self.hDownloadButton setTitle:@"Download" forState:UIControlStateNormal];
      [self.hDownloadButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/instanoads/download.png"] forState:UIControlStateNormal];
      self.hDownloadButton.frame = CGRectMake(self.frame.size.width - 40, self.frame.size.height - ([HCommon isNotch] ? 120.0 : 90.0), 24.0, 24.0);
      [self addSubview:self.hDownloadButton];
      return self;
    }

    %new
    - (void)hDownloadButtonPressed:(UIButton *)sender {
      if ([self.mediaView isKindOfClass:%c(IGStoryPhotoView)]) {
        NSURL *url = ((IGStoryPhotoView *)self.mediaView).photoView.imageSpecifier.url;
        [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:url appendExtension:nil mediaType:Image toAlbum:@"Instagram" view:self];
      } else if ([self.mediaView isKindOfClass:%c(IGStoryVideoView)]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGVideo *_video = MSHookIvar<IGVideo *>(((IGStoryVideoView *)self.mediaView).videoPlayer, "_video");
        NSArray *videoURLArray = [_video.allVideoURLs allObjects];
        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" viewController:self.viewController];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      } else {
        [HCommon showAlertMessage:@"This story has no media to download. Seems like it's a bug. Please report to the developer" withTitle:@"Error" viewController:nil];
      }
    }
  %end

  %hook IGSundialVideoPlaybackView
    - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGFeedItem *_feedItem = MSHookIvar<IGFeedItem *>(self, "_video");
        IGVideo *video = _feedItem.video;
        NSArray *videoURLArray = [video.allVideoURLs allObjects];

        [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            AVPlayer *player = [AVPlayer playerWithURL:videoURLArray[videoURLArray.count - 1]];
            AVPlayerViewController *playerViewController = [AVPlayerViewController new];
            playerViewController.player = player;
            playerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.viewController presentViewController:playerViewController animated:YES completion:^{
              [playerViewController.player play];
            }];
        }]];

        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d (%@)", i + 1, i == 0 ? @"HD" : @"SD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" view:self];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end
%end

%group CanSaveHDProfilePicture
  %hook IGProfilePictureImageView
    - (id)initWithFrame:(CGRect)arg1 imagePriority:(long long)arg2 placeholderImage:(id)arg3 buttonDisabled:(BOOL)arg4 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    - (id)initWithFrame:(CGRect)arg1 imagePriority:(long long)arg2 placeholderImage:(id)arg3 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    - (id)initWithFrame:(CGRect)arg1 imagePriority:(long long)arg2 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    - (id)initWithFrame:(CGRect)arg1 {
      self = %orig;
      [self addHandleLongPress];
      return self;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.3;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instagram No Ads" message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        NSURL *HDProfilePicURL = [self.user HDProfilePicURL];

        [alert addAction:[UIAlertAction actionWithTitle:@"Preview" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          InstaZoomImageViewController *imageVC = [[%c(InstaZoomImageViewController) alloc] initWithSourceImageUrl:HDProfilePicURL];

          if (imageVC) {
            imageVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
            imageVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            //AppDelegate *igDelegate = [UIApplication sharedApplication].delegate;
            [self.viewController presentViewController:imageVC animated:YES completion:nil];
          }
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Download HD Profile Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:HDProfilePicURL appendExtension:nil mediaType:Image toAlbum:@"Instagram" viewController:self.viewController];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end
%end

%group DisableDirectMessageSeenReceipt
  %hook IGDirectThreadViewListAdapterDataSource
    - (BOOL)shouldUpdateLastSeenMessage {
      return FALSE;
    }
  %end
%end

%group DisableStorySeenReceipt
  %hook IGStoryViewerViewController
    - (void)fullscreenSectionController:(id)arg1 didMarkItemAsSeen:(id)arg2 {
    }
  %end
%end

%group DetermineIfUserIsFollowingYou
  %hook IGProfileSimpleAvatarStatsCell
    %property (nonatomic, retain) UILabel *isFollowingYouLabel;
    %property (nonatomic, retain) UIView *isFollowingYouBadge;

    - (id)initWithFrame:(CGRect)arg1 {
      self = %orig;

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ // ensure user's relationship is fetched
        @try {
          IGProfileViewController *vc = (IGProfileViewController *)self.viewController;
          if (!vc) {
            throw [NSException exceptionWithName:@"NullPointerException" reason:@"IGProfileViewController is nil" userInfo:nil];
          }
          IGProfileBioModel *_bioModel = MSHookIvar<IGProfileBioModel *>(vc, "_bioModel");
          IGUser *user = _bioModel.user;

          IGWindow *rootView = (IGWindow *)[self _rootView];
          IGUser *currentUser = rootView.userSession.user;
          if (![user.username isEqualToString:currentUser.username] && user.followsCurrentUser) {
            [self addIsFollowingYouBadgeView];
          }
        } @catch (NSException *e) { }
      });

      return self;
    }

    %new
    - (void)addIsFollowingYouBadgeView {
      self.isFollowingYouBadge = [[UIView alloc] init];
      self.isFollowingYouBadge.frame = CGRectMake(155, 75, 70, 16);
      self.isFollowingYouBadge.alpha = 1;
      self.isFollowingYouBadge.layer.cornerRadius = 4;
      self.isFollowingYouBadge.backgroundColor = [HCommon isDarkMode] ? [UIColor colorWithRed:0.125 green:0.137 blue:0.153 alpha:1] : [UIColor colorWithRed:0.922 green:0.933 blue:0.941 alpha:1];

      [self addSubview:self.isFollowingYouBadge];

      UIFont * customFont = [UIFont fontWithName:@"Arial-BoldMT" size:10]; //custom font
      self.isFollowingYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(2.0, 0.0, 66.0, 16.0)];
      self.isFollowingYouLabel.translatesAutoresizingMaskIntoConstraints = false;
      self.isFollowingYouLabel.text = @"Follows you";
      self.isFollowingYouLabel.font = customFont;
      self.isFollowingYouLabel.adjustsFontSizeToFitWidth = true;
      self.isFollowingYouLabel.textAlignment = NSTextAlignmentCenter;
      self.isFollowingYouLabel.textColor = [HCommon isDarkMode] ? [UIColor colorWithRed:0.486 green:0.514 blue:0.541 alpha:1] : [UIColor colorWithRed:0.357 green:0.439 blue:0.541 alpha:1];
      [self.isFollowingYouBadge addSubview:self.isFollowingYouLabel];

    }
  %end
%end

static id observer;
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  %init(SecurityGroup);

  // http://iphonedevwiki.net/index.php/User:Uroboro#Using_blocks
  observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
    object:nil queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification *notification) {
      if (showLikeCount) {
        %init(ShowLikeCount);
      }

      if (likeConfirmation) {
        %init(LikeConfirmation);
      }

      if (noads) {
        %init(NoAds);
      }

      if (canSaveMedia) {
        %init(CanSaveMedia);
      }

      if (canSaveHDProfilePicture) {
        %init(CanSaveHDProfilePicture);
      }

      if (determineIfUserIsFollowingYou) {
        %init(DetermineIfUserIsFollowingYou)
      }

      if (disableDirectMessageSeenReceipt) {
        %init(DisableDirectMessageSeenReceipt)
      }

      if (disableStorySeenReceipt) {
        %init(DisableStorySeenReceipt)
      }

      if (unlimitedReplayDirectMessage) {
        %init(UnlimitedReplayDirectMessage)
      }
    }
  ];
}

%dtor {
  [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

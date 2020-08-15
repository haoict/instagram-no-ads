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
BOOL determineIfUserIsFollowingYou;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveMedia = [[settings objectForKey:@"canSaveMedia"] ?: @(YES) boolValue];
  canSaveHDProfilePicture = [[settings objectForKey:@"canSaveHDProfilePicture"] ?: @(YES) boolValue];
  showLikeCount = [[settings objectForKey:@"showLikeCount"] ?: @(YES) boolValue];
  determineIfUserIsFollowingYou = [[settings objectForKey:@"determineIfUserIsFollowingYou"] ?: @(YES) boolValue];
  disableDirectMessageSeenReceipt = [[settings objectForKey:@"disableDirectMessageSeenReceipt"] ?: @(NO) boolValue];
  disableStorySeenReceipt = [[settings objectForKey:@"disableStorySeenReceipt"] ?: @(NO) boolValue];
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

%group Common
  %hook IGFeedItem
    - (id)buildLikeCellStyledStringWithIcon:(id)arg1 andText:(id)arg2 style:(id)arg3 {
      NSString *newArg2 = showLikeCount ? [NSString stringWithFormat:@"%@ (%lld)", arg2 ?: @"Liked:", self.likeCount] : arg2;
      return %orig(arg1, newArg2, arg3);
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
%end

%group CanSaveMedia
  %hook IGImageView
    - (id)initWithFrame:(CGRect)arg1 shouldBackgroundDecode:(BOOL)arg2 shouldUseProgressiveJPEG:(BOOL)arg3 placeholderProvider:(id)arg4 {
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
        [alert addAction:[UIAlertAction actionWithTitle:@"Download photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:self.imageSpecifier.url appendExtension:nil mediaType:Image toAlbum:@"Instagram" view:self];
        }]];
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
        NSURL *url = ((IGStoryPhotoView *)self.mediaView).mediaViewLastLoadedImageSpecifier.url;
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
        [alert addAction:[UIAlertAction actionWithTitle:@"Download HD Profile Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          NSURL *HDProfilePicURL = [self.user HDProfilePicURL];
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

          IGShakeWindow *rootView = (IGShakeWindow *)[self _rootView];
          IGUser *currentUser = rootView.userSession.user;
          if (![user.username isEqualToString:currentUser.username]) {
            BOOL isFollowingYou = user.followsCurrentUser;
            self.isFollowingYouLabel = [[UILabel alloc]initWithFrame:CGRectMake(141, 70, 200, 20)];
            self.isFollowingYouLabel.text = isFollowingYou ? @"is following you" : @"is not following you";
            self.isFollowingYouLabel.font = [UIFont systemFontOfSize:14];
            self.isFollowingYouLabel.textColor = isFollowingYou ? [HCommon colorFromHex:@"#E1306C"] : [UIColor grayColor];
            [self addSubview:self.isFollowingYouLabel];
          }
        } @catch (NSException *e) { }
      });

      return self;
    }
  %end
%end

static id observer;
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  // http://iphonedevwiki.net/index.php/User:Uroboro#Using_blocks
  observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
    object:nil queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification *notification) {
      %init(Common);

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
    }
  ];
}

%dtor {
  [[NSNotificationCenter defaultCenter] removeObserver:observer];
}
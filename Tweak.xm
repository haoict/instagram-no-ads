#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL canSaveMedia;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveMedia = [[settings objectForKey:@"canSaveMedia"] ?: @(YES) boolValue];
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
%end

%group CanSaveMedia
  %hook IGImageView
    - (id)initWithFrame:(CGRect)arg1 shouldBackgroundDecode:(BOOL)arg2 shouldUseProgressiveJPEG:(BOOL)arg3 placeholderProvider:(id)arg4 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Download photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:self.imageSpecifier.url appendExtension:nil mediaType:Image toAlbum:@"Instagram" view:self];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGFeedItemVideoView
    - (id)initWithFrame:(struct CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        NSArray *videoURLArray = [self.video.allVideoURLs allObjects];
        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d", i + 1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" view:self];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGTVFullscreenVideoCell
    - (id)initWithFrame:(struct CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGVideoPlayer *_videoPlayer = MSHookIvar<IGVideoPlayer *>(self.delegate, "_videoPlayer");
        IGVideo *_video = MSHookIvar<IGVideo *>(_videoPlayer, "_video");
        NSArray *videoURLArray = [_video.allVideoURLs allObjects];
        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d", i + 1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" viewController:self.viewController];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end

  %hook IGStoryVideoView
    - (id)initWithFrame:(CGRect)arg1 userSession:(id)arg2 playerPreloadPool:(id)arg3 subtitleOffset:(double)arg4 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGVideo *_video = MSHookIvar<IGVideo *>(self.videoPlayer, "_video");
        NSArray *videoURLArray = [_video.allVideoURLs allObjects];
        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d", i + 1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:[videoURLArray objectAtIndex:i] appendExtension:nil mediaType:Video toAlbum:@"Instagram" viewController:self.viewController];
          }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alert animated:YES completion:nil];
      }
    }
  %end
%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();
  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/InstagramAppCoreFramework.framework/InstagramAppCoreFramework"] UTF8String], RTLD_NOW);

  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
  if ([version compare:@"145.0" options:NSNumericSearch] == NSOrderedAscending) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [HCommon showAlertMessage:@"Your current version of Instagram is not supported, please go to App Store and update it (>=145.0)" withTitle:@"Please update Instagram" viewController:nil];
      });
    });
  }

  if (noads) {
    %init(NoAds);
  }

  if (canSaveMedia) {
    %init(CanSaveMedia);
  }
}

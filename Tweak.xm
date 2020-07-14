/**
 * @author Hao Nguyen
 */

#import "Tweak.h"

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
      longPress.minimumPressDuration = 0.3;
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
      longPress.minimumPressDuration = 0.3;
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

  %hook IGStoryViewerContainerView
    %property (nonatomic, retain) UIButton *hDownloadButton;
    - (id)initWithFrame:(CGRect)arg1 shouldCreateComposerBackgroundView:(BOOL)arg2 userSession:(id)arg3 bloksContext:(id)arg4 {
      self = %orig;

      // detect iphone with notch
      double yPadding = 90;
      if (@available( iOS 11.0, * )) {
        if ([[[UIApplication sharedApplication] keyWindow] safeAreaInsets].bottom > 0) {
          yPadding = 120.0;
        }
      }
      self.hDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [self.hDownloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
      [self.hDownloadButton addTarget:self action:@selector(hDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
      // [self.hDownloadButton setTitle:@"Download" forState:UIControlStateNormal];
      [self.hDownloadButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/instanoads/download.png"] forState:UIControlStateNormal];
      self.hDownloadButton.frame = CGRectMake(self.frame.size.width - 40, self.frame.size.height - yPadding, 24.0, 24.0);
      [self addSubview:self.hDownloadButton];
      return self;
    }

    %new
    - (void)hDownloadButtonPressed:(UIButton *)sender {
      if ([self.mediaView isKindOfClass:%c(IGStoryPhotoView)]) {
        NSURL *url = ((IGStoryPhotoView *)self.mediaView).mediaViewLastLoadedImageSpecifier.url;
        [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:url appendExtension:nil mediaType:Image toAlbum:@"Instagram" view:self];
      } else if ([self.mediaView isKindOfClass:%c(IGStoryVideoView)]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        IGVideo *_video = MSHookIvar<IGVideo *>(((IGStoryVideoView *)self.mediaView).videoPlayer, "_video");
        NSArray *videoURLArray = [_video.allVideoURLs allObjects];
        for (int i = 0; i < [videoURLArray count]; i++) {
          [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Download video - link %d", i + 1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
%end

static id observer;
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  // http://iphonedevwiki.net/index.php/User:Uroboro#Using_blocks
  observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
    object:nil queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification *notification) {
      if (noads) {
        %init(NoAds);
      }

      if (canSaveMedia) {
        %init(CanSaveMedia);
      }
    }
  ];
}

%dtor {
  [[NSNotificationCenter defaultCenter] removeObserver:observer];
}
#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
}

%group IGHooks
  %hook IGMainFeedListAdapterDataSource
    - (NSArray *)objectsForListAdapter:(id)arg1 {
      NSMutableArray *orig = [%orig mutableCopy];
      [orig enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:%c(IGFeedItem)] && ([obj isSponsored] || [obj isSponsoredApp])) [orig removeObjectAtIndex:idx];
      }];
      return [orig copy];
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

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  if (!noads) {
    return;
  }

  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/InstagramAppCoreFramework.framework/InstagramAppCoreFramework"] UTF8String], RTLD_NOW);
  %init(IGHooks);
}

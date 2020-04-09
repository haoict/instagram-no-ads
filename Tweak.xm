#import <dlfcn.h>

@interface IGFeedItem : NSObject
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
@end

@interface IGStoryViewerViewModel : NSObject
- (BOOL)isSponsored;
@end

%group IGHooks

%hook IGMainFeedListAdapterDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
  NSArray *orig = %orig;
  NSMutableArray *objectsNoAds = [@[] mutableCopy];
  for (id object in orig) {
    if ([object isKindOfClass:(NSClassFromString(@"IGFeedItem"))]) {
      if ([object isSponsored] || [object isSponsoredApp]) {
        continue;
      }
    }
    [objectsNoAds addObject:object];
  }
  return objectsNoAds;
}
%end

%hook IGStoryAndLiveViewerDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
  NSArray *orig = %orig;
  NSMutableArray *objectsNoAds = [@[] mutableCopy];
  for (id object in orig) {
    if ([object isKindOfClass:(NSClassFromString(@"IGStoryViewerViewModel"))]) {
      if ([object isSponsored]) {
        continue;
      }
    }
    [objectsNoAds addObject:object];
  }
  return objectsNoAds;
}
%end

%end

%ctor{
  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/InstagramAppCoreFramework.framework/InstagramAppCoreFramework"] UTF8String], RTLD_NOW);
  %init(IGHooks);
}

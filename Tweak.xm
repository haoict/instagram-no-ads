#import <dlfcn.h>

@interface IGFeedItem : NSObject
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
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

%hook IGStoryAdPool
- (id)initWithUserSession:(id)arg1 {
  %orig(nil);
  return nil;
}
%end

%end

%ctor{
  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/InstagramAppCoreFramework.framework/InstagramAppCoreFramework"] UTF8String], RTLD_NOW);
  %init(IGHooks);
}

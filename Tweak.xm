#import <Foundation/Foundation.h>

@interface IGFeedItem : NSObject
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
@end

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
%end

%ctor {
  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/InstagramAppCoreFramework.framework/InstagramAppCoreFramework"] UTF8String], RTLD_NOW);
  %init(IGHooks);
}

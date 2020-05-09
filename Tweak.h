#import <Foundation/Foundation.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.instanoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.instanoadspref/PrefChanged"

@interface IGFeedItem : NSObject
- (BOOL)isSponsored;
- (BOOL)isSponsoredApp;
@end

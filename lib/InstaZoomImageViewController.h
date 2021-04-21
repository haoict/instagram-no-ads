#import <UIKit/UIKit.h>

@interface InstaZoomImageViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

/*! This is responsible for panning and zooming the images. */
@property (strong, nonatomic, nonnull) UIScrollView *scrollView;

/*! Initializes an instance of @C BFRImageViewController from the image source provided. The array can contain a mix of @c NSURL, @c UIImage, @c PHAsset, @c BFRBackLoadedImageSource or @c NSStrings of URLS. This can be a mix of all these types, or just one. */
- (id)initWithSourceImage:(UIImage*)image;
- (id)initWithSourceImageUrl:(NSURL*)url;

/*! Assigning YES to this property will make the background transparent. Default is NO. */
@property (nonatomic, getter=isUsingTransparentBackground) BOOL useTransparentBackground;

/*! Assigning YES to this property will disable long pressing media to present the activity view controller. Default is NO. */
@property (nonatomic) BOOL disableSharingLongPress;

/*! Flag property that toggles the doneButton. Defaults to YES */
@property (nonatomic) BOOL enableDoneButton;

/*! Flag property that sets the doneButton position (left or right side). Defaults to YES */
@property (nonatomic) BOOL showDoneButtonOnLeft;

/*! Dismiss properly with animations */
- (void)dismiss;

/*! Dismiss properly with animations and an optional completion handler */
- (void)dismissWithCompletion:(void (^ __nullable)(void))completion;

/*! Dismiss properly without custom animations */
- (void)dismissWithoutCustomAnimation;

/*! Dismiss properly without custom animations and an optional completion handler  */
- (void)dismissWithoutCustomAnimationWithCompletion:(void (^ __nullable)(void))completion;

@end

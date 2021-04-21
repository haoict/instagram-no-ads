#import "InstaZoomImageViewController.h"

@interface InstaZoomImageViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) UIImageView *imgView;

/*! This will automatically hide the "Done" button after five seconds. */
@property (strong, nonatomic, nullable) NSTimer *timerHideUI;

/*! The behavior which allows for the image to "snap" back to the center if it's vertical offset isn't passed the closing points. */
//@property (strong, nonatomic, nonnull) UIAttachmentBehavior *imgAttatchment;

/*! The animator which attaches the behaviors needed to drag the image. */
@property (strong, nonatomic, nonnull) UIDynamicAnimator *animator;

/*! The button that sticks to the top left of the view that is responsible for dismissing this view controller. */
@property (strong, nonatomic, nullable) UIButton *doneButton;

/*! This is used for nothing more than to defer the hiding of the status bar until the view appears to avoid any awkward jumps in the presenting view. */
@property (nonatomic, getter=shouldHideStatusBar) BOOL hideStatusBar;

@end

@implementation InstaZoomImageViewController

static CGPoint initialTouchPoint;

#pragma mark - Initializers

- (instancetype)initWithSourceImageUrl:(NSURL*)url {
    self = [super init];

    if (self) {
        // this isn't asynchronous. we may need to improve it https://stackoverflow.com/questions/1760857/iphone-how-to-get-a-uiimage-from-a-url
        NSData * data = [NSData dataWithContentsOfURL:url];
        UIImage * image = [UIImage imageWithData:data];
        if (image) {
            self.image = image;
        }
        else {
            // Failed (load an error image?)
        }

        [self commonInit];
    }

    return self;
}

- (instancetype)initWithSourceImage:(UIImage*)image {
    self = [super init];

    if (self) {
        self.image = image;
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    //self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //self.modalPresentationStyle = UIModalPresentationFullScreen;
    self.enableDoneButton = YES;
    self.showDoneButtonOnLeft = YES;
    self.disableSharingLongPress = NO;
    initialTouchPoint = CGPointMake(0,0);
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // View setup
    self.view.backgroundColor = [UIColor blackColor];

    // Scrollview (for pinching in and out of image)
    [self addChromeToUI];
    self.scrollView = [self createScrollView];
    [self.view addSubview:self.scrollView];


    // Animator - used to snap the image back to the center when done dragging
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.scrollView];

    [self addImageToScrollView];

    if (!self.image) {
        UILabel *errorMessage = [[UILabel alloc] initWithFrame:self.view.bounds];
        errorMessage.text = @"Error loading image";
        errorMessage.textAlignment = NSTextAlignmentCenter;
        errorMessage.textColor = [UIColor whiteColor];

        [self.view addSubview:errorMessage];
    }
}

- (void)addChromeToUI {
    if (self.enableDoneButton) {
        //NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        //NSString *imagePath = [bundle pathForResource:@"cross" ofType:@"png"];
        //UIImage *crossImage = [[UIImage alloc] initWithContentsOfFile:imagePath];

        self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGFloat buttonX = self.showDoneButtonOnLeft ? 20 : CGRectGetMaxX(self.view.bounds) - 37;
        CGFloat closeButtonY = 40;

        if (@available(iOS 11.0, *)) {
            closeButtonY = self.view.safeAreaInsets.top > 0 ? self.view.safeAreaInsets.top : 40;
        }

        self.doneButton.frame = CGRectMake(buttonX, closeButtonY, 70, 30);
        [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.doneButton.backgroundColor = [UIColor grayColor];
        //self.doneButton.layer.borderColor = [UIColor blackColor].CGColor;
        self.doneButton.layer.borderWidth = 0.0;
        self.doneButton.layer.cornerRadius = 10.0f;

        [self.doneButton setTitle:@"Close" forState:UIControlStateNormal];
        //[self.doneButton setImage:crossImage forState:UIControlStateNormal];
        [self.doneButton addTarget:self action:@selector(handleDoneAction) forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:self.doneButton];
        //[self updateChromeFrames];
    }
}
//
// - (void)updateChromeFrames {
//     if (self.enableDoneButton) {
//         CGFloat buttonX = self.showDoneButtonOnLeft ? 20 : CGRectGetMaxX(self.view.bounds) - 37;
//         CGFloat closeButtonY = 20;
//
//         if (@available(iOS 11.0, *)) {
//             closeButtonY = self.view.safeAreaInsets.top > 0 ? self.view.safeAreaInsets.top : 20;
//         }
//
//         self.doneButton.frame = CGRectMake(buttonX, closeButtonY, 17, 17);
//     }
// }

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.hideStatusBar = YES;
    [UIView animateWithDuration:0.1 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)viewWillLayoutSubviews {
    // Scrollview
    [self.scrollView setFrame:self.view.bounds];

    // Set the aspect ratio of the image
    float hfactor = self.image.size.width / self.view.bounds.size.width;
    float vfactor = self.image.size.height /  self.view.bounds.size.height;
    float factor = fmax(hfactor, vfactor);

    // Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = self.image.size.width / factor;
    float newHeight = self.image.size.height / factor;

    // Then figure out offset to center vertically or horizontally
    float leftOffset = (self.view.bounds.size.width - newWidth) / 2;
    float topOffset = ( self.view.bounds.size.height - newHeight) / 2;

    // Reposition image view
    CGRect newRect = CGRectMake(leftOffset, topOffset, newWidth, newHeight);

    // Check for any NaNs, which should get corrected in the next drawing cycle
    BOOL isInvalidRect = (isnan(leftOffset) || isnan(topOffset) || isnan(newWidth) || isnan(newHeight));
    self.imgView.frame = isInvalidRect ? self.view.bounds : newRect;
}

- (UIScrollView *)createScrollView {
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.delegate = self;
    sv.showsHorizontalScrollIndicator = NO;
    sv.showsVerticalScrollIndicator = NO;
    sv.decelerationRate = UIScrollViewDecelerationRateFast;
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    return sv;
}



- (void)addImageToScrollView {
  self.imgView = [[UIImageView alloc] initWithImage:self.image];
  self.imgView.frame = self.view.bounds;
  self.imgView.clipsToBounds = YES;
  self.imgView.userInteractionEnabled = YES;
  self.imgView.contentMode = UIViewContentModeScaleAspectFit;
  self.imgView.backgroundColor = [UIColor clearColor];

  // Reset the image on double tap
  UITapGestureRecognizer *doubleImgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recenterImageOriginOrZoomToPoint:)];
  doubleImgTap.numberOfTapsRequired = 2;
  [self.view addGestureRecognizer:doubleImgTap];

  // Share options
  if (!self.disableSharingLongPress) {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleShareLongPress:)];
      [self.view addGestureRecognizer:longPress];
  }

  //[self addChromeToUI];
  // Dragging to dismiss
  UIPanGestureRecognizer *panImg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
  panImg.delegate = self;
  [self.view addGestureRecognizer:panImg];


  [self.scrollView addSubview:self.imgView];
  [self.view bringSubviewToFront:self.doneButton];
  [self setMaxMinZoomScalesForCurrentBounds];
}



#pragma mark - Gesture Recognizer Delegate

// If we have more than one image, this will cancel out dragging horizontally to make it easy to navigate between images
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
    return (self.scrollView.zoomScale <= self.scrollView.minimumZoomScale) && (fabs(velocity.y) > fabs(velocity.x));
}

#pragma mark - Scrollview Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.scrollView.subviews.firstObject;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self.animator removeAllBehaviors];
    [self centerScrollViewContents];
}

#pragma mark - Scrollview Util Methods

/*! This calculates the correct zoom scale for the scrollview once we have the image's size */
- (void)setMaxMinZoomScalesForCurrentBounds {

    // Sizes
    CGSize boundsSize = self.scrollView.bounds.size;
    CGSize imageSize = self.imgView.frame.size;

    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);

    // Calculate Max
    CGFloat maxScale = self.scrollView.maximumZoomScale;
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];

        if (maxScale < minScale) {
            maxScale = minScale * 2;
        }
    }

    // Apply zoom
    self.scrollView.maximumZoomScale = maxScale;
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.zoomScale = minScale;
}

/*! Called during zooming of the image to ensure it stays centered */
- (void)centerScrollViewContents {
    self.scrollView.maximumZoomScale = 10.0f;
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imgView.frame;

    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }

    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }

    self.imgView.frame = contentsFrame;
}

/*! Called when an image is double tapped. Either zooms out or to specific point */
- (void)recenterImageOriginOrZoomToPoint:(UITapGestureRecognizer *)tap {
    self.scrollView.maximumZoomScale = 2.0f;
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        // Zoom out since we zoomed in here
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else {
        //Zoom to a point
        CGPoint touchPoint = [tap locationInView:self.scrollView];
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    }
}

#pragma mark - Dragging and Long Press Methods
/*! This method has three different states due to the gesture recognizer. In them, we either add the required behaviors using UIDynamics, update the image's position based off of the touch points of the drag, or if it's ended we snap it back to the center or dismiss this view controller if the vertical offset meets the requirements. */
- (void)handleDrag:(UIPanGestureRecognizer *)recognizer {

    CGPoint touchPoint = [recognizer locationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        initialTouchPoint = touchPoint;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.view.frame = CGRectOffset(self.view.frame,0,touchPoint.y - initialTouchPoint.y);
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (fabs(velocity.y) > 400.0f)
        {
          [self dismiss];
        } else {
          	[UIView animateWithDuration:0.3 animations:^{ self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);}
          	 completion:nil];
        }
        initialTouchPoint = CGPointMake(0,0);
    }
}

- (void)handleShareLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self presentActivityController];
    }
}

- (void)presentActivityController {
    id activityItem = self.image;
    if (activityItem == nil) return;

    UIActivityViewController *activityVC;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[activityItem] applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}


#pragma mark - Status bar

- (BOOL)prefersStatusBarHidden {
    if (self.presentingViewController.prefersStatusBarHidden) {
        return YES;
    }

    return self.shouldHideStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - Utility methods

- (void)dismiss {
    [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void (^ __nullable)(void))completion {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self dismissViewControllerAnimated:YES completion:completion];
}

- (void)dismissWithoutCustomAnimation {
    [self dismissWithoutCustomAnimationWithCompletion:nil];
}

- (void)dismissWithoutCustomAnimationWithCompletion:(void (^ __nullable)(void))completion {
    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_VC_SHOULD_CANCEL_CUSTOM_TRANSITION object:@(1)];

    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self dismissViewControllerAnimated:YES completion:completion];
}

- (void)handleDoneAction {
    [self dismissWithCompletion:nil];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

#pragma mark - Memory Considerations

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

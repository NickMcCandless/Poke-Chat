

#import <UIKit/UIKit.h>


@interface TGRImageViewController : UIViewController

// The scroll view used for zooming.
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

// The image view that displays the image.
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

// The image that will be shown.
@property (strong, nonatomic, readonly) UIImage *image;

// Initializes the receiver with the specified image.
- (id)initWithImage:(UIImage *)image;

@end

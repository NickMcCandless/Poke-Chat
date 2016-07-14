//
//  GalleryImageCell.h
//  photogallerytest
//
//  Created by K Rummler on 6/4/13.
//

#import <UIKit/UIKit.h>

@interface GalleryImageCell : UICollectionViewCell<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

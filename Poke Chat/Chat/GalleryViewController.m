//
//  GalleryViewController.m
//  photogallerytest
//
//  Created by K Rummler on 5/29/13.
//

#import "GalleryViewController.h"
#import "GalleryImageCell.h"

@interface GalleryViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;


@end

@implementation GalleryViewController

- (id)initWithImages:(NSArray*)images selected:(NSUInteger)selectedImage
{
    self = [super initWithNibName:@"GalleryViewController" bundle:nil];
    if (self) {
        self.images = images;
        self.selectedImage = selectedImage;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.navigationController.navigationBarHidden = TRUE;
    self.navigationController.hidesBarsOnTap = TRUE;
    self.navigationController.navigationBar.translucent = TRUE;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.frame = [[UIApplication sharedApplication] keyWindow].frame;
    UINib *cellNib = [UINib nibWithNibName:@"GalleryImageCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"galleryImageCell"];
    
    [self.collectionView setPagingEnabled:YES];
    
    self.collectionView.hidden = YES;
    [activity startAnimating];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self setSelectedImage:self.selectedImage];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = FALSE;
    self.navigationController.hidesBarsOnTap = FALSE;
}

#pragma mark - collectionView methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GalleryImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"galleryImageCell" forIndexPath:indexPath];
    cell.scrollView.zoomScale = 1.0;
    cell.imgView.image = [self.images objectAtIndex:indexPath.row];
    [self.collectionView addGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionView addGestureRecognizer:cell.scrollView.panGestureRecognizer];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(GalleryImageCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {

    [self.collectionView removeGestureRecognizer:cell.scrollView.pinchGestureRecognizer];
    [self.collectionView removeGestureRecognizer:cell.scrollView.panGestureRecognizer];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
}

- (void)setSelectedImage:(NSUInteger)selectedImage
{
    _selectedImage = selectedImage;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedImage inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically) animated:NO];
    self.collectionView.hidden = NO;
    activity.hidden = TRUE;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  MediaViewController.m
//  app
//
//  Created by Rakesh G. Bhatt on 30/12/14.
//  Copyright (c) 2014 KZ. All rights reserved.
//

#import "MediaViewController.h"
#import "CCellCollectionViewCell.h"
#import "GalleryViewController.h"

@interface MediaViewController ()

@end

@implementation MediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:[CCellCollectionViewCell class] forCellWithReuseIdentifier:@"CCell"];
    [self.collectionView reloadData];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [self.arrPhoto count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"CCell";
    CCellCollectionViewCell *cell = (CCellCollectionViewCell *)[cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.imgView.image = [self.arrPhoto objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    GalleryViewController *gallaryViewController = [[GalleryViewController alloc]initWithNibName:@"GalleryViewController" bundle:nil];
    gallaryViewController.images = self.arrPhoto;
    gallaryViewController.selectedImage = indexPath.row;
    [self.navigationController pushViewController:gallaryViewController animated:YES];
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float size =  (self.view.bounds.size.width * 0.87) / 3.0;
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    float padding =  self.view.bounds.size.width * 0.0312;
    return UIEdgeInsetsMake(padding, padding, padding, padding);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    float padding =  self.view.bounds.size.width * 0.0312;
    return padding;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

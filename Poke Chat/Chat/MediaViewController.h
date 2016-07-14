//
//  MediaViewController.h
//  app
//
//  Created by Rakesh G. Bhatt on 30/12/14.
//  Copyright (c) 2014 KZ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) NSArray *arrPhoto;
@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

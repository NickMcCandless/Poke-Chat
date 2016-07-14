//
//  CCellCollectionViewCell.m
//  app
//
//  Created by Rakesh G. Bhatt on 30/12/14.
//  Copyright (c) 2014 KZ. All rights reserved.
//

#import "CCellCollectionViewCell.h"

@implementation CCellCollectionViewCell

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"CCellCollectionViewCell" owner:self options:nil];
        self = [arrayOfViews objectAtIndex:0];
    }
    return self;
}

@end

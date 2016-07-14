//
//  NSString+Category.h
//  Poke Chat
//
//  Created by Prakhar Singh on 14/07/16.
//  Copyright © 2016 TAC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Category)
+ (NSString *) getUniqueDeviceIdentifier;
+ (NSString *) getUserId;
+ (NSString *)resourcePath:(NSString *)resourceName;

@end

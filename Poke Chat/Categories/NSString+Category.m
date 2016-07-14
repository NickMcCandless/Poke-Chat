//
//  NSString+Category.m
//  Poke Chat
//
//  Created by Prakhar Singh on 14/07/16.
//  Copyright © 2016 TAC. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "NSString+Category.h"
#import "SSKeychain.h"

@implementation NSString (Category)
+(NSString *) getUniqueDeviceIdentifier{
    NSString *appName=[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    NSString *strApplicationUUID = [SSKeychain passwordForService:appName account:@"incoding"];
    if (strApplicationUUID == nil){
        strApplicationUUID  = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [SSKeychain setPassword:strApplicationUUID forService:appName account:@"incoding"];
    }
    return strApplicationUUID;
}

+ (NSString *)resourcePath:(NSString *)resourceName{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:resourceName];
}

+ (NSString *) getUserId{
    return [[NSString getUniqueDeviceIdentifier] substringToIndex:6];
}
@end

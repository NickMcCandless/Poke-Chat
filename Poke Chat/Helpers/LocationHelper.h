//
//  LocationHelper.h
//  Poke Chat
//
//  Created by Prakhar Singh on 14/07/16.
//  Copyright © 2016 TAC. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface LocationHelper : NSObject<CLLocationManagerDelegate>
+(LocationHelper *)sharedInstance;
- (void) startLocationUpdate;
- (void) stopLocationUpdate;
- (void) findCoordinatesFromAddress:(NSDictionary *)dict;
@end

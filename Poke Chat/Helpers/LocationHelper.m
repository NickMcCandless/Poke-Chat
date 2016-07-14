//
//  LocationHelper.m
//  Poke Chat
//
//  Created by Prakhar Singh on 14/07/16.
//  Copyright © 2016 TAC. All rights reserved.
//

#import "LocationHelper.h"
#import "AppConstants.h"
static CLLocationManager *locManager = nil;
static BOOL stopped = NO;
@interface LocationHelper ()
@property (nonatomic, strong) NSTimer *locationTimer;
@end
@implementation LocationHelper

- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(instancetype) initUniqueInstance {
    [locManager setDelegate:self];
    return [super init];
}

+(LocationHelper *)sharedInstance {
    static dispatch_once_t pred;
    static LocationHelper *shared = nil;
    dispatch_once(&pred, ^{
        locManager = [[CLLocationManager alloc] init];
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

- (void) startLocationUpdate{
    if(stopped == NO){
        [self stopLocationUpdate];
    }
    stopped = NO;
    self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:100 target:self selector:@selector(locationFailed:) userInfo:nil repeats:NO];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([locManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locManager requestAlwaysAuthorization];
    }
#endif
    
    [locManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locManager startUpdatingLocation];
}

- (void) stopLocationUpdate{
    stopped = YES;
    [locManager stopUpdatingLocation];
}

- (void) findCoordinatesFromAddress:(NSDictionary *)dict{
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder geocodeAddressDictionary:dict completionHandler:^(NSArray *placemarks, NSError *error) {
        if(placemarks && [placemarks count] > 0){
            [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:[placemarks firstObject] userInfo:nil];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:error userInfo:nil];
        }
    }];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if(stopped)
        return;
    [self.locationTimer invalidate];
    CLLocation *loc = [locations lastObject];
    if (loc.horizontalAccuracy < 0) return;
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    [self stopLocationUpdate];
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        if(placemarks && [placemarks count] > 0){
            [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:[placemarks firstObject] userInfo:nil];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:error userInfo:nil];
        }
    }];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    //    CLLocationAccuracy accuracy = [manager desiredAccuracy];
    /*BOOL updateAgain = YES;
     if(accuracy == kCLLocationAccuracyBest){
     accuracy = kCLLocationAccuracyNearestTenMeters;
     }else if(accuracy == kCLLocationAccuracyNearestTenMeters){
     accuracy = kCLLocationAccuracyHundredMeters;
     }else if(accuracy == kCLLocationAccuracyHundredMeters){
     accuracy = kCLLocationAccuracyKilometer;
     }else if(accuracy == kCLLocationAccuracyKilometer){
     accuracy = kCLLocationAccuracyThreeKilometers;
     }else if(accuracy == kCLLocationAccuracyThreeKilometers){
     updateAgain = NO;
     }
     if(updateAgain){
     [locManager setDesiredAccuracy:accuracy];
     }else{*/
    if(stopped)
        return;
    [self.locationTimer invalidate];
    [self stopLocationUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:error userInfo:nil];
    //    }
}

- (void) locationFailed:(NSTimer *) aTimer{
    [aTimer invalidate];
    [self stopLocationUpdate];
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Failed to update user location." forKey:NSLocalizedDescriptionKey];
    NSError *eror = [NSError errorWithDomain:@"Location" code:NSIntegerMax userInfo:errorDetail];
    [[NSNotificationCenter defaultCenter] postNotificationName:LocationManagerUpdatedLocation object:eror userInfo:nil];
}

@end

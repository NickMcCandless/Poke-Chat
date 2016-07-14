//
//  ViewController.m
//  Poke Chat
//
//  Created by Prakhar Singh on 14/07/16.
//  Copyright © 2016 TAC. All rights reserved.
//

#import "AppConstants.h"
#import "LocationHelper.h"
#import "ViewController.h"
#import "SVProgressHUD.h"
#import "ChatView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:LocationManagerUpdatedLocation object:nil];
    
    [SVProgressHUD show];
    [[LocationHelper sharedInstance] startLocationUpdate];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSNotifications

- (void) locationUpdated:(NSNotification *) aNotification{
    [SVProgressHUD dismiss];
    id obj  = [aNotification object];
    if([obj isKindOfClass:[NSError class]]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please make sure your location settings are turn on" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [SVProgressHUD show];
            [[LocationHelper sharedInstance] startLocationUpdate];
        }];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    }else{
        NSString *zipcode = ((CLPlacemark *) obj).postalCode;
        NSString *roomId = [NSString stringWithFormat:@"%@xxx", [zipcode substringToIndex:[zipcode length]-3]];
        //---------------------------------------------------------------------------------------------------------------------------------------------
        ChatView *chatView = [[ChatView alloc] initWith:roomId];
        chatView.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:chatView animated:YES];
    
    }
}


@end

//
// Copyright (c) 2014 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"
#import "NSString+Category.h"

#import "AppConstants.h"
#import <AsyncImageView/AsyncImageView.h>
#import "LocationHelper.h"
#import "TGRImageViewController.h"
#import "ChatView.h"
#import "MediaViewController.h"
#import "GalleryViewController.h"
#import "ios-ntp.h"
static NSDateFormatter *formatter = nil;

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatView()
{
    NSString *roomId;
    
    BOOL initialized;
    FirebaseHandle handle;
    
    NSMutableArray *mediaImage;
    
    NSMutableArray *messages;
    NSMutableDictionary *avatars;
    
    JSQMessagesBubbleImage *outgoingBubbleImageData;
    JSQMessagesBubbleImage *incomingBubbleImageData;
    
    JSQMessagesAvatarImage *placeholderImageData;
    UIImagePickerController *imagePickerController;
    BOOL showingOtherView;
    NSIndexPath *idPath;
}
@property (nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic, strong) NSString *roomDocPath;;
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ChatView

//+(void)deleteFileWithName:(NSString *)urlStr{
//    urlStr = [NSString stringWithFormat: @"https://api.parse.com/1/files/%@", [urlStr lastPathComponent]];
//    NSURL* url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
//    //    [ProgressHUD show:@""];
//    [req setHTTPMethod:@"DELETE"];
//    [req setValue:kParseApplicationKey forHTTPHeaderField:@"X-Parse-Application-Id"];
//    [req setValue:kParseMasterKey forHTTPHeaderField:@"X-Parse-Master-Key"];
//    [req setValue:kParseClientKey forHTTPHeaderField:@"X-Parse-Client-Key"];
//    
//    NSLog(@"Updating file: %@", urlStr);
//    [NSURLConnection sendAsynchronousRequest:req
//                                       queue:[NSOperationQueue currentQueue]
//                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//                               if (connectionError) {
//                                   NSLog(@"Error");
//                               }else
//                                   NSLog(@"Deleted old file");
//                               //                               PFFile* file = [PFFile fileWithName:name data:imageData];
//                               //                               [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                               //                                   NSLog(@"Saved new file");
//                               //                                   completion(file);
//                               //                               }];
//                               
//                           }];
//}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)roomId_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    self = [super init];
    roomId = roomId_;
    return self;
}

- (NSString *)roomDocPath{
    if(_roomDocPath == nil){
        NSString *str = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _roomDocPath = [str stringByAppendingPathComponent:[roomId stringByReplacingOccurrencesOfString:@"-" withString:@""]];
        BOOL isDirectory = YES;
        BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:_roomDocPath isDirectory:&isDirectory];
        if(success == NO){
            success = [[NSFileManager defaultManager] createDirectoryAtPath:_roomDocPath withIntermediateDirectories:YES attributes:nil error:nil];
            NSLog(@"%@",success ? @"Created" : @"Not Created");
        }
    }
    return _roomDocPath;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [super viewDidLoad];
    AsyncImageView *imgView = [[AsyncImageView alloc] init];
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [imgView setFrame:CGRectMake(0, 0, 40, 40)];
    imgView.layer.cornerRadius = imgView.frame.size.width/2;
    imgView.layer.masksToBounds = YES;
    NSString *imageURL = (_chatImage == nil) ? @"" : _chatImage;
//    [imgView setImageURL:[imageURL shouldLoadProfileImage] ? [NSURL fileURLWithPath:[NSString resourcePath:DEFAULT_PROFILE_PIC]] : [NSURL URLWithString:imageURL]];
//    [imgView loadInBackground];
    [imgView setImageURL:[NSURL fileURLWithPath:[NSString resourcePath:DEFAULT_PROFILE_PIC]]];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:[imgView frame]];
    [btn addSubview:imgView];
    [btn addTarget:self action:@selector(chatImageClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:btnItem];
    
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [imagePickerController setAllowsEditing:YES];
    [imagePickerController setDelegate:self];
    messages = [[NSMutableArray alloc] init];
    avatars = [[NSMutableDictionary alloc] init];
    mediaImage = [[NSMutableArray alloc] init];
//    PFUser *user = [PFUser currentUser];
    self.senderId = [NSString getUserId];
    self.senderDisplayName = [NSString getUserId];
    //    if([_message[PF_MESSAGES_DESCRIPTION] isEqualToString:@"Private"]){
    //        if([[_message[PF_MESSAGES_USER] objectId] isEqualToString:[PFUser currentUser].objectId]){
    //            self.title = _message[PF_MESSAGES_OTHERUSER];
    //        }else{
    //            self.title = [PFUser currentUser][PF_USER_FULLNAME];
    //        }
    //    }else{
    //        self.title = _message[PF_MESSAGES_DESCRIPTION];
    //    }
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    placeholderImageData = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"chat_blank"] diameter:30.0];
    //    PFFile *file = user[PF_USER_THUMBNAIL];
    //    if(file){
    //        UIImage *img = [UIImage imageWithData:[file getData]];
    //        avatars[self.senderId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:img diameter:30.0];
    //    }else{
    //        avatars[self.senderId] = placeholderImageData;
    //    }
    //    if(_receiver){
    //        [_receiver fetchIfNeeded];
    //        file = _receiver[PF_USER_THUMBNAIL];
    //        if(file){
    //            UIImage *img = [UIImage imageWithData:[file getData]];
    //            avatars[_receiver.objectId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:img diameter:30.0];
    //
    //        }else{
    //            avatars[_receiver.objectId] = placeholderImageData;
    //        }
    //    }
    [self loadMessages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:LocationManagerUpdatedLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatRoomCreated:) name:ChatRoomCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userActionsUpdated:) name:USER_ACTIONS_UPDATE object:nil];
//    ClearMessageCounter(_message);
}

- (void) dealloc{
    [self.firebase removeAllObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) userActionsUpdated:(NSNotification *) aNotification{
//    NSDictionary *object = [aNotification object];
//    if([[object objectForKey:@"receiverId"] isEqualToString:[NSString getUserId]]){
////        [_user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
////            if (error == nil) {
////                [self updateActionButtons];
////            }
////        }];
//        [self.view endEditing:YES];
//        UILabel *lbl = (UILabel *)[self.view viewWithTag:999];
//        if([[object objectForKey:@"action"] isEqualToString:PF_BLOCK_OR_FOLLOW_USERS_ACTION_BLOCK]){
//            if(lbl == nil){
//                lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//                [lbl setTag:999];
////                [lbl.layer setBorderWidth:30];
////                [lbl.layer setBorderColor:[UIColor customRed].CGColor];
//                [lbl setBackgroundColor:[UIColor customRed]];
//                [lbl setAlpha:0.9];
//                [lbl setTextColor:[UIColor customYellow]];
//                [lbl setNumberOfLines:0];
//                [lbl setTextAlignment:NSTextAlignmentCenter];
//                [lbl setFont:[UIFont boldSystemFontOfSize:18.0]];
//                [lbl setText:@"You can not send any messages now as!you are blocked."];
//                [lbl setUserInteractionEnabled:NO];
//            }
//            [self.view addSubview:lbl];
//        }else if([[object objectForKey:@"action"] isEqualToString:PF_BLOCK_OR_FOLLOW_USERS_ACTION_UNBLOCK]){
//            if (lbl != nil) {
//                [lbl removeFromSuperview];
//            }
//        }
//    }
}

- (void) chatRoomCreated:(NSNotification *) aNotification{
//    if (_message == nil) {
//        PFObject *msg = (PFObject *)[aNotification object];
//        if(msg){
//            if([msg[PF_MESSAGES_ROOMID] isEqualToString:roomId]){
//                [SVProgressHUD dismiss];
//                self.message = msg;
//            }
//        }else{
//            [SVProgressHUD showErrorWithStatus:@"Error Occurred!"];
//            [self.navigationController popViewControllerAnimated:YES];
//        }
//    }
}

- (void) locationUpdated:(NSNotification *) aNotification{
    id obj  = [aNotification object];
    if([obj isKindOfClass:[NSError class]]){
        
    }else{
        [self sendLocation:obj];
    }
}

- (void) sendLocation:(CLLocation *) loc{
    Firebase *fb = [self.firebase childByAutoId];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *currentServerDate = [[NetworkClock sharedNetworkClock] networkTime];
    NSString *dateStr = [formatter stringFromDate:currentServerDate];
    id obj = @{@"location":[NSString stringWithFormat:@"%f:%f",[loc coordinate].latitude,[loc coordinate].longitude], @"userId":self.senderId, @"date":dateStr, @"name":self.senderDisplayName};
    [fb setValue:obj];
    NSString *text = nil;
//    text = @"Sent an Image.";
    //---------------------------------------------------------------------------------------------------------------------------------------------
    
    //    if([type isEqualToString:@"picture"]){
    //
    //    }else if ([type isEqualToString:@"video"]){
    //
    //    }else{
    //        [type ];
    //    }
    if (text == nil || [text isEqualToString:@""]) {
        text = [NSString stringWithFormat:@"%@ shared his location.", self.senderDisplayName];
    }
    if(_group == NO){
//        SendPushNotification(_message, text);
//        UpdateMessageCounter(_message, text);
    }
    //---------------------------------------------------------------------------------------------------------------------------------------------
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessage];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [super viewDidAppear:animated];
    if(!showingOtherView)
        self.collectionView.collectionViewLayout.springinessEnabled = NO;
    showingOtherView = NO;

}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [super viewWillDisappear:animated];
    if(!showingOtherView){
        //        if([_message[PF_MESSAGES_STARTED] boolValue] == NO){
        //            DeleteMessageItem(_message);
        //        }
        [self.firebase removeAllObservers];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - Backend methods

- (void) registerFirebase{
    [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
     {
         NSString *userId = nil;
         NSString *name = nil;
         NSDate *date = nil;
         NSString *text = nil;
         NSString *location = nil;
         NSString *mediaURL = nil;
         NSString *mediaType = nil;
         NSDictionary *dict = snapshot.value;
         for (NSString *key in [dict allKeys]) {
             @autoreleasepool {
                 if([key isEqualToString:@"userId"]){
                     userId = [dict objectForKey:key];
                 }else if([key isEqualToString:@"name"] || [key isEqualToString:@"userName"]){
                     name = [dict objectForKey:key];
                 }else if([key isEqualToString:@"date"]){
                     NSString *dateStr = [dict objectForKey:key];
                     if (formatter == nil) {
                         formatter = [[NSDateFormatter alloc] init];
                         [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                     }
                     [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
                     date = [formatter dateFromString:dateStr];
                     if(date == nil){
                         [formatter setDateFormat:@"dd MMM yyyy HH:mm:ss zzz"];
                         date = [formatter dateFromString:dateStr];
                     }
                 }else if([key isEqualToString:@"text"]){
                     text = [dict objectForKey:key];
                 }else if([key isEqualToString:@"picture"] || [key isEqualToString:@"video"]){
                     mediaURL = [dict objectForKey:key];
                     mediaType = key;
                 }else if([key isEqualToString:@"location"]){
                     location = [dict objectForKey:key];
                     mediaType = key;
                 }
             }
         }
         if([mediaType isEqualToString:@"picture"]){
             JSQPhotoMediaItem *mediaItem = [[JSQPhotoMediaItem alloc] initWithImage:nil];
             mediaItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
             JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name
                                                                   date:date media:mediaItem];
             [messages addObject:message];
             NSString *str = [self roomDocPath];
             NSString *name = [snapshot key];
             name = [name stringByReplacingOccurrencesOfString:@"-" withString:@""];
             name = [name stringByAppendingString:@".jpg"];
             str = [str stringByAppendingPathComponent:name];
             if ([[NSFileManager defaultManager] fileExistsAtPath:str]) {
                 UIImage *image = [UIImage imageWithContentsOfFile:str];
                 if(image == nil){
                     image = [UIImage imageNamed:@"noImage.png"];
                 }
                 mediaItem.image = image;
                 [mediaImage addObject:str];
                 [self.collectionView reloadData];
             }else{
                 NSURL *url = [NSURL URLWithString:[mediaURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                 NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:BundleID];
                 dispatch_queue_t backgroundQueue =  dispatch_queue_create([bundleID UTF8String], 0);
                 dispatch_async(backgroundQueue, ^{
                     NSData *imageData = [NSData dataWithContentsOfURL:url];
                     if(imageData){
                         dispatch_async(dispatch_get_main_queue(), ^{
                             if(imageData)
                                 mediaItem.image = [UIImage imageWithData:imageData];
                             else
                                 mediaItem.image = [UIImage imageNamed:@"noImage.png"];
                             NSError *error = nil;
                             BOOL success = [imageData writeToFile:str options:NSDataWritingAtomic error:&error];
                             if(success){
//                                 [ChatView deleteFileWithName:mediaURL];
                                 [mediaImage addObject:str];
                             }else{
                                 NSLog(@"%@",[error localizedDescription]);
                             }
                             [self.collectionView reloadData];
                         });
                     }
                 });
             }
         }else if([mediaType isEqualToString:@"location"]){
             NSArray *loc = [location componentsSeparatedByString:@":"];
             float lat = [[loc firstObject] floatValue];
             float lng = [[loc lastObject] floatValue];
             CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
             JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
             locationItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
             JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name
                                                                   date:date media:locationItem];
             [messages addObject:message];
             [locationItem setLocation:location withCompletionHandler:^{
                 [self.collectionView reloadData];
             }];
             //             NSString *str = [self roomDocPath];
             //             NSString *name = [snapshot key];
             //             name = [name stringByReplacingOccurrencesOfString:@"-" withString:@""];
             //             name = [name stringByAppendingString:@".jpg"];
             //             str = [str stringByAppendingPathComponent:name];
             //             [mediaImage addObject:str];
         }else if(mediaType == nil){
             JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date text:text];
             [messages addObject:message];
         }
         
         if (initialized)
         {
             [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
             [self finishReceivingMessage];
         }
     }];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadMessages
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    initialized = NO;
    self.firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/%@", FIREBASE, roomId]];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    [self registerFirebase];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    handle = [self.firebase observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
              {
                  [self.firebase removeObserverWithHandle:handle];
                  
                  [self finishReceivingMessage];
                  [SVProgressHUD dismiss];
                  
                  initialized	= YES;
              }];
}

#pragma mark - JSQMessagesViewController method overrides

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *dateStr = [formatter stringFromDate:date];
    
    [[self.firebase childByAutoId] setValue:@{@"text":text, @"userId":senderId, @"date":dateStr, @"name":senderDisplayName}];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    if(_group == NO){
//        SendPushNotification(_message, [NSString stringWithFormat:@"%@: %@", self.senderDisplayName, text]);
//        UpdateMessageCounter(_message, text);
    }
    //---------------------------------------------------------------------------------------------------------------------------------------------
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessage];
}


- (void) updateMessages:(NSArray *) arr{
    Firebase *fb = [self.firebase childByAutoId];
    [fb setValue:[arr firstObject]];
    NSString *text = nil;
    text = [NSString stringWithFormat:@"%@: Sent an Image.",self.senderDisplayName];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    
    //    if([type isEqualToString:@"picture"]){
    //
    //    }else if ([type isEqualToString:@"video"]){
    //
    //    }else{
    //        [type ];
    //    }
    if (text == nil || [text isEqualToString:@""]) {
        text = [NSString stringWithFormat:@"You received a file from : %@", [[arr firstObject] objectForKey:@"name"]];
    }
    if(_group == NO){
//        SendPushNotification(_message, text);
//        UpdateMessageCounter(_message, text);
    }
    //---------------------------------------------------------------------------------------------------------------------------------------------
    
    NSString *str = [self roomDocPath];
    NSString *name = [fb key];
    name = [name stringByReplacingOccurrencesOfString:@"-" withString:@""];
    name = [name stringByAppendingString:@".jpg"];
    str = [str stringByAppendingPathComponent:name];
    
    NSData *data = [arr lastObject];
    [data writeToFile:str atomically:YES];
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessage];
}
//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressSendButton:(UIButton *)button withMessageMedia:(id)media type:(NSString *)type senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
//    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
//    NSString *dateStr = [formatter stringFromDate:date];
//    if([type isEqualToString:@"picture"]){
//        NSData *data = UIImageJPEGRepresentation(media, 0.5);
//        NSString *flName = @"picture.jpg";
//        PFFile *file = [PFFile fileWithName:flName data:data];
//        [SVProgressHUD showWithStatus:@"Sending..."];
//        //        [file save];
//        [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            [SVProgressHUD dismiss];
//            if(succeeded){
//                NSLog(@"%@",[file url]);
//                id onj = @{type:[file url], @"userId":senderId, @"date":dateStr, @"name":senderDisplayName};
//                NSArray *arr = [NSArray arrayWithObjects:onj, data, nil];
//                [self performSelector:@selector(updateMessages:) withObject:arr afterDelay:0.2];
//            }else{
//                NSLog(@"%@",[[error userInfo] objectForKey:@"error"]);
//                //                [SVProgressHUD dismissWithError:[[error userInfo] objectForKey:@"error"] afterDelay:ErrorDisplayTime];
//            }
//        }];
//        
//    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressAccessoryButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    //    NSLog(@"didPressAccessoryButton");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose from Gallery", @"Share Location", nil];
    actionSheet.tag = 101;
    [actionSheet showInView:self.view];
}

#pragma mark - JSQMessages CollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    return messages[indexPath.item];
}
//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    JSQMessage *message = messages[indexPath.item];
    if ([message.senderId isEqualToString:self.senderId])
    {
        return outgoingBubbleImageData;
    }
    return incomingBubbleImageData;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    /*JSQMessage *message = messages[indexPath.item];
     NSString *userId = [message senderId];
     
     if (avatars[userId] == nil)
     {
     PFQuery *query = [PFQuery queryWithClassName:PF_USER_CLASS_NAME];
     [query whereKey:PF_USER_OBJECTID equalTo:userId];
     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
     if (error == nil)
     {
     if ([objects count] != 0)
     {
     PFUser *user = [objects firstObject];
     PFFile *fileThumbnail = user[PF_USER_THUMBNAIL];
     [fileThumbnail getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error)
     {
     if (error == nil)
     {
     UIImage *image = [UIImage imageWithData:imageData];
     avatars[userId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:30.0];
     [self.collectionView reloadData];
     }
     else NSLog(@"Network error.");
     }];
     }
     }
     else NSLog(@"Network error.");
     }];
     return placeholderImageData;
     }
     else return avatars[userId];*/
    return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    if (indexPath.item % 3 == 0)
    {
        JSQMessage *message = messages[indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    JSQMessage *message = messages[indexPath.item];
    if ([message.senderId isEqualToString:self.senderId])
    {
        return nil;
    }
    
    if (indexPath.item - 1 > 0)
    {
        JSQMessage *previousMessage = messages[indexPath.item-1];
        if ([previousMessage.senderId isEqualToString:message.senderId])
        {
            return nil;
        }
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    return nil;
}

#pragma mark - UICollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    return [messages count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    JSQMessage *message = messages[indexPath.item];
    if ([message.senderId isEqualToString:self.senderId])
    {
        cell.textView.textColor = [UIColor blackColor];
    }
    else
    {
        cell.textView.textColor = [UIColor whiteColor];
    }
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    if (indexPath.item % 3 == 0)
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return 0.0f;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    JSQMessage *message = messages[indexPath.item];
    if ([message.senderId isEqualToString:self.senderId])
    {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0)
    {
        JSQMessage *previousMessage = messages[indexPath.item-1];
        if ([previousMessage.senderId isEqualToString:message.senderId])
        {
            return 0.0f;
        }
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    NSLog(@"didTapLoadEarlierMessagesButton");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
           atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didTapAvatarImageView");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView messagesCollectionViewCellDidHoldMessageBubble:(NSIndexPath *)indexPath
{
    NSLog(@"didHoldMessageBubble");
    JSQMessage *mesage = messages[indexPath.item];
    if([mesage isMediaMessage] && [[mesage media] isKindOfClass:[JSQPhotoMediaItem class]]){
        idPath = indexPath;
        UIActionSheet *actSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save", nil];
        [actSheet setTag:102];
        [actSheet showInView:self.view];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *mesage = messages[indexPath.item];
    if([mesage isMediaMessage]){
        if([[mesage media] isKindOfClass:[JSQPhotoMediaItem class]]){
            UIImageView *imageview = (UIImageView*)[[mesage media] mediaView];
            
            NSMutableArray *images = [NSMutableArray array];
            __block NSUInteger selected = 0;
            
            [mediaImage enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                UIImage *image = [UIImage imageWithContentsOfFile:obj];
                if(image == nil){
                    image = [UIImage imageNamed:@"noImage.png"];
                }
                NSData *data1 = UIImagePNGRepresentation(image);
                NSData *data2 = UIImagePNGRepresentation(imageview.image);
                if ([data1 isEqual:data2]) {
                    selected = idx;
                }
                if(image)
                    [images addObject:image];
            }];
            
            GalleryViewController *gallaryViewController = [[GalleryViewController alloc]initWithNibName:@"GalleryViewController" bundle:nil];
            gallaryViewController.images = images;
            gallaryViewController.selectedImage = selected;
            showingOtherView = YES;
            [self.navigationController pushViewController:gallaryViewController animated:YES];
        }else if([[mesage media] isKindOfClass:[JSQLocationMediaItem class]]){
//            JSQLocationMediaItem *locationItem = (JSQLocationMediaItem *)[mesage media];
//            NSString *className = NSStringFromClass([MapViewController class]);
//            UIWindow *backWindow = [UIApplication sharedApplication].windows[0];
//            UIStoryboard *storyBoard = backWindow.rootViewController.storyboard;
//            MapViewController *viewController = (MapViewController *)[storyBoard instantiateViewControllerWithIdentifier:className];
//            [viewController setLocation:[locationItem location]];
//            showingOtherView = YES;
//            [self.navigationController pushViewController:viewController animated:YES];
            //            [];
        }
    }
    
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    NSLog(@"didTapCellAtIndexPath %@", NSStringFromCGPoint(touchLocation));
//    if(_message == nil || [_message[PF_MESSAGES_DESCRIPTION] isEqualToString:@"Private"] == NO){
//        JSQMessage *mesage = messages[indexPath.item];
//        PFUser *user = [PFUser objectWithoutDataWithObjectId:mesage.senderId];
//        [self showUserProfile:user];
//    }
}

#pragma mark - UIActionSheet Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *pickedImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSDate *currentServerDate = [[NetworkClock sharedNetworkClock] networkTime];
    [self didPressSendButton:nil withMessageMedia:pickedImage type:@"picture" senderId:self.senderId senderDisplayName:self.senderDisplayName date:currentServerDate];
    showingOtherView = NO;
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if([actionSheet tag] == 101){
        if(buttonIndex == 0){
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.showsCameraControls = YES;
                [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
                self.overlayView.frame = imagePickerController.cameraOverlayView.frame;
                imagePickerController.cameraOverlayView = self.overlayView;
                self.overlayView = nil;
                showingOtherView = YES;
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
        }else if (buttonIndex == 1){
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                showingOtherView = YES;
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
        }else if (buttonIndex == 2){
            LocationHelper *location = [LocationHelper sharedInstance];
            [location startLocationUpdate];
        }
    }else if([actionSheet tag] == 102){
        if(buttonIndex == 0){
            JSQPhotoMediaItem *media = [messages[idPath.row] media];
            UIImage *img = [media image];
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        }
    }
}

#pragma mark - UI Navigation Item

//- (void) showUserProfile:(PFUser *)user{
//    ProfileView *prflView = [[ProfileView alloc] init];
//    [prflView setUser:user];
//    [self.navigationController pushViewController:prflView animated:YES];
//}
//
//- (void) chatImageClicked:(id)sender{
//    NSLog(@"I am clicked");
//    if([_message[PF_MESSAGES_DESCRIPTION] isEqualToString:@"Private"]){
//        PFUser *user = nil;
//        if([[_message[PF_MESSAGES_USER] objectId] isEqualToString:[PFUser currentUser].objectId]){
//            user = _message[PF_MESSAGES_OTHERUSER];
//        }else{
//            user = _message[PF_MESSAGES_USER];
//        }
//        [self showUserProfile:user];
//    }
//}

- (void) allMedia:(id)sender{
    NSMutableArray *images = [NSMutableArray array];
    
    [mediaImage enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIImage *image = [UIImage imageWithContentsOfFile:obj];
        if(image == nil){
            image = [UIImage imageNamed:@"noImage.png"];
        }
        [images addObject:image];
    }];
    
    MediaViewController *mediaViewController = [[MediaViewController alloc]initWithNibName:@"MediaViewController" bundle:nil];
    mediaViewController.arrPhoto = images;
    showingOtherView = YES;
    [self.navigationController pushViewController:mediaViewController animated:YES];
}
@end

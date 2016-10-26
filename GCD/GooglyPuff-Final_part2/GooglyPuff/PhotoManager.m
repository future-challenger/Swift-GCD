//  PhotoManager.m
//  PhotoFilter
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

@import CoreImage;
@import AssetsLibrary;
#import "PhotoManager.h"

@interface PhotoManager ()
@property (nonatomic, strong) NSMutableArray *photosArray;
@property (nonatomic, strong) dispatch_queue_t concurrentPhotoQueue;
@end

@implementation PhotoManager

+ (instancetype)sharedManager
{
    static PhotoManager *sharedPhotoManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPhotoManager = [[PhotoManager alloc] init];
        sharedPhotoManager->_photosArray = [NSMutableArray array];
        sharedPhotoManager->_concurrentPhotoQueue = dispatch_queue_create("com.selander.GooglyPuff.photoQueue",
                                                                          DISPATCH_QUEUE_CONCURRENT);
    });
    
    return sharedPhotoManager;
}

//*****************************************************************************/
#pragma mark - Unsafe Setter/Getters
//*****************************************************************************/

- (NSArray *)photos
{
    __block NSArray *array; // 1
    dispatch_sync(self.concurrentPhotoQueue, ^{ // 2
        array = _photosArray; // 3
    });
    return array;
}

- (void)addPhoto:(Photo *)photo
{
    if (photo) { // 1
        dispatch_barrier_async(self.concurrentPhotoQueue, ^{ // 2
            [_photosArray addObject:photo]; // 3
            dispatch_async(dispatch_get_main_queue(), ^{ // 4
                [self postContentAddedNotification]; // 5
            });
        });
    }
}

//*****************************************************************************/
#pragma mark - Public Methods
//*****************************************************************************/

- (void)downloadPhotosWithCompletionBlock:(BatchPhotoDownloadingCompletionBlock)completionBlock
{
    // 1
    __block NSError *error;
    dispatch_group_t downloadGroup = dispatch_group_create();
    
    for (NSInteger i = 0; i < 3; i++) {
        NSURL *url;
        switch (i) {
            case 0:
                url = [NSURL URLWithString:kOverlyAttachedGirlfriendURLString];
                break;
            case 1:
                url = [NSURL URLWithString:kSuccessKidURLString];
                break;
            case 2:
                url = [NSURL URLWithString:kLotsOfFacesURLString];
                break;
            default:
                break;
        }
        
        dispatch_group_enter(downloadGroup); // 2
        Photo *photo = [[Photo alloc] initwithURL:url
                              withCompletionBlock:^(UIImage *image, NSError *_error) {
                                  if (_error) {
                                      error = _error;
                                  }
                                  dispatch_group_leave(downloadGroup); // 3
                              }];
        
        [[PhotoManager sharedManager] addPhoto:photo];
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{ // 4
        if (completionBlock) {
            completionBlock(error);
        }
    });
}

//*****************************************************************************/
#pragma mark - Private Methods
//*****************************************************************************/

- (void)postContentAddedNotification
{
    static NSNotification *notification = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [NSNotification notificationWithName:kPhotoManagerAddedContentNotification object:nil];
    });
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end

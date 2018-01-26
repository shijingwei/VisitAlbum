//
//  ViewController.m
//  Funsnap_album
//
//  Created by ShiAwe on 1/20/18.
//  Copyright © 2018 awe. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVPlayerViewControllerDelegate>

@property (nonatomic,strong) NSString * assetIdentifier;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic,strong) AVPlayerViewController *playerController;
@property (strong, nonatomic) IBOutlet UIView *videoContainer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)createAlbum:(id)sender {
    
    //[PhotoTool saveAlbum:@"Funsnap"];
    
}
- (IBAction)saveImage:(id)sender {
    NSString * str  = [[NSBundle mainBundle] pathForResource:@"test2.png" ofType:nil ];
//    [PhotoTool saveTest:str];
    PhotoTool * photoTool = [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    if(![photoTool isPermmited]){
        //提示并返回
        return ;
    }

    [photoTool saveImageToAlbum:str withBlock:^(BOOL result, NSString * identifier) {
        NSLog(@"%@",identifier);
        self.assetIdentifier =identifier;
    }];
}
- (IBAction)getImage:(id)sender {
    
    //NSString * key =@"9A538FA7-4723-4F89-ADEB-0ABF9264D509/L0/001";

    PhotoTool * photoTool = [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    __weak __typeof__(self) weakSelf = self;
    [photoTool getImageFromAlbumId:self.assetIdentifier complete:^(UIImage *result) {
        
        if(!result) {
            NSLog(@"未发现");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.imageView.image = result;
        });
    }];
}
- (IBAction)deleteImage:(id)sender {
    
    PhotoTool * photoTool = [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    [photoTool deleteAlbumId:self.assetIdentifier];
}

- (IBAction)saveVideo:(id)sender {
    NSString * str  = [[NSBundle mainBundle] pathForResource:@"test1.mp4" ofType:nil ];
    PhotoTool * photoTool = [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    if(![photoTool isPermmited]){
        //提示并返回
        return;
    }
    [photoTool saveVideoToAlbum:str withBlock:^(BOOL result, NSString * identifier) {
        NSLog(@"Video %@",identifier);
        self.assetIdentifier =identifier;
    }];
}

- (IBAction)playback:(id)sender {
    
    PhotoTool * photoTool = [PhotoTool shareInstanceWithAlbum:@"Funsnap"];
    __weak __typeof__(self) weakSelf = self;
    [photoTool getVideoFromAlbumId:self.assetIdentifier complete:^(AVAsset *result) {
        
        if(!result) {
            NSLog(@"未发现");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf playbackItem: result];
        });
    }];
}

- (void)playbackItem:(AVAsset * )avasset {
    AVPlayerItem * playerItem = [AVPlayerItem playerItemWithAsset:avasset];
    self.playerController = [[AVPlayerViewController alloc] init];
    self.playerController.player = [AVPlayer playerWithPlayerItem:playerItem];
    //self.playerController.view.frame = self.videoContainer.frame;
    self.playerController.delegate = self;
    //[self.videoContainer addSubview:self.playerController.view];
    [self presentViewController:self.playerController animated:YES completion:nil];
    [self.playerController.player play];

}
- (IBAction)preview:(id)sender {
    
    NSString * str  = [[NSBundle mainBundle] pathForResource:@"test1.mp4" ofType:nil ];
    NSURL * playUrl = [NSURL  fileURLWithPath:str];
    NSLog(@"preview playurl = %@",playUrl);
    self.playerController = [[AVPlayerViewController alloc] init];
    self.playerController.player = [[AVPlayer alloc] initWithURL:playUrl];
    self.playerController.view.frame = self.view.frame;
    self.playerController.delegate = self;
    [self.view addSubview:self.playerController.view];
    [self.playerController.player play];
    //[self presentViewController:self.playerController animated:YES completion:nil];
}

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"playerViewControllerWillStartPictureInPicture");
}

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    NSLog(@"playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart");
    return YES;
}

@end

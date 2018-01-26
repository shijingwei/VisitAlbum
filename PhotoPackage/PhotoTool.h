//
//  PhotoTool.h
//  Funsnap_album
//
//  Created by ShiAwe on 1/20/18.
//  Copyright © 2018 awe. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Photos/Photos.h>

typedef void(^PhotoToolBlock)(PHAuthorizationStatus status);
typedef void(^PhotoToolSaveBlock)(BOOL result, NSString * identifier);

@interface PhotoTool : NSObject

-(void) saveImageToAlbum:(NSString *) filename withBlock:(PhotoToolSaveBlock) block;
-(void) saveVideoToAlbum:(NSString *) filename withBlock:(PhotoToolSaveBlock) block;

//-(PHFetchResult<PHAsset *> *) getFromId:(NSString *) identifier;
-(void) getImageFromAlbumId:(NSString *) identifier complete:(void(^)(UIImage * result))compete;
-(void) getVideoFromAlbumId:(NSString *) identifier complete:(void(^)(AVAsset * result))compete;
-(void) deleteAlbumId:(NSString *) identifier;

+(void) saveTest:(NSString * ) filename;

+(instancetype) shareInstanceWithAlbum:(NSString * )albumName;
-(BOOL) isPermmited;
-(void) requestPermmitWithBlock:(PhotoToolBlock) block;

//+(PHAssetCollection *) saveAlbum:(NSString *) name;
//+(void) saveImage:(NSString *) fileNmae;
//+(void) saveVideo:(NSString *) fileNmae;
//+(void) save:(NSString *) filename;
//+(void) saveTest:(NSString * ) filename;

@end

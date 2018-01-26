//
//  PhotoTool.m
//  Funsnap_album
//
//  Created by ShiAwe on 1/20/18.
//  Copyright © 2018 awe. All rights reserved.
//

#import "PhotoTool.h"

@interface PhotoTool()
@property (nonatomic,strong) NSString * albumName;

@property (nonatomic,assign) BOOL haspermit;
@end


@implementation PhotoTool

+(instancetype) shareInstanceWithAlbum:(NSString * )albumName {
    static PhotoTool * sharedSingleton;
    @synchronized(self)
    {
        if (!sharedSingleton){
            sharedSingleton = [[PhotoTool alloc] init];
        }
        sharedSingleton.albumName = albumName;
        //[sharedSingleton requestPermmit];
        return sharedSingleton;
    }
}

-(void) setAlbumName:(NSString *)albumName {
    _albumName = albumName;
    [self saveAndFindAlbum];
}

-(instancetype) init {
    if(self= [super init]) {
        self.haspermit = NO;
        [self requestPermmitWithBlock:nil];
    }
    return self;
    
}

-(PHFetchResult<PHAsset *> *) getFromId:(NSString *) identifier {
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    return assets;
}

//删除指定文件
-(void) deleteAlbumId:(NSString *) identifier {
    NSError * error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [PHAssetChangeRequest deleteAssets:[self getFromId:identifier]];
    } error:&error];
}

-(BOOL) isPermmited {
    PHAuthorizationStatus lastStatus = [PHPhotoLibrary authorizationStatus];
    self.haspermit = (lastStatus == PHAuthorizationStatusAuthorized);
    return lastStatus == PHAuthorizationStatusAuthorized;
    
}

//访问权限检查
-(void) requestPermmitWithBlock:(PhotoToolBlock) block {
    //__weak __typeof(self)weakSelf = self;
    //(1) 获取当前的授权状态
    PHAuthorizationStatus lastStatus = [PHPhotoLibrary authorizationStatus];
    if(lastStatus == PHAuthorizationStatusAuthorized){
        self.haspermit = YES;
        return;
    }
    
    //(2) 请求授权
    [PHPhotoLibrary requestAuthorization:block];
//     ^(PHAuthorizationStatus status) {
//        //回到主线程
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            if(status == PHAuthorizationStatusDenied) //用户拒绝（可能是之前拒绝的，有可能是刚才在系统弹框中选择的拒绝）
//            {
//                if (lastStatus == PHAuthorizationStatusNotDetermined) {
//                    //说明，用户之前没有做决定，在弹出授权框中，选择了拒绝
//                    NSLog(@"需要访问权限");
//                    return;
//                }
//
//                NSLog(@"需要访问权限");
//                // 说明，之前用户选择拒绝过，现在又点击保存按钮，说明想要使用该功能，需要提示用户打开授权
//                //[SVProgressHUD showInfoWithStatus:@"失败！请在系统设置中开启访问相册权限"];
//
//            }
//            else if(status == PHAuthorizationStatusAuthorized) //用户允许
//            {
//                //weakSelf.haspermit = YES;
//                //保存图片---调用上面封装的方法
//            }
//            else if (status == PHAuthorizationStatusRestricted)
//            {
//                //weakSelf.haspermit = NO;
//                NSLog(@"需要访问权限");
//                //[SVProgressHUD showErrorWithStatus:@"系统原因，无法访问相册"];
//            }
//        });
//    }];
    
}

//保存相册名称
-(PHAssetCollection *) saveAndFindAlbum {
    
    [self isPermmited];
    if(!self.haspermit) {
        return nil;
    }
    PHAssetCollection * createdCollection = nil;
    NSError * error;
    
    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:self.albumName]) {
            createdCollection = collection;
            break;
        }
    }
    
    if (!createdCollection) { // 没有创建过相册
        __block NSString *createdCollectionId = nil;
        // 创建一个新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:self.albumName].placeholderForCreatedAssetCollection.localIdentifier;
        } error: &error];
        
        if(error) {
            NSLog(@"创建相册失败 %@",error);
            return nil;
        }
        // 创建完毕后再取出相册
        createdCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
    }
    return createdCollection;
}

//保存照片到相册
-(void ) saveImageToAlbum:(NSString *) filename withBlock:(PhotoToolSaveBlock)block{
    [self saveToAlbum:filename isVideo:NO withBlock:block];
}

-(void) saveVideoToAlbum:(NSString *) filename withBlock:(PhotoToolSaveBlock)block {
    [self saveToAlbum:filename isVideo:YES withBlock:block];
}

-(void) saveToAlbum:(NSString *) filename isVideo:(BOOL) isvideo withBlock:(PhotoToolSaveBlock)block {
    
    __block NSString *createdAssetId = nil;
    // 添加图片到【相机胶卷】
    NSError * error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        if(isvideo){
            createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filename]].placeholderForCreatedAsset.localIdentifier;
        }else {
            createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:filename]].placeholderForCreatedAsset.localIdentifier;
        }
    } error:&error];
    
    if(error) {
        NSLog(@"保存到相册失败 %@",error);
        block(NO,nil);
        return;
    }
    
    
    // 在保存完毕后取出图片
    PHFetchResult<PHAsset *> *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
    
    // 获取软件的名字作为相册的标题
    NSString *title = self.albumName;
    
    // 已经创建的自定义相册
    PHAssetCollection *createdCollection = nil;
    
    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            createdCollection = collection;
            break;
        }
    }
    
    if (!createdCollection) { // 没有创建过相册
        __block NSString *createdCollectionId = nil;
        // 创建一个新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error: &error];
        
        if(error) {
            NSLog(@"创建相册失败 %@",error);
            block(NO,nil);
        }
        
        // 创建完毕后再取出相册
        createdCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
    }
    
    if (createdAssets == nil || createdCollection == nil) {
        block(NO,nil);
        return;
    }
    
    // 将刚才添加到【相机胶卷】的图片，引用（添加）到【自定义相册】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        // 自定义相册封面默认保存第一张图,所以使用以下方法把最新保存照片设为封面
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    if(error) {
        NSLog(@"引用到相册失败 %@",error);
        block(NO,nil);
    }else {
        block(YES,createdAssetId);
    }
}

//-(void) saveToAlbum:(NSString *) filename isVideo:(BOOL) isvideo withBlock:(PhotoToolSaveBlock)block {
//
//    if(!self.haspermit) {
//        return;
//    }
//
//    // 添加图片到【相机胶卷】
//    __block NSString *createdAssetId = nil;
//
//    NSError * error;
//    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
//        if(isvideo){
//            createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filename]].placeholderForCreatedAsset.localIdentifier;
//        }else {
//            createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:filename]].placeholderForCreatedAsset.localIdentifier;
//        }
//    } error:&error];
//
//    if(error) {
//        NSLog(@"保存到相册失败 %@",error);
//        block(NO,nil);
//        return;
//    }
//
//    __block PHAssetCollection * createdCollection = [self saveAndFindAlbum];
//    __block PHFetchResult<PHAsset *> *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
//
//    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
//        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection assets:createdAssets];
//        [request addAssets:createdAssets];
//        //[request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
//
//    } error:&error];
//
//    if(error) {
//        NSLog(@"保存到相册失败 %@",error);
//        block(NO,nil);
//        return;
//    }else {
//         block(YES,createdAssetId);
//    }
//
//}

-(void) getImageFromAlbumId:(NSString *) identifier complete:(void(^)(UIImage * result))compete {
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (!assets){
        compete(nil);
    }
    PHAsset * asset = assets.firstObject;
    if(!asset){
        compete(nil);
    }
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(400, 300) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        compete(result);
    }];
    
}

-(void) getVideoFromAlbumId:(NSString *) identifier complete:(void(^)(AVAsset * result))compete {
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (!assets){
        compete(nil);
    }
    PHAsset * asset = assets.firstObject;
    if(!asset){
        compete(nil);
    }
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        compete(asset);
    }];
    
}


////////////////////
//
//+(PHAssetCollection *) saveAlbum:(NSString *) name {
//
//    //相册
//    //2 获取与 APP 同名的自定义相册
//    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
//    for (PHAssetCollection *collection in collections) {
//        //遍历
//        if ([collection.localizedTitle isEqualToString:name]) {
//            //找到了同名的自定义相册--返回
//            return collection;
//        }
//    }
//
//    //说明没有找到，需要创建
//    NSError *error = nil;
//    __block NSString *createID = nil; //用来获取创建好的相册
//    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
//        //发起了创建新相册的请求，并拿到ID，当前并没有创建成功，待创建成功后，通过 ID 来获取创建好的自定义相册
//        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
//        createID = request.placeholderForCreatedAssetCollection.localIdentifier;
//    } error:&error];
//    if (error) {
//        NSLog(@"保存失败, %@",error);
//        return nil;
//    }else{
//        NSLog(@"保存成功");
//        //通过 ID 获取创建完成的相册 -- 是一个数组
//        return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createID] options:nil].firstObject;
//    }
//
//}

//+(void) saveImage:(NSString *) fileNmae {
//
//    //异步保存图片
//        //1 必须在 block 中调用
//
//    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//        //2 异步执行保存图片操作
//        NSString * createdAssetID = [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithContentsOfFile:fileNmae]].placeholderForCreatedAsset.localIdentifier;
//
//        //获取保存到系统相册成功后的 asset 对象集合，并返回
//        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
//        if(assets==nil){
//            NSLog(@"assets is null");
//        }
//
//        __block PHAssetCollection *assetCollection = [PhotoTool saveAlbum:@"Funsnap"];
//        if (assetCollection == nil) {
//
//            return;
//        }
//
//        NSLog(@"collectiong: %@",assetCollection.localIdentifier);
//
//        //NSError *inerror = nil;
//        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//            //--告诉系统，要操作哪个相册
//            NSLog(@"collectiong: %@",assetCollection.localizedTitle);
//            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
//            //--添加图片到自定义相册--追加--就不能成为封面了
//            //[collectionChangeRequest addAssets:assets];
//            [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
//
//        } completionHandler:^(BOOL success, NSError * _Nullable error) {
//            if(error)
//                NSLog(@"2 error: %@",error);
//        }];
//
//
//    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//        if(error) {
//            NSLog(@"1 error: %@",error);
//        }
//
//    }];
////                                             completionHandler:^(BOOL success, NSError * _Nullable error) {
////            //3 保存结束后，回调
////            if (error) {
////                NSLog(@"保存失败, %@",error);
////            }else
////                NSLog(@"保存成功");
////        }];
//
//}

//+(void)save:(NSString *) filename
//{
//    //(1) 获取当前的授权状态
//    PHAuthorizationStatus lastStatus = [PHPhotoLibrary authorizationStatus];
//
//    //(2) 请求授权
//    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//        //回到主线程
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            if(status == PHAuthorizationStatusDenied) //用户拒绝（可能是之前拒绝的，有可能是刚才在系统弹框中选择的拒绝）
//            {
//                if (lastStatus == PHAuthorizationStatusNotDetermined) {
//                    //说明，用户之前没有做决定，在弹出授权框中，选择了拒绝
//                    //[SVProgressHUD showErrorWithStatus:@"保存失败"];
//                    return;
//                }
//                // 说明，之前用户选择拒绝过，现在又点击保存按钮，说明想要使用该功能，需要提示用户打开授权
//                //[SVProgressHUD showInfoWithStatus:@"失败！请在系统设置中开启访问相册权限"];
//
//            }
//            else if(status == PHAuthorizationStatusAuthorized) //用户允许
//            {
//                //保存图片---调用上面封装的方法
//                [PhotoTool saveImage:filename];
//            }
//            else if (status == PHAuthorizationStatusRestricted)
//            {
//                //[SVProgressHUD showErrorWithStatus:@"系统原因，无法访问相册"];
//            }
//        });
//    }];
//}

//+(void) saveVideo:(NSString *) fileNmae {
//    
//}
//
//
+(void) saveTest:(NSString * ) filename {
    __block NSString *createdAssetId = nil;
    // 添加图片到【相机胶卷】
    NSError * error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:filename]].placeholderForCreatedAsset.localIdentifier;
    } error:&error];
    
    if(error) {
        NSLog(@"保存到相册失败 %@",error);
    }
    
    
    // 在保存完毕后取出图片
    PHFetchResult<PHAsset *> *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
    
    // 获取软件的名字作为相册的标题
    NSString *title = @"Funsnap";
    
    // 已经创建的自定义相册
    PHAssetCollection *createdCollection = nil;
    
    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            createdCollection = collection;
            break;
        }
    }
    
    if (!createdCollection) { // 没有创建过相册
        __block NSString *createdCollectionId = nil;
        // 创建一个新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error: &error];
        
        if(error) {
            NSLog(@"创建相册失败 %@",error);
        }
        
        
        // 创建完毕后再取出相册
        createdCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
    }
    
    if (createdAssets == nil || createdCollection == nil) {
        
        return;
    }
    
    // 将刚才添加到【相机胶卷】的图片，引用（添加）到【自定义相册】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        // 自定义相册封面默认保存第一张图,所以使用以下方法把最新保存照片设为封面
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    if(error) {
        NSLog(@"引用到相册失败 %@",error);
    }
    
}

- (void)getOriginalImages
{
    // 获得所有的自定义相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    // 遍历所有的自定义相簿
    for (PHAssetCollection *assetCollection in assetCollections) {
        [self enumerateAssetsInAssetCollection:assetCollection original:YES];
    }
    
    // 获得相机胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    // 遍历相机胶卷,获取大图
    [self enumerateAssetsInAssetCollection:cameraRoll original:YES];
}


- (void)getThumbnailImages
{
    // 获得所有的自定义相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    // 遍历所有的自定义相簿
    for (PHAssetCollection *assetCollection in assetCollections) {
        [self enumerateAssetsInAssetCollection:assetCollection original:NO];
    }
    // 获得相机胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    [self enumerateAssetsInAssetCollection:cameraRoll original:NO];
}

/**
 *  遍历相簿中的所有图片
 *  @param assetCollection 相簿
 *  @param original        是否要原图
 */
- (void)enumerateAssetsInAssetCollection:(PHAssetCollection *)assetCollection original:(BOOL)original {
    NSLog(@"相簿名:%@", assetCollection.localizedTitle);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = YES;
    
    // 获得某个相簿中的所有PHAsset对象
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    for (PHAsset *asset in assets) {
        // 是否要原图
        CGSize size = original ? CGSizeMake(asset.pixelWidth, asset.pixelHeight) : CGSizeZero;
        
        // 从asset中获得图片
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            NSLog(@"%@", result);
        }];
    }
}


@end

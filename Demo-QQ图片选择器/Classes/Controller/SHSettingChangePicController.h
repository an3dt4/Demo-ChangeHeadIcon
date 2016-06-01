//
//  SHSettingChangePicController.h
//  Demo-QQ图片选择器
//
//  Created by Suning on 16/5/30.
//  Copyright © 2016年 jf. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "JKAssets.h"

typedef NS_ENUM(NSUInteger, SHSettingChangePicControllerFilterType) {
    SHSettingChangePicControllerFilterTypeNone,
    SHSettingChangePicControllerFilterTypePhotos,
    SHSettingChangePicControllerFilterTypeVideos
};

UIKIT_EXTERN ALAssetsFilter * SHSettingChangePicControllerAssertFilterType(SHSettingChangePicControllerFilterType type);

@class SHSettingChangePicController;

@protocol SHSettingChangePicControllerDelegate <NSObject>

@optional
- (void)imagePickerController:(SHSettingChangePicController *)imagePicker didSelectAsset:(JKAssets *)asset isSource:(BOOL)source;
- (void)imagePickerController:(SHSettingChangePicController *)imagePicker didSelectAssets:(NSArray *)assets isSource:(BOOL)source;
- (void)imagePickerControllerDidCancel:(SHSettingChangePicController *)imagePicker;
/** 点击单张图片事件 */
- (void)imagePickerController:(SHSettingChangePicController *)imagePicker didSelectAsset:(ALAsset *)asset;

@end

@interface SHSettingChangePicController : UIViewController

@property (nonatomic, weak) id<SHSettingChangePicControllerDelegate> delegate;
@property (nonatomic, assign) BOOL showsCancelButton;
@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;
@property (nonatomic, strong) NSMutableArray     *selectedAssetArray;
@property (nonatomic ,strong) NSMutableArray *selectedPhotos;
/** 类型选择，这里只是图片，没有视频 */
@property (nonatomic, assign) SHSettingChangePicControllerFilterType typeFilter;

@end

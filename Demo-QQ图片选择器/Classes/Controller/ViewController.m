//
//  ViewController.m
//  Demo-CALayerTest
//
//  Created by Suning on 16/3/29.
//  Copyright © 2016年 jf. All rights reserved.
//

#import "ViewController.h"
#import "UIView+Frame.h"
#import "JKImagePickerController.h"
#import "SHSettingChangePicController.h"
#import "SHSettingImageEditController.h"

#define mScreenWidth    [UIScreen mainScreen].bounds.size.width
#define mScreenHeight   [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<SHSettingChangePicControllerDelegate>

@property(nonatomic,strong) UIImage *portraitImg;

@property(nonatomic,strong) UIImageView *tempImgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"图片选择";
    
    [self createNav];
    
    UIButton *btnNext = [UIButton buttonWithType:UIButtonTypeCustom];
    btnNext.frame = CGRectMake(50, 200, 100, 50);
    [btnNext setTitle:@"选择图片" forState:UIControlStateNormal];
    [btnNext setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:btnNext];
    [btnNext addTarget:self action:@selector(clickTheNextBtn) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *vi = [[UIImageView alloc]initWithFrame:CGRectMake(40, btnNext.bottom+20, 200, 200)];
    vi.image = [UIImage imageNamed:@"temp"];
    [self.view addSubview:vi];
    self.tempImgView = vi;
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"SHSettingImageEditNotification" object:nil queue:nil usingBlock:^(NSNotification *note) {
        SHSettingChangePicController *VC = (SHSettingChangePicController *)note.object[@"vc"];
        VC.delegate = self;
    }];
}

/** 编辑导航栏 */
-(void)createNav{
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] init];
    self.navigationItem.backBarButtonItem = barItem;
    barItem.title = @"";
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

-(void)clickTheNextBtn{
    SHSettingChangePicController *picker = [[SHSettingChangePicController alloc]init];
    picker.minimumNumberOfSelection = 1;
    picker.maximumNumberOfSelection = 1;
    picker.delegate = self;
    [self.navigationController pushViewController:picker animated:YES];
}

#pragma mark - SHSettingChangePicDelegate
-(void)imagePickerController:(SHSettingChangePicController *)imagePicker didSelectAsset:(ALAsset *)asset{
    UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
    
    //矫正图片方向
    if (image.imageOrientation != UIImageOrientationUp) {
        UIGraphicsBeginImageContext(image.size);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    double size = image.size.height*image.size.width;
    UIImage *newImage;
    if ( size > 640 * 640) {
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = CGPointMake(0, 0);
        thumbnailRect.size.width = 640;
        thumbnailRect.size.height = 640;
        UIGraphicsBeginImageContext(thumbnailRect.size); // this will crop
        [image drawInRect:thumbnailRect];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }else {
        newImage = [image copy];
    }
    
    self.portraitImg = newImage;
    
    [self savePortrait];
    
    SHSettingImageEditController *ctrler = [[SHSettingImageEditController alloc] initWithImage:image];
    [self.navigationController pushViewController:ctrler animated:YES];
}


#pragma mark - SHSettingImageEditControllerDelegate
-(void)chooseThePersonImage:(UIImage *)image{
    //有导航栏
    [self.navigationController popToRootViewControllerAnimated:YES];
    self.navigationController.navigationBarHidden = NO;

    //矫正图片方向
    if (image.imageOrientation != UIImageOrientationUp) {
        UIGraphicsBeginImageContext(image.size);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    double size = image.size.height*image.size.width;
    UIImage *newImage;
    if ( size > 640 * 640) {
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = CGPointMake(0, 0);
        thumbnailRect.size.width = 640;
        thumbnailRect.size.height = 640;
        UIGraphicsBeginImageContext(thumbnailRect.size); // this will crop
        [image drawInRect:thumbnailRect];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }else {
        newImage = [image copy];
    }
    
    self.portraitImg = newImage;
    
    [self savePortrait];
    
    self.tempImgView.image = newImage;
}

//修改头像
- (void)savePortrait {
    NSString *imageUrl = [self saveImgLocal:self.portraitImg];
    //service回调
    //[self.faceService editUserImageWithImageData:imageUrl];
}

//将图片从相册保存到本地
- (NSString *)saveImgLocal:(UIImage *)image
{
    NSString* documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@.png",documentsDirectory,@"logo"];
    BOOL isSave = [imageData writeToFile:imagePath atomically:YES];
    if (isSave) {
//        NSLog(@"本地保存成功");
    } else{
//        NSLog(@"本地保存失败");
    }
    return imagePath;
}

@end

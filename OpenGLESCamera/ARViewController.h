//
//  ViewController.h
//  OpenGLESCamera
//
//  Created by arplanet on 2017/3/6.
//  Copyright © 2017年 joe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "opencv2/opencv.hpp"

@interface ARViewController : GLKViewController<CvVideoCameraDelegate>{

}

@property (strong, nonatomic) EAGLContext *context;
@property (strong,nonatomic) CvVideoCamera *videoCamera;

//UI
@property (strong, nonatomic) IBOutlet GLKView *videoView;
@property (strong, nonatomic) UIToolbar *toolbar;



@end


//
//  ARViewController.h
//  OenCVGLTest
//
//  Created by arplanet on 2016/5/11.
//  Copyright © 2016年 joe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLMeshData.h"
#import <opencv2/highgui/cap_ios.h>
#import "opencv2/opencv.hpp"
#import "GLSLProgram.h"


@interface ARViewController : GLKViewController <CvVideoCameraDelegate>{
@protected
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _viewMatrix;
}
//OpenGL
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *baseEffect;

@property (strong, nonatomic) OGLModel *backdropModel;
@property (strong, nonatomic) NSMutableArray *glEntities; // <GLModel>
@property (strong, nonatomic) NSMutableDictionary *glTextures; // <GLKTextureInfo>

//OpenCV
@property (nonatomic, retain) CvVideoCamera* videoCamera;

@property (strong, nonatomic) IBOutlet GLKView *videoView;
@property (strong, nonatomic) UIToolbar* toolbar;

@end

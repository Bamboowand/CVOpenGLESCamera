//
//  ARViewController.m
//  OenCVGLTest
//
//  Created by arplanet on 2016/5/11.
//  Copyright © 2016年 joe. All rights reserved.
//

#import "ARViewController.h"
#import <OpenGLES/ES2/glext.h>

#import "GLSLProgram.h"

static const GLfloat imageVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat noRotationTextureCoordinates[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

#define ProcessMethod 0
@implementation ARViewController{
     BOOL isRunning;
    GLSLProgram *grayProgram, *haarisProgram, *filterXYProgram, *thresholdNonMaximumProgram;
    
    GLuint positionAttribute, textureCoordinateAttribute;
    GLuint sensitivityUniform,  inputImageTextureUniform;
    
    GLuint positionAttributeSecond, textureCoordinateAttributeSecond;
    GLuint edgeStrengthUniformSecond, inputImageTextureUniformSecond, texelWidthUniform, texelHeightUniform;
    GLuint thresholdUniform;
    
    GLuint grayPositionAttribute, grayTextureCoordinateAttribute;
    GLuint graySensitivityUniform, grayInputImageTextureUniform;
    
    GLuint fbo;
    
    GLuint filterXYPositionAttribute,filterXYTextureCoordinateAttribute;
    GLuint filterXYEdgeStrength,filterXYInputImageTextureUniform;
    GLuint filterXYTexelWidth,filterXYTexelHeight;
    
    GLuint thresholdNonMaximumPositionAttribute, thresholdNonMaximumTextureCoordinateAttribute;
    GLuint thresholdNonMaximumInputImageTextureUniform, thresholdNonMaximumThresholdUniform;
    GLuint thresholdNonMaximumTexelWidth, thresholdNonMaximumTexelHeight;
    
    GLint viewport[4];
    
//    GLuint textureId;
}

@synthesize videoView,toolbar;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    isRunning=NO;
    
    [self initLayout];
    [self setupGL];
    [self setupVideoCamera];
}

-(void)dealloc{

}

-(void)initLayout{
    
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    int screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, screenHeight - 44, screenWidth, 44)];
    self.toolbar.barStyle = UIBarStyleDefault;
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace  target:self action:nil];
    UIBarButtonItem *startButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(startAction:)];
    UIBarButtonItem *stopButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStylePlain target:self action:@selector(stopAction:)];
    NSArray* items;
    items=[NSArray arrayWithObjects:startButtonItem, space, stopButtonItem,nil];
    
    [self.toolbar setItems:items animated:YES];
    self.toolbar.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:self.toolbar];
    
    self.videoView=[[GLKView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];

    self.videoView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:videoView];
    
    //Add button constraints
    NSMutableDictionary * viewDict = [NSMutableDictionary dictionaryWithObject:self.videoView forKey:@"videoView"];
    [viewDict setObject:toolbar forKey:@"toolBar"];
    [viewDict setObject:self.view forKey:@"window"];
    //    [viewDict setObject:indicatorView forKey:@"indicatorView"];
    
    NSString *horizontalConstrainsParam1=@"H:|[videoView]|";
    NSString *horizontalConstrainsParam2=@"H:|[toolBar]|";
    NSString *verticalConstrainsParam=@"V:|[videoView][toolBar(44)]|";
    //    NSString *indicatorViewConstrainsV=@"V:|[indicatorView][toolBar(44)]|";
    //    NSString *indicatorViewConstrainsH=@"H:|[indicatorView]|";
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:horizontalConstrainsParam1
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:viewDict
                               ]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:horizontalConstrainsParam2
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:viewDict
                               ]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:verticalConstrainsParam
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:viewDict]];
}
#pragma mark -
#pragma mark OpenGL

- (void)setupGL
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.enableSetNeedsDisplay = NO;
    
    [EAGLContext setCurrentContext:self.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = YES;
    self.baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    
    [self initGLSL];
    
    // set some gl state flags
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    
    glBindVertexArrayOES(0);
    
    _projectionMatrix = GLKMatrix4Identity;
    _viewMatrix = GLKMatrix4Identity;

    [self initGLBackdrop];
    [self initGLEntities];
   
}

-(void) initGLBackdrop{
    
    // create a backdrop plane as the first entities
    OGLMesh *bgMesh = [[OGLMesh alloc] initCoords:BACKGROUND_MESH_DATA meshDataSize:sizeof(BACKGROUND_MESH_DATA) withVertexCount:sizeof(BACKGROUND_MESH_DATA) / sizeof(MeshTextureVertex)];
    
    OGLModel *bgModel = [[OGLModel alloc] init];
    bgModel.effect = self.baseEffect;
    bgModel.mesh = bgMesh;
    self.backdropModel = bgModel;
}

-(void) initGLEntities{
    self.glEntities = [NSMutableArray array];
    self.glTextures = [NSMutableDictionary dictionary];
}

-(void) drawModels{
//    for( size_t i=0; i<self.glEntities.count; i++ ){
//        OGLModel *model = (OGLModel*)[self.glEntities objectAtIndex:i];
//        [model draw:_projectionMatrix viewMatrix:_viewMatrix];
//    }
}

#pragma mark - GLKView delegate methods
- (void)update{
    for( size_t i=0; i<self.glEntities.count; i++ ){
        OGLModel *model = (OGLModel*)[self.glEntities objectAtIndex:i];
        [model update:self.timeSinceLastUpdate];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    NSLog(@"GlkView Draw");
    
    [self drawCameraStream];
//    [self detectGLSL_frameWidth:rect.size.width frameHeight:rect.size.height];
    [self drawModels];

}

-(void) drawCameraStream{
    
    glUseProgram(0);
    
    glDisable(GL_DEPTH_TEST);
    [self.backdropModel draw:GLKMatrix4Identity viewMatrix:GLKMatrix4Identity];
    
    glEnable(GL_DEPTH_TEST);
}

#pragma mark - VideoCamera

-(void) setupVideoCamera{
    self.videoCamera = [[CvVideoCamera alloc] init];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.delegate = self;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
//    [self.videoCamera start];
}

#pragma mark- Button action
- (IBAction)startAction:(id)sender {
    if(isRunning==YES){
        NSLog(@"Starting!!!!");
    }else{
        [self.videoCamera start];
        isRunning = YES;
        //        [indicatorView stopAnimating];
    }
}

- (IBAction)stopAction:(id)sender {
    if(isRunning==NO){
        NSLog(@"Stoping!!!!");
    }else{
        [self.videoCamera stop];
        isRunning = NO;
        //        [indicatorView startAnimating];
    }
}

#pragma mark- CvVideoCameraDelegate method
- (void)processImage:(cv::Mat&)image{
    dispatch_sync( dispatch_get_main_queue(),^{
        double totalTime = (double)cv::getTickCount();
        cv::Mat image_RGBA;
        cv::cvtColor(image, image_RGBA, CV_BGRA2RGBA);

        BOOL refresh = YES;
        cv::Mat& imageToRender = [self doProcessImage:image_RGBA refreshDisplay:refresh];
        if( refresh ){
            [self renderCameraFrame:imageToRender.data frameWidth:imageToRender.cols frameHeight:imageToRender.rows];
        
            GLKView *view = (GLKView *)self.view;
            [view display];
        }
        totalTime = ((double)cv::getTickCount() - totalTime)/cv::getTickFrequency();
        printf("Total time t=%f  Total FPS=%f \n", totalTime, 1/totalTime);
    });
}
                  
-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
    refresh = YES;
    
    cv::Mat image_BGR, outputImage_BGR;
    cvtColor(image, image_BGR, CV_RGBA2BGR);
    cvtColor(image_BGR, image, CV_BGR2RGBA);
    
    return image;
}

-(void) renderCameraFrame:(uchar*) frameData frameWidth:(size_t) width frameHeight:(size_t) height{
    if (!frameData)
    {
        NSLog(@"No video texture cache");
        return;
    }
//    NSLog(@"renderCameraFrame");
    GLuint textureId = self.backdropModel.textureId;
//    glViewport(0, 0, 500 ,500);
    glViewport(0, 0, static_cast<int>(width) ,static_cast<int>(height));
    glGetIntegerv( GL_VIEWPORT, viewport );
    glViewport( viewport[0], viewport[1], viewport[2], viewport[3] );
    
    if( !textureId ){
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        
        // create texture for video frame
        glGenTextures(1, &textureId);
        
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // required for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA , GL_UNSIGNED_BYTE, frameData);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
//        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    } else{
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        // update video frame
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, frameData);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
//        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        [self detectGLSL_frameWidth:width frameHeight:height textureID:textureId];
    }
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    self.backdropModel.textureId = textureId;
//    [self detectGLSL];
    glBindTexture(GL_TEXTURE_2D, 0);
}

#pragma mark- test GLSL
-(void)initGLSL{
    grayProgram = [[GLSLProgram alloc] initWithVertexShaderFilename:@"vertexHARRIS" fragmentShaderFilename:@"fragmentGray"];
    [grayProgram addAttribute:@"position"];
    [grayProgram addAttribute:@"inputTextureCoordinate"];
    [grayProgram link];
    
    grayPositionAttribute = [grayProgram attributeIndex:@"position"];
    grayTextureCoordinateAttribute = [grayProgram attributeIndex:@"inputTextureCoordinate"];
    grayInputImageTextureUniform = [grayProgram uniformIndex:@"inputImageTexture"];
    graySensitivityUniform = [grayProgram uniformIndex:@"sensitivity"];
    
    glEnableVertexAttribArray(grayPositionAttribute);
    glEnableVertexAttribArray(grayTextureCoordinateAttribute);
    
    glVertexAttribPointer( grayPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer( grayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    
    haarisProgram = [[GLSLProgram alloc] initWithVertexShaderFilename:@"vertexHARRIS" fragmentShaderFilename:@"fragmentHARRIS"];
    [haarisProgram addAttribute:@"position"];
    [haarisProgram addAttribute:@"inputTextureCoordinate"];
    [haarisProgram link];
    
    positionAttribute = [haarisProgram attributeIndex:@"position"];
    textureCoordinateAttribute = [haarisProgram attributeIndex:@"inputTextureCoordinate"];
    inputImageTextureUniform = [haarisProgram uniformIndex:@"inputImageTexture"];
    sensitivityUniform = [haarisProgram uniformIndex:@"sensitivity"];
    
    glEnableVertexAttribArray(positionAttribute);
    glEnableVertexAttribArray(textureCoordinateAttribute);
    
    glVertexAttribPointer( positionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer( textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    
    
    filterXYProgram = [[GLSLProgram alloc] initWithVertexShaderFilename:@"vertexNearbyTexelSampling" fragmentShaderFilename:@"fragmentXYDerivativeFilter"];
    [filterXYProgram addAttribute:@"position"];
    [filterXYProgram addAttribute:@"inputTextureCoordinate"];
    [filterXYProgram link];
    
    filterXYPositionAttribute = [filterXYProgram attributeIndex:@"position"];
    filterXYTextureCoordinateAttribute = [filterXYProgram attributeIndex:@"inputTextureCoordinate"];
    filterXYInputImageTextureUniform = [filterXYProgram uniformIndex:@"inputImageTexture"];
    filterXYEdgeStrength = [filterXYProgram uniformIndex:@"edgeStrength"];
    filterXYTexelWidth = [filterXYProgram uniformIndex:@"texelWidth"];
    filterXYTexelHeight = [filterXYProgram uniformIndex:@"texelHeight"];
    
    glEnableVertexAttribArray(filterXYPositionAttribute);
    glEnableVertexAttribArray(filterXYTextureCoordinateAttribute);
    
    glVertexAttribPointer( filterXYPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer( filterXYTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    
    
    thresholdNonMaximumProgram = [[GLSLProgram alloc] initWithVertexShaderFilename:@"vertexNearbyTexelSampling" fragmentShaderFilename:@"ThresholdedNonMaximumSuppression"];
    [thresholdNonMaximumProgram addAttribute:@"position"];
    [thresholdNonMaximumProgram addAttribute:@"inputTextureCoordinate"];
    [thresholdNonMaximumProgram link];
    
    thresholdNonMaximumPositionAttribute = [thresholdNonMaximumProgram attributeIndex:@"position"];
    thresholdNonMaximumTextureCoordinateAttribute = [thresholdNonMaximumProgram attributeIndex:@"inputTextureCoordinate"];
    thresholdNonMaximumInputImageTextureUniform = [thresholdNonMaximumProgram uniformIndex:@"inputImageTexture"];
    thresholdNonMaximumThresholdUniform = [thresholdNonMaximumProgram uniformIndex:@"threshold"];
    thresholdNonMaximumTexelWidth = [thresholdNonMaximumProgram uniformIndex:@"texelWidth"];
    thresholdNonMaximumTexelHeight= [thresholdNonMaximumProgram uniformIndex:@"texelHeight"];
    glEnableVertexAttribArray(thresholdNonMaximumPositionAttribute);
    glEnableVertexAttribArray(thresholdNonMaximumTextureCoordinateAttribute);
    
    glVertexAttribPointer( thresholdNonMaximumPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer( thresholdNonMaximumTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
}

-(void)detectGLSL_frameWidth:(size_t) width frameHeight:(size_t) height textureID:(GLuint) textureId{
    if(!textureId) textureId=self.backdropModel.textureId;
    
//    glViewport(0, 0, 600, 600);
    [grayProgram use];
//    glDisable(GL_DEPTH_TEST);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(grayInputImageTextureUniform, 0);
    glUniform1f(graySensitivityUniform, 5.0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glEnable(GL_DEPTH_TEST);
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
//    //    glViewport(320, 700, 700, 700);
//    [filterXYProgram use];
//    glDisable(GL_DEPTH_TEST);
//    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
//    glBindTexture(GL_TEXTURE_2D, textureId);
//    glUniform1i(filterXYInputImageTextureUniform, 0);
//    glUniform1f(filterXYEdgeStrength, 1.0);
//    glUniform1f(filterXYTexelHeight, 1.0f/static_cast<float>(height) );
//    glUniform1f(filterXYTexelWidth , 1.0f/static_cast<float>(width)  );
//    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glEnable(GL_DEPTH_TEST);
//    //    glBindFramebuffer(GL_FRAMEBUFFER, 0);
//
////    glViewport(320, 700, 700, 700);
//    [haarisProgram use];
////    glDisable(GL_DEPTH_TEST);
//    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
//    glBindTexture(GL_TEXTURE_2D, textureId);
//    glUniform1i(inputImageTextureUniform, 0);
//    glUniform1f(sensitivityUniform, 5.0);
//    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
////    glEnable(GL_DEPTH_TEST);
////    glBindFramebuffer(GL_FRAMEBUFFER, 0);
////
//    [thresholdNonMaximumProgram use];
////    glDisable(GL_DEPTH_TEST);
//    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
//    glBindTexture(GL_TEXTURE_2D, textureId);
//    glUniform1i( thresholdNonMaximumInputImageTextureUniform, 0);
//    glUniform1f(thresholdNonMaximumThresholdUniform, 0.3);
//    glUniform1f(thresholdNonMaximumTexelWidth, 10.0f/static_cast<float>(width)  );
//    glUniform1f(thresholdNonMaximumTexelHeight, 10.0f/static_cast<float>(height));
//    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
////    glEnable(GL_DEPTH_TEST);

}
@end

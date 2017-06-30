//
//  ViewController.m
//  OpenGLESCamera
//
//  Created by arplanet on 2017/3/6.
//  Copyright © 2017年 joe. All rights reserved.
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
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f,  1.0f,
    1.0f,  1.0f,
};

typedef struct
{
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords0;
}MeshTextureVertex;

static const MeshTextureVertex BACKGROUND_MESH_DATA[] = {
    {{1.0, 1.0, -0.0},      {0.0, 0.0, 1.0},    {1.0, 0.0}},  // top right
    {{-1.0, 1.0, -0.0},     {0.0, 0.0, 1.0},    {0.0, 0.0}}, // top left
    {{-1.0, -1.0, -0.0},    {0.0, 0.0, 1.0},    {0.0, 1.0}}, // bottom left
    {{1.0, 1.0, -0.0},      {0.0, 0.0, 1.0},    {1.0, 0.0}}, // top right
    {{-1.0, -1.0, -0.0},    {0.0, 0.0, 1.0},    {0.0, 1.0}}, // bottom left
    {{1.0, -1.0, -0.0},     {0.0, 0.0, 1.0},    {1.0, 1.0}}, // bottom right
};

@interface ARViewController (){
    BOOL isRunning;
    //VBO
    GLuint vertexArray;
    GLuint vertexBuffer;
    GLsizei vertsCount;
    GLKVector3 modelSize;
    
    //Texture
    GLuint textureId;
    GLKBaseEffect *baseEffect;
    
    //Shader
    GLSLProgram *grayProgram, *thresholdNonMaximumProgram;
    GLuint grayPositionAttribute, grayTextureCoordinateAttribute;
    GLuint graySensitivityUniform, grayInputImageTextureUniform;
    
    GLuint thresholdNonMaximumPositionAttribute, thresholdNonMaximumTextureCoordinateAttribute;
    GLuint thresholdNonMaximumInputImageTextureUniform, thresholdNonMaximumThresholdUniform;
    GLuint thresholdNonMaximumTexelWidth, thresholdNonMaximumTexelHeight;
    
    GLint backingWidth, backingHeight;
    
    //Frame Buffer
    GLuint viewFramebuffer, viewRenderbuffer;
    GLuint positionFramebuffer, positionRenderbuffer;
}

@end

@implementation ARViewController
@synthesize videoView, toolbar;

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    isRunning = NO;
    [self initLayout];
    [self setupVideoCamera];
    [self setupGL];
}

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
    
    self.videoView = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];
    
    self.videoView.translatesAutoresizingMaskIntoConstraints=NO;
    self.videoView.backgroundColor = [UIColor redColor];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- Button action
- (IBAction)startAction:(id)sender {
    if(isRunning==YES){
        NSLog(@"Starting!!!!");
    }else{
        [self.videoCamera start];
        //        [self.gpuCamera startCameraCapture];
        isRunning = YES;
        //        [indicatorView stopAnimating];
    }
}

- (IBAction)stopAction:(id)sender {
    if( isRunning == NO ){
        NSLog(@"Stoping!!!!");
    }else{
        [self.videoCamera stop];
        //        [self.gpuCamera stopCameraCapture];
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
        //[self.GPUCamera processVideoSampleBuffer:];
        
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
    glViewport(0, 0, static_cast<int>(width), static_cast<int>(height) );
    
    if( !textureId ){
        // create texture for video frame
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
        
        glGenTextures(1, &textureId);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // required for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, static_cast<int>(width), static_cast<int>(height), 0, GL_RGBA, GL_UNSIGNED_BYTE, frameData);

    } else{
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, static_cast<int>(width), static_cast<int>(height), GL_RGBA, GL_UNSIGNED_BYTE, frameData);
    }
    [self detectGLSL];
    
    glBindTexture(GL_TEXTURE_2D, 0);
}


#pragma mark - GLKView delegate methods
- (void)update{
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self drawCameraStream];
}

-(void) drawCameraStream{
    
//    glUseProgram(0);
//    glDisable(GL_DEPTH_TEST);
    if( baseEffect ){
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Identity, GLKMatrix4Identity);
        
        baseEffect.transform.projectionMatrix = GLKMatrix4Identity;
        baseEffect.transform.modelviewMatrix = modelViewMatrix;
        baseEffect.useConstantColor = GL_TRUE;
        baseEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        
        // assign texture
        if( textureId ){
            baseEffect.texture2d0.name = textureId;
        } else{
            baseEffect.texture2d0.name = 0;
        }
        
        // prepare to draw
        [baseEffect prepareToDraw];

        
        // draw mesh
        glBindVertexArrayOES(vertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glDrawArrays(GL_TRIANGLES, 0, vertsCount);
        
        glBindVertexArrayOES(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
//    glEnable(GL_DEPTH_TEST);
    
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
    
    baseEffect = [[GLKBaseEffect alloc] init];
    baseEffect.useConstantColor = YES;
    baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    
    glBindVertexArrayOES(0);
    [self initGLBackdrop];
    [self setOnscreenFBO];
    [self initGLSL];
}

-(void) initGLBackdrop{
    GLsizei count = sizeof(BACKGROUND_MESH_DATA) / sizeof(MeshTextureVertex);
    
    // create a backdrop plane as the first entities
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(BACKGROUND_MESH_DATA), BACKGROUND_MESH_DATA, GL_STATIC_DRAW);
    
    vertsCount = count;
    
    // position
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(MeshTextureVertex), 0);
    
    // normals
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE,  sizeof(MeshTextureVertex), (char *)12);
    
    // texture coords
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(MeshTextureVertex), (char *)24);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
//    float minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0, minZ = 0.0, maxZ = 0.0;
//    
//    // calculate size
//    for( size_t i=0; i<count; i++ ){
//        if( i == 0 ){
//            minX = maxX = BACKGROUND_MESH_DATA[i].position.x;
//            minY = maxY = BACKGROUND_MESH_DATA[i].position.y;
//            minZ = maxZ = BACKGROUND_MESH_DATA[i].position.z;
//        } else{
//            minX = MIN(minX, BACKGROUND_MESH_DATA[i].position.x);
//            maxX = MAX(maxX, BACKGROUND_MESH_DATA[i].position.x);
//            
//            minY = MIN(minY, BACKGROUND_MESH_DATA[i].position.y);
//            maxY = MAX(maxY, BACKGROUND_MESH_DATA[i].position.y);
//            
//            minZ = MIN(minZ, BACKGROUND_MESH_DATA[i].position.z);
//            maxZ = MAX(maxZ, BACKGROUND_MESH_DATA[i].position.z);
//        }
//    }
//    modelSize = GLKVector3Make(maxX - minX, maxY - minY, maxZ - minZ);
}

-(void)setOnscreenFBO{
    
    // Onscreen framebuffer object
    glGenFramebuffers(1, &viewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    glGenRenderbuffers(1, &viewRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.videoView.layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failure with framebuffer generation");
        return;
    }
    
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
    
    thresholdNonMaximumProgram = [[GLSLProgram alloc] initWithVertexShaderFilename:@"vertexNearbyTexelSampling" fragmentShaderFilename:@"ThresholdedNonMaximumSuppression"];
    [thresholdNonMaximumProgram addAttribute:@"position"];
    [thresholdNonMaximumProgram addAttribute:@"inputTextureCoordinate"];
    [thresholdNonMaximumProgram link];
    
    thresholdNonMaximumPositionAttribute = [thresholdNonMaximumProgram attributeIndex:@"position"];
    thresholdNonMaximumTextureCoordinateAttribute = [thresholdNonMaximumProgram attributeIndex:@"inputTextureCoordinate"];
    thresholdNonMaximumInputImageTextureUniform = [thresholdNonMaximumProgram uniformIndex:@"inputImageTexture"];
    thresholdNonMaximumThresholdUniform = [thresholdNonMaximumProgram uniformIndex:@"threshold"];
    thresholdNonMaximumTexelWidth = [thresholdNonMaximumProgram uniformIndex:@"texelWidth"];
    thresholdNonMaximumTexelHeight = [thresholdNonMaximumProgram uniformIndex:@"texelHeight"];
    
    glEnableVertexAttribArray(thresholdNonMaximumPositionAttribute);
    glEnableVertexAttribArray(thresholdNonMaximumTextureCoordinateAttribute);
    
    glVertexAttribPointer( thresholdNonMaximumPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer( thresholdNonMaximumTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
}

-(void)detectGLSL{
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    [grayProgram use];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(grayInputImageTextureUniform, 0);
    glUniform1f(graySensitivityUniform, 5.0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    [thresholdNonMaximumProgram use];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i( thresholdNonMaximumInputImageTextureUniform, 0);
    glUniform1f(thresholdNonMaximumThresholdUniform, 0.3);
    glUniform1f(thresholdNonMaximumTexelWidth, 10.0f/static_cast<float>(backingWidth)  );
    glUniform1f(thresholdNonMaximumTexelHeight, 10.0f/static_cast<float>(backingHeight));
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
@end

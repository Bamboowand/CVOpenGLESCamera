//
//  OGLModel.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 14/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GLSLProgram.h"

@class OGLMesh;

@interface OGLModel : NSObject

@property (nonatomic, readwrite) BOOL visible;
@property (nonatomic,readwrite) GLuint textureId;
@property (nonatomic, strong) OGLMesh *mesh;
@property (nonatomic,readwrite) GLKMatrix4 modelMatrix;
@property (nonatomic,strong) GLKBaseEffect *effect;
@property (nonatomic, readwrite) GLKVector3 modelSize;

-(void) update:(float) elapsedTime;

-(void) draw:(GLKMatrix4) projectionMatrix viewMatrix:(GLKMatrix4) viewMatrix;

@end

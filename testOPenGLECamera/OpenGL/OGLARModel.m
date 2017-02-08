//
//  OGLARModel.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "OGLARModel.h"

@implementation OGLARModel

@synthesize arId = _arId; 
@synthesize ttf = _ttf;

-(void) update:(float) elapsedTime{
    if( _ttf > 0 ){
        _ttf -= elapsedTime;        
        [super update:elapsedTime];
    }
}

-(void) draw:(GLKMatrix4) projectionMatrix viewMatrix:(GLKMatrix4) viewMatrix{
    if( _ttf > 0 ){
        [super draw:projectionMatrix viewMatrix:viewMatrix];
    }
}

-(GLKMatrix4) modelMatrixFromPosition:(GLKVector3) position rotation:(GLKVector3) rotation scale:(GLKVector3) scale{
    GLKMatrix4 newModelMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
    
    // rotation
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, rotation.x, 1.0f, 0.0f, 0.0f);
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, rotation.y, 0.0f, 1.0f, 0.0f);
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, rotation.z, 0.0f, 0.0f, 1.0f);
    
    // scale
    newModelMatrix = GLKMatrix4Scale(newModelMatrix, scale.x, scale.y, scale.z);
    
    return newModelMatrix;
}

@end

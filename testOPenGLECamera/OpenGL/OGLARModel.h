//
//  OGLARModel.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "OGLModel.h"

@interface OGLARModel : OGLModel{
    NSInteger _arId;
    CFTimeInterval _ttf;
}

@property (nonatomic,readwrite) NSInteger arId; 
@property (nonatomic, readwrite) CFTimeInterval ttf;

-(GLKMatrix4) modelMatrixFromPosition:(GLKVector3) position rotation:(GLKVector3) rotation scale:(GLKVector3) scale;

@end

//
//  OGLModel.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 14/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "OGLModel.h"
#import "OGLMesh.h"

@implementation OGLModel

@synthesize visible;
@synthesize textureId;
@synthesize mesh;
@synthesize modelMatrix;
@synthesize effect;
@synthesize modelSize;

- (id)init
{
    self = [super init];
    if (self) {
        self.visible = YES;
        self.modelMatrix = GLKMatrix4Identity;
        [self update:0.0f];
    }
    return self;
}


-(id) initWithMesh:(OGLMesh*) aMesh
{
    self = [super init];
    if (self) {
        self.mesh = aMesh;
        self.modelMatrix = GLKMatrix4Identity;
        [self update:0.0f];
    }
    return self;
}

-(void) update:(float) elapsedTime{
    if( !visible ){
        return;
    }
}

-(void) draw:(GLKMatrix4) projectionMatrix viewMatrix:(GLKMatrix4) viewMatrix{
    if( !visible ){
        return; 
    }
    
    if( self.effect ){
        
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, self.modelMatrix);
        
        self.effect.transform.projectionMatrix = projectionMatrix;
        self.effect.transform.modelviewMatrix = modelViewMatrix;
        self.effect.useConstantColor = GL_TRUE;
        self.effect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        
        // assign texture
        if( self.textureId ){
            self.effect.texture2d0.name = self.textureId;
        } else{
            self.effect.texture2d0.name = 0;
        }
        
        // prepare to draw
        [self.effect prepareToDraw];
        
        // draw mesh
        [self.mesh bind];
        [self.mesh draw];
        [self.mesh unbind];
        glUseProgram(0);
    }
}

@end

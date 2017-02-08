//
//  OGLMesh.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 14/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

typedef struct
{
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords0;
}
MeshTextureVertex;

typedef MeshTextureVertex* MeshTextureVertexPtr;

@interface OGLMesh : NSObject

@property (nonatomic,readwrite) GLKVector3 modelSize;

-(id)initCoords:(const MeshTextureVertex*)meshData meshDataSize:(uint) meshDataSize withVertexCount:(GLsizei) count;

-(void) bind;

-(void) draw;

-(void) unbind;

@end

//
//  OGLMesh.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 14/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "OGLMesh.h"

@interface OGLMesh(){
    GLKMatrix3 normalMatrix;
    
    GLuint vertexArray;
    GLuint vertexBuffer;
    
    GLsizei vertsCount;
}

@end

@implementation OGLMesh

@synthesize modelSize; 

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(id)initCoords:(const MeshTextureVertex*)meshData meshDataSize:(uint) meshDataSize withVertexCount:(GLsizei) count{
    self = [super init];
    if (self) {
        glGenVertexArraysOES(1, &vertexArray);
        glBindVertexArrayOES(vertexArray);
        
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, meshDataSize, meshData, GL_STATIC_DRAW);
        
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
        
        float minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0, minZ = 0.0, maxZ = 0.0;
        
        // calculate size
        for( size_t i=0; i<count; i++ ){
            if( i == 0 ){
                minX = maxX = meshData[i].position.x;
                minY = maxY = meshData[i].position.y;
                minZ = maxZ = meshData[i].position.z;
            } else{
                minX = MIN(minX, meshData[i].position.x);
                maxX = MAX(maxX, meshData[i].position.x);
                
                minY = MIN(minY, meshData[i].position.y);
                maxY = MAX(maxY, meshData[i].position.y);
                
                minZ = MIN(minZ, meshData[i].position.z);
                maxZ = MAX(maxZ, meshData[i].position.z);
            }
        }
        
        self.modelSize = GLKVector3Make(maxX - minX, maxY - minY, maxZ - minZ);
    }
    return self;
}

-(void) bind{
    glBindVertexArrayOES(vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
}


-(void) draw{
    glDrawArrays(GL_TRIANGLES, 0, vertsCount);
}


-(void) unbind{
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


- (void)dealloc
{
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteVertexArraysOES(1, &vertexArray);
}

@end

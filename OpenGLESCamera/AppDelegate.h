//
//  AppDelegate.h
//  OpenGLESCamera
//
//  Created by arplanet on 2017/3/6.
//  Copyright © 2017年 joe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


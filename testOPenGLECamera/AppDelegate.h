//
//  AppDelegate.h
//  testOPenGLECamera
//
//  Created by arplanet on 2017/1/11.
//  Copyright © 2017年 joe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


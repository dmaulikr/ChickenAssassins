//
//  AssassinsAppDelegate.h
//  Assassins
//
//  Created by David Quail on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AssassinateHUDViewController.h"
#import "AttackViewController.h"
#import "AttackCompletedViewController.h"
#import "FBConnect.h"

@interface AssassinsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	AttackViewController *attackController;
	AttackCompletedViewController *completedController;
	AssassinateHUDViewController *hudController;	
	Facebook *facebook;
	NSString *hitCombo;
	NSString *location;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) AttackViewController *attackController;
@property (nonatomic, retain) AttackCompletedViewController *completedController;
@property (nonatomic, retain) AssassinateHUDViewController *hudController;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, retain) NSString *hitCombo;
@property (nonatomic, retain) NSString *location;

- (void) lockTarget: (UIImage *) targetImage;
- (void) targetKilled: (UIImage *)targetImage;
- (void) showHud;
@end


//
//  AttackViewController.h
//  Accelerometer
//
//  Created by David Quail on 01/11/11.
//  Copyright 2011 Invisible Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "ShakeEventSource.h"
#import "SoundClipPool.h"

@class AssassinsAppDelegate;

@interface AttackViewController : UIViewController <ShakeDelegate, SoundClipPoolDelegate> {
	ShakeEventSource *shakeEventSource;

	SoundClipPool *slapClips;
	SoundClipPool *jabClips;
	SoundClipPool *bonkClips;
	SoundClipPool *responseClips;
	SoundClipPool *finishHimClips;

	double lastSlapTime;
	
	BOOL slapping;
	BOOL shouldPlayFinishHim;
	
	UIImage *targetImage;
	
	int slapCount;
	
	UIProgressView *progressView;
	UIImageView *targetImageView;
	
	UIImageView *chickenImageView;
	UIView *redOverlay;
	NSTimer *timer;	
}

@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIImageView *targetImageView;
@property (nonatomic, retain) IBOutlet UIImageView *chickenImageView;
@property (nonatomic, retain) IBOutlet UIView *redOverlay;

- (id) initWithTargetImage:(UIImage *)image;

- (IBAction)onCancelAttack;
- (IBAction)slapButton;
	
// Resets the hitcount, combination etc.
- (void) resetUsingImage:(UIImage *) image;

@end


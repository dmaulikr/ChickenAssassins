//
//  AttackViewController.m
//  Accelerometer
//
//  Created by David Quail on 01/11/11.
//  Copyright 2011 Invisible Software Inc. All rights reserved.
//

#import "AttackViewController.h"
#import "AttackCompletedViewController.h"
#import "AssassinsAppDelegate.h"

@interface AttackViewController (Private)
- (void) finishKill;
@end


@implementation AttackViewController

@synthesize appDelegate;

#define MAX_PAST_ACCELERATION_EVENTS 2

#define NONSHAKE_DELTA 0.4
#define SHAKE_DELTA 2.0
#define HITS_TO_KILL 15
#define HITS_TO_FINISH_HIM 5

- (IBAction)slapButton {
	[self slap];
}

- (void) completeInitialization {
	shakeEventSource = [[ShakeEventSource alloc] init];
	slapHistory = [[NSMutableString alloc] initWithString:@""];	
	[shakeEventSource addDelegate: self];

	/*
	 * Create slap clips
	 */
	slapClips = [[SoundClipPool alloc] init];
	
	NSString *slapURLs[] = {
		@"slap_splat_3.caf",
		@"slap_bonk.caf",
		@"slap_hard_1.caf",
		@"slap_hard_2.caf",
		@"slap_light_1.caf",
		@"slap_light_2.caf",
		@"slap_ow.caf",
		@"slap_splat_1.caf",
		@"slap_splat_4.caf",
		@"slap_squeak.caf",
		@"slap01.caf",
		@"slap02.caf",
		@"slap03.caf",
		@"slap04.caf",
		@"slap05.caf",
		@"slap06.caf",
		@"slap07.caf",
		@"slap08.caf",
		@"slap.caf",
		@"slap2.caf",
		@"slap3.caf",
		@"slap4.caf",
		@"slap5.caf",
		@"slap6.caf",
		@"slap7.caf",
	};
	
	for (int i = 0; i < (sizeof(slapURLs) / sizeof(slapURLs[0])); i++) {
		NSURL *slapURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent: slapURLs[i]];
		NSLog(@"Slap Url: %@", slapURL);
		AVAudioPlayer *slapSound = [[AVAudioPlayer alloc] initWithContentsOfURL: slapURL error: NULL];
		[slapClips addSoundClip: slapSound];
	}
	
	lastSlapTime = CACurrentMediaTime();
	
	responseClips = [[SoundClipPool alloc] init];
	responseClips.delegate = self;
	
	/*
	 * Create response clips
	 */
	NSString *responseURLs[] = {
		@"ah.caf",
		@"dominating.caf",
		@"dude.caf",
		//@"excellent.caf",
		@"hey.caf",
		@"stopit.caf",
		@"whatthehell.caf",
		@"isthatachicken.caf",
		@"oof.caf",
		@"ow.caf",
		@"thathurts.caf",
//		@"threat.caf",
		@"ah2.caf",
		@"chicken_squawk1.caf",
		@"chicken_squawk2.caf",
		@"dude2.caf",
		@"dude3.caf",
		@"hesgotarubberchicken.caf",
		@"hey_ow.caf",
		@"hey2.caf",
		@"hey3.caf",
		@"isthatarubberchicken.caf",
		@"oomf1.caf",
		@"ow_whine.caf",
		@"ow2.caf",
		@"ow3.caf",
		@"ow4.caf",
		@"stopit2.caf",
		@"uhh2.caf",
		@"uhh3.caf",
		@"uhh4.caf",
		@"umm_ouch.caf",
		@"what_the1.caf",
		@"what_the2.caf",
		@"what_the3.caf",
		@"uhh.caf",
		@"whatthehell.caf",
		//@"godlike.caf",
		//@"firstblood.caf",
		//@"holyshit.caf",
		//@"ludicrouskill.caf",
		//@"pathetic.caf",
		//@"prepare.caf",
		//@"rampage.caf",
		//@"wickedsick.caf",
	};
	
	for (int i = 0; i < (sizeof(responseURLs) / sizeof(responseURLs[0])); i++) {
		NSURL *url = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent: responseURLs[i]];
		
		AVAudioPlayer *clip = [[AVAudioPlayer alloc] initWithContentsOfURL: url error: NULL];
		[responseClips addSoundClip: clip];
	}
	
	[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(checkIfStillSlapping) userInfo: nil repeats: YES];
	
	/*
	 * Create Finish him clips
	 */
	finishHimClips = [[SoundClipPool alloc] init];	
	NSString *finishURLs[] = {
		@"finishhim.caf",
		@"punishhim.caf",
	};
	
	for (int i = 0; i < (sizeof(finishURLs) / sizeof(finishURLs[0])); i++) {
		NSURL *url = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent: finishURLs[i]];
		
		AVAudioPlayer *clip = [[AVAudioPlayer alloc] initWithContentsOfURL: url error: NULL];
		[finishHimClips addSoundClip: clip];
	}
	
	
}

- (id) initWithTargetImage:(UIImage *)image{
	targetImage = [image retain];
	return [self initWithNibName:nil bundle:nil];
}

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self completeInitialization];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
		[self completeInitialization];
    }
	
    return self;
}

- (void)dealloc {
	[NSTimer cancelPreviousPerformRequestsWithTarget: self];
	
	responseClips.delegate = nil;
	[responseClips release];
	
	[finishHimClips release];
	
	[shakeEventSource removeDelegate: self];
	[shakeEventSource release];
	
	[targetImage release];
	
    [super dealloc];
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void) finishKill{
	self.appDelegate.hitCombo = slapHistory;
	[self.appDelegate targetKilled:targetImage];
}

- (void) slap {
	NSLog(@"Slapping %d", slapCount);
	++slapCount;
	shouldPlayFinishHim = NO;
	if (slapCount >= HITS_TO_KILL){
		[self finishKill];
	}
	else if (slapCount == HITS_TO_FINISH_HIM){
		shouldPlayFinishHim = YES;
	}

	else{
		double currentTime = CACurrentMediaTime();
		if ((currentTime - lastSlapTime) >= 0.15) {
			lastSlapTime = currentTime;
			
			[slapClips playRandomClip];
			
			if (!slapping) {
				[responseClips playRandomClip];
				slapping = YES;
			}
		}
	}
}

- (void) checkIfStillSlapping {
	double currentTime = CACurrentMediaTime();
	
	if ((currentTime - lastSlapTime) >= 0.5) {
		//NSLog(@"%lf %lf", currentTime, lastSlapTime);
		slapping = NO;
	}
}

- (void) shake: (int) direction {
	if (direction & AccelerometerShakeDirectionLeft) {
		NSLog(@"AccelerofmeterShakeDirectionLeft");
		[slapHistory appendString:@"L,"];
		[self slap];
	}
	
	if (direction & AccelerometerShakeDirectionRight) {
		NSLog(@"AccelerometerShakeDirectionRight");
		[slapHistory appendString:@"R,"];
		[self slap];
	}
	
	if (direction & AccelerometerShakeDirectionUp) {
		NSLog(@"AccelerometerShakeDirectionUp");
		[slapHistory appendString:@"U,"];
		[self slap];
	}
	
	if (direction & AccelerometerShakeDirectionDown) {
		NSLog(@"AccelerometerShakeDirectionDown");
		[slapHistory appendString:@"D,"];		
		[self slap];
	}
	
	if (direction & AccelerometerShakeDirectionPush) {
		[self slap];
		[slapHistory appendString:@"F,"];		
		NSLog(@"AccelerometerShakeDirectionPush");
	}
	
	if (direction & AccelerometerShakeDirectionPull) {
		[slapHistory appendString:@"B,"];		
		NSLog(@"AccelerometerShakeDirectionPull");
	}
	NSLog(@"Slap history: %@",slapHistory);
}

- (void) playNextResponse {
	if (shouldPlayFinishHim)
	{
		[finishHimClips playRandomClip];
	}
	else if (slapping) {
		[responseClips playRandomClip];
	}
}

- (void) soundClipPoolDidFinishPlaying: (SoundClipPool *) pool {
	// 0.5 - 1.5 second delay
	double delay = 1.5 + (double) (arc4random() % 10) / 10.0;
	
	[NSTimer scheduledTimerWithTimeInterval: delay target: self selector: @selector(playNextResponse) userInfo: nil repeats: NO];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.appDelegate = (AssassinsAppDelegate *)[UIApplication sharedApplication].delegate;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end

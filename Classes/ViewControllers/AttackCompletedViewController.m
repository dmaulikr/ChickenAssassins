//
//  AttackCompletedViewController.m
//  Assassins
//
//  Created by David Quail on 11/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AttackCompletedViewController.h"
#import "UIImage+Combine.h"
#import "AssassinsAppDelegate.h"
#import "PickAFriendTableViewController.h"
#import "AssassinsServer.h"
#import "FlurryAPI.h"

@interface AttackCompletedViewController (Private)
- (void) showObituary:(NSString *)obituaryURL;
@end


@implementation AttackCompletedViewController

@synthesize targetImageView, overlayImageView, scoreLabel, facebook, alertView;

#pragma mark -
#pragma mark ViewController lifecycle

- (id) initWithTargetImage:(UIImage *)image andFacebook:(Facebook *) fbook {
	if (self = [super initWithNibName:nil bundle:nil])
	{
		targetImage = [image retain];
		self.facebook = fbook;
	}
	return self;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.targetImageView.image = targetImage;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [super dealloc];
	[targetImageView release];
	[targetImage release];
	[overlayImageView release];
	[scoreLabel release]; 
	[alertView release];
	[facebook release];
}

#pragma mark -
#pragma mark UIEvents 

- (IBAction) startAttack{
	//Start a new attack
	[FlurryAPI logEvent:@"AttackAgainSelected"];	
	AssassinsAppDelegate *appDelegate = (AssassinsAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate showHud];
}

- (IBAction) postToFacebook {
	[FlurryAPI logEvent:@"PostToFacebookSelected"];	
    AssassinsAppDelegate *appDelegate = (AssassinsAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	[self.facebook setTokenFromCache];
	
    // only authorize if the access token isn't valid
    // if it *is* valid, no need to authenticate. just move on
    if (![self.facebook isSessionValid]) {
		/*
		UIAlertView *alert;
		alert = [[UIAlertView alloc] initWithTitle:@"Facebook" 
											   message:@"We use Facebook data to create a fake obituary for your target.  Nothing will be posted on Facebook without your permission.  You'll be asked to enter your Facebook info now." 
											  delegate:self cancelButtonTitle:@"Ok" 
									 otherButtonTitles:nil];
		[alert show];
		[alert release];
		*/
		NSArray *permissions = [[[NSArray alloc] initWithObjects:@"publish_stream", @"read_stream", @"read_friendlists", @"offline_access", nil] autorelease];
		[self.facebook authorize:permissions delegate:self];		
		return;
    }
	
	else if ([appDelegate.friendData count] > 0){
        //We already have a friend list

        
        UIImage *image = [[targetImage scaledToSize:overlayImageView.image.size] overlayWith:overlayImageView.image];
        PickAFriendTableViewController *pickController = [[[PickAFriendTableViewController alloc] initWithNibName:nil bundle:nil friendJSON:appDelegate.friendData friendPic:image] autorelease];
        pickController.delegate = self;
        [self presentModalViewController:pickController animated:YES];        
        
    }
    
    else{
        //We don't have any creds.  prompt
        self.alertView = [[ActivityAlert alloc] initWithStatus:@"Loading friend list ..."];
        [self.alertView show];
        [facebook requestWithGraphPath:@"me" andDelegate:self];
        [facebook requestWithGraphPath:@"me/friends" andDelegate:self];
    }
	
}

#pragma mark -
#pragma mark Facebook delegate
/**
 * Called when the user has logged in successfully.
 */
- (void)fbDidLogin {
	
	NSLog(@"Login succeeded - token - %@", self.facebook.accessToken);
	// store the access token and expiration date to the user defaults
	[self.facebook saveTokenToCache];

	self.alertView = [[ActivityAlert alloc] initWithStatus:@"Loading friend list ..."];
	
	[self.alertView show];
	
	// get the logged-in user's friends	
	[facebook requestWithGraphPath:@"me" andDelegate:self];	
	[facebook requestWithGraphPath:@"me/friends" andDelegate:self];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
	NSLog(@"did not login");
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fbDidLogout {
	NSLog(@"Failed login");
}


////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"received response");
}

/**
 * Called when a request returns and its response has been parsed into
 * an object. The resulting object may be a dictionary, an array, a string,
 * or a number, depending on the format of the API response. If you need access
 * to the raw response, use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
	//Result could be the users info or a friend list
	NSDictionary *resultDict;
	if ([result isKindOfClass:[NSDictionary class]]){
		resultDict = (NSDictionary *) result;
		if ([resultDict objectForKey:@"id"])
		{
			//This is a callback from get user info
			AssassinsAppDelegate *appDelegate = (AssassinsAppDelegate *)[[UIApplication sharedApplication] delegate];
			appDelegate.attackInfo.assassinID = [resultDict objectForKey:@"id"];
			appDelegate.attackInfo.assassinName = [resultDict objectForKey:@"name"];
		}
		else {
			[self.alertView hide];
			NSArray *friendArray;
			friendArray = [resultDict objectForKey:@"data"];

			UIImage *image = [[targetImage scaledToSize:overlayImageView.image.size] overlayWith:overlayImageView.image];
			PickAFriendTableViewController *pickController = [[[PickAFriendTableViewController alloc] initWithNibName:nil bundle:nil friendJSON:friendArray 
																										   friendPic:image] autorelease];
			pickController.delegate = self;
			[self presentModalViewController:pickController animated:YES];
		}
	}
	else {
		NSLog(@"Something went wrong with the json returned");
	}
};

/**
 * Called when an error prevents the Facebook API request from completing
 * successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
	[self.alertView hide];
	//[self.label setText:[error localizedDescription]];
};


////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

/**
 * Called when a UIServer Dialog successfully return.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
	NSLog(@"dialogDidComplete");
	//[self.label setText:@"publish successfully"];
}

#pragma mark -
#pragma mark PickAFriendDelegate
- (void) donePickingFriendWithID:(NSString *) friendID{
	[self dismissModalViewControllerAnimated:YES];
	if (friendID == nil) {
		[FlurryAPI logEvent:@"CancelledObitCreate"];		
		return;
	}
	[FlurryAPI logEvent:@"SelectedFriendForObit"];	
	AssassinsAppDelegate *appDelegate = (AssassinsAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.attackInfo.targetID = friendID;
	NSLog(@"Friend picked: %@", friendID);
	

	NSData *imageData = UIImageJPEGRepresentation(targetImage, 0.2);
	NSLog(@"Location: %@", appDelegate.attackInfo.location);
	
	 //Todo - Use this to post to our server
	AssassinsServer *server = [AssassinsServer sharedServer];
	server.delegate = self;
	
	self.alertView = [[ActivityAlert alloc] initWithStatus:@"Generating obituary. This may take up to one minute to complete ..."];
	[self.alertView show];
	
	[server postKillWithToken:(NSString *) facebook.accessToken
														  imageData:imageData
														   killerID:appDelegate.attackInfo.assassinID
														   victimID:appDelegate.attackInfo.targetID
														   location:appDelegate.attackInfo.location
													 attackSequence:appDelegate.attackInfo.hitCombo];
	
}
	
- (void) showObituary:(NSString *)obituaryURL{
	ObituaryViewController *obituaryViewController = [[[ObituaryViewController alloc] initWithObituaryURL:obituaryURL] autorelease];
	obituaryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	
	[self presentModalViewController: obituaryViewController animated: YES];
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void) webViewDidFinishLoad:(UIWebView *)webView{
	NSLog(@"finished loading");	
}

#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	//Only called when the user has seen the mesage about facebook
}

#pragma mark -
#pragma mark AssassinsServerDelegate
- (void) onRequestDidLoad:(NSString*) response{
	AssassinsAppDelegate *appDelegate = (AssassinsAppDelegate *)[[UIApplication sharedApplication] delegate];
	[self.alertView hide];
	appDelegate.attackInfo.obituaryString = response;
	
	NSLog(@"Obituary returned was: %@", response);
	if ([response isEqualToString: @""]){
		UIAlertView *alert;
		
		alert = [[UIAlertView alloc] initWithTitle:@"Error" 
										   message:@"Unable to create obituary." 
										  delegate:self cancelButtonTitle:@"Ok" 
								 otherButtonTitles:nil];
		
		[alert show];
		[alert release];		
	}
	else{
		[self showObituary:	appDelegate.attackInfo.obituaryString];
	}	
}

- (void) onRequestDidFail{
	[self.alertView hide];
	UIAlertView *alert;
	
	alert = [[[UIAlertView alloc] initWithTitle:@"Error" 
									   message:@"Unable to create obituary." 
									  delegate:self cancelButtonTitle:@"Ok" 
							 otherButtonTitles:nil] autorelease];
	
	[alert show];
}

@end

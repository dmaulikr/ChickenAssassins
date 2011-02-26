//
//  PickAFriendTableViewController.h
//  Assassins
//
//  Created by Cameron Linke on 11-02-12.
//  Copyright 2011 Independent. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PickAFriendDelegate <NSObject>
- (void) donePickingFriendWithID:(NSString *) friendID;
@end



@interface PickAFriendTableViewController : UIViewController {
	id<PickAFriendDelegate> delegate;
	UIImage *friendPic;
	IBOutlet UIImageView *imageView;
	NSArray *arrayOfFriends;
	UIButton *postButton;
}

@property (nonatomic, retain) id<PickAFriendDelegate> delegate;
@property (nonatomic, retain) UIImage *friendPic;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) NSArray *arrayOfFriends;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil friendJSON:(NSArray*) friendArray friendPic:(UIImage *)friendPicture;

- (IBAction) onCancel;
- (IBAction) onPost;
@end
//
//  Controller+TransferMenu.m
//  OneWay
//
//  Copyright 2010 Nick Jensen <http://goto11.net>
//

#import "Controller+TransferMenu.h"
#import "NSString+Truncate.h"
#import "NSString+URLEncoding.h"
#import "NSMenu+Extras.h"
#import "FNGlue.h"


enum OWTransferMenuTag {
	OWTransferMenuStop			= 0,
	OWTransferMenuRemove		= 1,
	OWTransferMenuReload		= 2,
	OWTransferMenuReveal		= 3,
	OWTransferMenuURLSubMenu	= 4,
	OWTransferMenuFileURL		= 5,
	OWTransferMenuCreateBookmark = 6,
	OWTransferMenuEditBookmark  = 7,
	OWTransferMenuDeleteBookmark = 8,
	OWTransferMenuShowTransfers = 9,
	OWTransferMenuShowBookmarks = 10,
	OWTransferMenuBringToFront	= 11,
	OWTransferMenuRemoveAll		= 12
};


@implementation Controller (TransferMenu)


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{		
	BOOL answer = NO;
	
	Upload *upload = nil;
	Location *location = nil;
	
	switch ([menuItem tag])
	{
		case OWTransferMenuStop:
			if ([transferTable selectedRow] < 0) return NO;
			upload = [transfers objectAtIndex:[transferTable selectedRow]];
			answer = [upload isActive];
			break;
		case OWTransferMenuRemove:
		case OWTransferMenuReload:
			if ([transferTable selectedRow] < 0) return NO;
			upload = [transfers objectAtIndex:[transferTable selectedRow]];
			answer = ![upload isActive];
			break;
		case OWTransferMenuFileURL:
		case OWTransferMenuReveal:
			if ([transferTable selectedRow] < 0) return NO;
			upload = [transfers objectAtIndex:[transferTable selectedRow]];			
			answer = (upload != nil);
			break;

		case OWTransferMenuEditBookmark:
		case OWTransferMenuDeleteBookmark:
			if ([menuTable selectedRow] < 0) return NO;
			location = [savedLocations objectAtIndex:[menuTable selectedRow]];			
			answer = (location != nil);
			break;
			
		case OWTransferMenuCreateBookmark:
		case OWTransferMenuShowTransfers:
		case OWTransferMenuShowBookmarks:
		case OWTransferMenuBringToFront:
			answer = YES;
			break;
			
		case OWTransferMenuRemoveAll:
			answer = [transfers count] > 0;
			break;
			
		default:
			break;
	}
	
	return answer;
}


- (void)menuWillOpen:(NSMenu *)menu
{	
	if ([transferTable selectedRow] < 0) 
		return;

	Upload *upload = [transfers objectAtIndex:[transferTable selectedRow]];
	
	NSMenuItem *copyMenu = [menu itemWithTag:OWTransferMenuURLSubMenu];
	
	[[copyMenu submenu] removeAllItems];
	
	if ([[upload url] length] > 0)
	{
		for (int i = 0; i < [[upload transfers] count]; i++)
		{
			FileTransfer *file = [[upload transfers] objectAtIndex:i];
			
			NSString *url = @"";
			NSArray *pieces = [[upload url] componentsSeparatedByString:@"://"];
			NSString *title;
			SEL selector = nil;
			
			if ([pieces count] != 2)
			{
				title = @"Malformed URL";
			}
			else
			{
				NSString *endPath = [[file remotePath] substringFromIndex:[[upload path] length]];
				
				url = [NSString stringWithFormat:@"%@://%@", [pieces objectAtIndex:0], 
					   [[pieces objectAtIndex:1] stringByAppendingPathComponent:endPath]];
				
				title = [url stringTruncatedToLength:40 direction:NSTruncateMiddle];
				
				selector = @selector(copyHyperlinkToClipboard:);
			}
			
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title 
															   action:selector
														keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:[url encodedURLString]];
			[menuItem setTag:OWTransferMenuFileURL];
			
			[[copyMenu submenu] insertItem:menuItem 
								   atIndex:i];
		}
	}
	else
	{
		[[copyMenu submenu] insertItemWithTitle:@"Not enabled for this bookmark" 
										 action:nil 
								  keyEquivalent:@"" 
										atIndex:0];
	}
}


- (IBAction)revealUploadInFinder:(id)sender
{
	Upload *upload = (Upload *)[transfers objectAtIndex:[transferTable selectedRow]];
	
	NSMutableArray *files = [[NSMutableArray alloc] init];
	NSMutableArray *errors = [[NSMutableArray alloc] init];
	NSFileManager *mgr = [[NSFileManager alloc] init];
	
	for (int i = 0; i < [[upload localFiles] count]; i++)
	{
		NSString *path = [[upload localFiles] objectAtIndex:i];
		if ([mgr fileExistsAtPath:path])
		{
			[files addObject:[NSURL fileURLWithPath:[path stringByStandardizingPath]]];
		}
		else
		{
			[errors addObject:[path stringByStandardizingPath]];
		}
	}
	
	FNApplication *finder = [[FNApplication alloc] initWithBundleID: @"com.apple.finder"];
	[[finder activate] send];
	[[finder select:files] sendWithError:nil];
	
	if ([errors count] > 0)
	{
		NSBeginInformationalAlertSheet(@"The following files could not be found:", @"OK", nil, nil, nil, nil, nil, nil, nil, [errors componentsJoinedByString:@"\n"]);
	}
	
	[finder release];
	[files release];
	[errors release];
	[mgr release];
}


- (void)copyHyperlinkToClipboard:(NSMenuItem *)menuItem
{
	NSLog(@"Copying Hyperlink %@", [menuItem representedObject]);
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	
	[pb declareTypes:types owner:self];
	[pb setString:[menuItem representedObject] forType:NSStringPboardType];
}


@end

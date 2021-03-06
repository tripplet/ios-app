//
//  WALBrowserViewController.m
//  Wallabag
//
//  Created by Kevin Meyer on 24.02.14.
//  Copyright (c) 2014 Wallabag. All rights reserved.
//

#import "WALBrowserViewController.h"

@interface WALBrowserViewController ()
@property (strong) NSURL *initialUrl;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)refreshToolbarButtonPushed:(id)sender;
- (IBAction)shareToolbarButtonPushed:(id)sender;
- (IBAction)backToolbarButtonPushed:(id)sender;
- (IBAction)forwardToolbarButtonPushed:(id)sender;


@property (strong, nonatomic) IBOutlet UIBarButtonItem *backToolBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardToolbarButton;
@property (strong) UIPopoverController *activityPopover;
@property (strong) UIActionSheet *actionSheet;
@end

@implementation WALBrowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.webView.delegate = self;
	
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.initialUrl]];
	self.title = [self.initialUrl absoluteString];
	[self updateToolbarButtons];
}

- (void)setStartURL:(NSURL*) startURL
{
	self.initialUrl = startURL;
}

- (void)viewWillAppear:(BOOL)animated
{
	if (self.navigationController.isToolbarHidden)
		[self.navigationController setToolbarHidden:NO animated:animated];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
//	[self.navigationController setToolbarHidden:YES animated:animated];
	[super viewWillDisappear:animated];
}

#pragma mark - ToolbarButton Actions

- (IBAction)refreshToolbarButtonPushed:(id)sender
{
	[self.webView reload];
}

- (IBAction)shareToolbarButtonPushed:(id)sender
{
	if (self.actionSheet)
	{
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
		self.actionSheet = nil;
		return;
	}
	
	///! @todo implement and extend functions
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:self.webView.request.mainDocumentURL.absoluteString
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"cancel", nil)
											   destructiveButtonTitle:nil
													otherButtonTitles:NSLocalizedString(@"Open in Safari", nil), NSLocalizedString(@"Share link", nil), nil];
	self.actionSheet.tag = 1;
	
	[self.actionSheet showFromBarButtonItem:sender animated:true];
}

- (IBAction)backToolbarButtonPushed:(id)sender
{
	[self.webView goBack];
}

- (IBAction)forwardToolbarButtonPushed:(id)sender
{
	[self.webView goForward];
}

- (void) updateToolbarButtons
{
	self.backToolBarButton.enabled = [self.webView canGoBack];
	self.forwardToolbarButton.enabled = [self.webView canGoForward];
}

#pragma mark - WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType != UIWebViewNavigationTypeOther)
	{
		self.title = self.webView.request.mainDocumentURL.absoluteString;
	}
	
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	[self updateToolbarButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self updateToolbarButtons];
	
	//! Ignore often occuring NSURLError -999
	if (error.code == NSURLErrorCancelled)
		return;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
														message:error.localizedDescription
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles: nil];
	[alertView show];

}

#pragma mark - ActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == 1)
	{
		//NSLog(@"Pressed Button: %ld", (long)buttonIndex);
		
		// Open in Safari
		if (buttonIndex == 0)
		{
			if (self.webView.request.mainDocumentURL)
				[[UIApplication sharedApplication] openURL:self.webView.request.mainDocumentURL];
			else
				[[UIApplication sharedApplication] openURL:self.initialUrl];
		}
		// Share link
		else if (buttonIndex == 1)
		{
			if ([self.activityPopover isPopoverVisible])
			{
				[self.activityPopover dismissPopoverAnimated:true];
				return;
			}

			NSURL *urlToShare;
			
			if (self.webView.request.mainDocumentURL)
				urlToShare = self.webView.request.mainDocumentURL;
			else
				urlToShare = self.initialUrl;
			
			NSArray* dataToShare = @[self.title, urlToShare];
			//! @todo add more custom activities
			UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare applicationActivities:nil];
			activityViewController.excludedActivityTypes = @[UIActivityTypeAirDrop];

			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				self.activityPopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
				[self.activityPopover presentPopoverFromBarButtonItem:self.navigationController.toolbar.items[7] permittedArrowDirections:UIPopoverArrowDirectionUp animated:true];
			}
			else
			{
				[self presentViewController:activityViewController animated:YES completion:^{}];
			}
		}
	}
	self.actionSheet = nil;
}


@end

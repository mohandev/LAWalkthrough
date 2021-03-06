//  LAWalkthroughViewController.m
//  LAWalkthrough
//
//  Created by Larry Aasen on 4/11/13.
//
// Copyright (c) 2013 Larry Aasen (http://larryaasen.wordpress.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LAWalkthroughViewController.h"

@interface LAWalkthroughViewController ()
{
  NSMutableArray *pageViews;
}

@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) UIButton *nextButton;
@property (nonatomic, assign) NSInteger currentPageBeforeOrientationChange;

@end

@implementation LAWalkthroughViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    pageViews = NSMutableArray.new;
  }
  return self;
}

- (void)loadView
{
  self.view = [[UIView alloc] initWithFrame:CGRectZero];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
  [self.view addSubview:self.backgroundImageView];
  
  scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  scrollView.pagingEnabled = YES;
  scrollView.showsHorizontalScrollIndicator = NO;
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.scrollsToTop = NO;
  scrollView.delegate = self;
  [self.view addSubview:scrollView];
  
  pageControl = [self createPageControl];
  pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
  pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
  [pageControl addTarget:self action:@selector(changePage) forControlEvents:UIControlEventValueChanged];
  pageControl.currentPage = 0;
  [self.view addSubview:pageControl];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.backgroundImage)
  {
    self.backgroundImageView.frame = self.view.frame;
    self.backgroundImageView.image = self.backgroundImage;
  }

  scrollView.frame = self.view.frame;
  scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * self.numberOfPages, scrollView.frame.size.height);
  
  pageControl.frame = self.pageControlFrame;
  pageControl.numberOfPages = self.numberOfPages;
  
  BOOL useDefaultNextButton = !(self.nextButtonImage || self.nextButtonText);
  if (useDefaultNextButton)
  {
    self.nextButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    self.nextButton.frame = CGRectMake(0, 0, self.nextButton.frame.size.width+20, self.nextButton.frame.size.height);
  }
  else
  {
    self.nextButton = UIButton.new;
    CGRect buttonFrame = self.nextButton.frame;
    if (self.nextButtonText)
    {
      [self.nextButton setTitle:self.nextButtonText forState:UIControlStateNormal];
      self.nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
      buttonFrame.size = CGSizeMake(100, 36);
    }
    else if (self.nextButtonImage)
    {
      self.nextButton.imageView.image = self.nextButtonImage;
      buttonFrame.size = self.nextButtonImage.size;
    }
    self.nextButton.frame = buttonFrame;
  }
  CGRect buttonFrame = self.nextButton.frame;
  buttonFrame.origin = self.nextButtonOrigin;
  self.nextButton.frame = buttonFrame;
  [self.view addSubview:self.nextButton];
  [self.nextButton addTarget:self action:@selector(displayNextPage) forControlEvents:UIControlEventTouchUpInside];
  
  [super viewWillAppear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.currentPageBeforeOrientationChange = pageControl.currentPage;
    
    [UIView animateWithDuration:duration animations:^{
        scrollView.alpha = 0.01;
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Update content size for current orientation!
    scrollView.frame = [self defaultPageFrame];
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * self.numberOfPages, scrollView.frame.size.height);
    
    // Update the page view origins for the current orienation
    for (NSInteger i = 0; i < self.numberOfPages; ++i) {
        UIView *pageView = pageViews[i];
        CGRect newPageFrame = [self defaultPageFrame];
        newPageFrame.origin.x = i * [self defaultPageFrame].size.width;
        
        if(!CGRectEqualToRect(pageView.frame, newPageFrame)) {
            pageView.frame = newPageFrame;
        }
    }
    
    // Scroll the current page after the orientation change.
    NSInteger currentPage = self.currentPageBeforeOrientationChange;
    CGRect currentPageFrame = scrollView.frame;
    currentPageFrame.origin.x = currentPage * scrollView.frame.size.width;
    [scrollView scrollRectToVisible:currentPageFrame animated:NO];
    
    [UIView animateWithDuration:0.4 animations:^{
        scrollView.alpha = 1.0;
    }];
}

- (CGRect)defaultPageFrame
{
  return self.view.frame;
}

- (UIView *)addPageWithBody:(NSString *)bodyText
{
  UIView *pageView = [self addPageWithView:nil];
  
  CGRect frame = pageView.frame;
  frame.origin = CGPointZero;
  UILabel *label = [[UILabel alloc] initWithFrame:frame];
  label.backgroundColor = [UIColor clearColor];
  label.opaque = NO;
  label.textColor = [UIColor lightGrayColor];
  label.font = [UIFont systemFontOfSize:22];
  label.lineBreakMode = NSLineBreakByWordWrapping;
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;
  label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  label.autoresizesSubviews = YES;

  label.text = bodyText;
  
  [pageView addSubview:label];

  return pageView;
}

- (UIView *)addPageWithNibName:(NSString *)name bundle:(NSBundle *)bundleOrNil
{
  UINib *nib = [UINib nibWithNibName:name bundle:bundleOrNil];
  NSArray *objects = [nib instantiateWithOwner:self options:nil];
  UIView *view = objects.lastObject;
  view.frame = self.view.frame;
  [self addPageWithView:view];
  
  return view;
}

- (UIView *)addPageWithView:(UIView *)pageView
{
  if (!pageView)
  {
    pageView = [[UIView alloc] initWithFrame:[self defaultPageFrame]];
    pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  }

  // Move the view to its correct page location
  CGRect frame = [self defaultPageFrame];
  frame.origin.x = self.numberOfPages * [self defaultPageFrame].size.width;
  pageView.frame = frame;
  
  [pageViews addObject:pageView];
  [scrollView addSubview:pageView];
  return pageView;
}

- (void)displayNextPage
{
  pageControl.currentPage++;
  [self changePage];
}

- (void)changePage
{
  NSInteger pageIndex = pageControl.currentPage;
    
  // update the scroll view to the appropriate page
  CGRect frame = scrollView.frame;
  frame.origin.x = frame.size.width * pageIndex;
  frame.origin.y = 0;
  [scrollView scrollRectToVisible:frame animated:YES];

  pageControlUsed = YES;
    
  if (self.delegate != nil &&
      [self.delegate respondsToSelector:@selector(walkThroughViewController:didChangeToPage:)]) {
      [self.delegate walkThroughViewController:self didChangeToPage:pageIndex];
  }
}

- (NSArray *)pages
{
  return [pageViews copy];
}

// Used only by consumers
- (NSInteger)numberOfPages
{
  return pageViews.count;
}

- (CGPoint)nextButtonOrigin
{
  return CGPointMake(pageControl.frame.size.width - self.nextButton.frame.size.width, pageControl.frame.origin.y);
}

- (CGRect)pageControlFrame
{
  CGSize pagerSize = [pageControl sizeForNumberOfPages:self.numberOfPages];
  
  CGFloat y = 0;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    y = 10.0;
  }

  return CGRectMake(0,
                    y,
                    self.view.frame.size.width,
                    pagerSize.height);
}

- (UIPageControl *)createPageControl
{
  return [[UIPageControl alloc] initWithFrame:CGRectZero];
}

#pragma mark UIScrollViewDelegate method

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
  CGFloat pageWidth = scrollView.frame.size.width;
  int nextPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  
  // Hide the Next button when this is the last page
  self.nextButton.hidden = nextPage == (pageControl.numberOfPages-1);

  if (pageControlUsed)
  {
    return;
  }

  pageControl.currentPage = nextPage;
    
  if (self.delegate != nil &&
    [self.delegate respondsToSelector:@selector(walkThroughViewController:didChangeToPage:)]) {
    [self.delegate walkThroughViewController:self didChangeToPage:nextPage];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  pageControlUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  pageControlUsed = NO;
}

@end

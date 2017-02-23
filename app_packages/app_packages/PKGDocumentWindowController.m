
#import "PKGDocumentWindowController.h"

#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0

@interface PKGDocumentWindowController ()
{
	PKGProjectMainViewController * _projectMainViewController;
}

	@property (readwrite) PKGProject * project;

@end

@implementation PKGDocumentWindowController

- (instancetype)initWithProject:(PKGProject *)inProject
{
	self=[super init];
	
	if (self!=nil)
	{
		_project=inProject;
	}
	
	return self;
}

- (NSString *)windowNibName
{
	return @"PKGDocumentWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[PKGDistributionProjectMainViewController new];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowDistributionProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[PKGPackageProjectMainViewController new];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSView * tContentView=self.window.contentView;
	
	NSView * tMainView=_projectMainViewController.view;
	
	NSRect tBounds=tContentView.bounds;
	
	tMainView.frame=tBounds;
	
	[_projectMainViewController WB_viewWillAppear];
	
	[tContentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAppear];
	
	[self.window setContentBorderThickness:33.0 forEdge:NSMinYEdge];
}

@end

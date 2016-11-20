
#import "PKGProjectAssistantTemplateChoiceViewController.h"

#import "PKGProjectAssistantFinishViewController.h"

#import "WBCollectionView.h"

#import "PKGProjectTemplateAssistantSettingsKeys.h"

@interface PKGProjectAssistantTemplateChoiceViewController () <WBCollectionViewDelegate>
{
	IBOutlet WBCollectionView * _collectionView;
	
	IBOutlet NSImageView * _templateIcon;
	
	IBOutlet NSTextField * _templateNameLabel;
	
	IBOutlet NSTextField * _templateDescriptionLabel;
	
	// Data
	
	NSUInteger _selectedIndex;
	
	NSArray * _projectTemplates;
}

- (void)updateInformationPane;

@end

@implementation PKGProjectAssistantTemplateChoiceViewController

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_projectTemplates=[PKGProjectTemplate allTemplates];
		
		_selectedIndex=NSNotFound;
		
		[_projectTemplates enumerateObjectsUsingBlock:^(PKGProjectTemplate * bProjectTemplate,NSUInteger bIndex,BOOL * bOutStop){
		
			if (bProjectTemplate.enabled==YES)
			{
				_selectedIndex=bIndex;
				*bOutStop=YES;
			}
		}];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_collectionView.content=_projectTemplates;
	
	if (_selectedIndex==NSNotFound)
		return;
	
	[_collectionView WB_selectItemAtIndex:_selectedIndex];
	
	[self updateInformationPane];
}

#pragma mark -

- (BOOL)shouldShowNextStepViewController
{
	if ([_collectionView.selectionIndexes count]!=1)
		return NO;
	
	PKGProjectTemplate * tSelectedTemplate=self.selectedProjectTemplate;
	
	if (tSelectedTemplate!=nil)
		[self.assistantController.assistantSettings setObject:tSelectedTemplate forKey:PKGProjectTemplateAssistantSettingsProjectTemplateKey];
	
	return YES;
}

- (PKGAssistantStepViewController *)nextStepViewController
{
	PKGProjectTemplate * tSelectedTemplate=self.selectedProjectTemplate;
	
	PKGAssistantPlugin * tAssistantPlugin=tSelectedTemplate.assistantPlugin;
	
	if (tAssistantPlugin!=nil)
	{
		tAssistantPlugin.assistantSettings=self.assistantController.assistantSettings;
		
		return [tAssistantPlugin stepViewController];
	}
			
	return [PKGProjectAssistantFinishViewController new];
}

- (PKGProjectTemplate *)selectedProjectTemplate
{
	NSUInteger tSelectedIndex=[_collectionView.selectionIndexes firstIndex];
	
	if (tSelectedIndex==NSNotFound)
		return nil;
	
	return _projectTemplates[tSelectedIndex];
}

#pragma mark -

- (void)updateInformationPane
{
	PKGProjectTemplate * tSelectedTemplate=self.selectedProjectTemplate;
	
	_templateIcon.image=tSelectedTemplate.icon;
	_templateNameLabel.stringValue=tSelectedTemplate.name;
	_templateDescriptionLabel.stringValue=tSelectedTemplate.localizedDescription;
}

#pragma mark - RSSCollectionViewDelegate

- (BOOL)WB_selectionShouldChangeInCollectionView:(NSCollectionView *)inCollectionView
{
	return YES;
}

- (BOOL)WB_collectionView:(NSCollectionView *)inCollectionView shouldSelectItemAtIndex:(NSInteger)inIndex
{
	PKGProjectTemplate * tSelectedTemplate=_projectTemplates[inIndex];
	
	return tSelectedTemplate.enabled;
}

- (void)WB_collectionViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_collectionView)
		return;
	
	[self updateInformationPane];
}

@end

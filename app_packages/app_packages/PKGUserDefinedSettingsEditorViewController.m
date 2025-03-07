//
//  PKGUserDefinedSettingsEditorViewController.m
//  app_packages
//
//  Created by stephane on 25/09/2021.
//

#import "PKGUserDefinedSettingsEditorViewController.h"

#import "PKGProject+UserDefinedSettings.h"

#import "PKGDocumentWindowController.h"

#import "NSArray+UniqueName.h"

#import "NSTableView+Selection.h"

@interface PKGUserDefinedSettingsEditorViewController () <NSTableViewDelegate,NSTableViewDataSource>
{
    IBOutlet NSTableView * _tableView;
    
    IBOutlet NSView * _accessoryView;
    
    IBOutlet NSButton * _removeButton;
    
    NSMutableDictionary * _userDefinedSettingsRegistry;
    
    NSArray<NSString *> * _sortedAndFilteredKeys;
}

- (IBAction)addUserDefinedSettingsInstance:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation PKGUserDefinedSettingsEditorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
    self=[super initWithDocument:inDocument];
    
    if (self!=nil)
    {
        // Do not listen to our own notifications
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PKGProjectSettingsUserSettingsDidChangeNotification object:inDocument];
    }
    
    return self;
}

#pragma mark -

- (NSString *)nibName
{
    return @"PKGUserDefinedSettingsEditorViewController";
}

- (void)WB_viewDidAppear
{
    [super WB_viewDidAppear];
    
    NSView * tLeftAccessoryView=((PKGDocumentWindowController *) self.view.window.windowController).leftAccessoryView;
    
    _accessoryView.frame=tLeftAccessoryView.bounds;
    
    [tLeftAccessoryView addSubview:_accessoryView];
    
    [self.view.window makeFirstResponder:_tableView];
}

- (void)WB_viewWillDisappear
{
    [super WB_viewWillDisappear];
    
    [_accessoryView removeFromSuperview];
}

#pragma mark -

- (void)setUserDefinedSettings:(NSMutableDictionary *)inUserDefinedSettings
{
    _userDefinedSettingsRegistry=inUserDefinedSettings;
    
    _sortedAndFilteredKeys=[_userDefinedSettingsRegistry.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

#pragma mark -

- (IBAction)takeKeyFrom:(NSTextField *)sender
{
    NSUInteger tEditedRow=[_tableView rowForView:sender];
    
    if (tEditedRow==-1)
        return;
    
    NSString * tKey=_sortedAndFilteredKeys[tEditedRow];
    
    NSString * tNewKey=sender.stringValue;
    
    if (tNewKey.length==0)
    {
        NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:tEditedRow];
        NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[_tableView columnWithIdentifier:@"settings.key"]];
        
        [_tableView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
        
        return;
    }
    
    if ([tNewKey isEqualToString:tKey]==YES)
        return;
    
    if ([_sortedAndFilteredKeys indexesOfObjectsPassingTest:^BOOL(NSString * bKey,NSUInteger bIndex,BOOL * bOutStop){
        
        if (bIndex==tEditedRow)
            return NO;
        return [bKey isEqualToString:tNewKey];
        
    }].count>0)
    {
        NSAlert * tAlert=[NSAlert new];
        tAlert.alertStyle=WBAlertStyleCritical;
        tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),tNewKey];
        tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
        
        [tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
        
        return;
    }
    
    NSString * tValue=_userDefinedSettingsRegistry[tKey];
    
    [_userDefinedSettingsRegistry removeObjectForKey:tKey];
    
    _userDefinedSettingsRegistry[tNewKey]=tValue;
    
    _sortedAndFilteredKeys=[_userDefinedSettingsRegistry.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [_tableView reloadData];
    
    NSUInteger tSelectedRow=[_sortedAndFilteredKeys indexOfObject:tNewKey];
    
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedRow] byExtendingSelection:NO];
    
    [self noteDocumentHasChanged];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PKGProjectUserDefinedSettingsRegistryDidChangeNotification object:self.document];
    
    // Hack to select the value cell on tab and back-tab events when the order of rowa has changed
    
    NSEvent * tCurrentEvent=[NSApp currentEvent];
    if (tCurrentEvent.type!=WBEventTypeKeyDown)
        return;
    
    NSString * tCharacters=tCurrentEvent.characters;
    
    if (tCharacters.length>0)
    {
        unichar tFirstCharacter=[tCharacters characterAtIndex:0];
        
        switch(tFirstCharacter)
        {
            case 0x09:    // Tab
            case 0x19:    // Back Tab
                
                dispatch_async(dispatch_get_main_queue(), ^{
                  
                    [_tableView editColumn:[_tableView columnWithIdentifier:@"settings.value"] row:tSelectedRow withEvent:nil select:YES];
                });
                
                break;
        }
    }
}

- (IBAction)takeValueFrom:(NSTextField *)sender
{
    NSUInteger tEditedRow=[_tableView rowForView:sender];
    
    if (tEditedRow==-1)
        return;
    
    NSString * tKey=_sortedAndFilteredKeys[tEditedRow];
    
    NSString * tNewValue=sender.stringValue;
    
    if ([_userDefinedSettingsRegistry[tKey] isEqualToString:tNewValue]==YES)
        return;
    
    _userDefinedSettingsRegistry[tKey]=tNewValue;
    
    [self noteDocumentHasChanged];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PKGProjectUserDefinedSettingsRegistryDidChangeNotification object:self.document];
}

- (IBAction)addUserDefinedSettingsInstance:(id)sender
{
    NSString * tNewKey=[_sortedAndFilteredKeys uniqueNameWithBaseName:@"NEW_SETTING" format:@"%@_%lu" options:0 usingNameExtractor:^NSString *(NSString * bKey, NSUInteger bIndex) {
        
        return bKey;
    }];
    
    _userDefinedSettingsRegistry[tNewKey]=@"";
    
    _sortedAndFilteredKeys=[_userDefinedSettingsRegistry.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [_tableView reloadData];
    
    NSUInteger tSelectedRow=[_sortedAndFilteredKeys indexOfObject:tNewKey];
    
    [_tableView editColumn:[_tableView columnWithIdentifier:@"settings.key"] row:tSelectedRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
    NSIndexSet * tIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
    
    if (tIndexSet.count<1)
        return;
    
    [_tableView deselectAll:nil];
    
    NSArray * tSelectedKeys=[_sortedAndFilteredKeys objectsAtIndexes:tIndexSet];
    
    [_userDefinedSettingsRegistry removeObjectsForKeys:tSelectedKeys];
    
    _sortedAndFilteredKeys=[_userDefinedSettingsRegistry.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [_tableView reloadData];
    
    [self noteDocumentHasChanged];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PKGProjectUserDefinedSettingsRegistryDidChangeNotification object:self.document];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
    return _sortedAndFilteredKeys.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
    if (inTableView!=_tableView)
        return nil;
    
    NSString * tTableColumnIdentifier=inTableColumn.identifier;
    NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
    
    if ([tTableColumnIdentifier isEqualToString:@"settings.key"]==YES)
    {
        tTableCellView.textField.stringValue=_sortedAndFilteredKeys[inRow];
        
        return tTableCellView;
    }
    
    if ([tTableColumnIdentifier isEqualToString:@"settings.value"]==YES)
    {
        tTableCellView.textField.stringValue=_userDefinedSettingsRegistry[_sortedAndFilteredKeys[inRow]];
        
        return tTableCellView;
    }
    
    return nil;
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    if (inNotification.object!=_tableView)
        return;
    
    NSIndexSet * tSelectionIndexSet=_tableView.selectedRowIndexes;
    
    // Delete button state
    
    _removeButton.enabled=(tSelectionIndexSet.count>0);
}

@end

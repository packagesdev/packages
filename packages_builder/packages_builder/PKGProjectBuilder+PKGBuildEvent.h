
#import "PKGProjectBuilder.h"

#import "PKGBuildStep+Constants.h"
#import "PKGBuildEvent.h"

@interface PKGProjectBuilder (PKGBuildEvent)

- (void)postStep:(PKGBuildStep)inStep beginEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep infoEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep successEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep failureEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep warningEvent:(PKGBuildEvent *)inEvent;

- (void)postCurrentStepInfoEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepSuccessEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepFailureEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepWarningEvent:(PKGBuildEvent *)inEvent;

@end

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

static NSString * const kWindowOriginKey = @"YijiFloatWindowOrigin";
static NSString * const kLastActivityKey = @"YijiFloatLastActivity";
static NSString * const kCompletedEntriesKey = @"YijiFloatCompletedEntriesByDay";
static const CGFloat kWindowWidth = 240.0;
static const CGFloat kWindowHeight = 340.0;
static const CGFloat kPetMaxHeight = 88.0;
static const CGFloat kBubbleWidth = 220.0;
static const CGFloat kBubbleBottom = 78.0;
static const NSTimeInterval kIdleReminderSeconds = 20.0 * 60.0;
static const NSTimeInterval kEntertainmentReminderSeconds = 60.0 * 60.0;
static const NSTimeInterval kActionAnimationFrameSeconds = 0.12;

@class YijiAppController;

@interface YijiAppController : NSObject
- (void)handlePetSingleClick;
- (void)handlePetDoubleClick;
- (void)cancelPendingPetSingleClick;
- (void)showPetContextMenuForEvent:(NSEvent *)event inView:(NSView *)view;
- (void)hideBubble;
- (void)persistWindowOrigin;
@end

@interface YijiWindow : NSWindow
@end

@implementation YijiWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
@end

@interface YijiBubbleView : NSView
@property (nonatomic, strong) NSColor *fillColor;
@property (nonatomic, strong) NSColor *strokeColor;
@end

@implementation YijiBubbleView

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    self.wantsLayer = YES;
    self.layer.masksToBounds = NO;
    self.fillColor = [NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.94 alpha:1.0];
    self.strokeColor = [NSColor colorWithCalibratedRed:0.89 green:0.84 blue:0.75 alpha:1.0];
  }
  return self;
}

- (BOOL)isOpaque {
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  NSRect bodyRect = NSMakeRect(0, 12, self.bounds.size.width, self.bounds.size.height - 12);
  NSBezierPath *bodyPath = [NSBezierPath bezierPathWithRoundedRect:bodyRect xRadius:18 yRadius:18];

  [self.fillColor setFill];
  [bodyPath fill];
  [self.strokeColor setStroke];
  [bodyPath setLineWidth:1.0];
  [bodyPath stroke];

  NSBezierPath *tail = [NSBezierPath bezierPath];
  CGFloat tailCenterX = self.bounds.size.width - 36;
  [tail moveToPoint:NSMakePoint(tailCenterX - 10, 12)];
  [tail lineToPoint:NSMakePoint(tailCenterX, 0)];
  [tail lineToPoint:NSMakePoint(tailCenterX + 10, 12)];
  [tail closePath];
  [self.fillColor setFill];
  [tail fill];
  [self.strokeColor setStroke];
  [tail setLineWidth:1.0];
  [tail stroke];
}

@end

@interface YijiTimelineView : NSView
@property (nonatomic, copy) NSString *mode;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSDictionary *> *> *entriesByDay;
@property (nonatomic, strong) NSArray<NSString *> *visibleDayKeys;
@end

@implementation YijiTimelineView

- (BOOL)isOpaque {
  return NO;
}

- (NSColor *)colorForLabel:(NSString *)label alpha:(CGFloat)alpha {
  NSDictionary<NSString *, NSColor *> *map = @{
    @"读文献": [NSColor colorWithCalibratedRed:0.84 green:0.92 blue:0.81 alpha:alpha],
    @"洗数据": [NSColor colorWithCalibratedRed:0.85 green:0.92 blue:0.96 alpha:alpha],
    @"做模型": [NSColor colorWithCalibratedRed:0.93 green:0.85 blue:0.95 alpha:alpha],
    @"写论文": [NSColor colorWithCalibratedRed:0.95 green:0.89 blue:0.70 alpha:alpha],
    @"娱乐": [NSColor colorWithCalibratedRed:0.97 green:0.86 blue:0.88 alpha:alpha],
    @"饭饭": [NSColor colorWithCalibratedRed:0.97 green:0.88 blue:0.76 alpha:alpha],
    @"运动": [NSColor colorWithCalibratedRed:0.84 green:0.93 blue:0.86 alpha:alpha],
    @"家庭生活": [NSColor colorWithCalibratedRed:0.89 green:0.87 blue:0.97 alpha:alpha],
    @"开组会": [NSColor colorWithCalibratedRed:0.82 green:0.90 blue:0.88 alpha:alpha],
    @"seminar": [NSColor colorWithCalibratedRed:0.90 green:0.84 blue:0.76 alpha:alpha]
  };
  return map[label] ?: [NSColor colorWithCalibratedWhite:0.86 alpha:alpha];
}

- (NSString *)shortTimeString:(NSDate *)date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"H:mm";
  return [formatter stringFromDate:date];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  [[NSColor clearColor] setFill];
  NSRectFill(dirtyRect);

  if ([self.mode isEqualToString:@"week"]) {
    [self drawWeekView];
  } else {
    [self drawTodayView];
  }
}

- (void)drawTodayView {
  CGFloat dayStartHour = 7.0;
  CGFloat dayEndHour = 23.0;
  CGFloat visibleHours = dayEndHour - dayStartHour;
  CGFloat leftLabelWidth = 52.0;
  CGFloat topPadding = 8.0;
  CGFloat gridHeight = self.bounds.size.height - topPadding - 12.0;
  CGFloat hourHeight = gridHeight / visibleHours;
  NSRect columnRect = NSMakeRect(leftLabelWidth, topPadding, self.bounds.size.width - leftLabelWidth - 8.0, gridHeight);

  for (NSInteger hour = (NSInteger)dayStartHour; hour <= (NSInteger)dayEndHour; hour += 1) {
    CGFloat y = topPadding + (hour - dayStartHour) * hourHeight;
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(leftLabelWidth, y)];
    [line lineToPoint:NSMakePoint(NSMaxX(columnRect), y)];
    [[NSColor colorWithCalibratedWhite:0.87 alpha:1.0] setStroke];
    [line setLineWidth:1.0];
    [line stroke];
    if (hour < (NSInteger)dayEndHour) {
      NSString *label = [NSString stringWithFormat:@"%02ld:00", (long)hour];
      NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.45 green:0.49 blue:0.46 alpha:1.0]
      };
      [label drawAtPoint:NSMakePoint(4, y - 5) withAttributes:attrs];
    }
  }

  NSArray<NSDictionary *> *entries = self.visibleDayKeys.count > 0 ? self.entriesByDay[self.visibleDayKeys.firstObject] : @[];
  NSArray<NSDictionary *> *sortedEntries = [entries sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
    return [a[@"start"] compare:b[@"start"]];
  }];
  NSMutableArray<NSNumber *> *laneEndTimes = [NSMutableArray array];

  for (NSDictionary *entry in sortedEntries) {
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *startComp = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:startDate];
    NSDateComponents *endComp = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:endDate];
    CGFloat startHour = startComp.hour + (startComp.minute / 60.0);
    CGFloat endHour = endComp.hour + (endComp.minute / 60.0);
    if (endHour <= startHour) {
      endHour = startHour + (MAX(1.0, [endDate timeIntervalSinceDate:startDate] / 3600.0));
    }
    if (endHour < dayStartHour || startHour > dayEndHour) {
      continue;
    }
    startHour = MAX(startHour, dayStartHour);
    endHour = MIN(endHour, dayEndHour);
    NSInteger laneIndex = 0;
    BOOL placed = NO;
    for (NSInteger i = 0; i < (NSInteger)laneEndTimes.count; i += 1) {
      if (startHour >= laneEndTimes[i].doubleValue) {
        laneIndex = i;
        laneEndTimes[i] = @(endHour);
        placed = YES;
        break;
      }
    }
    if (!placed) {
      laneIndex = laneEndTimes.count;
      [laneEndTimes addObject:@(endHour)];
    }

    CGFloat y = topPadding + (startHour - dayStartHour) * hourHeight;
    CGFloat height = MAX(38.0, (endHour - startHour) * hourHeight);
    NSInteger laneCount = MAX(1, (NSInteger)laneEndTimes.count);
    CGFloat laneGap = 4.0;
    CGFloat usableWidth = columnRect.size.width - 12.0;
    CGFloat blockWidth = floor((usableWidth - laneGap * (laneCount - 1)) / laneCount);
    CGFloat x = leftLabelWidth + 6.0 + laneIndex * (blockWidth + laneGap);
    NSRect blockRect = NSInsetRect(NSMakeRect(x, y, blockWidth, height), 0, 1.5);
    NSBezierPath *block = [NSBezierPath bezierPathWithRoundedRect:blockRect xRadius:8 yRadius:8];
    [[self colorForLabel:entry[@"label"] alpha:1.0] setFill];
    [block fill];
    NSDictionary *titleAttrs = @{
      NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
      NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.16 green:0.18 blue:0.17 alpha:1.0]
    };
    NSDictionary *timeAttrs = @{
      NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightMedium],
      NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.26 green:0.30 blue:0.28 alpha:1.0]
    };
    NSString *title = entry[@"label"] ?: @"";
    NSString *timeText = [NSString stringWithFormat:@"%@-%@", [self shortTimeString:startDate], [self shortTimeString:endDate]];
    [title drawInRect:NSMakeRect(blockRect.origin.x + 7, blockRect.origin.y + blockRect.size.height - 18, blockRect.size.width - 14, 14) withAttributes:titleAttrs];
    [timeText drawInRect:NSMakeRect(blockRect.origin.x + 7, blockRect.origin.y + 7, blockRect.size.width - 14, 12) withAttributes:timeAttrs];
  }
}

- (void)drawWeekView {
  CGFloat dayStartHour = 7.0;
  CGFloat dayEndHour = 23.0;
  CGFloat visibleHours = dayEndHour - dayStartHour;
  CGFloat leftPadding = 12.0;
  CGFloat topPadding = 28.0;
  CGFloat bottomPadding = 12.0;
  CGFloat availableWidth = self.bounds.size.width - leftPadding * 2;
  CGFloat columnGap = 10.0;
  NSUInteger dayCount = MAX((NSUInteger)1, self.visibleDayKeys.count);
  CGFloat columnWidth = (availableWidth - columnGap * (dayCount - 1)) / dayCount;
  CGFloat gridHeight = self.bounds.size.height - topPadding - bottomPadding;
  CGFloat hourHeight = gridHeight / visibleHours;

  NSDictionary *labelAttrs = @{
    NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
    NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.37 green:0.42 blue:0.39 alpha:1.0]
  };

  [self.visibleDayKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull dayKey, NSUInteger idx, BOOL * _Nonnull stop) {
    CGFloat x = leftPadding + idx * (columnWidth + columnGap);
    NSString *dayLabel = [dayKey substringFromIndex:5];
    [dayLabel drawAtPoint:NSMakePoint(x + 4, 6) withAttributes:labelAttrs];

    NSRect columnRect = NSMakeRect(x, topPadding, columnWidth, gridHeight);
    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:columnRect xRadius:12 yRadius:12];
    [[NSColor colorWithCalibratedWhite:0.93 alpha:1.0] setFill];
    [border fill];
    [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] setStroke];
    [border setLineWidth:1.0];
    [border stroke];

    NSArray<NSDictionary *> *entries = self.entriesByDay[dayKey] ?: @[];
    for (NSDictionary *entry in entries) {
      NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
      NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
      NSCalendar *calendar = [NSCalendar currentCalendar];
      NSDateComponents *startComp = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:startDate];
      NSDateComponents *endComp = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:endDate];
      CGFloat startHour = startComp.hour + (startComp.minute / 60.0);
      CGFloat endHour = endComp.hour + (endComp.minute / 60.0);
      if (endHour <= startHour) {
        endHour = startHour + (MAX(1.0, [endDate timeIntervalSinceDate:startDate] / 3600.0));
      }
      if (endHour < dayStartHour || startHour > dayEndHour) {
        continue;
      }
      startHour = MAX(startHour, dayStartHour);
      endHour = MIN(endHour, dayEndHour);
      CGFloat y = topPadding + (startHour - dayStartHour) * hourHeight;
      CGFloat height = MAX(6.0, (endHour - startHour) * hourHeight);
      NSRect blockRect = NSInsetRect(NSMakeRect(x + 4, y, columnWidth - 8, height), 0, 1);
      NSBezierPath *block = [NSBezierPath bezierPathWithRoundedRect:blockRect xRadius:8 yRadius:8];
      [[self colorForLabel:entry[@"label"] alpha:1.0] setFill];
      [block fill];
    }
  }];
}

@end

@interface YijiPetView : NSView
@property (nonatomic, weak) YijiAppController *controller;
@property (nonatomic, assign) NSPoint dragStartPoint;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, strong) NSImage *image;
@end

@interface YijiAppController () <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate>
@property (nonatomic, strong) YijiWindow *window;
@property (nonatomic, strong) NSView *rootView;
@property (nonatomic, strong) YijiPetView *petView;
@property (nonatomic, strong) YijiBubbleView *bubbleView;
@property (nonatomic, strong) NSTextField *bubbleTitle;
@property (nonatomic, strong) NSTextField *bubbleText;
@property (nonatomic, strong) NSView *overviewOptionsView;
@property (nonatomic, strong) NSView *startOptionsView;
@property (nonatomic, strong) NSView *stopFormView;
@property (nonatomic, strong) NSTextField *outcomeField;
@property (nonatomic, strong) NSTextField *feelingField;
@property (nonatomic, strong) NSButton *continueButton;
@property (nonatomic, strong) NSButton *finishButton;
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSTimer *actionAnimationTimer;
@property (nonatomic, copy) NSString *activeTaskLabel;
@property (nonatomic, copy) NSString *bubbleMode;
@property (nonatomic, strong) NSDate *activeTaskStart;
@property (nonatomic, strong) NSArray<NSString *> *categories;
@property (nonatomic, strong) NSImage *idleStillImage;
@property (nonatomic, strong) NSArray<NSImage *> *startActionFrames;
@property (nonatomic, strong) NSArray<NSImage *> *finishActionFrames;
@property (nonatomic, strong) NSArray<NSImage *> *quitActionFrames;
@property (nonatomic, strong) NSArray<NSImage *> *currentActionFrames;
@property (nonatomic, assign) NSUInteger currentActionFrameIndex;
@property (nonatomic, strong) NSPanel *reviewPanel;
@property (nonatomic, strong) NSTextField *reviewTitleLabel;
@property (nonatomic, strong) YijiTimelineView *timelineView;
@property (nonatomic, strong) NSTextField *reviewSummaryLabel;
@property (nonatomic, assign) BOOL shouldQuitAfterAction;
@property (nonatomic, copy) NSString *lastEntertainmentReminderTaskId;
@end

@implementation YijiPetView

- (BOOL)isOpaque {
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  if (self.image == nil) {
    return;
  }

  NSSize imageSize = self.image.size;
  if (imageSize.width <= 0 || imageSize.height <= 0) {
    return;
  }

  CGFloat widthScale = self.bounds.size.width / imageSize.width;
  CGFloat heightScale = self.bounds.size.height / imageSize.height;
  CGFloat scale = MIN(widthScale, heightScale);
  NSSize drawSize = NSMakeSize(floor(imageSize.width * scale), floor(imageSize.height * scale));
  NSRect drawRect = NSMakeRect(floor((self.bounds.size.width - drawSize.width) / 2.0),
                               floor((self.bounds.size.height - drawSize.height) / 2.0),
                               drawSize.width,
                               drawSize.height);

  [self.image drawInRect:drawRect
                fromRect:NSZeroRect
               operation:NSCompositingOperationSourceOver
                fraction:1.0
          respectFlipped:YES
                   hints:@{
                     NSImageHintInterpolation: @(NSImageInterpolationNone)
                   }];
}

- (void)mouseDown:(NSEvent *)event {
  self.dragging = NO;
  self.dragStartPoint = [NSEvent mouseLocation];

  if (event.clickCount >= 2) {
    [self.controller cancelPendingPetSingleClick];
    [self.controller handlePetDoubleClick];
    return;
  }
}

- (void)mouseDragged:(NSEvent *)event {
  NSPoint current = [NSEvent mouseLocation];
  CGFloat dx = current.x - self.dragStartPoint.x;
  CGFloat dy = current.y - self.dragStartPoint.y;
  if (!self.dragging && hypot(dx, dy) > 4.0) {
    self.dragging = YES;
    [self.controller hideBubble];
  }
  if (self.dragging) {
    [self.window setFrameOrigin:NSMakePoint(self.window.frame.origin.x + dx, self.window.frame.origin.y + dy)];
    self.dragStartPoint = current;
  }
}

- (void)mouseUp:(NSEvent *)event {
  if (!self.dragging && event.clickCount == 1) {
    [self.controller handlePetSingleClick];
  }
  self.dragging = NO;
  [self.controller persistWindowOrigin];
}

- (void)rightMouseDown:(NSEvent *)event {
  [self.controller cancelPendingPetSingleClick];
  [self.controller showPetContextMenuForEvent:event inView:self];
}

@end

@implementation YijiAppController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  self.categories = @[ @"开组会", @"seminar", @"读文献", @"洗数据", @"做模型", @"写论文", @"娱乐", @"饭饭", @"运动", @"家庭生活" ];
  self.bubbleMode = @"hidden";
  [self buildMenu];
  [self buildWindow];
  [self buildPet];
  [self buildBubble];
  [self buildReviewPanel];
  [self startHeartbeat];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [self.actionAnimationTimer invalidate];
  [self persistWindowOrigin];
}

- (void)windowDidMove:(NSNotification *)notification {
  [self persistWindowOrigin];
}

- (void)buildMenu {
  NSMenu *mainMenu = [[NSMenu alloc] init];
  NSMenuItem *appItem = [[NSMenuItem alloc] init];
  [mainMenu addItem:appItem];

  NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Yiji Float"];
  [appItem setSubmenu:appMenu];
  [appMenu addItemWithTitle:@"Hide Yiji Float" action:@selector(hide:) keyEquivalent:@"h"];
  [appMenu addItem:[NSMenuItem separatorItem]];
  [appMenu addItemWithTitle:@"Quit Yiji Float" action:@selector(terminate:) keyEquivalent:@"q"];
  [NSApp setMainMenu:mainMenu];
}

- (void)buildWindow {
  NSPoint origin = [self loadWindowOrigin];
  NSRect frame = NSMakeRect(origin.x, origin.y, kWindowWidth, kWindowHeight);
  self.window = [[YijiWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
  self.window.delegate = self;
  self.window.opaque = NO;
  self.window.backgroundColor = NSColor.clearColor;
  self.window.hasShadow = NO;
  self.window.level = NSStatusWindowLevel;
  self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
  self.window.ignoresMouseEvents = NO;
  self.window.releasedWhenClosed = NO;
  self.window.movableByWindowBackground = NO;
  self.window.minSize = NSMakeSize(kWindowWidth, kWindowHeight);
  self.window.maxSize = NSMakeSize(kWindowWidth, kWindowHeight);

  self.rootView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth, kWindowHeight)];
  self.rootView.wantsLayer = YES;
  self.rootView.layer.backgroundColor = NSColor.clearColor.CGColor;
  self.window.contentView = self.rootView;
  [self.window orderFrontRegardless];
  [self.window makeKeyAndOrderFront:nil];
}

- (void)buildPet {
  self.idleStillImage = [self loadFirstFrameForState:@"idle"];
  self.startActionFrames = [self loadFramesForState:@"running"];
  self.finishActionFrames = [self loadFramesForState:@"jumping"];
  self.quitActionFrames = [self loadFramesForState:@"waving"];
  NSImage *image = self.idleStillImage;
  if (image == nil) {
    image = [[NSImage alloc] initWithContentsOfFile:[self assetPath:@"yiji-static-final.png"]];
  }
  NSSize imageSize = image.size;
  CGFloat petHeight = kPetMaxHeight;
  CGFloat petWidth = petHeight;
  if (imageSize.width > 0 && imageSize.height > 0) {
    petWidth = floor((imageSize.width / imageSize.height) * petHeight);
  }
  NSRect petFrame = NSMakeRect(kWindowWidth - petWidth - 10, 0, petWidth, petHeight);
  self.petView = [[YijiPetView alloc] initWithFrame:petFrame];
  self.petView.controller = self;
  self.petView.wantsLayer = YES;
  self.petView.layer.backgroundColor = NSColor.clearColor.CGColor;
  self.petView.image = image;
  [self.rootView addSubview:self.petView];
}

- (void)buildBubble {
  self.bubbleView = [[YijiBubbleView alloc] initWithFrame:NSMakeRect(kWindowWidth - kBubbleWidth - 8, kBubbleBottom, kBubbleWidth, 270)];
  self.bubbleView.hidden = YES;
  [self.rootView addSubview:self.bubbleView];

  self.bubbleTitle = [self labelWithFrame:NSMakeRect(16, 234, 188, 18) fontSize:15 weight:NSFontWeightSemibold];
  [self.bubbleView addSubview:self.bubbleTitle];

  self.bubbleText = [self labelWithFrame:NSMakeRect(16, 212, 188, 18) fontSize:12 weight:NSFontWeightRegular];
  self.bubbleText.textColor = [NSColor colorWithCalibratedRed:0.38 green:0.44 blue:0.40 alpha:1.0];
  [self.bubbleView addSubview:self.bubbleText];

  self.overviewOptionsView = [[NSView alloc] initWithFrame:NSMakeRect(12, 18, 196, 116)];
  [self.bubbleView addSubview:self.overviewOptionsView];
  [self buildOverviewOptions];

  self.startOptionsView = [[NSView alloc] initWithFrame:NSMakeRect(12, 16, 196, 172)];
  [self.bubbleView addSubview:self.startOptionsView];
  [self buildStartOptions];

  self.stopFormView = [[NSView alloc] initWithFrame:NSMakeRect(16, 12, 188, 194)];
  [self.bubbleView addSubview:self.stopFormView];
  [self buildStopForm];
}

- (void)buildOverviewOptions {
  NSButton *todayButton = [self bubbleButtonWithFrame:NSMakeRect(0, 54, 196, 40)
                                                title:@"Done Today"
                                                 fill:[NSColor colorWithCalibratedRed:0.85 green:0.92 blue:0.96 alpha:1.0]
                                            textColor:[NSColor colorWithCalibratedRed:0.16 green:0.28 blue:0.33 alpha:1.0]];
  todayButton.target = self;
  todayButton.action = @selector(showTodayOverview:);
  [self.overviewOptionsView addSubview:todayButton];

  NSButton *weekButton = [self bubbleButtonWithFrame:NSMakeRect(0, 6, 196, 40)
                                               title:@"Done This Week"
                                                fill:[NSColor colorWithCalibratedRed:0.89 green:0.87 blue:0.97 alpha:1.0]
                                           textColor:[NSColor colorWithCalibratedRed:0.22 green:0.20 blue:0.36 alpha:1.0]];
  weekButton.target = self;
  weekButton.action = @selector(showWeekOverview:);
  [self.overviewOptionsView addSubview:weekButton];
}

- (void)buildStartOptions {
  CGFloat buttonWidth = 94;
  CGFloat buttonHeight = 28;
  NSArray<NSColor *> *fills = @[
    [NSColor colorWithCalibratedRed:0.82 green:0.90 blue:0.88 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.90 green:0.84 blue:0.76 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.84 green:0.92 blue:0.81 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.85 green:0.92 blue:0.96 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.93 green:0.85 blue:0.95 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.95 green:0.89 blue:0.70 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.97 green:0.86 blue:0.88 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.97 green:0.88 blue:0.76 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.84 green:0.93 blue:0.86 alpha:1.0],
    [NSColor colorWithCalibratedRed:0.89 green:0.87 blue:0.97 alpha:1.0]
  ];

  [self.categories enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {
    NSUInteger row = idx / 2;
    NSUInteger col = idx % 2;
    CGFloat x = col * (buttonWidth + 8);
    CGFloat y = 144 - row * (buttonHeight + 8);
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, buttonWidth, buttonHeight)];
    button.title = title;
    button.bordered = NO;
    button.bezelStyle = NSBezelStyleRegularSquare;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 12;
    button.layer.backgroundColor = fills[idx].CGColor;
    button.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
    button.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
      NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.20 green:0.22 blue:0.20 alpha:1.0],
      NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]
    }];
    button.target = self;
    button.action = @selector(selectCategory:);
    [self.startOptionsView addSubview:button];
  }];
}

- (void)buildStopForm {
  NSTextField *outcomeLabel = [self labelWithFrame:NSMakeRect(0, 168, 188, 16) fontSize:11 weight:NSFontWeightMedium];
  outcomeLabel.stringValue = @"这一段做成了什么";
  outcomeLabel.textColor = [NSColor colorWithCalibratedRed:0.46 green:0.48 blue:0.43 alpha:1.0];
  [self.stopFormView addSubview:outcomeLabel];

  self.outcomeField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 126, 188, 30)];
  self.outcomeField.placeholderString = @"这一段做成了什么";
  self.outcomeField.bezelStyle = NSTextFieldRoundedBezel;
  self.outcomeField.font = [NSFont systemFontOfSize:12];
  [self.stopFormView addSubview:self.outcomeField];

  NSTextField *feelingLabel = [self labelWithFrame:NSMakeRect(0, 84, 188, 16) fontSize:11 weight:NSFontWeightMedium];
  feelingLabel.stringValue = @"感觉如何";
  feelingLabel.textColor = [NSColor colorWithCalibratedRed:0.46 green:0.48 blue:0.43 alpha:1.0];
  [self.stopFormView addSubview:feelingLabel];

  self.feelingField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 42, 188, 30)];
  self.feelingField.placeholderString = @"感觉如何";
  self.feelingField.bezelStyle = NSTextFieldRoundedBezel;
  self.feelingField.font = [NSFont systemFontOfSize:12];
  [self.stopFormView addSubview:self.feelingField];

  self.continueButton = [self bubbleButtonWithFrame:NSMakeRect(0, 0, 88, 30)
                                              title:@"继续"
                                               fill:[NSColor colorWithCalibratedRed:0.94 green:0.90 blue:0.84 alpha:1.0]
                                          textColor:[NSColor colorWithCalibratedRed:0.24 green:0.25 blue:0.20 alpha:1.0]];
  self.continueButton.target = self;
  self.continueButton.action = @selector(cancelStop:);
  [self.stopFormView addSubview:self.continueButton];

  self.finishButton = [self bubbleButtonWithFrame:NSMakeRect(96, 0, 92, 30)
                                            title:@"喵，人好棒！"
                                             fill:[NSColor colorWithCalibratedRed:0.19 green:0.46 blue:0.35 alpha:1.0]
                                        textColor:NSColor.whiteColor];
  self.finishButton.target = self;
  self.finishButton.action = @selector(finishStop:);
  [self.stopFormView addSubview:self.finishButton];
}

- (void)buildReviewPanel {
  NSRect frame = NSMakeRect(0, 0, 460, 560);
  self.reviewPanel = [[NSPanel alloc] initWithContentRect:frame
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
  self.reviewPanel.releasedWhenClosed = NO;
  self.reviewPanel.titleVisibility = NSWindowTitleHidden;
  self.reviewPanel.titlebarAppearsTransparent = YES;

  NSView *contentView = [[NSView alloc] initWithFrame:frame];
  contentView.wantsLayer = YES;
  contentView.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.94 alpha:1.0].CGColor;
  self.reviewPanel.contentView = contentView;

  self.reviewTitleLabel = [self labelWithFrame:NSMakeRect(24, 520, 360, 24) fontSize:22 weight:NSFontWeightSemibold];
  [contentView addSubview:self.reviewTitleLabel];

  NSTextField *subtitle = [self labelWithFrame:NSMakeRect(24, 492, 400, 18) fontSize:12 weight:NSFontWeightRegular];
  subtitle.stringValue = @"今天和这周的努力，都会在这里长成看得见的战果。";
  subtitle.textColor = [NSColor colorWithCalibratedRed:0.38 green:0.44 blue:0.40 alpha:1.0];
  [contentView addSubview:subtitle];

  self.reviewSummaryLabel = [self labelWithFrame:NSMakeRect(24, 458, 412, 20) fontSize:13 weight:NSFontWeightMedium];
  self.reviewSummaryLabel.textColor = [NSColor colorWithCalibratedRed:0.22 green:0.27 blue:0.24 alpha:1.0];
  [contentView addSubview:self.reviewSummaryLabel];

  self.timelineView = [[YijiTimelineView alloc] initWithFrame:NSMakeRect(24, 24, 412, 420)];
  self.timelineView.wantsLayer = YES;
  self.timelineView.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:0.995 blue:0.985 alpha:1.0].CGColor;
  self.timelineView.layer.cornerRadius = 18;
  self.timelineView.layer.borderWidth = 1.0;
  self.timelineView.layer.borderColor = [NSColor colorWithCalibratedRed:0.89 green:0.84 blue:0.75 alpha:1.0].CGColor;
  [contentView addSubview:self.timelineView];
}

- (NSTextField *)labelWithFrame:(NSRect)frame fontSize:(CGFloat)fontSize weight:(NSFontWeight)weight {
  NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
  label.bezeled = NO;
  label.drawsBackground = NO;
  label.editable = NO;
  label.selectable = NO;
  label.font = [NSFont systemFontOfSize:fontSize weight:weight];
  label.textColor = [NSColor colorWithCalibratedRed:0.18 green:0.20 blue:0.17 alpha:1.0];
  return label;
}

- (NSButton *)bubbleButtonWithFrame:(NSRect)frame title:(NSString *)title fill:(NSColor *)fill textColor:(NSColor *)textColor {
  NSButton *button = [[NSButton alloc] initWithFrame:frame];
  button.title = title;
  button.bordered = NO;
  button.bezelStyle = NSBezelStyleRegularSquare;
  button.wantsLayer = YES;
  button.layer.cornerRadius = 14;
  button.layer.backgroundColor = fill.CGColor;
  button.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
  NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
    NSForegroundColorAttributeName: textColor,
    NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]
  }];
  button.attributedTitle = attr;
  return button;
}

- (NSString *)assetPath:(NSString *)filename {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"prototype/assets/%@", filename]];
}

- (NSString *)framesPathForState:(NSString *)state {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-frames", state]];
}

- (NSString *)todayKey {
  return [self dayKeyForDate:[NSDate date]];
}

- (NSString *)dayKeyForDate:(NSDate *)date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd";
  return [formatter stringFromDate:date];
}

- (NSString *)timeStringForDate:(NSDate *)date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterNoStyle;
  formatter.timeStyle = NSDateFormatterShortStyle;
  return [formatter stringFromDate:date];
}

- (NSString *)shortTimeString:(NSDate *)date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"H:mm";
  return [formatter stringFromDate:date];
}

- (NSString *)labelStringForDateKey:(NSString *)dayKey {
  NSDateFormatter *input = [[NSDateFormatter alloc] init];
  input.dateFormat = @"yyyy-MM-dd";
  NSDate *date = [input dateFromString:dayKey];
  if (date == nil) {
    return dayKey;
  }
  NSDateFormatter *output = [[NSDateFormatter alloc] init];
  output.dateFormat = @"M月d日 EEE";
  return [output stringFromDate:date];
}

- (NSMutableDictionary *)entriesByDayStore {
  NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCompletedEntriesKey];
  if (stored == nil) {
    return [NSMutableDictionary dictionary];
  }
  return [stored mutableCopy];
}

- (NSArray<NSDictionary *> *)entriesForDayKey:(NSString *)dayKey {
  NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCompletedEntriesKey];
  NSArray *entries = stored[dayKey];
  if (![entries isKindOfClass:[NSArray class]]) {
    return @[];
  }
  return entries;
}

- (void)appendCompletedEntryWithOutcome:(NSString *)outcome feeling:(NSString *)feeling {
  if (self.activeTaskLabel.length == 0 || self.activeTaskStart == nil) {
    return;
  }

  NSDate *endDate = [NSDate date];
  NSMutableDictionary *entry = [@{
    @"label": self.activeTaskLabel ?: @"未命名任务",
    @"start": @([self.activeTaskStart timeIntervalSince1970]),
    @"end": @([endDate timeIntervalSince1970]),
    @"outcome": outcome ?: @"",
    @"feeling": feeling ?: @""
  } mutableCopy];

  NSString *dayKey = [self dayKeyForDate:endDate];
  NSMutableDictionary *store = [self entriesByDayStore];
  NSMutableArray *dayEntries = [NSMutableArray arrayWithArray:store[dayKey] ?: @[]];
  [dayEntries addObject:entry];
  store[dayKey] = dayEntries;
  [[NSUserDefaults standardUserDefaults] setObject:store forKey:kCompletedEntriesKey];
}

- (NSString *)summaryTextForToday {
  NSArray<NSDictionary *> *entries = [self entriesForDayKey:[self todayKey]];
  NSMutableString *summary = [NSMutableString string];
  if (entries.count == 0) {
    [summary appendString:@"今天还没有收工记录。\n\n双击一姬开始第一段，今天的战果就会长出来。"];
    return summary;
  }

  NSInteger totalMinutes = 0;
  [summary appendFormat:@"今天一共完成了 %lu 段。\n\n", (unsigned long)entries.count];
  for (NSDictionary *entry in entries) {
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
    NSInteger minutes = MAX(1, (NSInteger)llround([endDate timeIntervalSinceDate:startDate] / 60.0));
    totalMinutes += minutes;
    [summary appendFormat:@"• %@  %@ - %@  (%ld 分钟)\n", entry[@"label"], [self timeStringForDate:startDate], [self timeStringForDate:endDate], (long)minutes];
    NSString *outcome = [entry[@"outcome"] length] > 0 ? entry[@"outcome"] : @"没有补细节也没关系，这一段已经算数啦。";
    [summary appendFormat:@"  做成了：%@\n", outcome];
    if ([entry[@"feeling"] length] > 0) {
      [summary appendFormat:@"  感受：%@\n", entry[@"feeling"]];
    }
    [summary appendString:@"\n"];
  }
  [summary appendFormat:@"总计：%ld 分钟。\n", (long)totalMinutes];
  if (self.activeTaskLabel.length > 0 && self.activeTaskStart != nil) {
    [summary appendFormat:@"\n现在还正在进行：%@（开始于 %@）。", self.activeTaskLabel, [self timeStringForDate:self.activeTaskStart]];
  }
  return summary;
}

- (NSString *)summaryTextForWeek {
  NSMutableString *summary = [NSMutableString string];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger totalEntries = 0;
  NSInteger totalMinutes = 0;

  for (NSInteger offset = 0; offset < 7; offset += 1) {
    NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:-offset toDate:[NSDate date] options:0];
    NSString *dayKey = [self dayKeyForDate:date];
    NSArray<NSDictionary *> *entries = [self entriesForDayKey:dayKey];
    if (entries.count == 0) {
      continue;
    }

    NSInteger dayMinutes = 0;
    for (NSDictionary *entry in entries) {
      NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
      NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
      dayMinutes += MAX(1, (NSInteger)llround([endDate timeIntervalSinceDate:startDate] / 60.0));
    }
    totalEntries += entries.count;
    totalMinutes += dayMinutes;

    [summary appendFormat:@"%@：%lu 段，%ld 分钟\n", [self labelStringForDateKey:dayKey], (unsigned long)entries.count, (long)dayMinutes];
    for (NSDictionary *entry in entries) {
      NSString *outcome = [entry[@"outcome"] length] > 0 ? entry[@"outcome"] : @"这段有记录，但没有补细节。";
      [summary appendFormat:@"• %@：%@\n", entry[@"label"], outcome];
    }
    [summary appendString:@"\n"];
  }

  if (totalEntries == 0) {
    [summary appendString:@"这周还没有收工记录。\n\n等你完成第一段，一姬就开始替你攒周报。"];
    return summary;
  }

  [summary appendFormat:@"这周累计 %ld 段，%ld 分钟。", (long)totalEntries, (long)totalMinutes];
  return summary;
}

- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)entriesForRecentDays:(NSInteger)count {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  for (NSInteger offset = count - 1; offset >= 0; offset -= 1) {
    NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:-offset toDate:[NSDate date] options:0];
    NSString *dayKey = [self dayKeyForDate:date];
    result[dayKey] = [self entriesForDayKey:dayKey];
  }
  return result;
}

- (NSArray<NSImage *> *)loadFramesForState:(NSString *)state {
  NSMutableArray<NSImage *> *frames = [NSMutableArray array];
  NSString *framesPath = [self framesPathForState:state];
  NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:framesPath error:nil];
  NSArray<NSString *> *sortedNames = [contents sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
  for (NSString *name in sortedNames) {
    if (![name.pathExtension.lowercaseString isEqualToString:@"png"]) {
      continue;
    }
    NSString *path = [framesPath stringByAppendingPathComponent:name];
    NSImage *frame = [[NSImage alloc] initWithContentsOfFile:path];
    if (frame != nil) {
      [frames addObject:frame];
    }
  }
  return frames.copy;
}

- (NSImage *)loadFirstFrameForState:(NSString *)state {
  return [self loadFramesForState:state].firstObject;
}

- (void)playActionFrames:(NSArray<NSImage *> *)frames {
  [self.actionAnimationTimer invalidate];
  self.currentActionFrames = frames;
  self.currentActionFrameIndex = 0;

  if (frames.count == 0) {
    [self returnToIdleStill];
    return;
  }

  self.petView.image = frames.firstObject;
  [self.petView setNeedsDisplay:YES];
  if (frames.count == 1) {
    [self performSelector:@selector(returnToIdleStill) withObject:nil afterDelay:0.35];
    return;
  }

  self.actionAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:kActionAnimationFrameSeconds
                                                               target:self
                                                             selector:@selector(stepActionAnimation)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (void)stepActionAnimation {
  if (self.currentActionFrames.count == 0) {
    [self returnToIdleStill];
    return;
  }

  self.currentActionFrameIndex += 1;
  if (self.currentActionFrameIndex >= self.currentActionFrames.count) {
    [self returnToIdleStill];
    return;
  }

  self.petView.image = self.currentActionFrames[self.currentActionFrameIndex];
  [self.petView setNeedsDisplay:YES];
}

- (void)returnToIdleStill {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(returnToIdleStill) object:nil];
  [self.actionAnimationTimer invalidate];
  self.actionAnimationTimer = nil;
  self.currentActionFrames = nil;
  self.currentActionFrameIndex = 0;
  if (self.shouldQuitAfterAction) {
    [NSApp terminate:nil];
    return;
  }
  self.petView.image = self.idleStillImage ?: [[NSImage alloc] initWithContentsOfFile:[self assetPath:@"yiji-static-final.png"]];
  [self.petView setNeedsDisplay:YES];
}

- (void)handlePetDoubleClick {
  [self recordActivityNow];
  if ([self.bubbleMode isEqualToString:@"reminder"]) {
    [self hideBubble];
    return;
  }

  if (self.activeTaskLabel.length > 0) {
    [self showStopBubble];
  } else {
    [self showStartBubble];
  }
}

- (void)handlePetSingleClick {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showOverviewBubble) object:nil];
  [self performSelector:@selector(showOverviewBubble) withObject:nil afterDelay:0.2];
}

- (void)cancelPendingPetSingleClick {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showOverviewBubble) object:nil];
}

- (void)showPetContextMenuForEvent:(NSEvent *)event inView:(NSView *)view {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Yiji"];
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quitApp:) keyEquivalent:@""];
  quitItem.target = self;
  [menu addItem:quitItem];
  [NSMenu popUpContextMenu:menu withEvent:event forView:view];
}

- (void)showOverviewBubble {
  [self recordActivityNow];
  if ([self.bubbleMode isEqualToString:@"reminder"]) {
    return;
  }
  self.bubbleMode = @"overview";
  self.bubbleTitle.stringValue = @"喵，战果想看哪一页";
  self.bubbleText.stringValue = @"单击一姬看看今天或这周。";
  self.overviewOptionsView.hidden = NO;
  self.startOptionsView.hidden = YES;
  self.stopFormView.hidden = YES;
  self.bubbleView.hidden = NO;
}

- (void)showStartBubble {
  self.bubbleMode = @"start";
  self.bubbleTitle.stringValue = @"喵，离accept更进一步";
  self.bubbleText.stringValue = @"点一下就开始计时。";
  self.overviewOptionsView.hidden = YES;
  self.startOptionsView.hidden = NO;
  self.stopFormView.hidden = YES;
  self.bubbleView.hidden = NO;
}

- (void)showStopBubble {
  self.bubbleMode = @"stop";
  self.bubbleTitle.stringValue = [NSString stringWithFormat:@"%@ 结束啦", self.activeTaskLabel ?: @"这段"];
  self.bubbleText.stringValue = @"补一句成果就收工。";
  self.overviewOptionsView.hidden = YES;
  self.startOptionsView.hidden = YES;
  self.stopFormView.hidden = NO;
  self.outcomeField.stringValue = @"";
  self.feelingField.stringValue = @"";
  self.bubbleView.hidden = NO;
}

- (void)showReminderBubbleWithTitle:(NSString *)title message:(NSString *)message {
  self.bubbleMode = @"reminder";
  self.bubbleTitle.stringValue = title;
  self.bubbleText.stringValue = message;
  self.overviewOptionsView.hidden = YES;
  self.startOptionsView.hidden = YES;
  self.stopFormView.hidden = YES;
  self.bubbleView.hidden = NO;
}

- (void)hideBubble {
  self.bubbleMode = @"hidden";
  self.bubbleView.hidden = YES;
}

- (void)selectCategory:(NSButton *)sender {
  self.shouldQuitAfterAction = NO;
  self.lastEntertainmentReminderTaskId = nil;
  self.activeTaskLabel = sender.title;
  self.activeTaskStart = [NSDate date];
  [self recordActivityNow];
  self.bubbleMode = @"reminder";
  self.bubbleTitle.stringValue = @"喵，努力给咪挣罐罐鸭！";
  self.bubbleText.stringValue = @"这段已经开始啦。";
  self.overviewOptionsView.hidden = YES;
  self.startOptionsView.hidden = YES;
  self.stopFormView.hidden = YES;
  self.bubbleView.hidden = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBubble) object:nil];
  [self performSelector:@selector(hideBubble) withObject:nil afterDelay:0.8];
  [self playActionFrames:self.startActionFrames];
}

- (void)cancelStop:(id)sender {
  [self hideBubble];
}

- (void)finishStop:(id)sender {
  self.shouldQuitAfterAction = NO;
  self.lastEntertainmentReminderTaskId = nil;
  [self appendCompletedEntryWithOutcome:self.outcomeField.stringValue feeling:self.feelingField.stringValue];
  self.activeTaskLabel = nil;
  self.activeTaskStart = nil;
  [self recordActivityNow];
  [self hideBubble];
  [self playActionFrames:self.finishActionFrames];
}

- (void)showTodayOverview:(id)sender {
  [self hideBubble];
  self.reviewTitleLabel.stringValue = @"Done Today";
  NSArray *entries = [self entriesForDayKey:[self todayKey]];
  NSInteger totalMinutes = 0;
  for (NSDictionary *entry in entries) {
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
    totalMinutes += MAX(1, (NSInteger)llround([endDate timeIntervalSinceDate:startDate] / 60.0));
  }
  self.reviewSummaryLabel.stringValue = entries.count == 0 ? @"今天还没有记录。" : [NSString stringWithFormat:@"今天完成了 %lu 段，总计 %ld 分钟。", (unsigned long)entries.count, (long)totalMinutes];
  self.timelineView.mode = @"today";
  self.timelineView.entriesByDay = @{ [self todayKey]: entries ?: @[] };
  self.timelineView.visibleDayKeys = @[ [self todayKey] ];
  [self.timelineView setNeedsDisplay:YES];
  [self.reviewPanel center];
  [self.reviewPanel makeKeyAndOrderFront:nil];
}

- (void)showWeekOverview:(id)sender {
  [self hideBubble];
  self.reviewTitleLabel.stringValue = @"Done This Week";
  NSDictionary *entriesByDay = [self entriesForRecentDays:7];
  NSInteger totalEntries = 0;
  NSInteger totalMinutes = 0;
  NSArray<NSString *> *keys = [[entriesByDay allKeys] sortedArrayUsingSelector:@selector(compare:)];
  for (NSString *dayKey in keys) {
    NSArray *entries = entriesByDay[dayKey];
    totalEntries += entries.count;
    for (NSDictionary *entry in entries) {
      NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"start"] doubleValue]];
      NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[entry[@"end"] doubleValue]];
      totalMinutes += MAX(1, (NSInteger)llround([endDate timeIntervalSinceDate:startDate] / 60.0));
    }
  }
  self.reviewSummaryLabel.stringValue = totalEntries == 0 ? @"这周还没有记录。" : [NSString stringWithFormat:@"这周累计 %ld 段，总计 %ld 分钟。", (long)totalEntries, (long)totalMinutes];
  self.timelineView.mode = @"week";
  self.timelineView.entriesByDay = entriesByDay;
  self.timelineView.visibleDayKeys = keys;
  [self.timelineView setNeedsDisplay:YES];
  [self.reviewPanel center];
  [self.reviewPanel makeKeyAndOrderFront:nil];
}

- (void)quitApp:(id)sender {
  self.shouldQuitAfterAction = YES;
  self.bubbleMode = @"reminder";
  self.bubbleTitle.stringValue = @"喵，退下吧人。";
  self.bubbleText.stringValue = @"明天见。";
  self.overviewOptionsView.hidden = YES;
  self.startOptionsView.hidden = YES;
  self.stopFormView.hidden = YES;
  self.bubbleView.hidden = NO;
  [self playActionFrames:self.quitActionFrames];
}

- (void)startHeartbeat {
  self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                         target:self
                                                       selector:@selector(checkIdle)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)checkIdle {
  if (![self.bubbleMode isEqualToString:@"hidden"]) {
    return;
  }

  if (self.activeTaskLabel.length > 0) {
    if ([self.activeTaskLabel isEqualToString:@"娱乐"] && self.activeTaskStart != nil) {
      NSTimeInterval entertainmentDuration = [[NSDate date] timeIntervalSinceDate:self.activeTaskStart];
      NSString *taskId = [NSString stringWithFormat:@"%@-%f", self.activeTaskLabel, [self.activeTaskStart timeIntervalSince1970]];
      if (entertainmentDuration >= kEntertainmentReminderSeconds &&
          ![self.lastEntertainmentReminderTaskId isEqualToString:taskId]) {
        self.lastEntertainmentReminderTaskId = taskId;
        [self showReminderBubbleWithTitle:@"喵，不是说好要带咪发AER的吗？"
                                  message:@"娱乐已经满 1 小时啦。双击一姬关掉这条提醒，想继续还是收工都由你。"];
      }
    }
    return;
  }

  NSString *lastActivityString = [[NSUserDefaults standardUserDefaults] stringForKey:kLastActivityKey];
  if (lastActivityString.length == 0) {
    return;
  }

  NSDate *lastActivity = [NSDate dateWithTimeIntervalSince1970:lastActivityString.doubleValue];
  if ([[NSDate date] timeIntervalSinceDate:lastActivity] >= kIdleReminderSeconds) {
    [self showReminderBubbleWithTitle:@"喵，人在干什么？"
                              message:@"已经 20 分钟没有键盘或鼠标动静啦。双击一姬，我就当你回来继续上班班了。"];
  }
}

- (void)recordActivityNow {
  NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
  [[NSUserDefaults standardUserDefaults] setObject:timestamp forKey:kLastActivityKey];
}

- (NSPoint)loadWindowOrigin {
  NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kWindowOriginKey];
  if (saved.length > 0) {
    NSArray<NSString *> *parts = [saved componentsSeparatedByString:@","];
    if (parts.count == 2) {
      return NSMakePoint(parts[0].doubleValue, parts[1].doubleValue);
    }
  }
  NSScreen *screen = NSScreen.mainScreen;
  NSRect visibleFrame = screen != nil ? screen.visibleFrame : NSMakeRect(0, 0, 1440, 900);
  return NSMakePoint(NSMaxX(visibleFrame) - kWindowWidth - 18.0, NSMinY(visibleFrame) + 18.0);
}

- (void)persistWindowOrigin {
  NSPoint origin = self.window.frame.origin;
  NSString *value = [NSString stringWithFormat:@"%f,%f", origin.x, origin.y];
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:kWindowOriginKey];
}

@end

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
    YijiAppController *controller = [[YijiAppController alloc] init];
    application.delegate = controller;
    [application run];
  }
  return 0;
}

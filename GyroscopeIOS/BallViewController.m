//
//  BallViewController.m
//  GyroscopeIOS
//
//  Created by Admin on 01.06.15.
//  Copyright (c) 2015 OSher. All rights reserved.
//

#import "BallViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioServices.h>

#define kMinChangeValue 0.05f
#define kMinSpeed 1.0f
#define kBallSize 50.0f
#define kMinBallSpeed 10.0f
#define kMaxBallSpeed 600.0f
#define kDefaultCornerSize 250.0f

enum direction {
    UP = 0,
    LEFT,
    RIGHT,
    DOWN,
    UPLEFT,
    UPRIGHT,
    DOWNLEFT,
    DOWNRIGHT,
    NONE
};

@interface BallViewController ()
    @property (weak, nonatomic) IBOutlet UIButton *playResetButton;
    @property (weak, nonatomic) IBOutlet UIButton *clearButton;
    @property (weak, nonatomic) IBOutlet UIImageView *ball;
    @property (weak, nonatomic) IBOutlet UIImageView *corner;
    @property (weak, nonatomic) IBOutlet UILabel *timeLabel;
    @property (weak, nonatomic) IBOutlet UILabel *recordLabel;

    @property (strong, nonatomic) CMMotionManager *motionManager;
    @property (strong, nonatomic) NSTimer *timer;

    @property (nonatomic) NSInteger currentSpeed;
    @property (nonatomic) NSInteger currentCornerSize;
    @property (nonatomic) NSInteger totalTime;

    @property (nonatomic) BOOL isPlaying;

@end

@implementation BallViewController

#pragma -
#pragma mark View lifetime

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1.0f / 30.0f;
    self.motionManager.gyroUpdateInterval= 1.0f / 30.0f;
    
    self.isPlaying = NO;
    [self setPlayResetButtonTitle];
    [self resizeCornerWithSize:kDefaultCornerSize];
    [self.timeLabel setText:@"0s"];
    [self.timeLabel setTextColor:[UIColor greenColor]];
    self.totalTime = 0;
    
    self.totalTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"kUserRecord"];
    if (self.totalTime == 0) {
        [self.recordLabel setText:@"Best result: 0s"];
    } else {
        [self.recordLabel setText:[NSString stringWithFormat:@"Best result: %lds",(long)self.totalTime]];
    }
}

- (void)resizeCornerWithSize:(CGFloat)size {
    self.corner.frame = CGRectMake(160 - self.corner.frame.size.width, 284 - self.corner.frame.size.height, size, size);
    self.corner.center = self.view.center;
    UIImage *resizedCorner = [self imageWithImage:[UIImage imageNamed:@"corner.png"] scaledToSize:CGSizeMake(size, size)];
    [self.corner setImage:resizedCorner];
    self.currentCornerSize = size;
}

- (void)setPlayResetButtonTitle {
    if (self.isPlaying) {
        [self.playResetButton setTitle:@"Restart" forState:UIControlStateNormal];
    } else {
        [self.playResetButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

#pragma -
#pragma mark Inner calls

- (void)initBall {
    [self resetBall];
    
    [self.motionManager startGyroUpdates];
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self moveBall];
    }];
}

- (void)resetBall {
    [self.clearButton setEnabled:NO];
    
    [self stopTimer];
    
    self.currentSpeed = kMinBallSpeed;
    self.totalTime = 0;
    [self.timeLabel setText:@"0s"];
    [self.timeLabel setTextColor:[UIColor greenColor]];
    
    self.ball.center = self.view.center;
    [self resizeCornerWithSize:kDefaultCornerSize];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeCnahged) userInfo:nil repeats:YES];
}

- (void)cornerPassed {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopAccelerometerUpdates];
    [self stopTimer];
    NSString *message = [NSString stringWithFormat:@"Your record: %lds \r\n Do you want to try again?",(long)self.totalTime];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game Over!"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes",nil];
    [alert show];
}

- (double)getXOffsetByPointX:(double)x andMoveSpeed:(double)moveSpeed {
    double center = self.ball.center.x;
    
    x = x * self.currentSpeed;
    if (moveSpeed > kMinSpeed) {
        x = x * moveSpeed;
    }
    
    BOOL isXPossitive;
    if (x > kMinChangeValue) {
        isXPossitive = YES;
    } else if (x < -kMinChangeValue) {
        isXPossitive = NO;
    } else {
        return center - kBallSize/2;
    }
    
    if (isXPossitive) {
        if ((center + kBallSize/2 + x) >= (self.corner.frame.origin.x + self.currentCornerSize)) {
            [self cornerPassed];
            double centerX = (center + x - kBallSize/2);
            return centerX;
        } else {
            double centerX = (center + x - kBallSize/2);
            return centerX;
        }
    } else {
        if ((center - kBallSize/2 + x) <= self.corner.frame.origin.x) {
            [self cornerPassed];
            double centerX = (center + x - kBallSize/2);
            return centerX;
        } else {
            double centerX = (center + x - kBallSize/2);
            return centerX;
        }
    }
}

- (double)getYOffsetByPointY:(double)y andMoveSpeed:(double)moveSpeed {
    double center = self.ball.center.y;
    
    y = y * self.currentSpeed;
    if (moveSpeed > kMinSpeed) {
        y = y * moveSpeed;
    }
    
    BOOL isYPossitive;
    if (y > kMinChangeValue) {
        isYPossitive = YES;
    } else if (y < -kMinChangeValue) {
        isYPossitive = NO;
    } else {
        return center - kBallSize/2;
    }
    
    if (isYPossitive) {
        if ((center - kBallSize/2 - y) <= self.corner.frame.origin.y) {
            [self cornerPassed];
            double centerY = (center - y - kBallSize/2);
            return centerY;
        } else {
            double centerY = (center - y - kBallSize/2);
            return centerY;
        }
    } else {
        if ((center + kBallSize/2 - y) >= (self.corner.frame.origin.y + self.currentCornerSize)) {
            [self cornerPassed];
            double centerY = (center - y - kBallSize/2);
            return centerY;
        } else {
            double centerY = (center - y - kBallSize/2);
            return centerY;
        }
    }
}

- (double)getMoveSpeedByDirection:(NSInteger)direction andRotationPointX:(double)x andPointY:(double)y {
    switch (direction) {
        case UP:
        case DOWN:
            return fabs(x);
        case LEFT:
        case RIGHT:
            return fabs(y);
        case UPLEFT:
        case UPRIGHT:
        case DOWNLEFT:
        case DOWNRIGHT:
            return (fabs(x)+fabs(y))/2;
        case NONE:
        default:
            return 0.0f;
    }
}

- (NSInteger)getDirectionByPointX:(double)x andPointY:(double)y {
    BOOL xChange = NO;
    BOOL yChange = NO;
    
    if (fabs(x) > kMinChangeValue) {
        xChange = YES;
    }
    if (fabs(y) > kMinChangeValue) {
        yChange = YES;
    }
    
    if (xChange && !yChange) {
        if (x > kMinChangeValue) {
            return RIGHT;
        } else if (x < -kMinChangeValue) {
            return LEFT;
        }
    }
    else if (!xChange && yChange) {
        if (y > kMinChangeValue) {
            return UP;
        } else if (y < -kMinChangeValue) {
            return DOWN;
        }
    }
    else if (xChange && yChange) {
        if (x > kMinChangeValue && y > kMinChangeValue) {
            return UPRIGHT;
        }
        else if (x < -kMinChangeValue && y > kMinChangeValue) {
            return UPLEFT;
        }
        else if (x > kMinChangeValue && y < -kMinChangeValue) {
            return DOWNRIGHT;
        }
        else if (x < -kMinChangeValue && y < -kMinChangeValue) {
            return DOWNLEFT;
        }
    }
    
    return NONE;
}

-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0f);
    [image drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma -
#pragma mark MotionManager responders

- (void)moveBall {
    NSInteger direction = [self getDirectionByPointX:self.motionManager.accelerometerData.acceleration.x andPointY:self.motionManager.accelerometerData.acceleration.y];
    double moveSpeed = [self getMoveSpeedByDirection:direction andRotationPointX:self.motionManager.gyroData.rotationRate.x andPointY:self.motionManager.gyroData.rotationRate.y];
    
    double duration = 1.0f / moveSpeed;
    
    double xOffset = [self getXOffsetByPointX:self.motionManager.accelerometerData.acceleration.x andMoveSpeed:moveSpeed];
    double yOffset = [self getYOffsetByPointY:self.motionManager.accelerometerData.acceleration.y andMoveSpeed:moveSpeed];
    
    if (xOffset == -1 || yOffset == -1) {
        return;
    }
    
    CAKeyframeAnimation *ballMove = [CAKeyframeAnimation animation];
    ballMove.keyPath = @"position";
    ballMove.values = @[[NSValue valueWithCGPoint:CGPointMake(((self.ball.frame.origin.x + kBallSize/2)), ((self.ball.frame.origin.y + kBallSize/2)))],
                        [NSValue valueWithCGPoint:CGPointMake(xOffset, yOffset)]];
    ballMove.duration = duration;
    [self.ball.layer addAnimation:ballMove forKey:@"ballMove"];
    self.ball.frame = CGRectMake(xOffset, yOffset, self.ball.frame.size.width, self.ball.frame.size.height);
    [self.view bringSubviewToFront:self.ball];
}

#pragma -
#pragma mark Timer responders

- (void)timeCnahged {
    self.totalTime += 1;
    if (self.currentSpeed < kMaxBallSpeed) {
        self.currentSpeed += 10;
    } else {
        self.currentSpeed = kMaxBallSpeed;
    }
    [self.timeLabel setText:[NSString stringWithFormat:@"%lds",(long)self.totalTime]];
    switch (self.totalTime) {
        case 30:
        {
            [self.timeLabel setTextColor:[UIColor yellowColor]];
            [self resizeCornerWithSize:200];
        }
            break;
        case 60:
        {
            [self.timeLabel setTextColor:[UIColor redColor]];
            [self resizeCornerWithSize:150];
        }
            break;
        default:
            break;
    }
}

- (void)stopTimer {
    NSInteger record = [[NSUserDefaults standardUserDefaults] integerForKey:@"kUserRecord"];
    if (self.totalTime > record) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.totalTime forKey:@"kUserRecord"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.recordLabel setText:[NSString stringWithFormat:@"Best result: %lds",(long)self.totalTime]];
    }
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma -
#pragma mark AlertView delegate responders

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0) {
        [self initBall];
    } else {
        [self stopButtonPressed:self];
    }
}

#pragma -
#pragma mark Action responders

- (IBAction)playResetButtonPressed:(id)sender {
    if (self.isPlaying == NO) {
        [self initBall];
        self.isPlaying = YES;
        [self setPlayResetButtonTitle];
    } else {
        [self resetBall];
    }
}

- (IBAction)clearButtonPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"kUserRecord"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.recordLabel setText:@"Best result: 0s"];
    self.totalTime = 0;
}

- (IBAction)stopButtonPressed:(id)sender {
    self.isPlaying = NO;
    [self setPlayResetButtonTitle];
    [self.clearButton setEnabled:YES];
    
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopAccelerometerUpdates];
    [self stopTimer];
    
    self.currentSpeed = kMinBallSpeed;
    self.totalTime = 0;
    [self.timeLabel setText:@"0s"];
    [self.timeLabel setTextColor:[UIColor greenColor]];
    
    self.ball.center = self.view.center;
    [self resizeCornerWithSize:kDefaultCornerSize];
}

@end

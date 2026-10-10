//  PlayViewController.m
//  MazeCube4
//
//  Created by Peter Kramer on 11/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
///   Version 2.2.3 has xInt, yInt,zInt fix in completeMaze so that position can be saved correctly.
//

#import "SelectViewController.h"
#import "PlayViewController.h"
#import "QuartzFunView.h"
//#import "VerificationControllerPBKsimple.h"

@implementation PlayViewController

@synthesize clickNoise;
@synthesize quartzFunView;
@synthesize gestureStartPoint;
@synthesize graphView;
@synthesize DisplayMazeNumber;
@synthesize DisplayMazeSize;
@synthesize DisplayEasyHard;
@synthesize DisplayMovestoFinish;
@synthesize DisplayTime;
@synthesize DisplayShowWalls;
// @synthesize showBestMove;
@synthesize bshowBestMove;
@synthesize bRestartMaze;
@synthesize SelShowWalls;
// @synthesize SelShowFloors;
@synthesize bSelShowFloors;
// @synthesize SelShowMoves;
@synthesize bSelShowMoves;
@synthesize bSelColorZW;
@synthesize MarkPosition;
@synthesize picker;
//@synthesize picker1;
@synthesize bLandscapeNext;
@synthesize bLandscapeRestart;
@synthesize LandscapePorousNormal;
// @synthesize LandscapeMoves;
@synthesize bLandscapeMoves;
// @synthesize LandscapePortals;
@synthesize bLandscapePortals;
//@synthesize LandscapeShowbestmove;
@synthesize bLandscapeShowbestmove;
// @synthesize LandscapeMovesButton;
// @synthesize LandscapePortalsButton;
//@synthesize LandscapeShowbestmoveButton;
@synthesize SelMazeSize;
@synthesize DisMazeNumber;
@synthesize SelSound;
@synthesize SelEasyHard;
@synthesize DisMazeSize;
@synthesize SlideMazeNumber;
@synthesize DisWarning;
@synthesize Label1;
@synthesize Segment1;
@synthesize bSegment2;
@synthesize Label2;
@synthesize Label3;
@synthesize Label4;
@synthesize Label5;
@synthesize Label6;
@synthesize Label7;
@synthesize bpurchaseMazes;
@synthesize spinner;


// @synthesize portalsButton;
// @synthesize moveButton;
@synthesize bNextMaze;



int HardMaze, NumMazeSize, ShowWalls,INumMazeNumber,ShowFloors;
int XMaze, YMaze, ZMaze,WMaze,Xxx,Yyy,Zzz,Www;
int bHardMaze, bNumMazeSize, bShowWalls, bShowFloors, bINumMazeNumber;
float XYxOrigin,XYyOrigin, ZxOrigin, ZyOrigin;
float MarkerSize, SpaceSize, EdgeSize,touchEdgeSize;
int Direction;
BOOL WallThere,porous;
int xBest,yBest,zBest,wBest;
int Count;
double randommax;
int Variable1;
float randomratio;
int WallEnd;
int itime,iminutes,iseconds,ihour, itimeDelta;
int mazeXYZ [42][42][42][42];
BOOL mazeWalls [42][42][42][42][10];
int delWall [5][10];
int inverseWall[10];
int frontierXYZ [3200000][5];
int wallFrontierList [10];
float gestureStartXvalue;
int wallCount;
float randomOne;
int wallRemove;
int frontierCount;
BOOL showingBestMove;
float twoThirty;
int newFrontier;
BOOL freeVersion;
NSString *temp1;
NSString *temp2;
BOOL firstTime;
BOOL loadYes;
int complexCount;
int firstTimeEver;
int xInt, yInt, zInt,wInt;
float timerBestMoveInterval;
BOOL showedCompletedMaze;
BOOL BestMoveTimerOn, BestMoveTimerAgain, BestMoveActive;
BOOL BestMoveOnAuto;
BOOL touchUnmoved;
BOOL showFloors;
int xNumMazeSize,yNumMazeSize,zNumMazeSize,wNumMazeSize;
int bxNumMazeSize,byNumMazeSize,bzNumMazeSize,bwNumMazeSize;
int mazeShape;
BOOL showMovesNumber;
int	intshowMovesNumber;
float symbolEdgesize,symbolXorigin,symbolYorigin,symbolZorigin,symbolWorigin;
float wColor[8][7];
int cCount,selectedColor;
int makeNoiseValue;
BOOL makeNoiseOn;
float	widthGraph, heightGraph;
BOOL iphoneisDevice;
int iphoneDelta;
int numberOfMazesCompleted;

float NumMazeNumber;
int xyzwNum;
int aNumMazeSize,aHardMaze,aINumMazeNumber,aaINumMazeNumber;
BOOL selectShowing,selectShowingJustOff;
BOOL timerOn;

float touchXvalueBase, touchYvalueBase,shiftXvalue,shiftYvalue,shiftZvalue,shiftWvalue;
BOOL XYnotWZ;

int numberOfMazesPurchased;

-(void) timeDisplay {
	iminutes=itime/60;
	iseconds=60*iminutes;
	iseconds=itime-iseconds;
	if (iseconds<10) {
	temp1 = [[NSString alloc] initWithFormat:@"Time: %d:0%d",iminutes, iseconds];
	}	else {
	temp1 = [[NSString alloc] initWithFormat:@"Time: %d:%d",iminutes, iseconds];
	}
	DisplayTime.text=temp1;
	[temp1 release];
}

-(void)addSecondandDisplay {
	if(!timerOn){
	timerOn=YES;
	SEL AddTime = @selector(timeTriggered);
	[NSTimer scheduledTimerWithTimeInterval:1.0
	 target:self
	   selector:AddTime
	   userInfo:nil
	repeats:NO];
	}
}

-(void) timeTriggered {
	timerOn=NO;
	if(itimeDelta==2){
	itime=itime-1;
	itimeDelta=1;
	}
	if (itimeDelta==1) {
	[self addSecondandDisplay];
	if (self.view.superview&&!selectShowing) {
	itime=itime+1;
	[self timeDisplay];
	} else {
	//[showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	//[LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
    [bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
    [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
    bshowBestMove.backgroundColor=[UIColor clearColor];
    bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	showingBestMove=NO;
	}
	}
}

-(void) startCounting {
	itimeDelta=1;
	[self addSecondandDisplay];
}

-(void) stopCounting {
	itimeDelta=0;
	if(BestMoveOnAuto){
	[self showBestMovePressed:nil];
	[self endShowBestMove:nil];
	}
}

-(NSString *) dataFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex: 0];
	return [documentsDirectory stringByAppendingPathComponent:kFilename];
}

-(void) saveInfo {
	intshowMovesNumber=0;
	if(showMovesNumber)intshowMovesNumber=1;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:firstTimeEver forKey:firstTimerWord];
	[userDefaults setInteger:XMaze forKey:XMazeWord];
	[userDefaults setInteger:YMaze forKey:YMazeWord];
	[userDefaults setInteger:ZMaze forKey:ZMazeWord];
	[userDefaults setInteger:WMaze forKey:WMazeWord];
	[userDefaults setInteger:intshowMovesNumber forKey:MoveNumberWord];
	[userDefaults setInteger:INumMazeNumber forKey:MazeNumberWord];
	[userDefaults setInteger:NumMazeSize forKey:MazeSizeWord];
	[userDefaults setInteger:xNumMazeSize forKey:xMazeSizeWord];
	[userDefaults setInteger:yNumMazeSize forKey:yMazeSizeWord];
	[userDefaults setInteger:zNumMazeSize forKey:zMazeSizeWord];
	[userDefaults setInteger:wNumMazeSize forKey:wMazeSizeWord];
	[userDefaults setInteger:HardMaze forKey:HardMazeWord];
	[userDefaults setInteger:ShowWalls forKey:ShowWallsWord];
	[userDefaults setInteger:ShowFloors forKey:ShowFloorsWord];
	[userDefaults setInteger:itime forKey:itimeWord];
	[userDefaults setInteger:mazeShape forKey:mazeShapeWord];
	[userDefaults setInteger:selectedColor forKey:SelectedColorWord];
	[userDefaults setBool:makeNoiseOn forKey:makeNoiseWord];
	[userDefaults setInteger:numberOfMazesCompleted	forKey:mazesCompletedWord];
//	[userDefaults setInteger:numberOfMazesPurchased forKey:@"NumberOfMazesPurchased"];






	NSMutableArray *array=[[NSMutableArray alloc] init];
	[array addObject:kFieldYes];
	for (Xxx=1;Xxx<xNumMazeSize+1; Xxx=Xxx+1) {
	for (Yyy=1;Yyy<yNumMazeSize+1; Yyy=Yyy+1) {
	for (Zzz=1;Zzz<zNumMazeSize+1; Zzz=Zzz+1) {
	for (Www=1;Www<wNumMazeSize+1; Www=Www+1) {
	if (mazeWalls[Xxx][Yyy][Zzz][Www][9]==NO){
	[array addObject:kFieldNo];
	}else {
	[array addObject:kFieldYes];
	}
	}
	}
	}
	}
	[array writeToFile:[self dataFilePath] atomically:YES];
	[array release];
}


-(void) viewBeingCalled {
	widthGraph=675.0-iphoneDelta*18.75;
	heightGraph=540.0-iphoneDelta*14.5;
	EdgeSize=widthGraph/(wNumMazeSize+xNumMazeSize+2.0);
	if (EdgeSize>heightGraph/zNumMazeSize) EdgeSize=heightGraph/(zNumMazeSize);
	if (EdgeSize>heightGraph/yNumMazeSize) EdgeSize=heightGraph/(yNumMazeSize);
	Count=EdgeSize;
	Count=Count/2;
	EdgeSize=Count*2;
//	if (xNumMazeSize+wNumMazeSize==36) EdgeSize=EdgeSize+2;
	touchEdgeSize=EdgeSize;
	if(touchEdgeSize<20.0)touchEdgeSize=20.0;
	ZxOrigin=1.0*EdgeSize-1.0+0.25*(widthGraph+20.0-EdgeSize*(wNumMazeSize+xNumMazeSize+2.0))+iphoneDelta/2.0; //+ .1*(320.0-twoThirty);
	//   .5 on left, wnum, 1.0 in center, xnum, .5 on right then divide rest .25/.5/.25
	Count=ZxOrigin;
	ZxOrigin=Count;
//	if (xNumMazeSize+wNumMazeSize==36) ZxOrigin=ZxOrigin-2;
	ZyOrigin=20.0+EdgeSize*0.5+0.5*(heightGraph-EdgeSize*zNumMazeSize)-.5*iphoneDelta;
	Count=ZyOrigin;
	ZyOrigin=Count+10.0;
	XYxOrigin=ZxOrigin+EdgeSize*(wNumMazeSize+1.0)+0.50*(widthGraph+20.0-EdgeSize*(wNumMazeSize+xNumMazeSize+2.0))-iphoneDelta/2;
	Count= XYxOrigin;
	XYxOrigin=Count;
//	if (xNumMazeSize+wNumMazeSize==36) XYxOrigin=XYxOrigin+4;
	XYyOrigin=20.0+EdgeSize*0.5+0.5*(heightGraph-EdgeSize*yNumMazeSize)-0.5*iphoneDelta;
	Count=XYyOrigin;
	XYyOrigin=Count+10.0;


//    first time bINumMazeNumber is -1 so this is done, in the future whenever values change this is done again


	if ((bINumMazeNumber!=INumMazeNumber)||(bxNumMazeSize!=xNumMazeSize)||(byNumMazeSize!=yNumMazeSize)
	||(bzNumMazeSize!=zNumMazeSize)||(bwNumMazeSize!=wNumMazeSize)||(bHardMaze!=HardMaze)) {
	bINumMazeNumber=INumMazeNumber;
	bHardMaze=HardMaze;
	bxNumMazeSize=xNumMazeSize;
	byNumMazeSize=yNumMazeSize;
	bzNumMazeSize=zNumMazeSize;
	bwNumMazeSize=wNumMazeSize;
	[self createMazes];
	[self clearAllMarkers];
	[self RestartMaze:nil];
	}
	if(loadYes){
	[self createMazes];
	loadYes=NO;
	}
	temp1=[[NSString alloc] initWithFormat:@"Maze Size %dx%dx%dx%d",wNumMazeSize, zNumMazeSize,yNumMazeSize,xNumMazeSize];
	DisplayMazeSize.text=temp1;
	[temp1 release];
	[self timeDisplay];
//  timer advances at beginning too quickly
	if (itimeDelta==1&&iphoneisDevice)itimeDelta=2;
	SelShowWalls.selectedSegmentIndex=ShowWalls;
	// SelShowFloors.selectedSegmentIndex=ShowFloors;
	LandscapePorousNormal.selectedSegmentIndex=ShowWalls;
	// LandscapePortals.selectedSegmentIndex=ShowFloors;
	porous=NO;
	if(ShowWalls==0) porous=YES;
	showFloors=NO;
	if(ShowFloors==0)showFloors=YES;
	[quartzFunView mazeClear];
	[self drawMaze];
}


- (void)viewDidLoad {
    // NSLog(@" playview controller viewdidload");
//	NSString *path2 = [[NSBundle mainBundle] pathForResource:@"62708__hanstimm__tick91ed11" ofType:@"aiff"];
    float xDisplace=([[UIScreen mainScreen] bounds].size.width-320)/2;
    float yDisplace=([[UIScreen mainScreen] bounds].size.height-500)/2;
    if(yDisplace<0){
        yDisplace=0;
    }
 //   NSLog(@"the displacement is %f   %f",xDisplace,yDisplace);


    containerView.frame=CGRectMake(xDisplace, yDisplace, 320, 550);




    if(![[[UIDevice currentDevice] model] containsString:@"iPhone"]){
        xDisplace=([[UIScreen mainScreen] bounds].size.width-750)/2;
        yDisplace=([[UIScreen mainScreen] bounds].size.height-850)/2;
        if(yDisplace<100)yDisplace=100;
        self.view.frame=CGRectMake(xDisplace, yDisplace-100, 750,850);
    }






	NSString *path1 = [[NSBundle mainBundle] pathForResource:@"tap11" ofType:@"aiff"]; // had trouble linking to it and changed it to aiff not aif
	AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path1
                                                ], &clickNoise);

    timerOn=NO;
	selectShowing=NO;
	selectShowingJustOff=NO;
	if (!(self.view.superview)) {
	// load variables


	xyzwNum=1;
	hypercubeNames=[[NSArray alloc] initWithObjects:
	@"1D Line",@"2D Lines",@"2D Square",@"3D Squares",@"3D Cube",@"4D Cubes",
	@"4D Tesseract",@"Free Form",nil];
	edgeNumbers=[[NSArray alloc] initWithObjects:
	 @"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",
	 @"15",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",@"24",@"25",@"26",
	 @"27",@"28",@"29",@"30",@"31",@"32",@"33",@"34",@"35",@"36",@"37",@"38",@"39",@"40",nil];




	selectedColor=1;
	freeVersion=NO;
	showingBestMove=NO;
	// [showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	//[LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
        [bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
        [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
        bshowBestMove.backgroundColor=[UIColor clearColor];
        bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	inverseWall[1]=4;
	inverseWall[2]=5;
	inverseWall[3]=6;
	inverseWall[4]=1;
	inverseWall[5]=2;
	inverseWall[6]=3;
	inverseWall[7]=8;
	inverseWall[8]=7;
	delWall[1][1]=1;
	delWall[1][2]=0;
	delWall[1][3]=0;
	delWall[1][4]=-1;
	delWall[1][5]=0;
	delWall[1][6]=0;
	delWall[2][1]=0;
	delWall[2][2]=1;
	delWall[2][3]=0;
	delWall[2][4]=0;
	delWall[2][5]=-1;
	delWall[2][6]=0;
	delWall[3][1]=0;
	delWall[3][2]=0;
	delWall[3][3]=1;
	delWall[3][4]=0;
	delWall[3][5]=0;
	delWall[3][6]=-1;
	delWall[4][1]=0;
	delWall[4][2]=0;
	delWall[4][3]=0;
	delWall[4][4]=0;
	delWall[4][5]=0;
	delWall[4][6]=0;
	delWall[1][7]=0;
	delWall[2][7]=0;
	delWall[3][7]=0;
	delWall[4][7]=1;
	delWall[1][8]=0;
	delWall[2][8]=0;
	delWall[3][8]=0;
	delWall[4][8]=-1;
	wColor[1][1]=.76;
	wColor[1][2]=.66;
	wColor[1][3]=.56;
	wColor[0][1]=1;
	wColor[0][2]=1;
	wColor[0][3]=1;
	wColor[2][1]=1.;
	wColor[2][2]=0.;
	wColor[2][3]=0.;
	wColor[3][1]=1.;
	wColor[3][2]=.5;
	wColor[3][3]=0.;
	wColor[4][1]=.95;
	wColor[4][2]=.95;
	wColor[4][3]=0.;
	wColor[5][1]=0.;
	wColor[5][2]=1.;
	wColor[5][3]=0.;
	wColor[6][1]=0.;
	wColor[6][2]=1.;
	wColor[6][3]=1.;
	wColor[7][1]=1.;
	wColor[7][2]=.5;
	wColor[7][3]=1.;
	wColor[1][4]=.76*.55+.45;
	wColor[1][5]=.66*.55+.45;
	wColor[1][6]=.56*.55+.45;
	wColor[0][4]=.75;
	wColor[0][5]=.75;
	wColor[0][6]=.75;
	wColor[2][4]=1.*.55+.45;
	wColor[2][5]=0.*.55+.45;
	wColor[2][6]=0.*.55+.45;
	wColor[3][4]=1.*.55+.45;
	wColor[3][5]=.5*.55+.45;
	wColor[3][6]=0.*.55+.45;
	wColor[4][4]=.95*.2+.8;
	wColor[4][5]=.95*.2+.8;
	wColor[4][6]=0.*.2+.8;
	wColor[5][4]=0.*.35+.65;
	wColor[5][5]=1.*.35+.65;
	wColor[5][6]=0.*.35+.65;
	wColor[6][4]=0.*.25+.75;
	wColor[6][5]=1.*.25+.75;
	wColor[6][6]=1.*.25+.75;
	wColor[7][4]=1.*.45+.55;
	wColor[7][5]=.5*.45+.55;
	wColor[7][6]=1.*.45+.55;
	makeNoiseValue=0;
	makeNoiseOn=YES;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	firstTimeEver= (int)[userDefaults integerForKey:firstTimerWord];
//	firstTimeEver=1;
	if ( firstTimeEver!=36) {    //
	XMaze=1;
	YMaze=1;
	ZMaze=1;
	WMaze=1;
	INumMazeNumber= 1;
	NumMazeSize = 2;
	xNumMazeSize=2;
	yNumMazeSize=2;
	zNumMazeSize=2;
	wNumMazeSize=2;
	HardMaze = 0;
	ShowWalls= 1;
	ShowFloors=-1;
	itime=0;
	mazeShape=7;
	intshowMovesNumber=1;
	firstTimeEver=36;
	selectedColor=1;
	makeNoiseOn=YES;
	numberOfMazesCompleted=0;
	//	numberOfMazesPurchased=2;


	[self clearAllMarkers];
	}else {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	XMaze=(int)[userDefaults integerForKey:XMazeWord];
	YMaze=(int)[userDefaults integerForKey:YMazeWord];
	ZMaze=(int)[userDefaults integerForKey:ZMazeWord];
	WMaze=(int)[userDefaults integerForKey:WMazeWord];
	INumMazeNumber= (int)[userDefaults integerForKey:MazeNumberWord];
	NumMazeSize = (int)[userDefaults integerForKey:MazeSizeWord];
	xNumMazeSize = (int)[userDefaults integerForKey:xMazeSizeWord];
	yNumMazeSize = (int)[userDefaults integerForKey:yMazeSizeWord];
	zNumMazeSize = (int)[userDefaults integerForKey:zMazeSizeWord];
	wNumMazeSize = (int)[userDefaults integerForKey:wMazeSizeWord];
	intshowMovesNumber=(int)[userDefaults integerForKey:MoveNumberWord];
	HardMaze = (int)[userDefaults integerForKey:HardMazeWord];
	ShowWalls= (int)[userDefaults integerForKey: ShowWallsWord];
	ShowFloors= (int)[userDefaults integerForKey: ShowFloorsWord];
	itime=(int)[userDefaults integerForKey:itimeWord];
	mazeShape=(int)[userDefaults integerForKey:mazeShapeWord];
	selectedColor=(int)[userDefaults integerForKey:SelectedColorWord];
	makeNoiseOn=[userDefaults boolForKey:makeNoiseWord];
	numberOfMazesCompleted=(int)[userDefaults integerForKey:mazesCompletedWord];


	//	if (numberOfMazesCompleted<16 && numberOfMazesCompleted>0)numberOfMazesCompleted=16;
            if(numberOfMazesCompleted==15)numberOfMazesCompleted=14;


	//	numberOfMazesPurchased=[userDefaults integerForKey:@"NumberOfMazesPurchased"];
	//	if(numberOfMazesPurchased==0)numberOfMazesPurchased=2;






	NSString *filePath = [self dataFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
	NSArray *array=[[NSArray alloc] initWithContentsOfFile:filePath];
	Count=1;
	temp1=[array objectAtIndex:0];
	for (Xxx=1;Xxx<xNumMazeSize+1; Xxx=Xxx+1) {
	for (Yyy=1;Yyy<yNumMazeSize+1; Yyy=Yyy+1) {
	for (Zzz=1;Zzz<zNumMazeSize+1; Zzz=Zzz+1) {
	for (Www=1;Www<wNumMazeSize+1; Www=Www+1) {
	mazeWalls[Xxx][Yyy][Zzz][Www][9]=([temp1 isEqual:[array objectAtIndex:Count]]);
	Count=Count+1;
	}
	}
	}
	}
	[array release];
	} else {
	[self clearAllMarkers];
	}
	}
        iphoneisDevice=[[[UIDevice currentDevice] model] containsString:@"iPhone"];
        if (iphoneisDevice) {
	iphoneDelta=20.0;
            // NSLog(@"set the iphone device here in playview");
	}






        /*
//        inAppAvailable=NO;
        //NSLog(@"here in viewedidload playvc  with numberofmazespuerchased=%i",numberOfMazesPurchased);
        if(numberOfMazesPurchased<100 && !iphoneisDevice){   // ipad uses this in popover, iphones uses selectview
           // NSLog(@"and surprise -----it's here!!!!");
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//            inAppAvailable=YES;
        }
        */




        numberOfMazesPurchased=2;
        int deviceCode=(unsigned)[[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash]%1000000;
        if((int)[userDefaults integerForKey:@"NumberOfMazesPurchased"]==deviceCode){
            numberOfMazesPurchased=100;
            [userDefaults setInteger:deviceCode forKey:@"NumberOfMazesPurchased"];
        }
        int versionNumber=620;  //version 6.2
        [userDefaults setInteger:versionNumber forKey:@"VersionNumber"];
        [userDefaults synchronize];






	if (intshowMovesNumber==1)showMovesNumber=YES;
	/* 	if (!showMovesNumber)[SelShowMoves setSelectedSegmentIndex:-1];
	if (showMovesNumber)[SelShowMoves setSelectedSegmentIndex:0];
	if (!showMovesNumber)[LandscapeMoves setSelectedSegmentIndex:-1];
	if (showMovesNumber)[LandscapeMoves setSelectedSegmentIndex:0]; */
	loadYes=YES;
	bxNumMazeSize=xNumMazeSize;
	byNumMazeSize=yNumMazeSize;
	bzNumMazeSize=zNumMazeSize;
	bwNumMazeSize=wNumMazeSize;
	bINumMazeNumber=INumMazeNumber;
	bNumMazeSize=NumMazeSize;
	bHardMaze=HardMaze;


	[self PortraitMode];
	}


    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone &&
       [[UIScreen mainScreen] bounds].size.height >= 568){




        DisplayMazeSize.frame=CGRectMake(DisplayMazeSize.frame.origin.x, DisplayMazeSize.frame.origin.y-20, DisplayMazeSize.frame.size.width, DisplayMazeSize.frame.size.height);


    //    float down2=66.0;
        /*
        SelColorZW.frame=CGRectMake(SelShowWalls.frame.origin.x+10 +44, SelShowWalls.frame.origin.y+53-53, SelShowWalls.frame.size.width/2, SelShowWalls.frame.size.height);


        SelShowWalls.frame=CGRectMake(SelShowWalls.frame.origin.x+10, SelShowWalls.frame.origin.y+53, SelShowWalls.frame.size.width, SelShowWalls.frame.size.height);
        SelShowFloors.frame=CGRectMake(SelShowFloors.frame.origin.x-17, SelShowFloors.frame.origin.y +10,SelShowFloors.frame.size.width, SelShowFloors.frame.size.height);
        portalsButton.frame=CGRectMake(portalsButton.frame.origin.x-17, portalsButton.frame.origin.y +10,portalsButton.frame.size.width, portalsButton.frame.size.height);
        NextMaze.frame=CGRectMake(NextMaze.frame.origin.x+20, NextMaze.frame.origin.y+down2, NextMaze.frame.size.width, NextMaze.frame.size.height);
        RestartMaze.frame=CGRectMake(RestartMaze.frame.origin.x+34, RestartMaze.frame.origin.y+down2, RestartMaze.frame.size.width, RestartMaze.frame.size.height);
        SelShowMoves.frame=CGRectMake(SelShowMoves.frame.origin.x+60, SelShowMoves.frame.origin.y+down2, SelShowMoves.frame.size.width, SelShowMoves.frame.size.height);




        moveButton.frame=CGRectMake(moveButton.frame.origin.x+60, moveButton.frame.origin.y+down2, moveButton.frame.size.width, moveButton.frame.size.height);


        */
    }






	[super viewDidLoad];


}



-(void)processButton:(UIButton *)button{
    button.layer.cornerRadius=10.0;
    button.layer.borderColor=[UIColor whiteColor].CGColor;
    button.layer.borderWidth=1.0f;
    button.backgroundColor=[UIColor clearColor];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];


    [self processButton:bLandscapeShowbestmove];
    [self processButton:bshowBestMove];
    [self processButton:bSelShowFloors];
    [self processButton:bLandscapePortals];
    [self processButton:bSelShowMoves];
    [self processButton:bLandscapeMoves];
    [self processButton:bRestartMaze];
    [self processButton:bLandscapeRestart];
    [self processButton:bLandscapeNext];
    [self processButton:bNextMaze];
    [self processButton:bSegment2];
    [self processButton:bpurchaseMazes];
    [self processButton:bSelColorZW];


 //   do button for:      bLandscapeShowbestmove
    NSArray *theControls=[NSArray arrayWithObjects:SelShowWalls,SelSound,LandscapePorousNormal,SelEasyHard,nil];
    // NSLog(@"count is %li",[theControls count]);
    for(int iCount=0;iCount<[theControls count];iCount++){
     //   [self processSegmentControl:[theControls objectAtIndex:iCount]];
        UISegmentedControl *aControl= [theControls objectAtIndex:iCount];
       aControl.layer.borderColor = [UIColor whiteColor].CGColor;
       aControl.layer.borderWidth=1.0f;


        [aControl setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                    [UIFont boldSystemFontOfSize:13.0f],NSFontAttributeName,
                    [UIColor whiteColor],NSForegroundColorAttributeName,
                                         nil] forState:UIControlStateNormal];
        [aControl setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont boldSystemFontOfSize:13.0],NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           nil] forState:UIControlStateSelected];






        // NSLog(@"here  111");
    }




}
-(void)LandscapeMode {
	[bLandscapeNext setHidden:NO];
	[bLandscapeRestart setHidden:NO];
	[LandscapePorousNormal setHidden:NO];
	[bLandscapeMoves setHidden:NO];
	[bLandscapePortals setHidden:NO];
    //   [LandscapePortals setHidden:NO];
	//[LandscapeShowbestmove setHidden:NO];
    [bLandscapeShowbestmove setHidden:NO];
	// [LandscapeMovesButton setHidden:NO];
	// [LandscapePortalsButton setHidden:NO];
	//[LandscapeShowbestmoveButton setHidden:NO];
    if(![[[UIDevice currentDevice] model] containsString:@"iPhone"]){ // not needed
        float xDisplace=([[UIScreen mainScreen] bounds].size.width-750)/2;
        float yDisplace=([[UIScreen mainScreen] bounds].size.height-750)/2;
       //  if(yDisplace<100)yDisplace=100;
        self.view.frame=CGRectMake(xDisplace, 0, 750,800);
        if(yDisplace>xDisplace)
            self.view.frame=CGRectMake(yDisplace, 0, 750,800);
    }

 }
-(void)PortraitMode{
	[bLandscapeNext setHidden:YES];
	[bLandscapeRestart setHidden:YES];
	[LandscapePorousNormal setHidden:YES];
	[bLandscapeMoves setHidden:YES];
	// [LandscapePortals setHidden:YES];
        [bLandscapePortals setHidden:YES];
    [bLandscapeShowbestmove setHidden:YES];
	//[LandscapeShowbestmove setHidden:YES];
	//[LandscapeMovesButton setHidden:YES];
	// [LandscapePortalsButton setHidden:YES];
	//[LandscapeShowbestmoveButton setHidden:YES];
    if(![[[UIDevice currentDevice] model] containsString:@"iPhone"]){ // not needed
        float xDisplace=([[UIScreen mainScreen] bounds].size.width-750)/2;
        float yDisplace=([[UIScreen mainScreen] bounds].size.height-750)/2;
        if(xDisplace>yDisplace){
            float temp=xDisplace;
            xDisplace=yDisplace;
            yDisplace=temp;
        }
        if(yDisplace<150)yDisplace=150;
        self.view.frame=CGRectMake(xDisplace, yDisplace-150, 750,850);
    }



 }


-(void)getRandom:(id)sender {
	randommax=2148000000.0;
	randomOne=1.0*rand()/randommax;
	if (randomOne>0.99) randomOne=0.99;
}

-(void) drawMazeXY:(id)sender {
	if (xNumMazeSize==1) {
	[quartzFunView mazeLineWidth:EdgeSize];
	for (Variable1=1; Variable1<yNumMazeSize+1; Variable1=Variable1+ 1) {
	cCount=Variable1;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(yNumMazeSize==1)cCount=selectedColor;
	[quartzFunView mazeColorRed:wColor[cCount][1] green:wColor[cCount][2] blue:wColor[cCount][3]	alpha:.75];
	[quartzFunView mazeLineStartX:XYxOrigin-0.5*EdgeSize
	   ystart:XYyOrigin-1.5*EdgeSize+Variable1*EdgeSize+1
	 xend:XYxOrigin+0.5*EdgeSize
	 yend:XYyOrigin-1.5*EdgeSize+Variable1*EdgeSize+1];
	[quartzFunView mazeAddLine];
	}
	}
	if (xNumMazeSize>1) {
	[quartzFunView mazeLineWidth:EdgeSize];
	for (Variable1=1; Variable1<xNumMazeSize+1; Variable1=Variable1+ 1) {
	cCount=Variable1;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	[quartzFunView mazeColorRed:wColor[cCount][1] green:wColor[cCount][2] blue:wColor[cCount][3]	alpha:.75];
	[quartzFunView mazeLineStartX:XYxOrigin-1.5*EdgeSize+Variable1*EdgeSize+1
	   ystart:XYyOrigin-0.5*EdgeSize
	 xend:XYxOrigin-1.5*EdgeSize+Variable1*EdgeSize+1
	 yend:XYyOrigin-0.5*EdgeSize+yNumMazeSize*EdgeSize];
	[quartzFunView mazeAddLine];
	}
	}
	Zzz=ZMaze;
	Www=WMaze;
	if(!showFloors){
	  for (Xxx=1;Xxx<xNumMazeSize+1;Xxx=Xxx+1) {
	for (Yyy=1;Yyy<yNumMazeSize+1;Yyy=Yyy+1) {
	[self drawLine:1 :((mazeWalls[Xxx][Yyy][Zzz][Www][1])) :Xxx :Yyy :Zzz :Www];
	[self drawLine:2 :((mazeWalls[Xxx][Yyy][Zzz][Www][2])):Xxx :Yyy :Zzz :Www];
	[self MarkPositionXY:nil];
	}
	  }
	}
	WallThere=YES;
	for (Count=1; Count< xNumMazeSize+1; Count=Count+1) {
	Xxx=Count;
	Yyy=0;
	[self drawLine:2 :WallThere :Xxx :Yyy :Zzz :Www];
	Yyy=yNumMazeSize;
	[self drawLine:2 :WallThere :Xxx :Yyy :Zzz :Www];
	Zzz=Count;
	}
	Zzz=ZMaze;
	for (Count=1; Count< yNumMazeSize+1; Count=Count+1) {
	Xxx=xNumMazeSize;
	Yyy=Count;
	[self drawLine:1 :WallThere :Xxx :Yyy :Zzz :Www];
	Xxx=0;
	[self drawLine:1 :WallThere :Xxx :Yyy :Zzz :Www];
	Zzz=Count;
	}
	[self drawXYSymbols];


}


-(void)drawNoFloorXY {
	Zzz=ZMaze;
	Www=WMaze;
	for (Xxx=1;Xxx<xNumMazeSize+1;Xxx=Xxx+1) {
	for (Yyy=1;Yyy<yNumMazeSize+1;Yyy=Yyy+1) {
	cCount=Yyy;
	if(xNumMazeSize>1)cCount=Xxx;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(xNumMazeSize+yNumMazeSize==2)cCount=selectedColor;
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][7])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:XYxOrigin+(Xxx-0.5)*EdgeSize-EdgeSize/4.0
	   ystart:XYyOrigin+(Yyy-1.5)*EdgeSize+2
	 xend:XYxOrigin+(Xxx-0.5)*EdgeSize-EdgeSize/4.0
	 yend:XYyOrigin+(Yyy-0.5)*EdgeSize];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][8])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:XYxOrigin+(Xxx-1.5)*EdgeSize+2
	   ystart:XYyOrigin+(Yyy-1.5)*EdgeSize+2
	 xend:XYxOrigin+(Xxx-1.5)*EdgeSize+2
	 yend:XYyOrigin+(Yyy-0.5)*EdgeSize];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][3])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:XYxOrigin+(Xxx-1.5)*EdgeSize+2
	   ystart:XYyOrigin+(Yyy-0.5)*EdgeSize-EdgeSize/4.0
	 xend:XYxOrigin+(Xxx-0.5)*EdgeSize
	 yend:XYyOrigin+(Yyy-0.5)*EdgeSize-EdgeSize/4.0];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][6])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:XYxOrigin+(Xxx-1.5)*EdgeSize+2
	   ystart:XYyOrigin+(Yyy-1.5)*EdgeSize+2
	 xend:XYxOrigin+(Xxx-0.5)*EdgeSize
	 yend:XYyOrigin+(Yyy-1.5)*EdgeSize+2];
	[quartzFunView mazeAddLine];
	}
	[self drawLine:1 :((mazeWalls[Xxx][Yyy][Zzz][Www][1])) :Xxx :Yyy :Zzz :Www];
	[self drawLine:2 :((mazeWalls[Xxx][Yyy][Zzz][Www][2])):Xxx :Yyy :Zzz :Www];
	[self MarkPositionXY:nil];
	}
	}
	Xxx=XMaze;
	Yyy=YMaze;
	cCount=Yyy;
	if(xNumMazeSize>1)cCount=Xxx;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(xNumMazeSize+yNumMazeSize==2)cCount=selectedColor;
	for (Zzz=1;Zzz<zNumMazeSize+1;Zzz=Zzz+1) {
	for (Www=1; Www<wNumMazeSize+1; Www=Www+1) {
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][1])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:ZxOrigin+(Www-0.5)*EdgeSize-EdgeSize/4.0
	   ystart:ZyOrigin+(Zzz-1.5)*EdgeSize+2
	 xend:ZxOrigin+(Www-0.5)*EdgeSize-EdgeSize/4.0
	 yend:ZyOrigin+(Zzz-0.5)*EdgeSize];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][4])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:ZxOrigin+(Www-1.5)*EdgeSize+2
	   ystart:ZyOrigin+(Zzz-1.5)*EdgeSize+2
	 xend:ZxOrigin+(Www-1.5)*EdgeSize+2
	 yend:ZyOrigin+(Zzz-0.5)*EdgeSize];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][2])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:ZxOrigin+(Www-1.5)*EdgeSize+2
	   ystart:ZyOrigin+(Zzz-0.5)*EdgeSize-EdgeSize/4.0
	 xend:ZxOrigin+(Www-0.5)*EdgeSize
	 yend:ZyOrigin+(Zzz-0.5)*EdgeSize-EdgeSize/4.0];
	[quartzFunView mazeAddLine];
	}
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][5])) {
	[quartzFunView mazeLineWidth:EdgeSize/4.0];
	[quartzFunView mazeColorRed:wColor[cCount][4] green:wColor[cCount][5] blue:wColor[cCount][6] alpha:1.];
	[quartzFunView mazeLineStartX:ZxOrigin+(Www-1.5)*EdgeSize+2
	   ystart:ZyOrigin+(Zzz-1.5)*EdgeSize+2
	 xend:ZxOrigin+(Www-0.5)*EdgeSize
	 yend:ZyOrigin+(Zzz-1.5)*EdgeSize+2];
	[quartzFunView mazeAddLine];
	}
	[self drawLine:3 :((mazeWalls[Xxx][Yyy][Zzz][Www][3])) :Xxx :Yyy :Zzz :Www];
	[self drawLine:7 :((mazeWalls[Xxx][Yyy][Zzz][Www][7])) :Xxx :Yyy :Zzz :Www];
	[self MarkPositionZZ:nil];
	}
	}
}

-(void)drawExitXY:(BOOL)colorIt {
	Count=1;
	if(mazeWalls[xNumMazeSize][yNumMazeSize][zNumMazeSize][wNumMazeSize][5])Count=0;
	Variable1=1;
	if(mazeWalls[xNumMazeSize][yNumMazeSize][zNumMazeSize][wNumMazeSize][4])Variable1=0;
	[quartzFunView mazeLineWidth:EdgeSize-2+Count];
	[quartzFunView mazeColorRed:.7 green:.6 blue:.5	alpha:1.0];
	if(colorIt)	[quartzFunView mazeColorRed:.4 green:.6 blue:.9	alpha:1.0];
	[quartzFunView mazeLineStartX:XYxOrigin+1+(xNumMazeSize-1.5)*EdgeSize+1-Variable1
	   ystart:XYyOrigin+1+(yNumMazeSize-1.5)*EdgeSize+1-Count
	 xend:XYxOrigin+1+(xNumMazeSize-0.5)*EdgeSize-1
	 yend:XYyOrigin+1+(yNumMazeSize-1.5)*EdgeSize+1-Count];
	[quartzFunView mazeAddLine];
	[self drawLine:2 :((mazeWalls[Xxx][Yyy][Zzz][Www][2])):Xxx :Yyy :Zzz :Www];
}

-(void)drawExitZ:(BOOL)colorIt {
	[quartzFunView mazeLineWidth:EdgeSize-2];
	[quartzFunView mazeColorRed:.7 green:.6 blue:.5	alpha:1.0];
	if(colorIt)	[quartzFunView mazeColorRed:.4 green:.6 blue:.9	alpha:1.0];
	[quartzFunView mazeLineStartX:ZxOrigin+2+(wNumMazeSize-1.0)*EdgeSize-EdgeSize/2.0
	   ystart:ZyOrigin+2+(zNumMazeSize-1.0)*EdgeSize-EdgeSize/2.0
	 xend:ZxOrigin+2+(wNumMazeSize-1.0)*EdgeSize-EdgeSize/2.0
	 yend:ZyOrigin+(zNumMazeSize-1.0)*EdgeSize+EdgeSize/2.0];
	[quartzFunView mazeAddLine];
}


-(void)drawEntranceXY:(BOOL)colorIt {
	[quartzFunView mazeLineWidth:EdgeSize-2.0];
	[quartzFunView mazeColorRed:.7 green:.6 blue:.5	alpha:1.0];
	if(colorIt)	[quartzFunView mazeColorRed:.3 green:.8 blue:.5	alpha:1.0];
	[quartzFunView mazeLineStartX:XYxOrigin+2-EdgeSize/2.0
	   ystart:XYyOrigin+2-EdgeSize/2.0
	 xend:XYxOrigin+2-EdgeSize/2.0
	 yend:XYyOrigin+EdgeSize/2.0];
	[quartzFunView mazeAddLine];
}


-(void)drawEntranceZ:(BOOL)colorIt {
	[quartzFunView mazeLineWidth:EdgeSize-2.0];
	[quartzFunView mazeColorRed:.7 green:.6 blue:.5	alpha:1.0];
	if(colorIt)	[quartzFunView mazeColorRed:.3 green:.8 blue:.5	alpha:1.0];
	[quartzFunView mazeLineStartX:(ZxOrigin+2)-EdgeSize/2.0
	   ystart:(ZyOrigin+2)-EdgeSize/2.0
	 xend:(ZxOrigin+2)-EdgeSize/2.0
	 yend:(ZyOrigin-0.5)+EdgeSize/2.0];
	[quartzFunView mazeAddLine];
}


-(void) drawMazeZ:(id)sender {
	if(yNumMazeSize>1)cCount=YMaze;
	if(xNumMazeSize>1)cCount=XMaze;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(cCount>7)cCount=cCount-6;
	if(xNumMazeSize+yNumMazeSize==2)cCount=selectedColor;
	[quartzFunView mazeLineWidth:EdgeSize*zNumMazeSize];
	[quartzFunView mazeColorRed:wColor[cCount][1] green:wColor[cCount][2] blue:wColor[cCount][3]	alpha:.75];
	[quartzFunView mazeLineStartX:ZxOrigin-0.5*EdgeSize
	   ystart:ZyOrigin-0.5*EdgeSize
	 xend:ZxOrigin-0.5*EdgeSize+EdgeSize*wNumMazeSize
	 yend:ZyOrigin-0.5*EdgeSize];
	[quartzFunView mazeAddLine];
	Xxx=XMaze;
	Yyy=YMaze;
	if(!showFloors){
	  for (Zzz=1;Zzz<zNumMazeSize+1;Zzz=Zzz+1) {
	for (Www=1; Www<wNumMazeSize+1; Www=Www+1) {
	[self drawLine:3 :((mazeWalls[Xxx][Yyy][Zzz][Www][3])) :Xxx :Yyy :Zzz :Www];
	[self drawLine:7 :((mazeWalls[Xxx][Yyy][Zzz][Www][7])) :Xxx :Yyy :Zzz :Www];
	[self MarkPositionZZ:nil];
	}
	  }
	}
	WallThere=YES;
	for (Count=1; Count< wNumMazeSize+1; Count=Count+1) {
	Www=Count;
	Zzz=0;
	[self drawLine:3 :WallThere :Xxx :Yyy :Zzz :Www];
	Zzz=zNumMazeSize;
	[self drawLine:3 :WallThere :Xxx :Yyy :Zzz :Www];
	}
	for (Count=1; Count< zNumMazeSize+1; Count=Count+1) {
	Www=wNumMazeSize;
	Zzz=Count;
	[self drawLine:7 :WallThere :Xxx :Yyy :Zzz :Www];
	Www=0;
	[self drawLine:7 :WallThere :Xxx :Yyy :Zzz :Www];
	}
	[self drawZWSymbols];
}

-(void)RestartMaze:(id)sender {
	[self ClearXYZ:nil];
	XMaze=1;
	YMaze=1;
	ZMaze=1;
	WMaze=1;
	itime=0;
	[self timeDisplay];
	[self drawMaze];
}

-(IBAction)endShowBestMove:(id)sender {
    // NSLog(@"endshowbestmove");
	if (!BestMoveOnAuto) {
	BestMoveTimerAgain=NO;
	BestMoveActive=NO;
	//  [showBestMove  setSelectedSegmentIndex:-1];
	//  [LandscapeShowbestmove  setSelectedSegmentIndex:-1];
	}
}

-(void)timeBestMove {
	if(self.view.superview&&!selectShowing){
	SEL BestMover = @selector(timeMove);
	[NSTimer scheduledTimerWithTimeInterval:timerBestMoveInterval
	 target:self
	   selector:BestMover
	   userInfo:nil
	repeats:NO];
	BestMoveTimerOn=YES;
	BestMoveActive=YES;
	}
}

-(void) timeMove {
	BestMoveTimerOn=NO;
	if (!(self.view.superview)||selectShowing) {
	showingBestMove=NO;
	// [showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	//   [showBestMove setSelectedSegmentIndex:-1];
        [bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
        [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
	// [LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	//    [LandscapeShowbestmove setSelectedSegmentIndex:-1];
        bshowBestMove.backgroundColor=[UIColor clearColor];
        bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	BestMoveTimerAgain=NO;
	BestMoveActive=NO;
	BestMoveOnAuto=NO;
	}else if (XMaze+YMaze+ZMaze+WMaze==xNumMazeSize+yNumMazeSize+zNumMazeSize+wNumMazeSize) {
	showingBestMove=NO;
	// [showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	//  [showBestMove setSelectedSegmentIndex:-1];
        [bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
        [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
	// [LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	// [LandscapeShowbestmove setSelectedSegmentIndex:-1];
        bshowBestMove.backgroundColor=[UIColor clearColor];
        bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	BestMoveTimerAgain=NO;
	BestMoveActive=NO;
	BestMoveOnAuto=NO;
	}else {
	if (BestMoveActive) {
	timerBestMoveInterval=timerBestMoveInterval*.9;
	if (timerBestMoveInterval<.4){
	timerBestMoveInterval=.2; //during this time it shows its pointer
	if(showingBestMove)timerBestMoveInterval=.3;
	BestMoveOnAuto=YES;
	}
	[self timeBestMove];
	if(BestMoveActive)[self BestMoveAdvance];
	// if(BestMoveOnAuto)[showBestMove setTitle:@"Stop Best Move" forSegmentAtIndex:0];
            if(BestMoveOnAuto){
                [bshowBestMove setTitle:@"Stop Best Move" forState:UIControlStateNormal];
	// if(BestMoveOnAuto)[LandscapeShowbestmove setTitle:@"Stop Best Move" forSegmentAtIndex:0];
                [bLandscapeShowbestmove setTitle:@"Stop Best Move" forState:UIControlStateNormal];


                bshowBestMove.backgroundColor=[UIColor redColor];
                bLandscapeShowbestmove.backgroundColor=[UIColor redColor];
            }
	}
	if (BestMoveTimerAgain) {
	timerBestMoveInterval=.5;
	BestMoveOnAuto=NO;
	BestMoveTimerAgain=NO;
	[self timeBestMove];
	}
	}
}

-(IBAction) showBestMovePressed:(id)sender {
    // NSLog(@"showbestmovepressed");
	// [showBestMove setSelectedSegmentIndex:0];
	// [LandscapeShowbestmove setSelectedSegmentIndex:0];
    bshowBestMove.backgroundColor=[UIColor clearColor];
    bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	if (BestMoveOnAuto) {
	showingBestMove=YES;
	// [showBestMove setTitle:@"Make Best Move" forSegmentAtIndex:0];
            [bshowBestMove setTitle:@"Make Best Move" forState:UIControlStateNormal];
	//  [LandscapeShowbestmove setTitle:@"Make Best Move" forSegmentAtIndex:0];
            [bLandscapeShowbestmove setTitle:@"Make Best Move" forState:UIControlStateNormal];
	//  BestMoveAdvance will invert this to "Show Best Move"
            bshowBestMove.backgroundColor=[UIColor clearColor];
            bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	}
	timerBestMoveInterval=.5;
	BestMoveOnAuto=NO;
	if (BestMoveTimerOn){
	BestMoveTimerAgain=YES;
	BestMoveActive=NO;
	} else {
	[self timeBestMove];
	}
	[self BestMoveAdvance];
	}
-(void) BestMoveAdvance {
	if ((XMaze+YMaze+ZMaze+WMaze)<xNumMazeSize+yNumMazeSize+zNumMazeSize+wNumMazeSize) {
	for (Count=1; Count<9; Count=Count+1) {
	if (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][Count]) {
	if (mazeXYZ[XMaze][YMaze][ZMaze][WMaze]>
	mazeXYZ[XMaze+delWall[1][Count]][YMaze+delWall[2][Count]][ZMaze+delWall[3][Count]][WMaze+delWall[4][Count]]) {
	xBest=XMaze+delWall[1][Count];
	yBest=YMaze+delWall[2][Count];
	zBest=ZMaze+delWall[3][Count];
	wBest=WMaze+delWall[4][Count];
	}
	}
	}
	if (!showingBestMove) {
	showingBestMove=YES;
	// [showBestMove setTitle:@"Make Best Move" forSegmentAtIndex:0];
            [bshowBestMove setTitle:@"Make Best Move" forState:UIControlStateNormal];
	//[LandscapeShowbestmove setTitle:@"Make Best Move" forSegmentAtIndex:0];
            [bLandscapeShowbestmove setTitle:@"Make Best Move" forState:UIControlStateNormal];


            bshowBestMove.backgroundColor=[UIColor clearColor];
            bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	[quartzFunView mazeLineWidth:5.0];
	[quartzFunView mazeColorRed:.2 green:.4 blue:.7	alpha:1.0];
	if (zBest==ZMaze && wBest==WMaze) {
	[quartzFunView mazeLineStartX:XYxOrigin+1+(XMaze-1)*EdgeSize
	   ystart:XYyOrigin+1+(YMaze-1)*EdgeSize
	 xend:XYxOrigin+1+(xBest-1)*EdgeSize
	 yend:XYyOrigin+1+(yBest-1)*EdgeSize];
	} else {


	[quartzFunView mazeLineStartX:ZxOrigin+1+(WMaze-1)*EdgeSize
	   ystart:ZyOrigin+1+(ZMaze-1)*EdgeSize
	 xend:ZxOrigin+1+(wBest-1)*EdgeSize
	 yend:ZyOrigin+1+(zBest-1)*EdgeSize];
	}
	[quartzFunView mazeDrawLine];
	}else {
	showingBestMove=NO;
	// [showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
            [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
	// [LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
            [bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
            bshowBestMove.backgroundColor=[UIColor clearColor];
            bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	[self ClearXYZ:nil];
	XMaze=xBest;
	YMaze=yBest;
	ZMaze=zBest;
	WMaze=wBest;
	[self makeNoise];
	[self drawMaze];
	}
	} else {
	BestMoveTimerAgain=NO;
	BestMoveActive=NO;
	showingBestMove=NO;
	// [showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
        [bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
	// [showBestMove  setSelectedSegmentIndex:-1];
	[bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];
        bshowBestMove.backgroundColor=[UIColor clearColor];
        bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
       // [LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
	// [LandscapeShowbestmove  setSelectedSegmentIndex:-1];
	}
}

-(void)MarkPositionXY:(id)sender {
	if(!(mazeWalls[Xxx][Yyy][Zzz][Www][9])){
	MarkerSize=EdgeSize*0.6;
	[quartzFunView mazeColorRed:1.0 green:1.0 blue:1.0	alpha:1.0];
	[quartzFunView mazeLineWidth:2.0];
	[quartzFunView mazeLineStartX:XYxOrigin+(Xxx-1)*EdgeSize-MarkerSize/10.0
	   ystart:XYyOrigin+(Yyy-1)*EdgeSize-MarkerSize/10.0
	 xend:XYxOrigin+2+(Xxx-1)*EdgeSize+MarkerSize/10.0
	 yend:XYyOrigin+2+(Yyy-1)*EdgeSize+MarkerSize/10.0];
	[quartzFunView mazeAddMarker];
	}
}

-(void)MarkPositionZZ:(id)sender {
	if(!(mazeWalls[Xxx][Yyy][Zzz][Www][9])){
	MarkerSize=EdgeSize*0.6;
	[quartzFunView mazeColorRed:1.0 green:1.0 blue:1.0	alpha:1.0];
	[quartzFunView mazeLineStartX:ZxOrigin+.5-MarkerSize/10.0-1+(Www-1)*EdgeSize
	   ystart:ZyOrigin+(Zzz-1)*EdgeSize-MarkerSize/10.0
	 xend:ZxOrigin+2.5+MarkerSize/10.0+(Www-1)*EdgeSize
	 yend:ZyOrigin+2+(Zzz-1)*EdgeSize+MarkerSize/10.0];
	[quartzFunView mazeAddMarker];
	}
}

-(void)MoveDown:(id)sender {
	if(ZMaze<zNumMazeSize){
	if ((!mazeWalls[XMaze][YMaze][ZMaze][WMaze][3]) || (porous)) {
	[self ClearXYZ:nil];
	ZMaze=ZMaze+1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveUp:(id)sender {
	if(ZMaze>1){
	if ((!mazeWalls[XMaze][YMaze][ZMaze-1][WMaze][3]) || (porous)) {
	[self ClearXYZ:nil];
	ZMaze=ZMaze-1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveIn:(id)sender {
	if(WMaze<wNumMazeSize){
	if ((!mazeWalls[XMaze][YMaze][ZMaze][WMaze][7]) || (porous)) {
	[self ClearXYZ:nil];
	WMaze=WMaze+1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveOut:(id)sender {
	if(WMaze>1){
	if ((!mazeWalls[XMaze][YMaze][ZMaze][WMaze-1][7]) || (porous)) {
	[self ClearXYZ:nil];
	WMaze=WMaze-1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveWest:(id)sender {
	if(XMaze>1){
	if ((!mazeWalls[XMaze-1][YMaze][ZMaze][WMaze][1]) || (porous)) {
	[self ClearXYZ:nil];
	XMaze=XMaze-1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveEast:(id)sender {
	if(XMaze<xNumMazeSize){
	if ((!mazeWalls[XMaze][YMaze][ZMaze][WMaze][1]) || (porous)) {
	[self ClearXYZ:nil];
	XMaze=XMaze+1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveNorth:(id)sender {
	if(YMaze>1){
	if ((!mazeWalls[XMaze][YMaze-1][ZMaze][WMaze][2]) || (porous)) {
	[self ClearXYZ:nil];
	YMaze=YMaze-1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void)MoveSouth:(id)sender {
	if(YMaze<yNumMazeSize){
	if ((!mazeWalls[XMaze][YMaze][ZMaze][WMaze][2]) || (porous)) {
	[self ClearXYZ:nil];
	YMaze=YMaze+1;
	[self makeNoise];
	[self drawMaze];
	}
	}
}

-(void) drawMaze {
	[self drawMazeZ:nil];
	[self drawMazeXY:nil];
	// if (showingBestMove)[showBestMove setTitle:@"Show Best Move" forSegmentAtIndex:0];
    if (showingBestMove)[bshowBestMove setTitle:@"Show Best Move" forState:UIControlStateNormal];
	// if (showingBestMove)[LandscapeShowbestmove setTitle:@"Show Best Move" forSegmentAtIndex:0];
    if (showingBestMove)[bLandscapeShowbestmove setTitle:@"Show Best Move" forState:UIControlStateNormal];


    bshowBestMove.backgroundColor=[UIColor clearColor];
    bLandscapeShowbestmove.backgroundColor=[UIColor clearColor];
	showingBestMove=NO;
	if (itimeDelta==0 && XMaze+YMaze+ZMaze+WMaze!=xNumMazeSize+yNumMazeSize+zNumMazeSize+wNumMazeSize) [self startCounting];
	Xxx=xNumMazeSize;
	Yyy=yNumMazeSize;
	Zzz=zNumMazeSize;
	Www=wNumMazeSize;
	if (ZMaze==zNumMazeSize && WMaze==wNumMazeSize) {
	[self drawExitXY:YES];
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][9])) [self MarkPositionXY:nil];
	}
	if ((XMaze==xNumMazeSize)&&(YMaze==yNumMazeSize)) {
	[self drawExitZ:YES];
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][9])) [self MarkPositionZZ:nil];
	}
	Xxx=1;
	Yyy=1;
	Zzz=1;
	Www=1;


	if (ZMaze==1 && WMaze==1) {
	[self drawEntranceXY:YES];
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][9])) [self MarkPositionXY:nil];
	}
	if ((XMaze==1)&&(YMaze==1)) {
	[self drawEntranceZ:YES];
	if (!(mazeWalls[Xxx][Yyy][Zzz][Www][9])) [self MarkPositionZZ:nil];
	}
	if (showFloors) [self drawNoFloorXY];




	if (XMaze+YMaze+ZMaze+WMaze==xNumMazeSize+yNumMazeSize+zNumMazeSize+wNumMazeSize) {
	shiftXvalue=0;shiftYvalue=0;shiftZvalue=0;shiftWvalue=0;
	}


	if(fabs(shiftXvalue)>.5*EdgeSize)shiftXvalue=0.5*fabs(shiftXvalue)*EdgeSize/shiftXvalue;
	if(fabs(shiftYvalue)>.5*EdgeSize)shiftYvalue=0.5*fabs(shiftYvalue)*EdgeSize/shiftYvalue;
	if(fabs(shiftWvalue)>.5*EdgeSize)shiftWvalue=0.5*fabs(shiftWvalue)*EdgeSize/shiftWvalue;
	if(fabs(shiftZvalue)>.5*EdgeSize)shiftZvalue=0.5*fabs(shiftZvalue)*EdgeSize/shiftZvalue;




	if(XMaze==xNumMazeSize && shiftXvalue>0)shiftXvalue=0;
	if(WMaze==wNumMazeSize && shiftWvalue>0)shiftWvalue=0;
	if(XMaze==1 && shiftXvalue<0)shiftXvalue=0;
	if(WMaze==1 && shiftWvalue<0)shiftWvalue=0;
	if(YMaze==yNumMazeSize && shiftYvalue>0)shiftYvalue=0;
	if(ZMaze==zNumMazeSize && shiftZvalue>0)shiftZvalue=0;
	if(YMaze==1 && shiftYvalue<0)shiftYvalue=0;
	if(ZMaze==1 && shiftZvalue<0)shiftZvalue=0;


	if (!porous) {
	if ((mazeWalls[XMaze][YMaze][ZMaze][WMaze][1])&&(shiftXvalue>0))shiftXvalue=0;
	if ((mazeWalls[XMaze-1][YMaze][ZMaze][WMaze][1])&&(shiftXvalue<0))shiftXvalue=0;
	if ((mazeWalls[XMaze][YMaze][ZMaze][WMaze][2])&&(shiftYvalue>0))shiftYvalue=0;
	if ((mazeWalls[XMaze][YMaze-1][ZMaze][WMaze][2])&&(shiftYvalue<0))shiftYvalue=0;
	if ((mazeWalls[XMaze][YMaze][ZMaze][WMaze][7])&&(shiftWvalue>0))shiftWvalue=0;
	if ((mazeWalls[XMaze][YMaze][ZMaze][WMaze-1][7])&&(shiftWvalue<0))shiftWvalue=0;
	if ((mazeWalls[XMaze][YMaze][ZMaze][WMaze][3])&&(shiftZvalue>0))shiftZvalue=0;
	if ((mazeWalls[XMaze][YMaze][ZMaze-1][WMaze][3])&&(shiftZvalue<0))shiftZvalue=0;
	}


	MarkerSize=EdgeSize*0.6;
	[quartzFunView mazeLineWidth:2.0];
	[quartzFunView mazeColorRed:.2 green:.4 blue:.7	alpha:1.0];
	[quartzFunView mazeLineStartX:XYxOrigin+1+(XMaze-1)*EdgeSize-MarkerSize/2.0+shiftXvalue
	   ystart:XYyOrigin+1+(YMaze-1)*EdgeSize-MarkerSize/2.0+shiftYvalue
	 xend:XYxOrigin+1+(XMaze-1)*EdgeSize+MarkerSize/2.0+shiftXvalue
	 yend:XYyOrigin+1+(YMaze-1)*EdgeSize+MarkerSize/2.0+shiftYvalue];
	[quartzFunView mazeAddMarker];
	[quartzFunView mazeLineStartX:ZxOrigin+1+(WMaze-1)*EdgeSize-MarkerSize/2.0+shiftWvalue
	   ystart:ZyOrigin+1+(ZMaze-1)*EdgeSize-MarkerSize/2.0+shiftZvalue
	 xend:ZxOrigin+1+(WMaze-1)*EdgeSize+MarkerSize/2.0+shiftWvalue
	 yend:ZyOrigin+1+(ZMaze-1)*EdgeSize+MarkerSize/2.0+shiftZvalue];
	[quartzFunView mazeAddMarker];




	if (!mazeWalls [XMaze][YMaze][ZMaze][WMaze][9]) {
	Xxx=XMaze;
	Yyy=YMaze;
	Zzz=ZMaze;
	Www=WMaze;
	[self MarkPositionXY:nil];
	[self MarkPositionZZ:nil];
	}
	if (XMaze+YMaze+ZMaze+WMaze==xNumMazeSize+yNumMazeSize+zNumMazeSize+wNumMazeSize) {
	if(!showedCompletedMaze)[self completedMaze:nil];
	} else {
	showedCompletedMaze=NO;
	}
	[quartzFunView mazeClear];
	[quartzFunView mazeDrawAllLines];
	if(showMovesNumber) {
	Count=mazeXYZ[XMaze][YMaze][ZMaze][WMaze]-1;
	temp2=[[NSString alloc] initWithFormat:@"Moves: %d",Count];
	}else {
	temp2=[[NSString alloc] initWithFormat:@""];
	}
	DisplayMovestoFinish.text=temp2;
	[temp2 release];
	if(HardMaze==1) {
	temp1=[[NSString alloc] initWithFormat:@"Complex #%d",INumMazeNumber];
	} else {
	temp1=[[NSString alloc] initWithFormat:@"Standard #%d",INumMazeNumber];
	}
	DisplayEasyHard.text=temp1;
	[temp1 release];
}

-(void)ShowMoves:(id)sender {
	showMovesNumber=!showMovesNumber;
	 /* if (!showMovesNumber)[SelShowMoves setSelectedSegmentIndex:-1];
	if (showMovesNumber)[SelShowMoves setSelectedSegmentIndex:0];
	if (!showMovesNumber)[LandscapeMoves setSelectedSegmentIndex:-1];
	if (showMovesNumber)[LandscapeMoves setSelectedSegmentIndex:0]; */
	[self viewBeingCalled];
}

-(void)ColorZW:(id)sender {
	selectedColor=selectedColor+1;
	if(selectedColor==8)selectedColor=0;
	[self viewBeingCalled];
}

-(void) drawLine:(int)WallDirection :(BOOL)DrawWall :(int)xdraw :(int)ydraw :(int)zdraw :(int)wdraw{
	if(DrawWall||((WallDirection==3||WallDirection==7)&&(wNumMazeSize==1||zNumMazeSize==1))){
	  [quartzFunView mazeLineWidth:2.0];
	  if(DrawWall){
	  WallEnd=2;
	  [quartzFunView mazeColorRed:.0 green:.0 blue:.0	alpha:1.0];
	  }
	  if (!DrawWall){
	  [quartzFunView mazeColorRed:.0 green:.0 blue:.0	alpha:.1];
	  WallEnd=0;
	  }


	  if (WallDirection==1) {
	[quartzFunView mazeLineStartX:XYxOrigin+(xdraw-0.5)*EdgeSize
	   ystart:XYyOrigin+(ydraw-1.5)*EdgeSize+2-WallEnd
	 xend:XYxOrigin+(xdraw-0.5)*EdgeSize
	 yend:XYyOrigin+(ydraw-0.5)*EdgeSize+WallEnd];
	  }
	  if (WallDirection==2) {
	[quartzFunView mazeLineStartX:XYxOrigin+(xdraw-1.5)*EdgeSize+2-WallEnd
	   ystart:XYyOrigin+(ydraw-0.5)*EdgeSize
	 xend:XYxOrigin+(xdraw-0.5)*EdgeSize+WallEnd
	 yend:XYyOrigin+(ydraw-0.5)*EdgeSize];
	  }
	  if (WallDirection==3) {
	[quartzFunView mazeLineStartX:ZxOrigin+(wdraw-1.5)*EdgeSize+2-WallEnd
	   ystart:ZyOrigin+(zdraw-0.5)*EdgeSize
	 xend:ZxOrigin+(wdraw-0.5)*EdgeSize+WallEnd
	 yend:ZyOrigin+(zdraw-0.5)*EdgeSize];
	  }
	  if (WallDirection==7) {
	[quartzFunView mazeLineStartX:ZxOrigin+(wdraw-0.5)*EdgeSize
	   ystart:ZyOrigin+(zdraw-1.5)*EdgeSize+2-WallEnd
	 xend:ZxOrigin+(wdraw-0.5)*EdgeSize
	 yend:ZyOrigin+(zdraw-0.5)*EdgeSize+WallEnd];
	  }
	  [quartzFunView mazeAddLine];
	}
}

-(void)drawXYSymbols {
	symbolEdgesize=EdgeSize;
	if(symbolEdgesize>20-iphoneDelta/4)symbolEdgesize=20-iphoneDelta/4;
	symbolXorigin=ZxOrigin+EdgeSize*(wNumMazeSize/2.0-0.5)-symbolEdgesize*.4;
	symbolYorigin=ZyOrigin-EdgeSize/2-symbolEdgesize*1.5;
	[quartzFunView mazeColorRed:.0 green:.0 blue:.0	alpha:1.0];
	[quartzFunView mazeLineWidth:3.0-iphoneDelta/20.0];
	[quartzFunView mazeLineStartX:symbolXorigin
	   ystart:symbolYorigin
	 xend:symbolXorigin+symbolEdgesize*.8
	 yend:symbolYorigin+symbolEdgesize];
	 [quartzFunView mazeAddLine];
	 [quartzFunView mazeLineStartX:symbolXorigin
	ystart:symbolYorigin+symbolEdgesize
	  xend:symbolXorigin+symbolEdgesize*.8
	  yend:symbolYorigin];
	[quartzFunView mazeAddLine];
	symbolXorigin=ZxOrigin-symbolEdgesize-EdgeSize/2-2;
	symbolYorigin=ZyOrigin+(zNumMazeSize/2.0)*EdgeSize-EdgeSize/2.0-symbolEdgesize*0.6;
	[quartzFunView mazeColorRed:.0 green:.0 blue:.0	alpha:1.0];
	[quartzFunView mazeLineWidth:3.0-iphoneDelta/20.0];
	[quartzFunView mazeLineStartX:symbolXorigin
	   ystart:symbolYorigin
	 xend:symbolXorigin+symbolEdgesize*.4
	 yend:symbolYorigin+symbolEdgesize*.5];
	[quartzFunView mazeAddLine];
	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.4
	   ystart:symbolYorigin+symbolEdgesize*.5
	 xend:symbolXorigin+symbolEdgesize*.8
	 yend:symbolYorigin];
	[quartzFunView mazeAddLine];


	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.4-1
	   ystart:symbolYorigin+symbolEdgesize*.5
	 xend:symbolXorigin+symbolEdgesize*.4 -1
	 yend:symbolYorigin+symbolEdgesize*1.2];
	[quartzFunView mazeAddLine];
}

-(void)drawZWSymbols {
	symbolEdgesize=EdgeSize;
	if(symbolEdgesize>20-iphoneDelta/4)symbolEdgesize=20-iphoneDelta/4;
	symbolXorigin=XYxOrigin+EdgeSize*(xNumMazeSize/2.0-0.5)-symbolEdgesize*.4;
	symbolYorigin=XYyOrigin-EdgeSize/2-symbolEdgesize*1.5;
	[quartzFunView mazeColorRed:.0 green:.0 blue:.0	alpha:1.0];
	[quartzFunView mazeLineWidth:3.0-iphoneDelta/20.0];
	[quartzFunView mazeLineStartX:symbolXorigin
	   ystart:symbolYorigin
	 xend:symbolXorigin+symbolEdgesize*.25
	 yend:symbolYorigin+symbolEdgesize];
	[quartzFunView mazeAddLine];
	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.25
	   ystart:symbolYorigin+symbolEdgesize
	 xend:symbolXorigin+symbolEdgesize*.5
	 yend:symbolYorigin];
	[quartzFunView mazeAddLine];
	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.5
	   ystart:symbolYorigin
	 xend:symbolXorigin+symbolEdgesize*.75
	 yend:symbolYorigin+symbolEdgesize];
	[quartzFunView mazeAddLine];
	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.75
	   ystart:symbolYorigin+symbolEdgesize
	 xend:symbolXorigin+symbolEdgesize
	 yend:symbolYorigin];
	[quartzFunView mazeAddLine];
	symbolXorigin=XYxOrigin-symbolEdgesize-EdgeSize/2-2;
	symbolYorigin=XYyOrigin+(yNumMazeSize/2.0)*EdgeSize-EdgeSize/2.0-symbolEdgesize*0.6;
	[quartzFunView mazeLineStartX:symbolXorigin
	   ystart:symbolYorigin
	 xend:symbolXorigin+symbolEdgesize*.8
	 yend:symbolYorigin];
	[quartzFunView mazeAddLine];
	[quartzFunView mazeLineStartX:symbolXorigin+symbolEdgesize*.8
	   ystart:symbolYorigin
	 xend:symbolXorigin
	 yend:symbolYorigin+symbolEdgesize];
	[quartzFunView mazeAddLine];


	[quartzFunView mazeLineStartX:symbolXorigin
	   ystart:symbolYorigin+symbolEdgesize
	 xend:symbolXorigin+symbolEdgesize*.8
	 yend:symbolYorigin+symbolEdgesize];
	[quartzFunView mazeAddLine];
}

-(void) ClearXYZ:(id)sender {
}

-(void)createMazes {
//  srand(INumMazeNumber*20+HardMaze+NumMazeSize*2);
	srand((620+INumMazeNumber)*5120000+HardMaze*2560000+xNumMazeSize*64000+yNumMazeSize*1600+zNumMazeSize*40+wNumMazeSize); //version 4.3.1 "110"   version 5.2  "210"  version 6.2 "620"
	[self getRandom:nil];
	[self getRandom:nil];
	[self initializeMaze];
	[self getFirstCell];
	[self expandFrontier];
	while (frontierCount>0) {
	[self pickCellFromFrontier];
	[self expandMaze];
	[self expandFrontier];
	}
	[self completeMaze];
    if(xNumMazeSize+yNumMazeSize==2){
        [bSelColorZW setHidden:NO];
    }else{
        [bSelColorZW setHidden:YES];
    }


    if(xNumMazeSize+yNumMazeSize==2 || zNumMazeSize+wNumMazeSize==2){
        [bLandscapePortals setHidden:YES];
        [bSelShowFloors setHidden:YES];
        showFloors=NO;
        ShowFloors=-1;
    }else{
        [bLandscapePortals setHidden:NO];
        [bSelShowFloors setHidden:NO];
    }


}

-(void)initializeMaze {
	frontierCount=0;
	for (Xxx=1;Xxx<xNumMazeSize+1 ;Xxx=Xxx+1) {
	for (Yyy=1; Yyy<yNumMazeSize+1;Yyy=Yyy+1) {
	for (Zzz=1; Zzz<zNumMazeSize+1;Zzz=Zzz+1) {
	for (Www=1; Www<wNumMazeSize+1;Www=Www+1) {
	mazeXYZ[Xxx][Yyy][Zzz][Www]=0;
	mazeXYZ[0][Yyy][Zzz][Www]=200000;
	mazeXYZ[xNumMazeSize+1][Yyy][Zzz][Www]=200000;
	mazeXYZ[Xxx][0][Zzz][Www]=200000;
	mazeXYZ[Xxx][yNumMazeSize+1][Zzz][Www]=200000;
	mazeXYZ[Xxx][Yyy][0][Www]=200000;
	mazeXYZ[Xxx][Yyy][zNumMazeSize+1][Www]=200000;
	mazeXYZ[Xxx][Yyy][Zzz][0]=200000;
	mazeXYZ[Xxx][Yyy][Zzz][wNumMazeSize+1]=200000;
	for (Direction=1; Direction<9; Direction=Direction+1) {
	mazeWalls[Xxx][Yyy][Zzz][Www][Direction]=YES;
	}
	}
	}
	}
	}
}

-(void) clearAllMarkers {
	for (Xxx=1;Xxx<xNumMazeSize+1 ;Xxx=Xxx+1) {
	for (Yyy=1; Yyy<yNumMazeSize+1;Yyy=Yyy+1) {
	for (Zzz=1; Zzz<zNumMazeSize+1;Zzz=Zzz+1) {
	for (Www=1; Www<wNumMazeSize+1;Www=Www+1) {
	mazeWalls[Xxx][Yyy][Zzz][Www][9]=YES;
	}
	}
	}
	}
}

-(void)getFirstCell {
	Xxx=1;
	Yyy=1;
	Zzz=1;
	Www=1;
	mazeXYZ[Xxx][Yyy][Zzz][Www]=1;
}

-(void)expandFrontier {
	newFrontier=frontierCount;
	if (Xxx<xNumMazeSize){
	if (mazeXYZ[Xxx+1][Yyy][Zzz][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx+1;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx+1][Yyy][Zzz][Www]=-1;
	}
	}
	if (Yyy<yNumMazeSize){
	if (mazeXYZ[Xxx][Yyy+1][Zzz][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy+1;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx][Yyy+1][Zzz][Www]=-1;
	}
	}
	if (Zzz<zNumMazeSize){
	if (mazeXYZ[Xxx][Yyy][Zzz+1][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz+1;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx][Yyy][Zzz+1][Www]=-1;
	}
	}
	if (Xxx>1){
	if (mazeXYZ[Xxx-1][Yyy][Zzz][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx-1;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx-1][Yyy][Zzz][Www]=-1;
	}
	}
	if (Yyy>1){
	if (mazeXYZ[Xxx][Yyy-1][Zzz][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy-1;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx][Yyy-1][Zzz][Www]=-1;
	}
	}
	if (Zzz>1) {
	if (mazeXYZ[Xxx][Yyy][Zzz-1][Www]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz-1;
	frontierXYZ[frontierCount][4]=Www;
	mazeXYZ[Xxx][Yyy][Zzz-1][Www]=-1;
	}
	}
	if (Www<wNumMazeSize){
	if (mazeXYZ[Xxx][Yyy][Zzz][Www+1]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www+1;
	mazeXYZ[Xxx][Yyy][Zzz][Www+1]=-1;
	}
	}
	if (Www>1){
	if (mazeXYZ[Xxx][Yyy][Zzz][Www-1]==0) {
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx;
	frontierXYZ[frontierCount][2]=Yyy;
	frontierXYZ[frontierCount][3]=Zzz;
	frontierXYZ[frontierCount][4]=Www-1;
	mazeXYZ[Xxx][Yyy][Zzz][Www-1]=-1;
	}
	}
	newFrontier=frontierCount-newFrontier;
}

-(void)pickCellFromFrontier {
	[self getRandom:nil];
	Count=frontierCount*randomOne+1.0;
	if (HardMaze==1) {
	Count=frontierCount-randomOne*newFrontier+0.999;
	}
	Xxx=frontierXYZ[Count][1];
	Yyy=frontierXYZ[Count][2];
	Zzz=frontierXYZ[Count][3];
	Www=frontierXYZ[Count][4];
	frontierXYZ[Count][1]=frontierXYZ[frontierCount][1];
	frontierXYZ[Count][2]=frontierXYZ[frontierCount][2];
	frontierXYZ[Count][3]=frontierXYZ[frontierCount][3];
	frontierXYZ[Count][4]=frontierXYZ[frontierCount][4];
	frontierCount=frontierCount-1;
}

-(void) expandMaze {
	Count=0;
	if (Xxx<xNumMazeSize){
	if (mazeXYZ[Xxx+1][Yyy][Zzz][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=1;
	}
	}
	if (Yyy<yNumMazeSize){
	if (mazeXYZ[Xxx][Yyy+1][Zzz][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=2;
	}
	}
	if (Zzz<zNumMazeSize){
	if (mazeXYZ[Xxx][Yyy][Zzz+1][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=3;
	}
	}
	if (Xxx>1){
	if (mazeXYZ[Xxx-1][Yyy][Zzz][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=4;
	}
	}
	if (Yyy>1){
	if (mazeXYZ[Xxx][Yyy-1][Zzz][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=5;
	}
	}
	if (Zzz>1) {
	if (mazeXYZ[Xxx][Yyy][Zzz-1][Www]>0) {
	Count=Count+1;
	wallFrontierList[Count]=6;
	}
	}
	if (Www<wNumMazeSize){
	if (mazeXYZ[Xxx][Yyy][Zzz][Www+1]>0) {
	Count=Count+1;
	wallFrontierList[Count]=7;
	}
	}
	if (Www>1){
	if (mazeXYZ[Xxx][Yyy][Zzz][Www-1]>0) {
	Count=Count+1;
	wallFrontierList[Count]=8;
	}
	}
	[self getRandom:nil];
	Count=Count*randomOne+1.0;
	wallRemove=wallFrontierList[Count];
	mazeWalls[Xxx][Yyy][Zzz][Www][wallRemove]=NO;
	mazeWalls[Xxx+delWall[1][wallRemove]][Yyy+delWall[2][wallRemove]][Zzz+delWall[3][wallRemove]][Www+delWall[4][wallRemove]][inverseWall[wallRemove]]=NO;
	mazeXYZ[Xxx][Yyy][Zzz][Www]=1+mazeXYZ[Xxx+delWall[1][wallRemove]][Yyy+delWall[2][wallRemove]][Zzz+delWall[3][wallRemove]][Www+delWall[4][wallRemove]];
}

//-(void)getBestX:(int)axBest :(int)ayBest :(int)azBest :(int)awBest {
//	for (Count=1; Count<9; Count=Count+1) {
//	if (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][Count]) {
//	if (mazeXYZ[XMaze][YMaze][ZMaze][WMaze]>
//	mazeXYZ[XMaze+delWall[1][Count]][YMaze+delWall[2][Count]][ZMaze+delWall[3][Count]][ZMaze+delWall[4]/[Count]]) {
//	axBest=XMaze+delWall[1][Count];
//	ayBest=YMaze+delWall[2][Count];
//	azBest=ZMaze+delWall[3][Count];
//	awBest=WMaze+delWall[4][Count];
//	}
//	}
//	}
//}

-(void)completeMaze {
	for (Xxx=1;Xxx<xNumMazeSize+1 ;Xxx=Xxx+1) {
	for (Yyy=1; Yyy<yNumMazeSize+1;Yyy=Yyy+1) {
	for (Zzz=1; Zzz<zNumMazeSize+1;Zzz=Zzz+1) {
	for (Www=1; Www<wNumMazeSize+1;Www=Www+1) {
	mazeXYZ[Xxx][Yyy][Zzz][Www]=0;
	}
	}
	}
	}
	mazeXYZ[xNumMazeSize][yNumMazeSize][zNumMazeSize][wNumMazeSize]=1;
	frontierCount=1;
	frontierXYZ[frontierCount][1]=xNumMazeSize;
	frontierXYZ[frontierCount][2]=yNumMazeSize;
	frontierXYZ[frontierCount][3]=zNumMazeSize;
	frontierXYZ[frontierCount][4]=wNumMazeSize;
	while (frontierCount>0) {
	Xxx=frontierXYZ[frontierCount][1];
	Yyy=frontierXYZ[frontierCount][2];
	Zzz=frontierXYZ[frontierCount][3];
	Www=frontierXYZ[frontierCount][4];
	frontierCount=frontierCount-1;
	for (Count=1; Count<9; Count=Count+1) {
	if (!mazeWalls[Xxx][Yyy][Zzz][Www][Count]) {
	if (mazeXYZ[Xxx+delWall[1][Count]][Yyy+delWall[2][Count]][Zzz+delWall[3][Count]][Www+delWall[4][Count]]==0) {
	mazeXYZ[Xxx+delWall[1][Count]][Yyy+delWall[2][Count]][Zzz+delWall[3][Count]][Www+delWall[4][Count]]=mazeXYZ[Xxx][Yyy][Zzz][Www]+1;
	frontierCount=frontierCount+1;
	frontierXYZ[frontierCount][1]=Xxx+delWall[1][Count];
	frontierXYZ[frontierCount][2]=Yyy+delWall[2][Count];
	frontierXYZ[frontierCount][3]=Zzz+delWall[3][Count];
	frontierXYZ[frontierCount][4]=Www+delWall[4][Count];
	}
	}
	}
	}
}


-(void) MarkPosition:(id)sender{
	mazeWalls[XMaze][YMaze][ZMaze][WMaze][9]=!mazeWalls[XMaze][YMaze][ZMaze][WMaze][9];
	[self drawMaze];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	gestureStartPoint=[touch locationInView:self.view];
	gestureStartXvalue=gestureStartPoint.x;
	touchUnmoved=YES;
	touchXvalueBase=gestureStartPoint.x; touchYvalueBase=gestureStartPoint.y;
	XYnotWZ=NO;
	if (gestureStartXvalue>30-1.5*iphoneDelta+XYxOrigin-EdgeSize-0.25*(widthGraph-EdgeSize*(wNumMazeSize+xNumMazeSize+2.0)))XYnotWZ=YES;
	if(selectShowing && (gestureStartPoint.x<220 || gestureStartPoint.x>568 || gestureStartPoint.y<187 || gestureStartPoint.y>706)){
	[self endSelectView];
	[self viewBeingCalled];
	selectShowingJustOff=YES;


        [[NSNotificationCenter defaultCenter] postNotificationName:@"SetPlayButtonWhite" object:nil userInfo:nil];




	}
}


-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {






if(!selectShowing){
	touchUnmoved=NO;
	UITouch *touch = [touches anyObject];
	CGPoint currentPosition = [touch locationInView:self.view];
	CGFloat deltaX=(-touchXvalueBase+currentPosition.x);
	CGFloat deltaY=(-touchYvalueBase+currentPosition.y);


	if (fabs(deltaX)>fabs(deltaY)) {
	if (XYnotWZ) {
	shiftYvalue=0;shiftWvalue=0;shiftZvalue=0;
	if (deltaX>0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][1]||porous)&&XMaze!=xNumMazeSize) {
	touchXvalueBase=touchXvalueBase+touchEdgeSize;touchYvalueBase=currentPosition.y;
	shiftXvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self MoveEast:nil];
	}else if (deltaX<-0.5*touchEdgeSize && (!mazeWalls[XMaze-1][YMaze][ZMaze][WMaze][1]||porous)&&XMaze!=1) {
	touchXvalueBase=touchXvalueBase-touchEdgeSize;touchYvalueBase=currentPosition.y;
	shiftXvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self MoveWest:nil];
	}else{
	shiftXvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self drawMaze];
	}
	}
	if (!XYnotWZ) {
	shiftYvalue=0;shiftXvalue=0;shiftZvalue=0;
	if (deltaX>0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][7]||porous)&&WMaze!=wNumMazeSize) {
	touchXvalueBase=touchXvalueBase+touchEdgeSize;touchYvalueBase=currentPosition.y;
	shiftWvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self MoveIn:nil];
	}else if (deltaX<-0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze][WMaze-1][7]||porous)&&WMaze!=1) {
	touchXvalueBase=touchXvalueBase-touchEdgeSize;touchYvalueBase=currentPosition.y;
	shiftWvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self MoveOut:nil];
	}else{
	shiftWvalue=(-touchXvalueBase+currentPosition.x)*EdgeSize/touchEdgeSize;
	[self drawMaze];
	}
	}
	}
	if (fabs(deltaX)<fabs(deltaY)) {
	if (XYnotWZ) {
	shiftXvalue=0;shiftWvalue=0;shiftZvalue=0;
	if (deltaY>0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][2]||porous)&&YMaze!=yNumMazeSize) {
	touchYvalueBase=touchYvalueBase+touchEdgeSize;touchXvalueBase=currentPosition.x;
	shiftYvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self MoveSouth:nil];
	} else if (deltaY<-0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze-1][ZMaze][WMaze][2]||porous)&&YMaze!=1) {
	touchYvalueBase=touchYvalueBase-touchEdgeSize;touchXvalueBase=currentPosition.x;
	shiftYvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self MoveNorth:nil];
	}else{
	shiftYvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self drawMaze];
	}
	}
	if (!XYnotWZ) {
	shiftYvalue=0;shiftXvalue=0;shiftWvalue=0;
	if (deltaY>0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze][WMaze][3]||porous)&&ZMaze!=zNumMazeSize) {
	touchYvalueBase=touchYvalueBase+touchEdgeSize;touchXvalueBase=currentPosition.x;
	shiftZvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self MoveDown:nil];
	}else if (deltaY<-0.5*touchEdgeSize && (!mazeWalls[XMaze][YMaze][ZMaze-1][WMaze][3]||porous)&&ZMaze!=1) {
	touchYvalueBase=touchYvalueBase-touchEdgeSize;touchXvalueBase=currentPosition.x;
	shiftZvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self MoveUp:nil];
	}else{
	shiftZvalue=(-touchYvalueBase+currentPosition.y)*EdgeSize/touchEdgeSize;
	[self drawMaze];
	}
	}
	}
}
}
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if(!selectShowing){
	if (!selectShowingJustOff && touchUnmoved&&gestureStartPoint.y<heightGraph+100.0) [self MarkPosition:nil];
	shiftXvalue=0;shiftYvalue=0;shiftZvalue=0;shiftWvalue=0;
	[self drawMaze];
	selectShowingJustOff=NO;
	}
}

-(IBAction)NextMaze:(id)sender {
	[self selectNextMaze:nil];
/*
	INumMazeNumber=INumMazeNumber+1;
	if(INumMazeNumber>100){
	INumMazeNumber=1;
	}
	XMaze=1;
	YMaze=1;
	ZMaze=1;
	WMaze=1;
	itime=0;
	[self viewBeingCalled];
*/


}

-(IBAction)ShowWalls:(id)sender {
	ShowWalls=(int)SelShowWalls.selectedSegmentIndex;
	[self viewBeingCalled];
}
-(IBAction)ShowWallsLandscape:(id)sender {
	ShowWalls=(int)LandscapePorousNormal.selectedSegmentIndex;
	[self viewBeingCalled];
}

-(IBAction)ShowFloors:(id)sender {
	if (showFloors){
	showFloors=NO;
	// [SelShowFloors setSelectedSegmentIndex:-1];
	// [LandscapePortals setSelectedSegmentIndex:-1];
	ShowFloors=-1;
	} else {
	showFloors=YES;
	// [SelShowFloors setSelectedSegmentIndex:0];
	//  [LandscapePortals setSelectedSegmentIndex:0];
	ShowFloors=0;
	}
	[self viewBeingCalled];
}

-(void)completedMaze:(id)sender {
	showedCompletedMaze=YES;
	if(itimeDelta==1){
	[self stopCounting];
	if (iminutes==0) {
	if (iseconds==1) {
	temp1=[[NSString alloc] initWithFormat:@"in %d second",iseconds];
	} else {
	temp1=[[NSString alloc] initWithFormat:@"in %d seconds",iseconds];
	}
	} else if (iminutes==1) {
	if (iseconds==1) {
	temp1=[[NSString alloc] initWithFormat:@"in %d minute and %d second",iminutes, iseconds];
	} else {
	temp1 = [[NSString alloc] initWithFormat:@"in %d minute and %d seconds",iminutes, iseconds];
	}
	} else {
	if (iseconds==1) {
	temp1= [[NSString alloc] initWithFormat:@"In %d minutes and %d second",iminutes, iseconds];
	} else {
	temp1 = [[NSString alloc] initWithFormat:@"In %d minutes and %d seconds",iminutes, iseconds];
	}
	}
	/*UIAlertView *completedDialog;
	completedDialog = [[UIAlertView alloc]
	initWithTitle:@"Maze Completed"
	message:temp1
	 	delegate: self
	 	cancelButtonTitle:@"Ok"
	 	otherButtonTitles:nil];
	[completedDialog show];
	[completedDialog release]; */


        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Maze Completed" message:temp1 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                numberOfMazesCompleted=numberOfMazesCompleted+1;
                if(numberOfMazesCompleted>=16)[self makeAnOffer];
        }];
        [alert addAction:defaultAction];
        [[self theParentVC] presentViewController:alert animated:YES completion:nil];


	[temp1 release];
	}
}




-(void) makeAnOffer {
	numberOfMazesCompleted=-16;


    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if(![[userDefaults objectForKey:@"parental_permission"] boolValue])return;


	/*UIAlertView *completedDialog;
	temp1=[[NSString alloc] initWithFormat:@"second line"];
	completedDialog = [[UIAlertView alloc]
	   initWithTitle:nil
	   message:@"You seem to be enjoying Maze HyperCube Lite. Would you like to write a review of Maze HyperCube Lite"
	   delegate: self
	   cancelButtonTitle:@"No, but remind me later."
	   otherButtonTitles:@"I'd like to write a review.",nil];
	[completedDialog show];
	[completedDialog release];
	[temp1 release];*/




    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"You seem to be enjoying Maze HyperCube Lite. Would you like to write a review of Maze HyperCube Lite" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* anotherAction = [UIAlertAction actionWithTitle:@"I'd like to write a review." style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id378658863?mt=8"] options:@{} completionHandler:nil];
    }];
    [alert addAction:anotherAction];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"No, but remind me later." style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [[self theParentVC] presentViewController:alert animated:YES completion:nil];




}


/*-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];


	if ([buttonTitle  isEqualToString:@"Ok"]){
        numberOfMazesCompleted=numberOfMazesCompleted+1;
        if(numberOfMazesCompleted>=16)[self makeAnOffer];
	}


	if ([buttonTitle  isEqualToString:@"I'd like to write a review."]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id378658863?mt=8"] options:@{} completionHandler:nil];
	}


	if ([buttonTitle  isEqualToString:@"Show me"]){
	if(![SKPaymentQueue canMakePayments] ){




            //UIAlertView *cantMakePayment;
	//cantMakePayment = [[UIAlertView alloc]
	//	   initWithTitle:@"Unable to make InApp payment"
	//	   message:@"You are not permitted to make purchases from this device."
	//	   delegate: self
	//	   cancelButtonTitle:@"Sorry"
	//	   otherButtonTitles:nil ] ;
	// [cantMakePayment show];
	// [cantMakePayment release];


            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Unable to make InApp payment" message:@"You are not permitted to make purchases from this device." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [[self theParentVC] presentViewController:alert animated:YES completion:nil];


//	[purchaseMazes setHidden:YES];
            //            inAppAvailable=NO;
            [purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	[spinner stopAnimating];
	}else {
	SKPayment *paymentRequest = [SKPayment paymentWithProduct:[validProduct objectAtIndex:0]];
	[[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
	}
        [validProduct release];
	}else if ([buttonTitle  isEqualToString:@"Verify purchases"]){
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        [validProduct release];
	}else if ([buttonTitle  isEqualToString:@"No thanks"]){ // no thanks
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	[spinner stopAnimating];
        [validProduct release];
	}


} */







//-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
//	return 1;
//}

//-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
//	return 2;
//}

//-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//	return @"empty";
//}


-(void) makeNoise{
//	makeNoiseValue=-makeNoiseValue+1;
//	if(makeNoiseOn)	[picker1 selectRow:makeNoiseValue inComponent:0 animated:NO];
	if(makeNoiseOn)AudioServicesPlaySystemSound(clickNoise);
}



- (void)dealloc {
	AudioServicesDisposeSystemSoundID(clickNoise);
	[edgeNumbers release];
	[hypercubeNames release];
    [super dealloc];
}



//SelectMaze follows......

-(void)startSelectView {


	selectShowing=YES;
	[SelMazeSize setHidden:NO];
	[DisMazeNumber setHidden:NO];
	[SelSound setHidden:NO];
	[SelEasyHard setHidden:NO];
	if(numberOfMazesPurchased==100)[SlideMazeNumber setHidden:NO];
//	if(inAppAvailable && numberOfMazesPurchased<100)[purchaseMazes setHidden:NO];
	if(                  numberOfMazesPurchased<100)[bpurchaseMazes setHidden:NO];
	[DisWarning setHidden:NO];
	[Label1 setHidden:NO];
	[Label2 setHidden:NO];
	[Label3 setHidden:NO];
	[Label4 setHidden:NO];
	[Label5 setHidden:NO];
	[Label6 setHidden:NO];
	[Label7 setHidden:NO];
	[Segment1 setHidden:NO];
	[bSegment2 setHidden:NO];
	[picker setHidden:NO];
}


-(void)endSelectView {
	selectShowing=NO;
	[SelMazeSize setHidden:YES];
	[DisMazeNumber setHidden:YES];
	[SelSound setHidden:YES];
	[SelEasyHard setHidden:YES];
	[SlideMazeNumber setHidden:YES];
	[bpurchaseMazes setHidden:YES];
	[DisWarning setHidden:YES];
	[Label1 setHidden:YES];
	[Label2 setHidden:YES];
	[Label3 setHidden:YES];
	[Label4 setHidden:YES];
	[Label5 setHidden:YES];
	[Label6 setHidden:YES];
	[Label7 setHidden:YES];
	[Segment1 setHidden:YES];
	[bSegment2 setHidden:YES];
	[picker	setHidden:YES];
}


-(IBAction)SlideMaze:(id)sender {
	NumMazeNumber=SlideMazeNumber.value;
	INumMazeNumber=NumMazeNumber;
	if (aaINumMazeNumber!=INumMazeNumber){
	[self displayCurrentValues];
	aaINumMazeNumber=INumMazeNumber;
	}
}

-(IBAction)SlideFinal:(id)sender{
	NumMazeNumber=SlideMazeNumber.value;
	INumMazeNumber=NumMazeNumber;
	if (aINumMazeNumber!=INumMazeNumber){
	[self reSetValues];
	[self displayCurrentValues];
	aINumMazeNumber=INumMazeNumber;
	}
}



//ONLY FOR IAP USE........  ipad???  popover oissue in ipad takes me here???
-(IBAction)considerInAppPurchase:(id)sender {


    // NSLog(@"here in donsider in PlayVioewController");




    if([[bpurchaseMazes titleForState:UIControlStateNormal] isEqualToString:@"Explore purchasing more mazes"]){


        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL theValue=[[userDefaults objectForKey:@"parental_permission"] boolValue];
        if(theValue==NO){
            /*UIAlertView *noPermission;
            noPermission = [[UIAlertView alloc]
                            initWithTitle:@"Parental permission needed"
                            message:@"This App is included under the 'Kids Category' on the App Store.  Therefore, explicit parental permission is required to purchase more mazes.  If you are authorized to grant such permission, you may do so through your Settings App.  Open Settings, scroll down to HyperCubeL, tap it, and then turn on Permission."
                            delegate: nil
                            cancelButtonTitle:@"Ok"
                            otherButtonTitles:nil ] ;
            [noPermission show];
            [noPermission release]; */


            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Parental permission needed" message:@"This App is included under the 'Kids Category' on the App Store.  Therefore, explicit parental permission is required to purchase more mazes.  If you are authorized to grant such permission, you may do so through your Settings App.  Open Settings, scroll down to HyperCubeL, tap it, and then turn on Permission." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [[self theParentVC] presentViewController:alert animated:YES completion:nil];
        }else{
            [spinner startAnimating];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(grantThisIAP:)
                                                         name:@"IAPResult" object:nil];
            iAPSystem=[[IAPSystem alloc] initWithProductIdentifiers:[NSSet setWithObjects:@"com.domainname.mazehypercube100Mazes", nil]];
            //      [iAPSystem allowBackDoorWithCode:randomCodeNumber andWebsite:@"https://sites.google.com/site/optionposition/f"];
          //  [iAPSystem provideSelf:self];
            [iAPSystem allowBackDoorWithCode:(unsigned)[[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash]%100000 andWebsite:@"https://sites.google.com/site/optionposition/f"];


            /*UIAlertView *upgradeAlertInfo = [[UIAlertView alloc]
                                             initWithTitle:@"Purchase More Mazes"
                                             message:@"You can purchase 100 mazes\nof each size and complexity level.\n through an In-App Purchase\nthat will upgrade this app."
                                             delegate: iAPSystem
                                             cancelButtonTitle:@"Not now, maybe later"
                                             otherButtonTitles:@"Show me the price",@"I already upgraded - restore",@"Get approved purchase",nil ] ;


            [upgradeAlertInfo show];
            [upgradeAlertInfo release]; */


            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Purchase More Mazes" message:@"You can purchase 100 mazes\nof each size and complexity level.\n through an In-App Purchase\nthat will upgrade this app." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* showPrice = [UIAlertAction actionWithTitle:@"Show me the price" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [iAPSystem alertWithButtonTitle:@"Show me the price"];
            }];
            [alert addAction:showPrice];
            UIAlertAction* restore = [UIAlertAction actionWithTitle:@"I already upgraded - restore" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [iAPSystem alertWithButtonTitle:@"I already upgraded - restore"];
            }];
            [alert addAction:restore];
            UIAlertAction* getApproved = [UIAlertAction actionWithTitle:@"Get approved purchase" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [iAPSystem alertWithButtonTitle:@"Get approved purchase"] ;
            }];
            [alert addAction:getApproved];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Not now, maybe later" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [iAPSystem alertWithButtonTitle:@"Not now, maybe later"] ;}];
            [alert addAction:defaultAction];


            [[self theParentVC] presentViewController:alert animated:YES completion:nil];


            [bpurchaseMazes setTitle:@"Going to App Store.  Please wait" forState:UIControlStateNormal];
            //      [purchaseMazes setEnabled:NO];
        }
    }
}

-(UIViewController *)theParentVC{
    UIViewController* parentController =[[UIApplication sharedApplication]keyWindow].rootViewController;
    while( parentController.presentedViewController &&
          parentController != parentController.presentedViewController ){
        parentController = parentController.presentedViewController;
    }
    return parentController;
}


-(void)processSegmentControl:(UISegmentedControl *)choice{


  //  ShowHelp.layer.cornerRadius = 5.0;
    choice.layer.borderColor = [UIColor whiteColor].CGColor;
    choice.layer.borderWidth=1.0f;
//    [choice setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
  //              [UIFont boldSystemFontOfSize:14.0f],NSFontAttributeName,
    //            [UIColor whiteColor],NSForegroundColorAttributeName,
      //                               nil] forState:UIControlStateNormal];
  //  choice.backgroundColor=[UIColor whiteColor];
  //  NSArray *segments=[choice subviews];
  //  for(UIView *aSegment in segments){
      //  aSegment.backgroundColor=[UIColor colorWithRed:195/255. green:166/255. blue:137/255. alpha:1.0];
   // }






}


//ONLY FOR IPAD USE.....
-(void)grantThisIAP:notification{
    NSString *productIdentifier=[notification object];


    //   NSLog(@"here in grantThisIAP");
    if([productIdentifier isEqualToString:@"com.domainname.mazehypercube100Mazes"]){
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        int deviceCode=    [[[proprietary code here]]]]
        if((int)[[[[proprietary code here]]]]==deviceCode){
            /*UIAlertView *upgraded;
            upgraded = [[UIAlertView alloc]
                        initWithTitle:@"Upgraded"
                        message:@"This version of Maze HyperCube Lite\nhas been upgraded to 100 mazes\nof each size and complexity level."
                        delegate: nil
                        cancelButtonTitle:@"Ok"
                        otherButtonTitles:nil ] ;
            [upgraded show];
            [upgraded release]; */


            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Upgraded" message:@"This version of Maze HyperCube Lite\nhas been upgraded to 100 mazes\nof each size and complexity level." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [[self theParentVC] presentViewController:alert animated:YES completion:nil];


            numberOfMazesPurchased=100;
            [self displayCurrentValues];
        }
    }else{
        // NSLog(@"here f1");
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"IAPResult" object:nil];
        [iAPSystem autorelease];
        iAPSystem=nil;
        [bpurchaseMazes setTitle:@"Explore purchasing more mazes" forState:UIControlStateNormal];
        // NSLog(@"here f2");
        [spinner stopAnimating];
        // NSLog(@"here f3");




        // NSLog(@"here f5");






    }
}



/*

-(IBAction)considerInAppPurchase:(id)sender {
    if([[purchaseMazes titleForSegmentAtIndex:0] isEqualToString:@"Explore purchasing more mazes"]){


        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL theValue=[[userDefaults objectForKey:@"parental_permission"] boolValue];
        if(theValue==NO){
            UIAlertView *noPermission;
            noPermission = [[UIAlertView alloc]
                            initWithTitle:@"Parental permission needed"
                            message:@"This App is included under the 'Kids Category' on the App Store.  Therefore, explicit parental permission is required to purchase more mazes.  If you are authorized to grant such permission, you may do so through your Settings App."
                            delegate: self
                            cancelButtonTitle:@"Ok"
                            otherButtonTitles:nil ] ;
            [noPermission show];
            [noPermission release];
        }else{


            // // NSLog(@"I am here!!!!!");
            NSString *productName=[NSString stringWithFormat:@"com.domainname.mazehypercube100Mazes"];
            SKProductsRequest *prodRequest=[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject: productName]];
            prodRequest.delegate = self;
            [prodRequest start];
            [spinner startAnimating];
            [purchaseMazes setTitle:@"Going to App Store.  Please wait" forSegmentAtIndex:0];
        }
    }
}


-(void) productsRequest: (SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
	//NSLog(@"here i am");
	if([response.products count]==0){
	UIAlertView *noValidProducts;
	noValidProducts = [[UIAlertView alloc]
	   initWithTitle:@"No mazes at the App Store"
	   message:@"Additional mazes do not seem to be available at the App Store at this time.  Please try again later."
	   delegate: self
	   cancelButtonTitle:@"Sorry"
	   otherButtonTitles:nil ] ;
	[noValidProducts show];
	[noValidProducts release];
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	[spinner stopAnimating];
//        inAppAvailable=NO;
	}else{
        validProduct=[[NSArray alloc] initWithArray:response.products];
	UIAlertView *validProductsExist;
	validProductsExist = [[UIAlertView alloc]
	  initWithTitle:@"More mazes are available from the App Store"
	  message:@"You can purchase 100 mazes of each size and complexity level.\n(If you think you already purchased these mazes touch \"Verify purchases\" below.)"
	  delegate: self
	  cancelButtonTitle:@"No thanks"
	  otherButtonTitles:@"Show me",@"Verify purchases",nil ] ;
	[validProductsExist show];
	[validProductsExist release];
	}
	[request release];
}



- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
	UIAlertView *restoreError;
	restoreError = [[UIAlertView alloc]
	initWithTitle:@"Store error"
	message:@"An error occured while trying to get information from the App Store.  Please try again later."
	delegate: self
	cancelButtonTitle:@"Sorry"
	otherButtonTitles:nil ] ;
	[restoreError show];
	[restoreError release];
	[request release];
    //    inAppAvailable=NO;
    [purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
//    [purchaseMazes setHidden:YES];
}


-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{


    VerificationControllerPBKsimple *verificationController=[[VerificationControllerPBKsimple alloc] init];
	for(SKPaymentTransaction *transaction in transactions){
	switch (transaction.transactionState){
	case SKPaymentTransactionStatePurchasing:
	break;
	case SKPaymentTransactionStatePurchased:
               // NSLog(@"a receipt came in for purchased in playvc!!!");
	if([transaction.payment.productIdentifier isEqualToString:@"com.domainname.mazehypercube100Mazes"]
                   && [verificationController isTransactionAndItsReceiptValid:transaction]){
	numberOfMazesPurchased=100;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:numberOfMazesPurchased forKey:@"NumberOfMazesPurchased"];
//	inAppAvailable=NO;
	[self displayCurrentValues];
	}else{
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	}
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[spinner stopAnimating];
	break;
	case SKPaymentTransactionStateRestored:
              //  NSLog(@"a receipt came in for restored in playvc!!!");
	if([transaction.payment.productIdentifier isEqualToString:@"com.domainname.mazehypercube100Mazes"]
                   && [verificationController isTransactionAndItsReceiptValid:transaction]){


                  //  NSLog(@"a receipt came in for restored in playvc!!!");


	numberOfMazesPurchased=100;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:numberOfMazesPurchased forKey:@"NumberOfMazesPurchased"];
//	inAppAvailable=NO;
	[self displayCurrentValues];
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[spinner stopAnimating];


	}else {
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	}


	//	NSLog(@"numberOfMazesPurchased= %i",numberOfMazesPurchased);
	break;
	case SKPaymentTransactionStateFailed:
	//	NSLog(@"here i am play failed");
	if(transaction.error.code !=SKErrorPaymentCancelled){
	UIAlertView *storeError;
	storeError = [[UIAlertView alloc]
	  initWithTitle:@"Transaction error"
	  message:@"An error occured while trying to transact with the App Store.  Please try again later."
	  delegate: self
	  cancelButtonTitle:@"Sorry"
	  otherButtonTitles:nil ] ;
	[storeError show];
	[storeError release];
	}
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	[spinner stopAnimating];
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	break;
	}
	}
    [verificationController release];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
	UIAlertView *restoreError;
	restoreError = [[UIAlertView alloc]
	initWithTitle:@"Error"
	message:@"An error occured while trying to verify your previous purchase at the App Store.  Please try again later."
	delegate: self
	cancelButtonTitle:@"Sorry"
	otherButtonTitles:nil ] ;
	[restoreError show];
	[restoreError release];
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	[spinner stopAnimating];
}


- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
	if(numberOfMazesPurchased<100){
	UIAlertView *restoreError;
	restoreError = [[UIAlertView alloc]
	initWithTitle:@"No purchase found"
	message:@"The App Store does not have a record of a previous purchase of mazes under your current iTunes account.  Please consider purchasing more mazes under your current iTunes account."
	delegate: self
	cancelButtonTitle:@"Sorry"
	otherButtonTitles:nil ] ;
	[restoreError show];
	[restoreError release];
	[purchaseMazes setTitle:@"Explore purchasing more mazes" forSegmentAtIndex:0];
	}
	[spinner stopAnimating];
}
*/

-(IBAction)selectNextMaze:(id)sender {
	INumMazeNumber=INumMazeNumber+1;
	if(INumMazeNumber>numberOfMazesPurchased) INumMazeNumber=1;
	if (aINumMazeNumber!=INumMazeNumber){
	[self reSetValues];
	[self displayCurrentValues];
	aINumMazeNumber=INumMazeNumber;
	}
//	if(INumMazeNumber==1 && inAppAvailable && !selectShowing){
    if(INumMazeNumber==1                   && !selectShowing   && numberOfMazesPurchased<100){
	/* UIAlertView *inAppPurchase;
	inAppPurchase = [[UIAlertView alloc]
	 initWithTitle:@"Going back to Maze #1"
	 message:@"You have used all of the mazes\nof this size and complexity.\nIf you wish to consider buying\nmore mazes, or if you already\nbought more mazes,\ntouch \"Select\" then touch\n\"Explore purchasing more mazes\""
	 delegate: self
	 cancelButtonTitle:@"Ok"
	 otherButtonTitles:nil];
	[inAppPurchase show];
	[inAppPurchase release]; */


        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Going back to Maze #1" message:@"You have used all of the mazes\nof this size and complexity.\nIf you wish to consider buying\nmore mazes, or if you already\nbought more mazes,\ntouch \"Select\" then touch\n\"Explore purchasing more mazes\"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                numberOfMazesCompleted=numberOfMazesCompleted+1;
                if(numberOfMazesCompleted>=16)[self makeAnOffer];
        }];
        [alert addAction:defaultAction];
        [[self theParentVC] presentViewController:alert animated:YES completion:nil];


	}
//	if(INumMazeNumber==1 && inAppAvailable && selectShowing){
	if(INumMazeNumber==1                   && selectShowing && numberOfMazesPurchased<100){
	/*UIAlertView *inAppPurchase;
	inAppPurchase = [[UIAlertView alloc]
	 initWithTitle:@"Going back to Maze #1"
	 message:@"You have used all of the mazes\nof this size and complexity.\nIf you wish to consider buying\nmore mazes, or if you already\nbought more mazes, touch\n\"Explore purchasing more mazes\""


	 delegate: self
	 cancelButtonTitle:@"Ok"
	 otherButtonTitles:nil];
	[inAppPurchase show];
	[inAppPurchase release];*/


        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Going back to Maze #1" message:@"You have used all of the mazes\nof this size and complexity.\nIf you wish to consider buying\nmore mazes, or if you already\nbought more mazes, touch\n\"Explore purchasing more mazes\"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                numberOfMazesCompleted=numberOfMazesCompleted+1;
                if(numberOfMazesCompleted>=16)[self makeAnOffer];
        }];
        [alert addAction:defaultAction];
        [[self theParentVC] presentViewController:alert animated:YES completion:nil];


	}










}

-(IBAction)PriorMaze:(id)sender {
	INumMazeNumber=INumMazeNumber-1;
	if(INumMazeNumber<1) INumMazeNumber=numberOfMazesPurchased;
	if (aINumMazeNumber!=INumMazeNumber){
	[self reSetValues];
	[self displayCurrentValues];
	aINumMazeNumber=INumMazeNumber;
	}
}

-(IBAction)EasyHard:(id)sender {
	HardMaze=(int)SelEasyHard.selectedSegmentIndex;
	if (aHardMaze!=HardMaze) {
	[self reSetValues];
	[self displayCurrentValues];
	aHardMaze=HardMaze;
	}
}

-(IBAction)NewSize:(id)sender {
}

-(void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    // NSLog(@"viewwilldissappear playview");
}

-(void) archiveCurrentValues{
	aINumMazeNumber=INumMazeNumber;
	aNumMazeSize=NumMazeSize;
	aHardMaze=HardMaze;
}

-(void) displayCurrentValues {
	NumMazeNumber=INumMazeNumber;
	temp1 = [[NSString alloc] initWithFormat:@"Maze Number %d",INumMazeNumber];
	DisMazeNumber.text=temp1;
	[temp1 release];
	if(numberOfMazesPurchased==100 && !iphoneisDevice){
	if(selectShowing)[SlideMazeNumber setHidden:NO];
	SlideMazeNumber.maximumValue=100.0;
	SlideMazeNumber.value=NumMazeNumber;
	[bpurchaseMazes setHidden:YES];
	}
	SlideMazeNumber.value=NumMazeNumber;
	SelMazeSize.selectedSegmentIndex = NumMazeSize-1;
	temp1 = [[NSString alloc] initWithFormat:@"Maze Size %dx%dx%dx%d",wNumMazeSize, zNumMazeSize,xNumMazeSize,yNumMazeSize];
	DisMazeSize.text=temp1;
	[temp1 release];
	SelEasyHard.selectedSegmentIndex=HardMaze;
	if(xNumMazeSize*yNumMazeSize*zNumMazeSize*wNumMazeSize>1000) temp1 = [[NSString alloc] initWithFormat:@"(too big)"];
	else temp1 = [[NSString alloc] initWithFormat:@""];
	DisWarning.text=temp1;
	[temp1 release];
	if(makeNoiseOn)SelSound.selectedSegmentIndex=1;
	if(!makeNoiseOn)SelSound.selectedSegmentIndex=0;
	[self viewBeingCalled];


	//  may want to redraw maze here....


}

-(void) reSetValues {
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 5;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
	//	return 1;
	if (component==0) return 8;
	else if (component==1) {
	if(mazeShape==5&&xNumMazeSize>1)return 39-xNumMazeSize-iphoneDelta;
	else if(mazeShape==5&&xNumMazeSize==1)return 39-iphoneDelta;
	else if (mazeShape==6) return 9;
	else if (mazeShape==7&&xNumMazeSize>1&&xNumMazeSize!=40-iphoneDelta) return 40-xNumMazeSize-iphoneDelta;
	else if (mazeShape==7&&xNumMazeSize==40-iphoneDelta) return 1;
	else if (mazeShape==7&&xNumMazeSize==1) return 40-iphoneDelta;
	else return 39-iphoneDelta;
	}
	else if (component==2) {
	if(mazeShape==7)return 40-iphoneDelta;
	else return 1;
	}
	else if (component==3){
	if(mazeShape==7) return 40-iphoneDelta;
	else if (mazeShape==1||mazeShape==3)return 40-iphoneDelta;
	else return 1;
	}
	else {
	if(mazeShape==7 && wNumMazeSize!=40-iphoneDelta&&wNumMazeSize!=1) return 40-wNumMazeSize-iphoneDelta;
	if(mazeShape==7 && wNumMazeSize!=40-iphoneDelta&&wNumMazeSize==1) return 40-iphoneDelta;
	else if(mazeShape==7 && wNumMazeSize==40-iphoneDelta) return 1;
	else if(mazeShape==5&&wNumMazeSize<40-iphoneDelta)return 40-wNumMazeSize-iphoneDelta;
	else return 1;
	}
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	if (component==0) return [hypercubeNames objectAtIndex:row];
	else if (component==1){
	if (mazeShape!=7) return [edgeNumbers objectAtIndex:row+1];
	else return [edgeNumbers objectAtIndex:row];
	}
	else if (component==2){
	if ((mazeShape!=7)&&(mazeShape!=1)&&(mazeShape!=0))return [edgeNumbers objectAtIndex:wNumMazeSize-1];
	else return [edgeNumbers objectAtIndex:row];
	}
	else if (component==3){
	if((mazeShape==4)||(mazeShape==5)||(mazeShape==6))return [edgeNumbers objectAtIndex:wNumMazeSize-1];
	else return [edgeNumbers objectAtIndex:row];
	}
	else {
	if (mazeShape==6)	return [edgeNumbers objectAtIndex:wNumMazeSize-1];
	else return [edgeNumbers objectAtIndex:row];
	}
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
	if(component==0){
	mazeShape=(int)row;
	if(mazeShape!=7&&wNumMazeSize==1)wNumMazeSize=2;
	}
	else if(component==1){
	wNumMazeSize=(int)row+2;
	if(mazeShape==7)wNumMazeSize=wNumMazeSize-1;
	}
	else if(component==2)zNumMazeSize=(int)row+1;
	else if(component==3)yNumMazeSize=(int)row+1;
	else xNumMazeSize=(int)row+1;
	[self pickerdelayTriggered];


}

-(void) pickerdelayTriggered {
	if (mazeShape==0) {
	zNumMazeSize=1;
	yNumMazeSize=1;
	xNumMazeSize=1;
	}
	if (mazeShape==1) {
	zNumMazeSize=1;
	xNumMazeSize=1;
	}
	if (mazeShape==2) {
	yNumMazeSize=1;
	xNumMazeSize=1;
	zNumMazeSize=wNumMazeSize;
	}
	if (mazeShape==3) {
	xNumMazeSize=1;
	zNumMazeSize=wNumMazeSize;
	}
	if (mazeShape==4) {
	zNumMazeSize=wNumMazeSize;
	yNumMazeSize=wNumMazeSize;
	xNumMazeSize=1;
	}
	if (mazeShape==5) {
	zNumMazeSize=wNumMazeSize;
	yNumMazeSize=wNumMazeSize;
	if (xNumMazeSize>40-iphoneDelta-wNumMazeSize) xNumMazeSize=40-iphoneDelta-wNumMazeSize;
	if(xNumMazeSize==0)xNumMazeSize=1;
	}


	if (mazeShape==6) {
	if(wNumMazeSize>10)wNumMazeSize=10;
	zNumMazeSize=wNumMazeSize;
	yNumMazeSize=wNumMazeSize;
	xNumMazeSize=wNumMazeSize;
	}
	[picker reloadComponent:1];
	[picker reloadComponent:2];
	[picker reloadComponent:3];
	[picker reloadComponent:4];
	if (mazeShape==7) {
	[picker selectRow:xNumMazeSize-1 inComponent:4 animated:YES];
	[picker selectRow:yNumMazeSize-1 inComponent:3 animated:YES];
	[picker selectRow:zNumMazeSize-1 inComponent:2 animated:YES];
	[picker selectRow:wNumMazeSize-1 inComponent:1 animated:YES];
	}
	if(mazeShape==5)[picker selectRow:xNumMazeSize-1 inComponent:4 animated:YES];
	if(mazeShape==1||mazeShape==3)[picker selectRow:yNumMazeSize-1 inComponent:3 animated:YES];
	[picker selectRow:mazeShape inComponent:0 animated:YES];
	if (mazeShape!=7)[picker selectRow:wNumMazeSize-2 inComponent:1 animated:YES];
	//	[self reSetValues];
	[self displayCurrentValues];
}


-(void) NoisesOnOff:(id)sender{
	makeNoiseOn=NO;
	if(SelSound.selectedSegmentIndex==1)makeNoiseOn=YES;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
	return 40;  //this does not changed with iPhone
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
	if (component==0) {
	return 155;
	}else {
	return 48;
	}
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];


	// Release any cached data, images, etc that aren't in use.
}
# Conversion of PlayViewController.m
# MazeCube4
#
# Converted by Jay McArthur 08/09/22
# Copyright 2022. All rights reserved.
# Version 2.2.3 has xInt, yInt, zInt fix in completeMaze so that position can be saved correctly.
#

# import "SelectViewController.h"
# import "PlayViewController.h"
# import "QuartzFunView.h"
import numpy as np
import threading


def data_file_path() -> str:
    paths = 'Path To Save File'  # TODO make this list myraid
    return paths


class PlayViewController:
    def __init__(self):
        self.clickNoise = None  # TODO These all might be display parts
        self.quartzFunView = None
        self.gestureStartPoint = None
        self.graphView = None
        self.DisplayMazeNumber = None
        self.DisplayMazeSize = None
        self.DisplayEasyHard = None
        self.DisplayMovesToFinish = None
        self.DisplayTime = None
        self.DisplayShowWalls = None
        # self.showBestMove = None
        self.bShowBestMove = {}
        self.bRestartMaze = None
        self.SelShowWalls = None
        # self.SelShowFloors = None
        self.bSelShowFloors = None
        # self.SelShowMoves = None
        self.bSelShowMoves = None
        self.bSelColorZW = None
        self.MarkPosition = None
        self.picker = None
        # self.picker1 = None
        self.bLandscapeNext = None
        self.bLandscapeRestart = None
        self.LandscapePorousNormal = None
        # self.LandscapeMoves = None
        self.bLandscapeMoves = None
        # self.LandscapePortals = None
        self.bLandscapePortals = None
        # self.LandscapeShowBestMove = None
        self.bLandscapeShowBestMove = {}
        # self.LandscapeMovesButton = None
        # self.LandscapePortalsButton = None
        # self.LandscapeShowBestMoveButton = None
        self.SelMazeSize = None
        self.DisMazeNumber = None
        self.SelSound = None
        self.SelEasyHard = None
        self.DisMazeSize = None
        self.SlideMazeNumber = None
        self.DisWarning = None
        self.Label1 = None
        self.Segment1 = None
        self.bSegment2 = None
        self.Label2 = None
        self.Label3 = None
        self.Label4 = None
        self.Label5 = None
        self.Label6 = None
        self.Label7 = None
        self.bPurchaseMazes = None
        self.spinner = None
        # self..portalsButton = None
        # self..moveButton = None
        self.bNextMaze = None

        # Line 76
        self.HardMaze, self.NumMazeSize, self.ShowWalls, self.ShowFloors = [0]*4
        self.XMaze, self.YMaze, self.ZMaze, self.WMaze, self.Xxx, self.Yyy, self.Zzz, self.Www = [0]*8
        self.bHardMaze, self.bNumMazeSize, self.bShowWalls, self.bShowFloors, self.bINumMazeNumber = [0]*5
        self.XYxOrigin, self.XYyOrigin, self.ZxOrigin, self.ZyOrigin = [0.0]*4
        self.MarkerSize, self.SpaceSize, self.EdgeSize,self.touchEdgeSize = [0.0]*4
        self.Direction = 0
        self.WallThere, self.porous = [False]*2
        self.xBest, self.yBest, self.zBest, self.wBest = [0]*4
        self.Count = 0
        self.randomMax = 0.0
        Variable1 = 0
        self.randomRatio = 0.0
        self.WallEnd = 0
        self.iTime, self.iMinutes, self.iSeconds, self.iHour, self.iTimeDelta = [0]*5
        self.mazeXYZ = np.zeros((42, 42, 42, 42, 10), dtype=int)
        self.mazeWalls = np.zeros((42, 42, 42, 42, 10), dtype=bool)
        self.delWall = np.zeros((5, 10), dtype=int)
        self.inverseWall = [0]*10
        self.frontierXYZ = np.zeros((3200000, 5), dtype=int)
        self.wallFrontierList = [0]*10
        self.gestureStartXvalue = 0.0
        self.wallCount = 0
        self.randomOne = 0.0
        self.wallRemove = 0
        self.frontierCount = 0
        self.showingBestMove = False
        self.twoThirty = 0.0
        self.newFrontier = 0
        self.freeVersion = False
        self.temp1 = ''
        self.temp2 = ''
        self.firstTime = False
        self.loadYes = False
        self.complexCount = 0
        self.firstTimeEver = 0
        self.xInt, self.yInt, self.zInt, self.wInt = [0]*4
        self.timerBestMoveInterval = 0.0
        self.showedCompletedMaze = False
        self.BestMoveTimerOn, self.BestMoveTimerAgain, self.BestMoveActive = [False]*3
        self.BestMoveOnAuto = False
        self.touchUnmoved = False
        self.showFloors = False
        self.xNumMazeSize, self.yNumMazeSize, self.zNumMazeSize, self.wNumMazeSize = [0]*4
        self.bxNumMazeSize, self.byNumMazeSize, self.bzNumMazeSize, self.bwNumMazeSize = [0]*4
        self.mazeShape = 0
        self.showMovesNumber = False
        self.intShowMovesNumber = 0
        self.symbolEdgeSize, self.symbolXOrigin, self.symbolYOrigin, self.symbolZOrigin, self.symbolWOrigin = [0.0]*5
        self.wColor = np.zeros((8,7), dtype=float)
        self.cCount, self.selectedColor = 0, 0
        self.makeNoiseValue = 0
        self.makeNoiseOn = False
        self.widthGraph, self.heightGraph = 0.0, 0.0
        self.iphoneIsDevice = False
        self.iphoneDelta = 0
        self.numberOfMazesCompleted = 0
        self.NumMazeNumber = 0.0
        self.xyzwNum = 0
        self.aNumMazeSize, self.aHardMaze, self.aINumMazeNumber, self.aaINumMazeNumber = [0]*4
        self.selectShowing, self.selectShowingJustOff = False, False
        self.timerOn = False
        self.touchXvalueBase, self.touchYValueBase, self.shiftXvalue, self.shiftYValue, self.shiftZValue, self.shiftWValue = [0.0]*6
        self.XYnotWZ = False
        self.numberOfMazesPurchased = 0

    def time_display(self) -> None:
        self.iMinutes = self.iTime / 60
        self.iSeconds = self.iTime % 60
        self.DisplayTime = f'Time: {self.iMinutes}:{self.iSeconds:0>2}'

    def add_second_and_display(self) -> None:
        if not self.timerOn:
            self.timerOn = True
            AddTime = threading.Timer(1, self.time_triggered)
            AddTime.start()

    def time_triggered(self) -> None:
        self.timerOn = False
        if self.iTimeDelta == 2:
            self.iTime -= 1
            self.iTimeDelta = 1
        if self.iTimeDelta == 1:
            self.add_second_and_display()
            if self.view.superview and not self.selectShowing:
                self.iTime += 1
                self.time_display()
            else:
                # self.showBestMove = 'Show Best Move' forSegmentAtIndex:0
                # self.LandscapeShowBestMove = 'Show Best Move' forSegmentAtIndex:0
                UIColor = {'clearColor': 0x000000}  # TODO Add UI Color, remove this
                self.bLandscapeShowBestMove.title = 'Show Best Move'  # forState:UIControlStateNormal
                self.bShowBestMove.title = 'Show Best Move'  # forState:UIControlStateNormal
                self.bShowBestMove.backgroundColor = UIColor.clearColor
                self.bLandscapeShowBestMove.backgroundColor = UIColor.clearColor
                self.showingBestMove = False

    def start_counting(self) -> None:
        self.iTimeDelta = 1
        self.add_second_and_display()

    def stop_counting(self) -> None:
        self.iTimeDelta = 0
        if self.BestMoveOnAuto:
            showBestMovePressed = False  # TODO - Make button not pressed

    def save_info(self) -> None:
        self.intShowMovesNumber = 1 if self.showMovesNumber else 0
        userDefaults = {
            'firstTimer': self.firstTimeEver,
            'XMaze': self.XMaze,
            'YMaze': self.YMaze,
            'ZMaze': self.ZMaze,
            'WMaze': self.WMaze,
            'MoveNumber': self.intShowMovesNumber,
            'MazeNumber': self.INumMazeNumber,  # TODO find out if this is a, aa, b
            'xMazeSize': self.xNumMazeSize,
            'yMazeSize': self.yNumMazeSize,
            'zMazeSize': self.zNumMazeSize,
            'wMazeSize': self.wNumMazeSize,
            'HardMaze': self.hardMaze,  # TODO which one
            'ShowWalls': self.ShowWalls,
            'ShowFloors': self.showFloors,
            'iTime': self.iTime,
            'mazeShape': self.mazeShape,
            'SelectedColor': self.selectedColor,
            'makeNoise': self.makeNoiseOn,
            'MazesCompleted': self.numberOfMazesCompleted
            # 'NumberOfMazesPurchased': self.numberOfMazesPurchased
        }
        array = []
        for self.Xxx in range(self.xNumMazeSize):
            for self.Yyy in range(self.yNumMazeSize):
                for self.Zzz in range(self.zNumMazeSize):
                    for self.Www in range(self.wNumMazeSize):
                        if not self.mazeWalls[self.Xxx][self.Yyy][self.Zzz][self.Www][9]:
                            array.append(False)
                        else:
                            array.append(True)





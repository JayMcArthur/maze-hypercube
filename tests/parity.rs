use std::{fs, process::Command};

// Compile the supplied controller's actual generation methods as C. This keeps
// the expected maze independent of the Rust implementation and failed Python port.
fn reference_source() -> String {
    let original = include_str!("../reference/ios/Play Page - Objective C.m").replace('\r', "");
    let names = [
        "getRandom",
        "initializeMaze",
        "getFirstCell",
        "expandFrontier",
        "pickCellFromFrontier",
        "expandMaze",
        "completeMaze",
    ];
    let mut c = String::from(
        r#"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#define YES 1
#define NO 0
int xNumMazeSize,yNumMazeSize,zNumMazeSize,wNumMazeSize,HardMaze,INumMazeNumber;
int Xxx,Yyy,Zzz,Www,Count,Direction,frontierCount,newFrontier,wallRemove;
double randommax;
float randomOne;
int mazeXYZ[42][42][42][42];
unsigned char mazeWalls[42][42][42][42][10];
int frontierXYZ[3200000][5],wallFrontierList[10];
int inverseWall[10]={0,4,5,6,1,2,3,8,7};
int delWall[5][10]={{0},{0,1,0,0,-1,0,0,0,0},{0,0,1,0,0,-1,0,0,0},{0,0,0,1,0,0,-1,0,0},{0,0,0,0,0,0,0,1,-1}};
uint64_t apple_state;
int apple_rand(void) {
    if (!apple_state) apple_state=123459876;
    // Mathematical definition of the Apple libc sequence.
    apple_state=(16807*apple_state)%2147483647;
    return apple_state;
}
#define rand apple_rand
"#,
    );
    for name in names {
        let start = original
            .find(&format!("-(void){name}"))
            .or_else(|| original.find(&format!("-(void) {name}")))
            .unwrap();
        let body_start = original[start..].find('{').unwrap() + start;
        let mut depth = 1;
        let mut end = body_start + 1;
        while depth != 0 {
            match original.as_bytes()[end] {
                b'{' => depth += 1,
                b'}' => depth -= 1,
                _ => {}
            }
            end += 1;
        }
        let mut body = original[body_start..end].to_owned();
        for called in names {
            body = body.replace(&format!("[self {called}:nil]"), &format!("{called}()"));
        }
        c.push_str(&format!("void {name}(void) {body}\n"));
    }
    c.push_str(r#"
int main(int argc,char **argv) {
    if(argc!=7)return 1;
    xNumMazeSize=atoi(argv[1]);yNumMazeSize=atoi(argv[2]);zNumMazeSize=atoi(argv[3]);wNumMazeSize=atoi(argv[4]);
    INumMazeNumber=atoi(argv[5]);HardMaze=atoi(argv[6]);
    apple_state=(uint32_t)((620+INumMazeNumber)*5120000U+HardMaze*2560000U+xNumMazeSize*64000+yNumMazeSize*1600+zNumMazeSize*40+wNumMazeSize);
    getRandom();getRandom();initializeMaze();getFirstCell();expandFrontier();
    while(frontierCount>0){pickCellFromFrontier();expandMaze();expandFrontier();}
    completeMaze();
    for(int x=1;x<=xNumMazeSize;x++)for(int y=1;y<=yNumMazeSize;y++)for(int z=1;z<=zNumMazeSize;z++)for(int w=1;w<=wNumMazeSize;w++) {
        unsigned walls=0;
        for(int d=1;d<=8;d++)if(mazeWalls[x][y][z][w][d])walls|=1U<<(d-1);
        printf("%u %d\n",walls,mazeXYZ[x][y][z][w]);
    }
    return 0;
}
"#);
    c
}

#[test]
fn every_wall_and_distance_matches_original_controller() {
    let directory =
        std::env::temp_dir().join(format!("hypercube-reference-{}", std::process::id()));
    fs::create_dir_all(&directory).unwrap();
    let source = directory.join("reference.c");
    let binary = directory.join("reference");
    fs::write(&source, reference_source()).unwrap();
    let compiled = Command::new("cc")
        .args(["-O2", "-fwrapv", "-ffp-contract=off", "-o"])
        .arg(&binary)
        .arg(&source)
        .output()
        .unwrap();
    assert!(
        compiled.status.success(),
        "{}",
        String::from_utf8_lossy(&compiled.stderr)
    );
    let sizes = [
        [1, 1, 1, 1],
        [1, 1, 1, 40],
        [1, 7, 1, 4],
        [1, 1, 5, 5],
        [1, 3, 5, 5],
        [1, 4, 4, 4],
        [3, 4, 4, 4],
        [2; 4],
        [3; 4],
        [10; 4],
        [20, 2, 3, 20],
        [40, 40, 40, 1],
        [20, 40, 40, 20],
    ];
    for size in sizes {
        for number in [1, 2, 37, 100] {
            for complex in [0, 1] {
                let args: Vec<String> = size
                    .into_iter()
                    .chain([number, complex])
                    .map(|n| n.to_string())
                    .collect();
                let expected = Command::new(&binary).args(&args).output().unwrap();
                let actual = Command::new(env!("CARGO_BIN_EXE_hypercube-maze"))
                    .arg("--dump")
                    .args(&args)
                    .output()
                    .unwrap();
                assert!(expected.status.success(), "C failed for {args:?}");
                assert!(
                    actual.status.success(),
                    "Rust failed for {args:?}: {}",
                    String::from_utf8_lossy(&actual.stderr)
                );
                assert!(
                    expected.stdout == actual.stdout,
                    "Maze differs from Objective-C for {args:?}"
                );
            }
        }
    }
    fs::remove_dir_all(directory).unwrap();
}

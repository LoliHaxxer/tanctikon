volatile boolean lock;

volatile long delayAIMove = 500;

final Set<Integer> keyCodeDownies=new HashSet();

volatile boolean instantUnits = false;
static final int debugInstantUnits = 0, cDebugButtons = 1;
static final C[][]debugButtons = new C[cDebugButtons][];
static{
  debugButtons[debugInstantUnits] = new C[]{new C(0,0.1),new C(0.05,0.05),};
}
static final String[] debugButtonText = new String[cDebugButtons];
static{
  debugButtonText[debugInstantUnits] = "IU";
}
int debugButtonColor(int i){
  switch(i){
    case debugInstantUnits:
      return instantUnits?infoTabRgb:0xffffff;
  }
  throw new RuntimeException();
}


static final int tileWater = 0, tileLand = 1, tileMountain = 2, cTile = 3;
static final int[] tileMovementCost = new int[cTile];
static{
  tileMovementCost[tileWater] = 1;
  tileMovementCost[tileLand] = 1;
  tileMovementCost[tileMountain] = 2;
}
static final int unitInfantry = 0, unitTank = 1, unitFighter = 2, unitBomber = 3, unitTransport = 4, unitDreadnought = 5, cUnit = 6;
static final int[] unitConstTime = new int[cUnit];
static{
  unitConstTime[unitInfantry] = 2;
  unitConstTime[unitTank] = 4;
  unitConstTime[unitFighter] = 7;
  unitConstTime[unitBomber] = 10;
  unitConstTime[unitTransport] = 5;
  unitConstTime[unitDreadnought] = 12;
}
static final float unitMaxMaxHp=10f;
static final float[] unitMaxHp = new float[cUnit];
static{
  unitMaxHp[unitInfantry] = 5;
  unitMaxHp[unitTank] = 7;
  unitMaxHp[unitFighter] = 7;
  unitMaxHp[unitBomber] = 6;
  unitMaxHp[unitTransport] = 6;
  unitMaxHp[unitDreadnought] = unitMaxMaxHp;
}
static final float[] unitMaxSpd = new float[cUnit];
static{
  unitMaxSpd[unitInfantry] = 2;
  unitMaxSpd[unitTank] = 3;
  unitMaxSpd[unitFighter] = 8;
  unitMaxSpd[unitBomber] = 7;
  unitMaxSpd[unitTransport] = 6;
  unitMaxSpd[unitDreadnought] = 6;
}
static final int movementTypeGround = 0, movementTypeAir = 1, movementTypeWater = 2, cMovementType = 3;
static final int movementGround = 0, movementAir = 1, movementWater = 2, movementGroundMountainBlock = 3, cMovement = 4;
static final int moveTypeIllegal = 0, moveTypeMovement = 1, moveTypeAttack = 2, moveTypeEmbark = 3, moveTypeIncitiate = 4, moveTypeCaptureCity = 5, cMoveType = 6;
static final boolean[] canCaptureCity = new boolean[cMovementType];
static{
  canCaptureCity[movementTypeGround]=true;
  canCaptureCity[movementTypeAir]=false;
  canCaptureCity[movementTypeWater]=false;
}
static final float[][] unitMaxDmg = new float[cUnit][cMovementType];
static{
  unitMaxDmg[unitInfantry][movementTypeGround] = 1.5;
  unitMaxDmg[unitInfantry][movementTypeAir] = 1;
  unitMaxDmg[unitInfantry][movementTypeWater] = 1;
  unitMaxDmg[unitTank][movementTypeGround] = 2;
  unitMaxDmg[unitTank][movementTypeAir] = 1;
  unitMaxDmg[unitTank][movementTypeWater] = 1.5;
  unitMaxDmg[unitFighter][movementTypeGround] = 1;
  unitMaxDmg[unitFighter][movementTypeAir] = 3;
  unitMaxDmg[unitFighter][movementTypeWater] = 1;
  unitMaxDmg[unitBomber][movementTypeGround] = 4;
  unitMaxDmg[unitBomber][movementTypeAir] = 1;
  unitMaxDmg[unitBomber][movementTypeWater] = 3;
  unitMaxDmg[unitTransport][movementTypeGround] = .5;
  unitMaxDmg[unitTransport][movementTypeAir] = 1;
  unitMaxDmg[unitTransport][movementTypeWater] = .5;
  unitMaxDmg[unitDreadnought][movementTypeGround] = 3;
  unitMaxDmg[unitDreadnought][movementTypeAir] = 3;
  unitMaxDmg[unitDreadnought][movementTypeWater] = 3;
}
static final int[] unitMaxMovementType = new int[cUnit];
static{
  unitMaxMovementType[unitInfantry] = movementTypeGround;
  unitMaxMovementType[unitTank] = movementTypeGround;
  unitMaxMovementType[unitFighter] = movementTypeAir;
  unitMaxMovementType[unitBomber] = movementTypeAir;
  unitMaxMovementType[unitTransport] = movementTypeWater;
  unitMaxMovementType[unitDreadnought] = movementTypeWater;
}
static final int[] unitMaxMovement = new int[cUnit];
static{
  unitMaxMovement[unitInfantry] = movementGround;
  unitMaxMovement[unitTank] = movementGroundMountainBlock;
  unitMaxMovement[unitFighter] = movementAir;
  unitMaxMovement[unitBomber] = movementAir;
  unitMaxMovement[unitTransport] = movementWater;
  unitMaxMovement[unitDreadnought] = movementWater;
}
static final boolean[] canCarry = new boolean[cUnit];
static{
  canCarry[unitInfantry]=false;
  canCarry[unitTank]=false;
  canCarry[unitFighter]=false;
  canCarry[unitBomber]=false;
  canCarry[unitTransport]=true;
  canCarry[unitDreadnought]=false;
}
static final boolean[] canEmbark = new boolean[cUnit];
static{
  canEmbark[unitInfantry]=true;
  canEmbark[unitTank]=true;
  canEmbark[unitFighter]=false;
  canEmbark[unitBomber]=false;
  canEmbark[unitTransport]=true;
  canEmbark[unitDreadnought]=false;
}


static final int infoTabRgb=0xdb43d1;
static final int[] tileRgb=new int[cTile];
static{
  tileRgb[tileWater] = 0x1c0cad;
  tileRgb[tileLand]=0x58ad08;
  tileRgb[tileMountain] = 0xc2c1c9;
}
static final Object[][] unitDisplay=new Object[cUnit][];
static{
  //unit_color,
  unitDisplay[unitInfantry] = new Object[]{0xb2ed7b,};
  unitDisplay[unitTank] = new Object[]{0x417510,};
  unitDisplay[unitFighter] = new Object[]{0xbadddc,};
  unitDisplay[unitBomber] = new Object[]{0x08aaa2,};
  unitDisplay[unitTransport] = new Object[]{0x603b35,};
  unitDisplay[unitDreadnought] = new Object[]{0x871c0c,};
}
static final int lToC=0, cToH=1, cSS=2;
static enum bpS{
  hp(){{
    rgb[lToC]=0x00ff00;
    rgb[cToH]=0xff0000;
  }},
  spd(){{
    rgb[lToC]=0x1ff4f4;
    rgb[cToH]=0x000000;
  }},
  ;
  int[]rgb=new int[cSS];
}

static final String[]tileName=new String[cTile];
static{
  tileName[tileWater] = "Water";
  tileName[tileLand] = "Land";
  tileName[tileMountain] = "Mountain";
}static final String[]unitName = new String[cUnit];
static{
  unitName[unitInfantry] = "Infantry";
  unitName[unitTank] = "Tank";
  unitName[unitFighter] = "Fighter";
  unitName[unitBomber] = "Bomber";
  unitName[unitTransport] = "Transport";
  unitName[unitDreadnought] = "Dreadnought";
}
static final String[]unitAbbrevName = new String[cUnit];
static{
  unitAbbrevName[unitInfantry] = "Inf";
  unitAbbrevName[unitTank] = "Tnk";
  unitAbbrevName[unitFighter] = "Fig";
  unitAbbrevName[unitBomber] = "Bmb";
  unitAbbrevName[unitTransport] = "Tra";
  unitAbbrevName[unitDreadnought] = "Dre";
}
static final String[]movementTypeName = new String[cMovementType];
static{
  movementTypeName[movementTypeGround] = "Ground";
  movementTypeName[movementTypeWater] = "Water";
  movementTypeName[movementTypeAir] = "Air";
}
static final String[]moveTypeName = new String[cMoveType];
static{
  moveTypeName[moveTypeIllegal] = "illegal_move";
  moveTypeName[moveTypeMovement] = "movement_move";
  moveTypeName[moveTypeAttack] = "attack_move";
  moveTypeName[moveTypeEmbark] = "embark_move";
  moveTypeName[moveTypeIncitiate] = "incitiation_move";
  moveTypeName[moveTypeCaptureCity] = "capture_move";
}
static final String[] movementDescription = new String[cMovement];
static{
  movementDescription[movementGround]="Can only pass through "+tileName[tileLand]+" terrain";
  movementDescription[movementGroundMountainBlock]=movementDescription[movementGround]+"\nCannot pass through "+tileName[tileMountain]+" terrain";
  movementDescription[movementAir]="Can pass through "+tileName[tileLand]+" and "+tileName[tileWater]+" terrain equally";
  movementDescription[movementWater]="Can only pass through "+tileName[tileWater]+" terrain";
}


static final int shiftActionAddPlayer = 0, shiftActionAddAI = 1, shiftActionRemPlayer = 2, shiftActionPauseMenu = 3, shiftActionDebug = 4, shiftActionReverse = 5, shiftActionForward = 6, shiftActionPauseAI = 7, cShiftAction = 8;
static final Set<Integer>[]shiftActions=new Set[cShiftAction];
static{
  for(int i=0;i<cShiftAction;++i)shiftActions[i]=new HashSet<Integer>();
  shiftActions[shiftActionAddPlayer].add(65); //a
  shiftActions[shiftActionAddAI].add(83); //s
  shiftActions[shiftActionRemPlayer].add(82); //r
  shiftActions[shiftActionPauseMenu].add(80); //p
  shiftActions[shiftActionDebug].add(68); //d
  shiftActions[shiftActionReverse].add(37); //<-
  shiftActions[shiftActionForward].add(39); //->
  shiftActions[shiftActionPauseAI].add(90); //z
}
static final Set<Character>[]cityKeyShortcuts=new Set[cUnit];
static{
  for(int i=0;i<cUnit;++i)cityKeyShortcuts[i]=new HashSet();
  cityKeyShortcuts[unitInfantry].add('q');
  cityKeyShortcuts[unitInfantry].add('Q');
  cityKeyShortcuts[unitTank].add('w');
  cityKeyShortcuts[unitTank].add('W');
  cityKeyShortcuts[unitFighter].add('e');
  cityKeyShortcuts[unitFighter].add('E');
  cityKeyShortcuts[unitBomber].add('r');
  cityKeyShortcuts[unitBomber].add('R');
  cityKeyShortcuts[unitTransport].add('t');
  cityKeyShortcuts[unitTransport].add('T');
  cityKeyShortcuts[unitDreadnought].add('y');
  cityKeyShortcuts[unitDreadnought].add('Y');
}


static final int controlTypePlayer = 0, controlTypeAI = 1, cControlType = 2;
static final boolean[] controlTypeReqCameraAction = new boolean[cControlType];
static{
  controlTypeReqCameraAction[controlTypePlayer] = true;
  controlTypeReqCameraAction[controlTypeAI] = false;
}
static final int typeAIBase = 0, cTypeAI = 1;

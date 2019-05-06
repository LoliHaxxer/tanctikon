import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Tanctikon extends PApplet {



float zoom = 1F, spdZoom=0.1F;
C camLoc=new C();
int screen;
int game=0, game_over=1, pause_menu=2, help=3;

int cPlayer;
List<Player> players;

int idMove;
List<Field.Unit.Move>historyMove;

int moving;
C selC;
List<Object>selected;
List<Field.Unit.Move>selCachedMoves;

HelpScreen helpScreen;

Field field;
float visTileSize;
float visCitySize;
float visUnitDesignationSize;
float visUnitAllianceSize;

boolean debug;
boolean pauseAI;
public void setup() {
  frameRate(24);
  

  screen=game;
  
  helpScreen=new HelpScreen();

  field=new Field(new C(24, 24), 0.03f,0.5f);

  cPlayer=2;

  players = new ArrayList<Player>();
  for (int i=0; i<cPlayer; ++i) {
    Player p=new Player(i,controlTypePlayer);
    players.add(p);
    implementPlayer(field,p);
  }
  
  replay = new Replay(copy(field));

  visTileSize=20f;
  visCitySize=15f;
  visUnitDesignationSize=20f;
  visUnitAllianceSize=13f;
}

public void draw() {
  synchronized (this){
  while(lock);
  lock=true;
  {
  Player p;
  if(!pauseAI&&(p=player(moving)).controlType==controlTypeAI) p.thonk();
  }
  fill(0xffffff);
  noStroke();
  rect(0, 0, width, height);
  float shota=width<height?width:height;
  float visScaTileSize=visTileSize*zoom;
  float visScaCitySize=visCitySize*zoom;
  float visScaUnitDesignationSize=visUnitDesignationSize*zoom;
  float visScaUnitAllianceSize=visUnitAllianceSize*zoom;
  for (Field.Tile[]tiles : field.tiles) {
    for (Field.Tile tile : tiles) {
      if(!onScreen(tile.loc,new C(visScaTileSize,visScaTileSize))){continue;}
      fill(tileRgb[tile.type]);
      stroke(0);
      strokeWeight(1);
      float ltx=camLoc.x+tile.loc.x*visScaTileSize, lty=camLoc.y+tile.loc.y*visScaTileSize; 
      rect(ltx, lty, visScaTileSize, visScaTileSize);
      textSize(visScaTileSize/5);
      fill(0);
      if(debug)text(tile.loc.simple(), ltx, lty+visScaTileSize);
      if (tile.city!=null) {
        float dif=(visScaTileSize-visScaCitySize)/2;
        fill(tile.city.rgb());
        rect(ltx+dif, lty+dif, visScaCitySize, visScaCitySize);
      } else if (tile.unit!=null) {
        float cx=ltx+visScaTileSize/2, cy=lty+visScaTileSize/2;
        fill((int)unitDisplay[tile.unit.type][0]);
        ellipse(cx, cy, visScaUnitDesignationSize, visScaUnitDesignationSize);
        fill(player(tile.unit.pid).rgb);
        ellipse(cx, cy, visScaUnitAllianceSize, visScaUnitAllianceSize);
        float segHp=visScaTileSize/50f;
        float linesHp=unitMaxMaxHp;
        float rectSizeHp=(visScaTileSize-segHp*(linesHp+1))/linesHp;
        stroke(0);
        for(int i=0;i<tile.unit.hp.h&&i<unitMaxMaxHp;++i){
          if(i<tile.unit.hp.c)fill(bpS.hp.rgb[lToC],i,ltx,lty,rectSizeHp,visScaTileSize,segHp,rectSizeHp);
          else fill(bpS.hp.rgb[cToH],i,ltx,lty,rectSizeHp,visScaTileSize,segHp,rectSizeHp);
        }
        for(int i=0;i<tile.unit.spd.h;++i){
          if(i<tile.unit.spd.c)fill(bpS.spd.rgb[lToC],i,ltx+visScaTileSize-rectSizeHp,lty,rectSizeHp,visScaTileSize,segHp,rectSizeHp);
          else fill(bpS.spd.rgb[cToH],i,ltx+visScaTileSize-rectSizeHp,lty,rectSizeHp,visScaTileSize,segHp,rectSizeHp);
        }
      }
    }
  }
  if (selected!=null) {
    Object sel=selected.get(0);
    Located loca=(Located)sel;
    float ltx=camLoc.x+loca.loc().x*visScaTileSize, lty=camLoc.y+loca.loc().y*visScaTileSize;
    C lt=new C(0.75f*width, 0);
    C ar=new C(0.25f*width, height);
    fill(infoTabRgb);
    rect(lt.x, lt.y, ar.x, ar.y);
    float segregation=height/50f;
    int lines=20;
    float ts=(height-segregation*(lines+1))/lines;
    textSize(ts);
    if (sel instanceof Field.City) {
      Field.City city=(Field.City)sel;
      fill(0);
      text("City", 0, lt, ar, segregation, ts);
      fill(city.rgb(), 1, lt, ar, segregation, ts);
      fill(0);
      text("Owner", 1, lt, ar, segregation, ts);
      text(city.stats(), 2, lt, ar, segregation, ts);
    } else if (sel instanceof Field.Unit) {
      Field.Unit unit=(Field.Unit)sel;
      fill(0);
      text(unitName[unit.type], 0, lt, ar, segregation, ts);
      fill(unit.rgb(), 1, lt, ar, segregation, ts);
      fill(0);
      text("Owner", 1, lt, ar, segregation, ts);
      text(unit.stats(), 2, lt, ar, segregation, ts);
    } else if (sel instanceof Field.Tile) {
      Field.Tile tile=(Field.Tile)sel;
      fill(0);
      text(tileName[tile.type], 0, lt, ar, segregation, ts);
      text("Movement cost: "+tileMovementCost[tile.type], 1, lt, ar, segregation, ts);
    }
    noFill();
    stroke(players.get(moving).rgb);
    strokeWeight(visScaTileSize/16);
    rect(ltx, lty, visScaTileSize, visScaTileSize);
  }
  if(cPlayer>0){
    float s=shota/13;
    noStroke();
    fill(players.get(moving).rgb);
    rect(0, 0, s, s);
    if(player(moving).controlType==controlTypeAI){
      fill(0x0);
      textSize(s/2);
      text("AI",0,s);
      if(player(moving).thonking){
        text("thonking...",s,s);
      }
    }
  }
  if(screen==pause_menu){
    Box box = new Box(C.ZERO, new C(width,height), 2, height/4f);
    box.colorText=0;
    box.colorBack=infoTabRgb;
    box.text("Q: Information",0);
    box.text("P: Continue",1);
  }else if(screen==help){
    helpScreen.draw();
  }
  if(debug){
    fill(0);
    textSize(height/50);
    text("debug",0,height);
    for(int i=0;i<cDebugButtons;i+=1){
      C lt = debugButtons[i][0].sca(height), ar = debugButtons[i][1].sca(height);
      stroke(0);
      strokeWeight(1);
      fill(debugButtonColor(i));
      rect(lt.x,lt.y,ar.x,ar.y);
      String text = debugButtonText[i];
      textSize(100);
      textSize(ar.x/textWidth(text)*100);
      fill(0);
      text(text,lt.x,lt.y+ar.y);
    }
  }
  }
  lock=false;
}

public void mouseClicked() {
  if (screen==game) {
    C mouse=new C(mouseX, mouseY);
    for(int i=0;i<cDebugButtons;i+=1){
      if(intersect(mouse,C.ZERO,debugButtons[i][0].sca(height),debugButtons[i][1].sca(height))){
        switch(i){
          case debugInstantUnits:
            instantUnits=!instantUnits;
            break;
        }
        return;
      }
    }
    C selectedC=mouse.sub(camLoc).sca(1/zoom/visTileSize).floor();
    if (selectedC.bounds(field.size)) {
      if (selectedC._(selC)) {
        selectCycle();
      } else {
        select(selectedC);
      }
    }
  }
}
public void keyPressed() {
  keyCodeDownies.add(keyCode);
  if (screen==game) {
    if (keyCode==32) {
      turn();
    } else if (keyCode==9) {
      if (keyCodeDownies.contains(16)) {
        tabCities();
      } else {
        tabUnits();
      }
    } else if(keyCodeDownies.contains(16)){
      int i=0;
      for(;i<shiftActions.length;++i)
        if(shiftActions[i].contains(keyCode))break;
      switch(i){
        case shiftActionAddPlayer:
          addPlayer(controlTypePlayer);
          break;
        case shiftActionAddAI:
          addPlayer(controlTypeAI);
          break;
        case shiftActionRemPlayer:
          remPlayer();
          break;
        case shiftActionPauseMenu:
          screen=pause_menu;
          break;
        case shiftActionDebug:
          debug=!debug;
          //if(debug)for(Controllable c : colle(truev(Controllable.class))){
          //  if(c instanceof Field.Unit && c.pid()==moving){
          //    Field.Unit unit = (Field.Unit)c;
          //    unit.hp=new S(666);
          //    println(unit.hp.c);
          //  }
          //}
          break;
        case shiftActionForward:
          replay.browse(1);
          break;
        case shiftActionReverse:
          replay.browse(-1);
          break;
        case shiftActionPauseAI:
          pauseAI=!pauseAI;
          break;
      }
    }else if (selected!=null) {
      Object sel=selected.get(0);
      if(sel instanceof Controllable && ((Controllable)sel).pid()==moving){
        if (sel instanceof Field.City) {
          Field.City city=(Field.City)sel;
          for (int i=0; i<cityKeyShortcuts.length; ++i) {
            if (cityKeyShortcuts[i].contains(key))city.produce(i);
          }
        } else if (sel instanceof Field.Unit)a:
        {
          Field.Unit unit=(Field.Unit)sel;
          C candi;
          switch(keyCode) {
          case 37:
            candi=unit.loc.add(C.LEFT);
            break;
          case 38:
            candi=unit.loc.add(C.UP);
            break;
          case 39:
            candi=unit.loc.add(C.RIGHT);
            break;
          case 40:
            candi=unit.loc.add(C.DOWN);
            break;
          default: 
            break a;
          }
          for (Field.Unit.Move move : selCachedMoves) {
            if (candi._(move.target)) {
              unit.move(move);
              cacheMoves(unit);
              break a;
            }
          }
        }
      }
    }
  }else if(screen==pause_menu){
    switch(keyCode){
      case 81:
        screen = help;
        break;
      case 80:
        screen = game;
        break;
    }
  }else if(screen==help){
    switch(keyCode){
      case 81:
        screen=pause_menu;
        break;
      case 39:
      case 40:
        helpScreen.browse(1);
        break;
      case 37:
      case 38:
        helpScreen.browse(-1);
        break;
    }
  }
}
public void keyReleased() {
  keyCodeDownies.remove(keyCode);
}
C mouLast=null;
public void mouseDragged(MouseEvent e) {
  if (mouLast==null) {
    mouLast=new C(mouseX, mouseY);
  } else {
    C now=new C(mouseX, mouseY), move=mouLast.sub(now);
    camLoc=camLoc.sub(move);
    mouLast=now;
  }
}
public void mouseMoved() {
  mouLast=null;
}
public void mouseWheel(MouseEvent e) {
  if (e.getCount()==1)zoom*=1-spdZoom;
  else zoom*=1+spdZoom;
}

interface Located {
  public C loc();
}
interface Controllable extends Located, IDed {
  public boolean idle();
  public int pid();
}
interface IDed {
  public int id();
}
int fieldIdAt = 1;
class Field {
  C size;
  Tile[][] tiles;
  //Set<City> cities=new HashSet();
  //Set<Unit> units=new HashSet();
  private Field(){}
  Field(C size, float cityFreq,float landSplitterness) {
    this.size=size;
    this.tiles=new Tile[(int)size.x][(int)size.y];
    for (int i=0; i<size.x; ++i) {
      for (int j=0; j<size.y; ++j) {
        C c=new C(i, j);
        tiles[i][j]=new Tile(c,(int)(noise(c,0,landSplitterness)*cTile));
      }
    }
    int wChunk = 8, hChunk = 8;
    for(int i=0;i*wChunk<size.x;i+=1){
      int lx = i*wChunk;
      int hx = lx+wChunk<size.x? lx+wChunk : (int)size.x;
      for(int j=0;j*hChunk<size.y;j+=1){
        int ly = (int)(j*hChunk);
        int hy = ly+hChunk<size.y? ly+hChunk : (int)size.y;
        C l=new C(lx,ly), h=new C(hx,hy);
        List<Tile>candis=new ArrayList();
        for(C loc : C.iter(l,h)){
          Tile tile=tile(loc);
          if(tile(loc).type==tileLand)candis.add(tile);
        }
        float citiesReq = candis.size()*cityFreq;
        int citiesMin = (int)citiesReq;
        citiesReq = random(1)<citiesReq-citiesMin?citiesMin:citiesMin+1;
        int citiesChosen = 0;
        while(citiesChosen<citiesReq){
          int choose=(int)random(candis.size());
          Tile candi = candis.remove(choose);
          candi.city=new City(candi.loc,-1);
          citiesChosen+=1;
        }
      }
    }
  }
  public boolean bounds(C loc) {
    return loc.bounds(size);
  }
  public Tile tile(C loc) {
    if (!bounds(loc))return null;
    return g(tiles, loc);
  }
  public Iterable<Tile>tiles(){
    return new Iterable(){
      public Iterator<Tile>iterator(){
        return new Iterator(){
          C at=C.ZERO;
          public Tile next(){
            Tile r=tile(at);
            at=at.add(new C(1,0));
            if(at.x>=size.x)at=new C(0,at.y+1);
            return r;
          }
          public boolean hasNext(){
            return at.bounds(size);
          }
        };
      }
    };
  }
  public List<City>cities() {
    List<City>r=new ArrayList();
    for (Tile[]tiles : tiles) {
      for (Tile tile : tiles) {
        if (tile.city!=null)r.add(tile.city);
      }
    }
    return r;
  }
  public void turn() {
    for (Tile[]tiles : tiles) {
      for (Tile tile : tiles) {
        tile.turn();
      }
    }
  }
  class Tile implements Located, IDed {
    C loc;
    int type, id;
    City city;
    Unit unit;
    Tile(C loc,int type) {
      this.id = fieldIdAt++;
      this.loc = loc;
      this.type = type;
    }
    public int owned() {
      if (city!=null)return city.pid;
      if (unit!=null)return unit.pid;
      return -1;
    }
    public int moveType(Unit u) {
      if (city!=null) {
        if(!city.full()){
          if (city.pid==u.pid) {
            return moveTypeIncitiate;
          }
        }
        if(city.pid!=u.pid){
          if(city.size()==0&&!city.full()) return moveTypeCaptureCity;
          return moveTypeAttack;
        }
      }
      if (unit!=null) {
        if (u.pid==unit.pid){
          if(canEmbark[u.type]&&canCarry[unit.type])return moveTypeEmbark;
          return moveTypeIllegal;
        }
        return moveTypeAttack;
      }
      if(!u.passable(type))return moveTypeIllegal;
      return moveTypeMovement;
    }
    public Unit defender(Unit u) {
      if (city!=null) {
        return city.defender(u);
      }
      return unit;
    }
    public void turn() {
      if (city!=null&&city.pid==moving)city.turn();
      if (unit!=null&&unit.pid==moving)unit.turn();
    }
    public void cleanse(int pid){
      if(city!=null&&city.pid==pid){
        city.clear();
        city.pid=-1;
      }
      if(unit!=null&&unit.pid==pid){
        unit.wiped();
        unit=null;
      }
    }
    public void revive(Unit me){
      if(me.internater==null){
        unit=me;
      }
      else if(me.internater instanceof City){
        city.add(me);
      }else if(me.internater instanceof Unit){
        unit.add(me);
      }
    }
    public void kill(Unit me){
      while(lock);
      lock=true;
      if(city!=null){
        me.internater=city;
        city.remove(me);
      }
      if(me==unit)unit=null;
      else if(unit!=null){
        me.internater=unit;
        unit.remove(me);
      }
      lock=false;
    }
    public void move(Unit me, C target) {
      while(lock);
      lock=true;
      if (city!=null) {
        city.remove(me);
      }
      if (me==unit) {
        unit=null;
      }
      if(me.embarkedIn!=null){
        me.embarkedIn.remove(me);
        me.embarkedIn=null;
      }
      Tile tar=tile(target);
      if (tar.city!=null) {
        tar.city.add(me);
      } else if(tar.unit!=null){
        tar.unit.add(me);
        me.embarkedIn=tar.unit;
      } else{
        tar.unit=me;
      }
      me.sLoc(target);
      lock=false;
    }
    public void reve(Unit me, C origin){
      while(lock);
      lock=true;
      if (city!=null) {
        city.remove(me);
        
      }
      if (me==unit) {
        unit=null;
      }
      if(me.embarkedIn!=null){
        me.embarkedIn.remove(me);
        me.embarkedIn=null;
      }
      Tile tar=tile(origin);
      if (tar.city!=null) {
        tar.city.add(me);
      } else if(tar.unit!=null){
        tar.unit.add(me);
        me.embarkedIn=tar.unit;
      } else{
        tar.unit=me;
      }
      me.sLoc(origin);
      lock=false;
    }
    public List<Object>selectibles() {
      List<Object> r=new ArrayList();
      if (city!=null)r.addAll(city.selectibles());
      if (unit!=null)r.addAll(unit.selectibles());
      r.add(this);
      return r;
    }
    public C loc() {
      return loc;
    }
    public List<Controllable> controllables() {
      List r=new ArrayList();
      if (city!=null)r.addAll(city.selectibles());
      if (unit!=null)r.addAll(unit.selectibles());
      return r;
    }
    public int id() {
      return id;
    }
  }
  class Unit implements Located, Controllable, IDed {
    C loc;
    S hp, spd, atks;
    S[]dmg=new S[cMovementType];
    int movementType, movement, pid, type, id, size=1;
    List<Unit>transporting;
    Unit embarkedIn;
    volatile boolean wiped;
    Unit(C loc, int pid, int type) {
      this.id=fieldIdAt++;
      this.loc=loc;
      this.pid=pid;
      this.type=type;
      hp=new S(unitMaxHp[type]);
      for(int i=0;i<cMovementType;i+=1){
        dmg[i]=new S(unitMaxDmg[type][i]);
      }
      spd=new S(unitMaxSpd[type]);
      movement=unitMaxMovement[type];
      movementType=unitMaxMovementType[type];
      atks=new S(1);
      if(canCarry[type])transporting=new ArrayList();
    }
    public List<String>stats(){
      List<String>ret=new ArrayList();
      ret.add("Health: "+hp.c+"|"+hp.h);
      ret.add("Damage:");
      for(int i=0;i<dmg.length;i+=1){
        ret.add("vs. "+movementTypeName[i]+": "+dmg[i].c);
      }
      ret.add("Speed: "+spd.c+"|"+spd.h);
      ret.add("Attacks: "+atks.c+"|"+atks.h);
      ret.add("Movement Type: "+movementTypeName[movementType]);
      if(canCarry[type]){
        ret.add("Transporting:");
        if(moving!=pid&&!debug)ret.add("Who knows?");
        else{
          int i=0, s=transporting.size();
          for (; i<size; ++i) {
            if (i<s)ret.add(unitAbbrevName[transporting.get(i).type]);
            else ret.add("Empty");
          }
        }
      }
      return ret;
    }
    public List<Move>moves() {
      List<Move>r=new ArrayList();
      moves(r, 0, (int)spd.c, loc, new HashSet());
      r.addAll(attack(loc));
      return r;
    }
    public List<Move>move(){
      List<Move>r=new ArrayList();
      moves(r, 0, (int)spd.c, loc, new HashSet());
      return r;
    }
    public void moves(List<Move>r, int movesUsed, int maxMoves, C loc, Set<Tile>visited) {
      if (movesUsed<maxMoves) {
        Map<C,Integer>nexts=new HashMap();
        for (C next : loc.next()) {
          Tile tile = tile(next);
          if (tile!=null&&!visited.contains(tile)) {
            visited.add(tile);
            int movesUsedAfter = movesUsed+tileMovementCost[tile.type], moveType;
            if (movesUsedAfter<=maxMoves&&((moveType=tile.moveType(this))!=moveTypeIllegal&&moveType!=moveTypeAttack)) {
              r.add(new Move(moveType, movesUsedAfter, this.loc, next));
              nexts.put(next,movesUsedAfter);
            }
          }
        }
        for(Map.Entry<C,Integer> next : nexts.entrySet()) moves(r, next.getValue(), maxMoves, next.getKey(), visited);
      }
    }
    public List<Move>attack(C loc) {
      List<Move>r=new ArrayList();
      if (atks.c>=1) {
        for (C next : loc.next()) {
          Tile tile = tile(next);
          int moveType;
          if (tile!=null&&(moveType=tile.moveType(this))==moveTypeAttack) {
            r.add(new Move(moveType, 0, this.loc, next));
          }
        }
      }
      return r;
    }
    public List<Object>selectibles(){
      List r=new ArrayList();
      r.add(this);
      if (moving==pid&&canCarry[type])r.addAll(transporting);
      return r;
    }
    public void turn() {
      spd.c=spd.h;
      atks.c=atks.h;
    }
    public boolean full(){return transporting.size()>=size;}
    public void add(Unit u){if(transporting!=null)transporting.add(u);}
    public void remove(Unit u){if(transporting!=null)transporting.remove(u);}
    public void move(Move move){move(move,true);}
    public void move(Move move,boolean register) {
      if(wiped)return;
      switch(move.type) {
      case moveTypeMovement:
      case moveTypeEmbark:
      case moveTypeIncitiate:
      case moveTypeCaptureCity:
        {
          Tile mine=tile(loc);
          mine.move(this, move.target);
          spd.ac(-move.drain);
          break;
        }
      case moveTypeAttack:
        {
          Tile target=tile(move.target);
          Unit targett=target.defender(this);
          move.targett=targett;
          targett.takeDmg(dmg[targett.movementType].c);
          atks.ac(-1);
          break;
        }
      }
      if(register)replay.register(move);
    }
    public void reve(Move move){
      switch(move.type) {
      case moveTypeMovement:
      case moveTypeEmbark:
      case moveTypeIncitiate:
      case moveTypeCaptureCity:
        {
          Tile mine=tile(loc);
          mine.reve(this, move.origin);
          spd.ac(move.drain);
          break;
        }
      case moveTypeAttack:
        {
          move.targett.takeDmg(-dmg[move.targett.movementType].c);
          atks.ac(1);
          break;
        }
      }
    }
    Controllable internater;
    public void takeDmg(float damage){
      hp.ac(-damage);
      if(wiped)tile(loc).revive(this);
      if(hp.c==0){
        tile(loc).kill(this);
      }
    }
    public boolean passable(int tileType) {
      switch(movementType) {
      case movementGround:
        return tileType==tileLand||tileType==tileMountain;
      case movementAir:
        return tileType==tileLand||tileType==tileMountain||tileType==tileWater;
      case movementWater:
        return tileType==tileWater;
      case movementGroundMountainBlock:
        return tileType==tileLand;
      }
      throw new RuntimeException();
    }
    public void wiped(){
      wiped=true;
    }
    public int rgb() {
      return players.get(pid).rgb;
    }
    public void sLoc(C v){
      loc=v;
      if(canCarry[type])for(Unit u : transporting) u.sLoc(v);
    }
    public C loc() {
      return loc;
    }
    public boolean idle() {
      return moves().size()>0;
    }
    public int id() {
      return id;
    }
    public int pid() {
      return pid;
    }
    class Move implements Tanctikon.Move{
      int type, drain;
      C origin,target;
      Unit targett;
      Move(int type, int drain, C origin, C target) {
        this.type=type;
        this.drain=drain;
        this.origin=origin;
        this.target=target;
      }
      public Unit Unit() {
        return Unit.this;
      }
      public int hashCode(){
        return ((target.hashCode()+type)*31+drain)*31;
      }
      public String toString(){
        return "{"+moveTypeName[type]+" target: "+target.simple()+" drain: "+drain+"}";
      }
      public void move(){
        Unit.this.move(this,false);
      }
      public void reve(){
        Unit.this.reve(this);
      }
    }
  }
  class City implements Located, Controllable, IDed {
    int size, pid, id;
    C loc;
    List<Unit>incitiated;
    int constUnitType=-1, constUnitTimeLeft;
    City(C loc, int pid) {
      this(loc, pid, 4);
    }
    City(C loc, int pid, int size) {
      this.id=fieldIdAt++;
      this.loc=loc;
      this.pid=pid;
      this.size=size;
      incitiated=new LinkedList();
    }
    public List<String>stats(){
      List<String>r=new ArrayList();
      boolean hideSensitiveInfo = moving!=pid&&!debug;
      if(hideSensitiveInfo){
        r.add("Production: Who knows?");
        r.add("");
      }else{
        r.add("Production: "+(constUnitType==-1?"None":unitName[constUnitType]));
        r.add(constUnitType!=-1?"Turns left: "+constUnitTimeLeft:"");
      }
      r.add("Size: "+size);
      r.add("What's Inside:");
      if(hideSensitiveInfo)r.add("Who knows?");
      else{
        int i=0, s=incitiated.size();
        for (; i<size; ++i) {
          if (i<s)r.add(unitAbbrevName[incitiated.get(i).type]);
          else r.add("Empty");
        }
      }
      boolean nextToWater=nextToWater();
      for(int i=0;i<cUnit;++i){
        if(nextToWater||unitMaxMovementType[i]!=movementTypeWater) r.add(g(cityKeyShortcuts[i])+": Produce "+unitName[i]);
      }
      return r;
    }
    public C loc() {
      return loc;
    }
    public boolean idle() {
      return constUnitType==-1;
    }
    public int id() {
      return id;
    }
    public int pid() {
      return pid;
    }
    public boolean add(Unit u) {
      boolean r;
      if (r=!full()) {
        incitiated.add(u);
        pid=u.pid;
      }
      return r;
    }
    public void remove(Unit u) {
      incitiated.remove(u);
    }
    public void clear(){
      constUnitType=-1;
      for(Unit u : incitiated){
        u.wiped();
      }
      incitiated.clear();
    }
    public void calc_pid() {
      if (incitiated.isEmpty())pid=-1;
      else pid=incitiated.get(0).pid;
    }
    public int size() {
      return incitiated.size();
    }
    public boolean full() {
      return incitiated.size()==size;
    }
    public boolean empt() {
      return incitiated.isEmpty();
    }
    public Unit defender(Unit atk) {
      if (incitiated.isEmpty())return null;
      return incitiated.get(0);
    }
    public int rgb() {
      if (pid==-1)return 0x0c0c0c;
      return player(pid).rgb;
    }
    public void turn() {
      if (!full()&&constUnitType!=-1) {
        constUnitTimeLeft-=1;
        if (constUnitTimeLeft<=0) {
          add(new Unit(loc, pid, constUnitType));
          constUnitType=-1;
        }
      }
      for (Unit u : incitiated) {
        u.turn();
      }
    }
    public List<Object>selectibles() {
      List r=new ArrayList();
      r.add(this);
      if (moving==pid)r.addAll(incitiated);
      return r;
    }
    public boolean nextToWater(){
      for(C next : loc.next()){
        Tile tile;
        if((tile=tile(next))!=null&&tile.type==tileWater)return true;
      }
      return false;
    }
    public boolean produce(int unitType){
      Move move = new Move(unitType,instantUnits?0:unitConstTime[unitType],constUnitType,constUnitTimeLeft);
      replay.register(move);
      return produce(unitType,instantUnits?0:unitConstTime[unitType]);
    }
    public boolean produce(int unitType,int unitTimeLeft) {
      if((constUnitTimeLeft=unitTimeLeft)>0){
        if (unitMaxMovementType[unitType]==movementTypeWater&&!nextToWater())return false;
        constUnitType=unitType;
      }else{
        add(new Unit(loc, pid, unitType));
      }
      return true;
    }
    class Move implements Tanctikon.Move{
      int constUnitType,constUnitTimeLeft;
      int bConstUnitType,bConstUnitTimeLeft;
      Move(int constUnitType,int constUnitTimeLeft,int bConstUnitType,int bConstUnitTimeLeft){
        this.constUnitType=constUnitType;
        this.constUnitTimeLeft=constUnitTimeLeft;
        this.bConstUnitType=bConstUnitType;
        this.bConstUnitTimeLeft=bConstUnitTimeLeft;
      }
      public void move(){
        produce(constUnitType,constUnitTimeLeft);
      }
      public void reve(){
        City.this.constUnitType=bConstUnitType;
        City.this.constUnitTimeLeft=bConstUnitTimeLeft;
      }
    }
  }
}
public Field copy(Field org){
  while(lock);
  lock=true;
  Field r = new Field();
  r.size=org.size;
  r.tiles=new Field.Tile[(int)r.size.x][(int)r.size.y];
  for(int i=0;i<r.size.x;i+=1){
    for(int j=0;j<r.size.y;j+=1){
      r.tiles[i][j]=org.tiles[i][j];
    }
  }
  lock=false;
  return r;
}

public Player player(int pid) {
  try{
  return players.get(pid);
  }
  catch(Exception e){e.printStackTrace();throw new RuntimeException();}
}
Set<Integer>pColors=new HashSet();
public void addPlayer(int controlType){
  int pid=cPlayer++;
  Player player=new Player(pid, controlType);
  if(pid>=players.size()) players.add(player);
  else players.set(pid,player);
  implementPlayer(field, player);
  replay.clear();
}
public void remPlayer(){
  if(cPlayer==0)return;
  int pid=--cPlayer;
  for(Field.Tile tile:field.tiles()){
    tile.cleanse(pid);
  }
  player(pid).del();
  turn();
  replay.clear();
}
public static boolean implementPlayer(Field field, Player player) {
  List<Field.City>cities=field.cities();
  int c=0;
  Field.City r=null;
  for (Field.City city : cities) {
    if (city.pid==-1) {
      c+=1;
      if (Math.random()<=1d/c)r=city;
    }
  }
  if (r==null)return false;
  return r.add(field.new Unit(r.loc, player.id, unitInfantry));
}


public List<Controllable>colleMe(final int pid){
  return colle(new V<Controllable>(){
    public boolean v(Controllable c){
      return pid==c.pid();
    }
  });
}
public List<Controllable>colleNotMe(final int pid){
  return colle(new V<Controllable>(){
    public boolean v(Controllable c){
      return pid!=c.pid();
    }
  });
}
public List<Controllable>colle(V<Controllable>validator){
  List<Controllable> r=new ArrayList();
  for(Field.Tile tile : field.tiles()){
    for(Controllable c : tile.controllables()){
      if(validator.v(c))r.add(c);
    }
  }
  return r;
}
public synchronized void turn() {
  moving+=1;
  if (moving>=cPlayer)moving=0;
  field.turn();
  tabUnits();
  if(moving==0&&cPlayer>0)idMove+=1;
  //println("turn",moving);
}
public C locToPixel(C loc){
  return loc.sca(visTileSize*zoom).add(camLoc);
}
public boolean onScreen(C loc,C ar){
  return intersect(loc.mul(ar).add(camLoc),ar,C.ZERO,new C(width,height));
}
public void center(C loc,C ar){
  camLoc = new C(width,height).sca(.5f).sub(loc.mul(ar));
}
public boolean tabUnits() {
  return tab(new V<Controllable>(){
    public boolean v(Controllable a){
      return a instanceof Field.Unit && a.pid()==moving && a.idle();
    }
  });
}
public boolean tabCities() {
  return tab(new V<Controllable>(){
    public boolean v(Controllable a){
      return a instanceof Field.City && a.pid()==moving && a.idle();
    }
  });
}
public boolean tab(V<Controllable>validator) {
  int id=0;
  IDed sel=null;
  if (selected!=null) {
    sel=(IDed)selected.get(0);
    if (sel!=null)id=sel.id();
  }
  Controllable low = null, candi = null;
  for (Field.Tile[]tiles : field.tiles) {
    for (Field.Tile tile : tiles) {
      for (Controllable s : tile.controllables()) {
        if (s!=sel&&validator.v(s)) {
          int sid=s.id();
          if(candi==null&&sid<id&&(low==null||sid<low.id())){
            low=s;
          }else if(sid>id&&(candi==null||sid<candi.id())){
            candi=s;
          }
        }
      }
    }
  }
  candi = candi==null?low:candi;
  select(candi);
  return candi!=null;
}
public synchronized Object selected(){
  return selected==null||selected.isEmpty()?null:selected.get(0);
}
public synchronized void select(Located c) {
  if (c==null)return;
  select(c.loc());
  while (selected!=null&&selected.get(0)!=c) {
    selectCycle();
  }
}
public void select(C c) {
  Field.Tile tile=field.tile(c);
  selC=c;
  selected=tile.selectibles();
  cache(selected.get(0));
  if(controlTypeReqCameraAction[player(moving).controlType]&&!onScreen(c,new C(visTileSize*zoom))){
    center(c,new C(visTileSize*zoom));
  }
}
public void selectCycle() {
  selected.remove(0);
  if (selected.isEmpty())unselect();
  else cache(selected.get(0));
}
public void cache() {
  if (selected!=null&&!selected.isEmpty())cache(selected.get(0));
}
public void cache(Object o) {
  if (o instanceof Field.Unit) {
    Field.Unit unit=(Field.Unit)o;
    if (unit.pid==moving)cacheMoves(unit);
    else selCachedMoves=new ArrayList();
  }
}
public void cacheMoves(Field.Unit u) {
  selCachedMoves=new ArrayList();
  selCachedMoves.addAll(((Field.Unit)u).moves());
}
public void unselect() {
  selC=null;
  selected=null;
}
volatile boolean lock;

volatile long delayAIMove = 500;

final Set<Integer> keyCodeDownies=new HashSet();

volatile boolean instantUnits = false;
static final int debugInstantUnits = 0, cDebugButtons = 1;
static final C[][]debugButtons = new C[cDebugButtons][];
static{
  debugButtons[debugInstantUnits] = new C[]{new C(0,0.1f),new C(0.05f,0.05f),};
}
static final String[] debugButtonText = new String[cDebugButtons];
static{
  debugButtonText[debugInstantUnits] = "IU";
}
public int debugButtonColor(int i){
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
  unitMaxDmg[unitInfantry][movementTypeGround] = 1.5f;
  unitMaxDmg[unitInfantry][movementTypeAir] = 1;
  unitMaxDmg[unitInfantry][movementTypeWater] = 1;
  unitMaxDmg[unitTank][movementTypeGround] = 2;
  unitMaxDmg[unitTank][movementTypeAir] = 1;
  unitMaxDmg[unitTank][movementTypeWater] = 1.5f;
  unitMaxDmg[unitFighter][movementTypeGround] = 1;
  unitMaxDmg[unitFighter][movementTypeAir] = 3;
  unitMaxDmg[unitFighter][movementTypeWater] = 1;
  unitMaxDmg[unitBomber][movementTypeGround] = 4;
  unitMaxDmg[unitBomber][movementTypeAir] = 1;
  unitMaxDmg[unitBomber][movementTypeWater] = 3;
  unitMaxDmg[unitTransport][movementTypeGround] = .5f;
  unitMaxDmg[unitTransport][movementTypeAir] = 1;
  unitMaxDmg[unitTransport][movementTypeWater] = .5f;
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
public void sleep(long millis){
  try{Thread.sleep(millis);}
  catch(Throwable t){t.printStackTrace();}
}
public float noise(C xy,float z,float of){return noise(xy.x*of,xy.y*of,z);}
public boolean intersect(C alt,C aar,C blt,C bar){
  return alt.x+aar.x>blt.x && alt.y+aar.y>blt.y && blt.x+bar.x>alt.x && blt.y+bar.y>alt.y;
}
<A> A choose(List<A>a){return a.get((int)random(a.size()));}
<A> A choose(A...tings){
  return tings[(int)random(tings.length)];
}
public List<Integer>transform(List<Integer>a){
  Integer[]r=new Integer[a.size()];
  for(int i=0;i<a.size();i+=1) r[a.get(i)]=i;
  return Arrays.asList(r);
}
<A> A g(Set<A>s){
  return s.iterator().next();
}
<A> A g(List<A>l,int i){
  int size=l.size();
  if(size==0)return null;
  if(i>=size)return l.get(0);
  return l.get(i);
}
<A>A g(A[][]a, C l) {
  return a[(int)l.x][(int)l.y];
}
public int count(Collection colle, V v){
  int r = 0;
  for(Object o : colle){
    if(v.v(o))r+=1;
  }
  return r;
}

public void text(List<String>texts, int sline, C lt, C ar, float seg, float ts) {
  for (int i=0,s=texts.size(); i<s; i+=1) {
    text(texts.get(i), sline+i, lt.x, lt.y, ar.x, ar.y, seg, ts);
  }
}
public void text(String text, int line, C lt, C ar, float seg, float ts) {
  text(text, line, lt.x, lt.y, ar.x, ar.y, seg, ts);
}
public void text(String text, int line, float ltx, float lty, float arx, float ary, float segregation, float ts) {
  textSize(ts);
  float tw = textWidth(text), x = ltx+arx/2-tw/2, y = lty+(line+1)*(segregation+ts);
  text(text, x, y);
}
public void fill(int text, int line, C lt, C ar, float seg, float ts) {
  fill(text, line, lt.x, lt.y, ar.x, ar.y, seg, ts);
}
public void fill(int rgb, int line, float ltx, float lty, float arx, float ary, float seg, float ts) {
  fill(rgb);
  rect(ltx, lty+(line+1)*seg+line*ts, arx, ts);
}

public void filla(int rgba){fill((rgba>>24)&0xff,(rgba>>16)&0xff,(rgba>>8)&0xff,(rgba>>0)&0xff);}
public void fill(int rgb){fill((rgb>>16)&0xff,(rgb>>8)&0xff,(rgb>>0)&0xff);}
public void stroke(int rgb){stroke((rgb>>16)&0xff,(rgb>>8)&0xff,(rgb>>0)&0xff);}

class Box{
  C lt, ar;
  int lines;
  float seg, ts;
  int colorText, colorBack;
  Box(C lt, C ar, int lines, float seg){
    this.lt=lt;this.ar=ar;
    this.lines=lines;
    this.seg=seg;
    ts=(ar.y-seg*(lines+1))/lines;
  }
  public void text(List<String>texts, int sline){
    for (int i=0,s=texts.size(); i<s; i+=1) text(texts.get(i), sline+i);
  }
  public void text(String text, int line){
    textSize(ts);
    float tw = textWidth(text), x = lt.x+ar.x/2-tw/2, y = lt.y+(line+1)*(seg+ts);
    if(colorBack!=-1){
      fill(colorBack);
      rect(x,y-ts,tw,ts);
    }
    fill(colorText);
    Tanctikon.this.text(text, x, y);
  }
}

class HelpScreen {
  int page;
  Box box;
  HelpScreen(){
    box=new Box(C.ZERO,new C(width,height),17,height/35f);
    box.colorBack=-1;
    box.colorText=0;
  }
  public void browse(int v){
    int wouldpage=page+v;
    if(wouldpage>=cUnit)wouldpage=0;
    else if(wouldpage<0)wouldpage=cUnit-1;
    page=wouldpage;
  }
  public void draw(){
    int type=page;
    List<String>text=new ArrayList();
    text.add(unitName[type]);
    text.add("");
    text.add("Abbreviation: "+unitAbbrevName[type]);
    text.add("Health: "+unitMaxHp[type]);
    text.add("Damage:");
    for(int i=0;i<cMovementType;i+=1){
      text.add("vs. "+movementTypeName[i]+": "+unitMaxDmg[type][i]);
    }
    text.add("Speed: "+unitMaxSpd[type]);
    if(canCaptureCity[unitMaxMovementType[type]])text.add("can capture cities");
    if(canEmbark[type])text.add("can embark on transports");
    if(canCarry[type])text.add("can carry units");
    text.add("Movement Type: "+unitMaxMovementType[type]);
    text.add("Movement: ");
    text.addAll(Arrays.asList(movementDescription[unitMaxMovement[type]].split("\n")));
    filla((infoTabRgb<<8)+120);
    noStroke();
    rect(0,0,width,height);
    box.text(text,0);
  }
}

static class C {
  static final C ZERO=new C(0,0);
  static final C LEFT=new C(-1,0);
  static final C UP=new C(0,-1);
  static final C RIGHT=new C(1,0);
  static final C DOWN=new C(0,1);
  float x, y;
  public C() {}
  public C(float s){
    this(s,s);
  }
  public C(float x, float y) {
    this.x=x;
    this.y=y;
  }
  public C add(C b) {
    return new C(x+b.x, y+b.y);
  }
  public C sub(C b) {
    return new C(x-b.x, y-b.y);
  }
  public C mul(C b){return new C(x*b.x, y*b.y);}
  public C div(C b){return new C(x/b.x, y/b.y);}
  public C sca(float f) {
    return new C(x*f, y*f);
  }
  public C floor(){return new C((int)x,(int)y);}
  public float len() {
    return sqrt(pow(x, 2)+pow(y, 2));
  }
  public Set<C> next(){
    Set<C>r=new HashSet();
    r.add(add(RIGHT));
    r.add(add(LEFT));
    r.add(add(UP));
    r.add(add(DOWN));
    return r;
  }
  public Iterable<C>iter(){return iter(C.ZERO,this);}
  public boolean bounds(C low,C up){return x>=low.x&&x<up.x&&y>=low.y&&y<up.y;}
  public boolean bounds(C up){return bounds(ZERO,up);}
  public boolean _(C o){return equals(o);}
  public boolean equals(C o){
    if(!(o instanceof C))return false;
    return x==o.x&&y==o.y;
  }
  public int hashCode(){
    return Float.floatToIntBits(x*y+x+y);
  }
  public String toString(){return "{x: "+x+", y: "+y+"}";}
  public String simple(){return (int)x+" "+(int)y;}
  
  static public Iterable<C>iter(final C from,final C to){
    return new Iterable<C>(){
      public Iterator<C>iterator(){
        return new Iterator<C>(){
          float x = from.x, y = from.y;
          public boolean hasNext(){
            return y<to.y;
          }
          public C next(){
            C r = new C(x,y);
            if(x+1<to.x)x+=1;
            else {
              x=from.x;
              y+=1;
            }
            return r;
          }
        };
      }
    };
  }
}

static class S {
  float l, c, h;
  S(float c) {
    this(c, c);
  }
  S(float c, float h) {
    this(c, h, 0);
  }
  S(float c, float h, float l) {
    this.c=c;
    this.h=h;
    this.l=l;
  }
  public void sc(float v) {
    this.c=v<=h?v>=l?v:l:h;
  }
  public void ac(float v){this.sc(c+v);}
}

static interface V<A>{
  public boolean v(A a);
}
static <A> V<A> truev(Class<A>c){
  return new V<A>(){
    public boolean v(A a){return true;}
  };
}
static <A>V<A> merge(final V<A>a, final V<A>b){
  return new V<A>(){
    public boolean v(A p){
      return a.v(p)&&b.v(p);
    }
  };
}
class Player {
  int controlType, id, rgb;
  int typeAI;
  boolean thonking;
  int doneFor;
  Player(int id, int controlType) {
    this.id=id;
    this.controlType=controlType;
    int rgb;
    do {
      rgb=(int)random(0x1000000);
    } while (pColors.contains(rgb));
    this.rgb=rgb;
    pColors.add(rgb);
    if(controlType==controlTypeAI)typeAI=(int)random(cTypeAI);
  }
  public void del() {
    pColors.remove(rgb);
  }
  public void move(Field.Unit unit, Field.Unit.Move move){
    if(move==null)return;
    sleep(delayAIMove);
    unit.move(move);
  }
  public synchronized void thonk(){
    if(doneFor==idMove||thonking)return;
    thonking=true;
    Thread thonker = new Thread(new Runnable(){
      public void run(){
        if(moving==id){
          final int actCity = 0, actKill = 1, cAct = 2;
          final int[][] prefAct = new int[cUnit][];
          prefAct[unitInfantry]=new int[]{
            actKill,actCity,
          };
          prefAct[unitTank]=new int[]{
            actKill,actCity,
          };
          prefAct[unitFighter]=new int[]{
            actKill,
          };
          prefAct[unitBomber]=new int[]{
            actKill,
          };
          prefAct[unitTransport]=new int[]{
            
          };
          prefAct[unitDreadnought]=new int[]{
            actKill,
          };
          final List<Controllable>all=colle(new V(){public boolean v(Object o){return true;}});
          final int iMine = 0, iEnem = 1, iNeut = 2, cIAlli = 3;
          final int iUnit = 0, iCity = 1, cIType = 2;
          final List<Controllable>[][]info = new List[cIAlli][cIType];
          for(int i=0;i<cIAlli;i+=1)for(int j=0;j<cIType;j+=1)info[i][j]=new ArrayList();
          final int[][] unitComp=new int[cIAlli][cUnit];
          for(Controllable c : all){
            int pid=c.pid();
            int iAlli = -1, iType = -1;
            if(pid==-1) iAlli=iNeut;
            else if(pid==id) iAlli=iMine;
            else iAlli=iEnem;
            if(c instanceof Field.City)iType=iCity;
            else if(c instanceof Field.Unit){
              iType=iUnit;
              unitComp[iAlli][((Field.Unit)c).type]+=1;
            }
            info[iAlli][iType].add(c);
          }
          Object last=null;
          for(Controllable sel : info[iMine][iUnit]){
            Field.Unit uni=(Field.Unit)sel;
            if(!uni.idle())continue;
            int[] order=prefAct[uni.type];
            boolean[] adjust=new boolean[cAct];
            for(int act : order){
              switch(act){
                case actCity:{
                  List<Field.Unit.Move> cityCaptures = new ArrayList();
                  for(Field.Unit.Move move : selCachedMoves){
                    if(move.type==moveTypeCaptureCity){
                      cityCaptures.add(move);
                    }
                  }
                  if(cityCaptures.size()>0){
                    Field.Unit.Move move = choose(cityCaptures);
                    println("cccccccccccc",move);
                    move(uni,move);
                  }else{
                    adjust[actCity]=true;
                  }
                break;}
                case actKill:{
                  Map<C,Field.Unit.Move> attackableLocs = new HashMap();
                  for(Field.Unit.Move attack : uni.attack(uni.loc)){
                      attackableLocs.put(attack.target,null);
                    }
                  for(Field.Unit.Move move : selCachedMoves){
                    for(Field.Unit.Move attack : uni.attack(move.target)){
                      Field.Unit.Move lastMove = attackableLocs.get(attack.target);
                      if(lastMove==null||move.drain<lastMove.drain)attackableLocs.put(attack.target,move);
                    }
                  }
                  if(attackableLocs.size()>0){
                    List<Integer> dmgMovementTypeOrder=new ArrayList();
                    dmgMovementTypeOrder.add(0);
                    for(int i=1;i<uni.dmg.length;i+=1){
                      float c=uni.dmg[i].c;
                      a:{
                        for(int j=0;j<dmgMovementTypeOrder.size();j+=1){
                          if(c>uni.dmg[dmgMovementTypeOrder.get(j)].c){
                            dmgMovementTypeOrder.add(j,i);
                            break a;
                          }
                        }
                        dmgMovementTypeOrder.add(i);
                      }
                    }
                    dmgMovementTypeOrder=transform(dmgMovementTypeOrder);
                    int bestOptionLevel=uni.dmg.length;
                    List<C>bestOptions=new ArrayList();
                    for(Map.Entry<C,Field.Unit.Move>e : attackableLocs.entrySet()){
                      println(e);
                      Field.Tile tile=field.tile(e.getKey());
                      Field.Unit target=tile.defender(uni);
                      int optionLevel=dmgMovementTypeOrder.get(target.movementType);
                      if(optionLevel<=bestOptionLevel){
                        if(optionLevel<bestOptionLevel){
                          bestOptionLevel=optionLevel;
                          bestOptions.clear();
                        }
                        bestOptions.add(e.getKey());
                      }
                    }
                    float closestDist=Float.POSITIVE_INFINITY;
                    C closestBestOption=null;
                    for(C option : bestOptions){
                      float dist=uni.loc.sub(option).len();
                      if(closestBestOption==null || dist<closestDist){
                        closestBestOption=option;
                        closestDist=dist;
                      }
                    }
                    println("aaaaaaaaaa",attackableLocs);
                    move(uni,attackableLocs.get(closestBestOption));
                    for(Field.Unit.Move attack : uni.attack(uni.loc)){
                      println("noway im stuck here");
                      if(attack.target._(closestBestOption)){
                        println("bbbbbbbbbb");
                        move(uni,attack);
                        break;
                      }
                    }
                  }else{
                    adjust[actKill]=true;
                  }
                break;}
              }
            }
            for(int act : order){
              if(adjust[act]){
                switch(act){
                  case actCity:{
                    List<Field.Unit.Move>movementMoves=uni.move();
                    float closestDist = Float.POSITIVE_INFINITY;
                    Field.City closestCapturableCity = null;
                    Field.Unit.Move closestMove = null;
                    for(int iAlli : new int[]{iEnem,iNeut,}){
                      for(Controllable c : info[iAlli][iCity]){
                        Field.City city = (Field.City)c;
                        float dist = uni.loc.sub(city.loc).len();
                        if(field.tile(city.loc).moveType(uni)==moveTypeCaptureCity&&(closestCapturableCity==null||dist<closestDist)){
                          closestCapturableCity = city;
                          closestDist = dist;
                          float closestMoveDist = Float.POSITIVE_INFINITY;
                          for(Field.Unit.Move move : movementMoves){
                            float moveDist = move.target.sub(city.loc).len();
                            if(moveDist<closestMoveDist){
                              closestMove = move;
                              closestMoveDist = moveDist;
                            }
                          }
                        }
                      }
                      if(closestMove!=null)move(uni,closestMove);
                    };
                    
                  break;}
                  case actKill:{
                    List<Field.Unit.Move>movementMoves=uni.move();
                    float closestDist=Float.POSITIVE_INFINITY;
                    Field.Unit closestEnem = null;
                    Field.Unit.Move closestMove = null;
                    for(Controllable c : info[iEnem][iUnit]){
                      Field.Unit enemUnit = (Field.Unit)c;
                      float dist = uni.loc.sub(enemUnit.loc).len();
                      if(closestEnem==null || dist<closestDist){
                        closestEnem = enemUnit;
                        closestDist = dist;
                        float closestMoveDist = Float.POSITIVE_INFINITY;
                        for(Field.Unit.Move move : movementMoves){
                          float moveDist = move.target.sub(enemUnit.loc).len();
                          if(moveDist<closestMoveDist){
                            closestMove = move;
                            closestMoveDist = moveDist;
                          }
                        }
                      }
                    }
                  if(closestMove!=null)move(uni,closestMove);
                  break;}
                }
              }
            }
          }
          
          for(Controllable c : info[iMine][iCity]){
            Field.City cit=(Field.City)c;
            if(!cit.idle())continue;
            cit.produce(choose(unitInfantry,unitTank,unitFighter,unitBomber));
          }
        }
        sleep(delayAIMove);
        doneFor=idMove;
        turn();
        thonking=false;
      }
    });
    thonker.start();
  }
}
Replay replay;
interface Move{
  public void move();
  public void reve();
}
class Replay{
  Field start;
  List<Move> moves = new ArrayList();
  int at = -1;
  Replay(Field field){
    start=field;
  }
  public void register(Move move){
    if(at==moves.size()-1)moves.add(move);
    else moves.set(at+1,move);
    at+=1;
  }
  public boolean browse(int i){
    int wouldat = at+i;
    if(wouldat<-1||wouldat>=moves.size())return false;
    for(;at!=wouldat;){
      if(i>0)moves.get(++at).move();
      else moves.get(at--).reve();
    }
    return true;
  }
  public void clear(){
    at = -1;
    moves.clear();
  }
}
  public void settings() {  size(1400, 787); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "Tanctikon" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

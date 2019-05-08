import java.util.*;

float zoom = 1F, spdZoom=0.1F;
C camLoc=new C();
int screen;
int game=0, game_over=1, pause_menu=2, help=3, shortcut_help=4;

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
void setup() {
  frameRate(60);
  size(1400, 787);

  screen=game;
  
  helpScreen=new HelpScreen();

  field=new Field(new C(24, 24), 0.03,0.5);

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

void draw() {
  synchronized (this){
    //while(lock);
    //lock=true;
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
      C lt=new C(0.75*width, 0);
      C ar=new C(0.25*width, height);
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
        if(!unit.wiped){
          fill(0);
          text(unitName[unit.type], 0, lt, ar, segregation, ts);
          fill(unit.rgb(), 1, lt, ar, segregation, ts);
          fill(0);
          text("Owner", 1, lt, ar, segregation, ts);
          text(unit.stats(), 2, lt, ar, segregation, ts);
        }else{
          unselect();
        }
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
      fill(0x0);
      textSize(s/2);
      text(idMove,0,s/2);
      if(player(moving).controlType==controlTypeAI){
        fill(0x0);
        textSize(s/2);
        text("AI",0,s);
        if(player(moving).thonking){
          text("delay(ms):"+delayAIMove,s,s/2);
          text("thonking...",s,s);
        }
      }
    }
    if(screen==pause_menu){
      Box box = new Box(C.ZERO, new C(width,height), 3, height/6f);
      box.colorText=0;
      box.colorBack=infoTabRgb;
      box.text("Q: Information",0);
      box.text("W: Shortcuts", 1);
      box.text("P: Continue",2);
    }else if(screen==help){
      helpScreen.draw();
    }else if(screen==shortcut_help){
      C screen=new C(width,height);
      filla((infoTabRgb<<8)+120);
      rect(0,0,width,height);
      Box box = new Box(screen.sca(.2), screen.sca(.6), 11, height/40f);
      box.colorText=0;
      box.colorBack=-1;
      box.text("Shift+P: Pause Menu",0);
      box.text("Tab: Select next idle unit",1);
      box.text("Shift+Tab: Select next idle city",2);
      box.text("Spacebar: End move",3);
      box.text("Shift+A: Add player",4);
      box.text("Shift+S: Add AI player",5);
      box.text("Shift+R: Remove last added player",6);
      box.text("Shift+Z: Pause AI",7);
      box.text("Shift+=: Speed Up AI",8);
      box.text("Shift+-: Slow Down AI",9);
      box.text("Q: Quit a menu",10);
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
    }else{
      textSize(height/40f);
      text("Shift+P",0,height);
    }
    //lock=false;
  }
}

void mouseClicked() {
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
void keyPressed() {
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
        case shiftActionSpeedUpAI:
          delayAIMove/=2;
          break;
        case shiftActionSlowDownAI:
          delayAIMove*=2;
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
      case 87:
        screen = shortcut_help;
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
  }else if (screen==shortcut_help){
    switch(keyCode){
      case 81:
        screen=pause_menu;
    }
  }
}
void keyReleased() {
  keyCodeDownies.remove(keyCode);
}
C mouLast=null;
void mouseDragged(MouseEvent e) {
  if (mouLast==null) {
    mouLast=new C(mouseX, mouseY);
  } else {
    C now=new C(mouseX, mouseY), move=mouLast.sub(now);
    camLoc=camLoc.sub(move);
    mouLast=now;
  }
}
void mouseMoved() {
  mouLast=null;
}
void mouseWheel(MouseEvent e) {
  if (e.getCount()==1)zoom*=1-spdZoom;
  else zoom*=1+spdZoom;
}

interface Located {
  C loc();
}
interface Controllable extends Located, IDed {
  boolean idle();
  int pid();
}
interface IDed {
  int id();
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
  boolean bounds(C loc) {
    return loc.bounds(size);
  }
  Tile tile(C loc) {
    if (!bounds(loc))return null;
    return g(tiles, loc);
  }
  Iterable<Tile>tiles(){
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
  List<City>cities() {
    List<City>r=new ArrayList();
    for (Tile[]tiles : tiles) {
      for (Tile tile : tiles) {
        if (tile.city!=null)r.add(tile.city);
      }
    }
    return r;
  }
  void turn() {
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
    int owned() {
      if (city!=null)return city.pid;
      if (unit!=null)return unit.pid;
      return -1;
    }
    int moveType(Unit u) {
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
    Unit defender(Unit u) {
      if (city!=null) {
        return city.defender(u);
      }
      return unit;
    }
    void turn() {
      if (city!=null&&city.pid==moving)city.turn();
      if (unit!=null&&unit.pid==moving)unit.turn();
    }
    void cleanse(int pid){
      synchronized(Tanctikon.this){
      if(city!=null&&city.pid==pid){
        city.clear();
        city.pid=-1;
      }
      if(unit!=null&&unit.pid==pid){
        unit.wiped();
        unit=null;
      }
      }
    }
    void revive(Unit me){
      if(me.internater==null){
        unit=me;
      }
      else if(me.internater instanceof City){
        city.add(me);
      }else if(me.internater instanceof Unit){
        unit.add(me);
      }
    }
    void kill(Unit me){
      //while(lock);
      //lock=true;
      if(city!=null){
        me.internater=city;
        city.remove(me);
      }
      if(me==unit)unit=null;
      else if(unit!=null){
        me.internater=unit;
        unit.remove(me);
      }
      //lock=false;
    }
    void move(Unit me, C target) {
      //while(lock);
      //lock=true;
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
      //lock=false;
    }
    void reve(Unit me, C origin){
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
    List<Object>selectibles() {
      List<Object> r=new ArrayList();
      if (city!=null)r.addAll(city.selectibles());
      if (unit!=null)r.addAll(unit.selectibles());
      r.add(this);
      return r;
    }
    C loc() {
      return loc;
    }
    List<Controllable> controllables() {
      List r=new ArrayList();
      if (city!=null)r.addAll(city.selectibles());
      if (unit!=null)r.addAll(unit.selectibles());
      return r;
    }
    int id() {
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
    List<String>stats(){
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
    List<Move>moves() {
      List<Move>r=new ArrayList();
      moves(r, 0, (int)spd.c, loc, new HashSet());
      r.addAll(attack(loc));
      return r;
    }
    List<Move>move(){
      List<Move>r=new ArrayList();
      moves(r, 0, (int)spd.c, loc, new HashSet());
      return r;
    }
    void moves(List<Move>r, int movesUsed, int maxMoves, C loc, Set<Tile>visited) {
      if (movesUsed<maxMoves) {
        Map<C,Integer>nexts=new HashMap();
        for (C next : loc.next()) {
          Tile tile = tile(next);
          if (tile!=null&&!visited.contains(tile)) {
            visited.add(tile);
            int movesUsedAfter = movesUsed+tileMovementCost[tile.type], moveType;
            if (movesUsedAfter<=maxMoves&&((moveType=tile.moveType(this))!=moveTypeIllegal&&moveType!=moveTypeAttack)) {
              Move move = new Move(moveType, movesUsedAfter, this.loc, next);
              if(moveType==moveTypeCaptureCity)move.bCityPid=tile.city.pid;
              r.add(move);
              nexts.put(next,movesUsedAfter);
            }
          }
        }
        for(Map.Entry<C,Integer> next : nexts.entrySet()) moves(r, next.getValue(), maxMoves, next.getKey(), visited);
      }
    }
    List<Move>attack(C loc) {
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
    List<Object>selectibles(){
      List r=new ArrayList();
      r.add(this);
      if (moving==pid&&canCarry[type])r.addAll(transporting);
      return r;
    }
    void turn() {
      spd.c=spd.h;
      atks.c=atks.h;
    }
    boolean full(){return transporting.size()>=size;}
    void add(Unit u){if(transporting!=null)transporting.add(u);}
    void remove(Unit u){if(transporting!=null)transporting.remove(u);}
    void move(Move move){move(move,true);}
    void move(Move move,boolean register) {
      synchronized(Tanctikon.this){
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
    }
    void reve(Move move){
      switch(move.type) {
      case moveTypeCaptureCity:
        tile(loc).city.pid=move.bCityPid;
      case moveTypeMovement:
      case moveTypeEmbark:
      case moveTypeIncitiate:
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
    void takeDmg(float damage){
      hp.ac(-damage);
      if(wiped)tile(loc).revive(this);
      if(hp.c==0){
        tile(loc).kill(this);
      }
    }
    boolean passable(int tileType) {
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
    void wiped(){
      wiped=true;
    }
    int rgb() {
      return players.get(pid).rgb;
    }
    void sLoc(C v){
      loc=v;
      if(canCarry[type])for(Unit u : transporting) u.sLoc(v);
    }
    C loc() {
      return loc;
    }
    boolean idle() {
      return moves().size()>0;
    }
    int id() {
      return id;
    }
    int pid() {
      return pid;
    }
    class Move implements Tanctikon.Move{
      int type, drain, bCityPid;
      C origin,target;
      Unit targett;
      Move(int type, int drain, C origin, C target) {
        this.type=type;
        this.drain=drain;
        this.origin=origin;
        this.target=target;
      }
      Unit Unit() {
        return Unit.this;
      }
      int hashCode(){
        return ((target.hashCode()+type)*31+drain)*31;
      }
      String toString(){
        return "{"+moveTypeName[type]+" target: "+target.simple()+" drain: "+drain+"}";
      }
      void move(){
        Unit.this.move(this,false);
      }
      void reve(){
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
    List<String>stats(){
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
    C loc() {
      return loc;
    }
    boolean idle() {
      return constUnitType==-1;
    }
    int id() {
      return id;
    }
    int pid() {
      return pid;
    }
    boolean add(Unit u) {
      boolean r;
      if (r=!full()) {
        incitiated.add(u);
        pid=u.pid;
      }
      return r;
    }
    void remove(Unit u) {
      incitiated.remove(u);
    }
    void clear(){
      constUnitType=-1;
      for(Unit u : incitiated){
        u.wiped();
      }
      incitiated.clear();
    }
    void calc_pid() {
      if (incitiated.isEmpty())pid=-1;
      else pid=incitiated.get(0).pid;
    }
    int size() {
      return incitiated.size();
    }
    boolean full() {
      return incitiated.size()==size;
    }
    boolean empt() {
      return incitiated.isEmpty();
    }
    Unit defender(Unit atk) {
      if (incitiated.isEmpty())return null;
      return incitiated.get(0);
    }
    int rgb() {
      if (pid==-1)return 0x0c0c0c;
      return player(pid).rgb;
    }
    void turn() {
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
    List<Object>selectibles() {
      List r=new ArrayList();
      r.add(this);
      if (moving==pid)r.addAll(incitiated);
      return r;
    }
    boolean nextToWater(){
      for(C next : loc.next()){
        Tile tile;
        if((tile=tile(next))!=null&&tile.type==tileWater)return true;
      }
      return false;
    }
    boolean produce(int unitType){
      Move move = new Move(unitType,instantUnits?0:unitConstTime[unitType],constUnitType,constUnitTimeLeft);
      replay.register(move);
      return produce(unitType,instantUnits?0:unitConstTime[unitType]);
    }
    boolean produce(int unitType,int unitTimeLeft) {
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
      void move(){
        produce(constUnitType,constUnitTimeLeft);
      }
      void reve(){
        City.this.constUnitType=bConstUnitType;
        City.this.constUnitTimeLeft=bConstUnitTimeLeft;
      }
    }
  }
}

Field copy(Field org){
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

Player player(int pid) {
  try{
  return players.get(pid);
  }
  catch(Exception e){e.printStackTrace();throw new RuntimeException();}
}
Set<Integer>pColors=new HashSet();
void addPlayer(int controlType){
  int pid=cPlayer++;
  Player player=new Player(pid, controlType);
  if(pid>=players.size()) players.add(player);
  else players.set(pid,player);
  implementPlayer(field, player);
  replay.clear();
}
void remPlayer(){
  if(cPlayer==0)return;
  int pid=--cPlayer;
  for(Field.Tile tile:field.tiles()){
    tile.cleanse(pid);
  }
  player(pid).del();
  turn();
  replay.clear();
}
static boolean implementPlayer(Field field, Player player) {
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


List<Controllable>colleMe(final int pid){
  return colle(new V<Controllable>(){
    public boolean v(Controllable c){
      return pid==c.pid();
    }
  });
}
List<Controllable>colleNotMe(final int pid){
  return colle(new V<Controllable>(){
    public boolean v(Controllable c){
      return pid!=c.pid();
    }
  });
}
List<Controllable>colle(V<Controllable>validator){
  List<Controllable> r=new ArrayList();
  for(Field.Tile tile : field.tiles()){
    for(Controllable c : tile.controllables()){
      if(validator.v(c))r.add(c);
    }
  }
  return r;
}
synchronized void turn() {
  moving+=1;
  if (moving>=cPlayer)moving=0;
  field.turn();
  tabUnits();
  if(moving==0&&cPlayer>0)idMove+=1;
  //println("turn",moving);
}
C locToPixel(C loc){
  return loc.sca(visTileSize*zoom).add(camLoc);
}
boolean onScreen(C loc,C ar){
  return intersect(loc.mul(ar).add(camLoc),ar,C.ZERO,new C(width,height));
}
void center(C loc,C ar){
  camLoc = new C(width,height).sca(.5).sub(loc.mul(ar));
}
boolean tabUnits() {
  return tab(new V<Controllable>(){
    public boolean v(Controllable a){
      return a instanceof Field.Unit && a.pid()==moving && a.idle();
    }
  });
}
boolean tabCities() {
  return tab(new V<Controllable>(){
    public boolean v(Controllable a){
      return a instanceof Field.City && a.pid()==moving && a.idle();
    }
  });
}
boolean tab(V<Controllable>validator) {
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
synchronized Object selected(){
  return selected==null||selected.isEmpty()?null:selected.get(0);
}
synchronized void select(Located c) {
  if (c==null)return;
  select(c.loc());
  while (selected!=null&&selected.get(0)!=c) {
    selectCycle();
  }
}
void select(C c) {
  Field.Tile tile=field.tile(c);
  selC=c;
  selected=tile.selectibles();
  cache(selected.get(0));
  if(controlTypeReqCameraAction[player(moving).controlType]&&!onScreen(c,new C(visTileSize*zoom))){
    center(c,new C(visTileSize*zoom));
  }
}
void selectCycle() {
  selected.remove(0);
  if (selected.isEmpty())unselect();
  else cache(selected.get(0));
}
void cache() {
  if (selected!=null&&!selected.isEmpty())cache(selected.get(0));
}
void cache(Object o) {
  if (o instanceof Field.Unit) {
    Field.Unit unit=(Field.Unit)o;
    if (unit.pid==moving)cacheMoves(unit);
    else selCachedMoves=new ArrayList();
  }
}
void cacheMoves(Field.Unit u) {
  selCachedMoves=new ArrayList();
  selCachedMoves.addAll(((Field.Unit)u).moves());
}
void unselect() {
  selC=null;
  selected=null;
}

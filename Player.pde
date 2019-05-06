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
  void del() {
    pColors.remove(rgb);
  }
  void move(Field.Unit unit, Field.Unit.Move move){
    if(move==null)return;
    sleep(delayAIMove);
    unit.move(move);
  }
  synchronized void thonk(){
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

Replay replay;
interface Move{
  void move();
  void reve();
}
class Replay{
  Field start;
  List<Move> moves = new ArrayList();
  int at = -1;
  Replay(Field field){
    start=field;
  }
  synchronized void register(Move move){
    if(at==moves.size()-1)moves.add(move);
    else moves.set(at+1,move);
    at+=1;
  }
  boolean browse(int i){
    int wouldat = at+i;
    if(wouldat<-1||wouldat>=moves.size())return false;
    for(;at!=wouldat;){
      if(i>0)moves.get(++at).move();
      else moves.get(at--).reve();
    }
    return true;
  }
  synchronized void clear(){
    at = -1;
    moves.clear();
  }
}

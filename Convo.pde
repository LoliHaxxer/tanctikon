void sleep(long millis){
  try{Thread.sleep(millis);}
  catch(Throwable t){t.printStackTrace();}
}
float noise(C xy,float z,float of){return noise(xy.x*of,xy.y*of,z);}
boolean intersect(C alt,C aar,C blt,C bar){
  return alt.x+aar.x>blt.x && alt.y+aar.y>blt.y && blt.x+bar.x>alt.x && blt.y+bar.y>alt.y;
}
<A> A choose(List<A>a){return a.get((int)random(a.size()));}
<A> A choose(A...tings){
  return tings[(int)random(tings.length)];
}
List<Integer>transform(List<Integer>a){
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
int count(Collection colle, V v){
  int r = 0;
  for(Object o : colle){
    if(v.v(o))r+=1;
  }
  return r;
}

void text(List<String>texts, int sline, C lt, C ar, float seg, float ts) {
  for (int i=0,s=texts.size(); i<s; i+=1) {
    text(texts.get(i), sline+i, lt.x, lt.y, ar.x, ar.y, seg, ts);
  }
}
void text(String text, int line, C lt, C ar, float seg, float ts) {
  text(text, line, lt.x, lt.y, ar.x, ar.y, seg, ts);
}
void text(String text, int line, float ltx, float lty, float arx, float ary, float segregation, float ts) {
  textSize(ts);
  float tw = textWidth(text), x = ltx+arx/2-tw/2, y = lty+(line+1)*(segregation+ts);
  text(text, x, y);
}
void fill(int text, int line, C lt, C ar, float seg, float ts) {
  fill(text, line, lt.x, lt.y, ar.x, ar.y, seg, ts);
}
void fill(int rgb, int line, float ltx, float lty, float arx, float ary, float seg, float ts) {
  fill(rgb);
  rect(ltx, lty+(line+1)*seg+line*ts, arx, ts);
}

void filla(int rgba){fill((rgba>>24)&0xff,(rgba>>16)&0xff,(rgba>>8)&0xff,(rgba>>0)&0xff);}
void fill(int rgb){fill((rgb>>16)&0xff,(rgb>>8)&0xff,(rgb>>0)&0xff);}
void stroke(int rgb){stroke((rgb>>16)&0xff,(rgb>>8)&0xff,(rgb>>0)&0xff);}

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
  void text(List<String>texts, int sline){
    for (int i=0,s=texts.size(); i<s; i+=1) text(texts.get(i), sline+i);
  }
  void text(String text, int line){
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
  void browse(int v){
    int wouldpage=page+v;
    if(wouldpage>=cUnit)wouldpage=0;
    else if(wouldpage<0)wouldpage=cUnit-1;
    page=wouldpage;
  }
  void draw(){
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
  int hashCode(){
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
  void sc(float v) {
    this.c=v<=h?v>=l?v:l:h;
  }
  void ac(float v){this.sc(c+v);}
}

static interface V<A>{
  boolean v(A a);
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

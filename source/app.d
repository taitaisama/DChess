import std.stdio;
import std.conv;
import chess.d;
import piece_maps.d;
import std.datetime.systime : SysTime, Clock;
import core.time : msecs, usecs, hnsecs, nsecs, Duration;
import core.thread.osthread: Thread;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Box;
import gtk.HButtonBox;
import gtk.Image;
import gtk.Button;
import gdk.Event;
import gdk.Screen;
import gdk.Display;
import gtk.Label;
import gtk.Entry;
import gtk.Fixed;
import pango.PgAttributeList;
import pango.PgAttribute;
import gtk.CssProvider;
import gtk.StyleContext;

int prevPressed = -1;
MoveSet [16] validMoves;

int showPosNum = 0;
int startMoveNum = 0;
int [] lastKill;
Chess_state [] allPositions;

int bitCount (ulong x){
  int num = 0;
  for (int i = 0; i < 64; i ++){
    if ((x & (1uL << i)) != 0){
      num ++;
    }
  }
  return num;
}

int pieceCount (Chess_state st){
  return bitCount(st.occupied[0]|st.occupied[1]);
}

__gshared int timeCutoff;//in msecs

class Timer : Thread {
  this (){
    super (&run);
  }
  
private:
  void run(){
    SysTime startTime = Clock.currTime();
    Duration cut = msecs(timeCutoff);
    while (Clock.currTime() - startTime < cut) { }
    synchronized{
      timeExceeded = true;
    }
  }
}

class MiniBoard : Label
{
  PgAttributeList pglist;
  this (string s){
    super(s);
    pglist = new PgAttributeList();
    pglist.change(PgAttribute.backgroundNew(50000, 50000, 50000));
    pglist.change(PgAttribute.foregroundNew(0, 0, 0));
    pglist.change(PgAttribute.scaleNew(1.7));
    pglist.change(PgAttribute.familyNew("Comic Sans"));
    this.setAttributes(pglist);
  }
}
class LoadFenWindow : MainWindow
{
  Entry enter;
  this (){
    super("Enter Fen String");
    setDefaultSize(200, 50);
    Box b = new Box(Orientation.VERTICAL, 5);
    enter = new Entry();
    enter.addOnActivate(delegate void (Entry e) {FenGameInput();});
    b.add(enter);
    add(b);
    showAll();
  }
}

LoadFenWindow fenWindow;
void LoadFen (){
  fenWindow = new LoadFenWindow();
  
}
void FenGameInput() {
  string fen = fenWindow.enter.getText();
  fenWindow.close();
  makeNewFenGame(fen);
}
PgAttributeList blue;
PgAttributeList white;

Timer cutoffTimer;
int playType = 0; //0 means computer is black, 1 means player is black, 2 means two player, 3 means computer vs computer

Move getMove (){
  synchronized{
    timeExceeded = false;
  }
  cutoffTimer = new Timer();
  cutoffTimer.start();
  return state.genBestMove();
}

void doMove (){
  Move best = getMove();
  board.depth.setMarkup("<big>Depth of search: " ~to!string(state.currDepth-1) ~ "</big> ");
  board.eval.setMarkup("<big>Evaluation: "~ to!string(best.score) ~" </big>");
  state.makeMove(best);
  allPositions ~= state;
  if ((pieceCount(allPositions[$-1]) != pieceCount(allPositions[$-2])) || (best.playType == 0)){
    lastKill ~= 0;
  }
  else {
    lastKill ~= lastKill[$-1]+1;
  }
  showPosNum = cast(int)allPositions.length-2;
  changePos(true);
  if (state.hash in numTimes){
    numTimes[state.hash] ++;
  }
  else {
    numTimes[state.hash] = 1;
  }
  if (numTimes[state.hash] >= 3 || lastKill[$-1] == 50){
    makePopUp("Tie by repetition");
    board.setEnabled(0);
    return;
  }
  validMoves = state.genValidMoves();
}

ulong getValidMovingPieces (){
  ulong valid = 0;
  int i = -1;
  do {
    i++;
    if (validMoves[i].set != 0){
      valid |= (1uL << validMoves[i].piecePos);
    }
  } while (validMoves[i].pieceType != 5);
  return valid;
}

string genStrings (){
  string str = "";
  for (int i = 0; i < 64; i ++){
    str ~= "buttons[" ~ to!string(i)~ "].addOnPressed(delegate void (Button b) {buttonPressed (" ~ to!string(i)~ ");});";
    str ~= "buttons[" ~ to!string(i)~ "].addOnReleased(delegate void (Button b) {buttonReleased (" ~ to!string(i)~ ");});";
  }
  return str;
}


void changeDifficulty (int dif){
  timeCutoff = dif;
  board.cutoff.setMarkup("<big>Time limit: " ~to!string(dif)~ " msecs </big>");
  board.customEntry.setText(to!string(dif));
}
void customEntryChange (){
  import std.string: isNumeric;
  string dif = board.customEntry.getText();
  if (isNumeric(dif)){
    changeDifficulty(to!int(dif));
  }
}

void changePlayer (int type){
  if (type == 0){
    (cast(Label)(board.whiteGame.getChild)).setAttributes(blue);
    (cast(Label)(board.blackGame.getChild)).setAttributes(white);
    (cast(Label)(board.twoGame.getChild)).setAttributes(white);
  }
  else if (type == 1){
    (cast(Label)(board.whiteGame.getChild)).setAttributes(white);
    (cast(Label)(board.blackGame.getChild)).setAttributes(blue);
    (cast(Label)(board.twoGame.getChild)).setAttributes(white);
  }
  else if (type == 2){
    (cast(Label)(board.whiteGame.getChild)).setAttributes(white);
    (cast(Label)(board.blackGame.getChild)).setAttributes(white);
    (cast(Label)(board.twoGame.getChild)).setAttributes(blue);
  }
  prevPressed = -1;
  playType = type;
  board.setEnabled(0);
  if (type == 0 && state.isBlackTurn){
    doMove();
  }
  else if (type == 1 && !state.isBlackTurn){
    doMove();
  }
  validMoves = state.genValidMoves();
  board.setImages(state.pieces);
  board.setEnabled(getValidMovingPieces());
  board.showAll();
}
void makeNewFenGame (string fen){
  try{
    auto x = fenToState(fen);
    state = x.state;
    startMoveNum = x.moveNum;
    lastKill.length = 0;
    lastKill ~= x.lastKill;
    state.assert_state(0);
  }
  catch (Exception e){
    makePopUp("Invalid Fen string, making normal game");
    state = Chess_state(false);
    startMoveNum = 0;
    lastKill.length = 0;
    lastKill ~= 0;
  }
  allPositions.length = 0;
  allPositions ~= state;
  showPosNum = 0;
  numTimes.clear();
  prevPressed = -1;
  transpositionTable.clear();
  if (playType == 1 && state.isBlackTurn == false){
    doMove();
  }
  else if (playType == 0 && state.isBlackTurn){
    doMove();
  }
  validMoves = state.genValidMoves();
  board.setImages(state.pieces);
  board.setEnabled(getValidMovingPieces());
  board.showAll();
}

void makeNewGame (){
  state = Chess_state(false);
  allPositions.length = 0;
  startMoveNum = 0;
  lastKill.length = 0;
  lastKill ~= 0;
  allPositions ~= state;
  showPosNum = 0;
  numTimes.clear();
  prevPressed = -1;
  transpositionTable.clear();
  if (playType == 1){
    doMove();
  }
  validMoves = state.genValidMoves();
  board.setImages(state.pieces);
  board.setEnabled(getValidMovingPieces());
  board.showAll();
}

class MessageWindow : MainWindow {
  this (string message){
    super(message);
    setDefaultSize(200, 100);
    Label label = new Label(message);
    add(label);
    showAll();
  }
}
class FenWindow :MainWindow {
  this (string message){
    super("Fen Representation Of Board");
    setDefaultSize(200, 50);
    Label l = new Label(message);
    l.setSelectable(true);
    add(l);
    showAll();
  }
}
void showStateFen (){
  string fen = stateToFen(allPositions[showPosNum], lastKill[showPosNum], showPosNum+startMoveNum);
  FenWindow win = new FenWindow(fen);
}

void makePopUp (string message){
  MessageWindow window = new MessageWindow(message);
}
void changePos (bool isFwd){
  if (isFwd && showPosNum < allPositions.length - 1){
    showPosNum ++;
    board.miniBoard.setMarkup(Chess_state.getMini(allPositions[showPosNum].pieces));
    board.moveNum.setMarkup("Move: " ~ to!string(showPosNum + startMoveNum));
  }
  else if (!isFwd && showPosNum > 0){
    showPosNum --;
    board.miniBoard.setMarkup(Chess_state.getMini(allPositions[showPosNum].pieces));
    board.moveNum.setMarkup("Move: " ~ to!string(showPosNum + startMoveNum));
  }
}
void flipZaBoard (){
  flipBoard = !flipBoard;
  board.setImages(state.pieces);
  board.setEnabled(getValidMovingPieces());
}
class ChessBoard : MainWindow
{

  Button [64] buttons;
  MiniBoard miniBoard;
  Label moveNum;
  Label eval;
  Label cutoff;
  Label depth;
  Entry customEntry;
  Button blackGame;
  Button whiteGame;
  Button twoGame;
  Button loadGame;
  
  this (){
    super ("Chess");
    setDefaultSize(1100, 800);
    setResizable(false);
    Box mainBox = new Box(Orientation.HORIZONTAL, 0);
    Box vbox = new Box(Orientation.VERTICAL, 0);
    for (int x = 0; x < 8; x ++){
      Box hbox = new Box(Orientation.HORIZONTAL, 0);
      for (int y = 0; y < 8; ++y){
	Button position = new Button();
	int pos = (7-x)*8 + (7-y);
	buttons[pos] = position;
	position.setRelief(GtkReliefStyle.NONE);
	hbox.add(position);
      }
      vbox.add(hbox);
    }
    Button flip = new Button("Flip Board");
    flip.addOnClicked(delegate void (Button b) {flipZaBoard();});
    Box newGameBox = new Box(Orientation.HORIZONTAL, 0);
    Button newGame = new Button("");
    newGame.addOnClicked(delegate void (Button b) {makeNewGame();});
    (cast(Label)(newGame.getChild())).setMarkup("<big>\nNew Game\n</big>");
    loadGame = new Button("");
    (cast(Label)(loadGame.getChild())).setMarkup("<big>\nLoad Game\n</big>");
    newGameBox.add(newGame);
    newGameBox.add(loadGame);
    loadGame.addOnClicked(delegate void (Button b) {LoadFen();});
    newGameBox.setHomogeneous(true);
    Box menu = new Box(Orientation.VERTICAL, 5);
    whiteGame = new Button("Play as White");
    whiteGame.addOnClicked( delegate void (Button b) {changePlayer(0);});
    blackGame = new Button("Play as Black");
    blackGame.addOnClicked( delegate void (Button b){changePlayer(1);});
    twoGame = new Button("Play 2 Player");
    twoGame.addOnClicked( delegate void (Button b){changePlayer(2);});
    menu.add(newGameBox);
    menu.add(whiteGame);
    menu.add(blackGame);
    menu.add(twoGame);
    mainBox.add(vbox);
    Box leftBox = new Box(Orientation.VERTICAL, 3);
    leftBox.add(menu);
    Box difBox = new Box(Orientation.VERTICAL, 10);
    Button difHard = new Button("Hard");
    Button difNormal = new Button("Normal");
    Button difEasy = new Button("Easy");
    Box custom = new Box(Orientation.HORIZONTAL, 5);
    Label difCustom = new Label("Custom: ");
    Box infoBox = new Box(Orientation.VERTICAL, 5);
    customEntry = new Entry("");
    customEntry.setHexpand(true);
    customEntry.addOnActivate(delegate void (Entry e) {customEntryChange();});
    difEasy.addOnClicked(delegate void (Button b) {changeDifficulty(300);});
    difNormal.addOnClicked(delegate void (Button b) {changeDifficulty(1500);});
    difHard.addOnClicked(delegate void (Button b) {changeDifficulty(4000);});
    custom.add(difCustom);
    custom.add(customEntry);
    Label setDif = new Label("");
    setDif.setMarkup("<big> Set Difficulty </big>");
    setDif.setUseMarkup(true);
    difBox.packStart(setDif, true, true, 20);
    difBox.packStart(difEasy, true, true, 0);
    difBox.packStart(difNormal, true, true, 0);
    difBox.packStart(difHard, true, true, 0);
    difBox.packStart(custom, true, true, 0);
    eval = new Label("<big>Evaluation: 0 </big>");
    depth = new Label("<big>Depth of search: -</big> ");
    cutoff = new Label("<big>Time limit: </big>");
    eval.setHexpand(true);
    depth.setHexpand(true);
    cutoff.setHexpand(true);
    eval.setUseMarkup(true);
    depth.setUseMarkup(true);
    cutoff.setUseMarkup(true);
    difBox.setHexpand(true);
    leftBox.add(difBox);
    leftBox.setHexpand(true);
    leftBox.packStart(new Label(""), false, true, 5);
    infoBox.packStart(cutoff, false, true, 0);
    infoBox.packStart(eval, false, true, 0);
    infoBox.packStart(depth, false, true, 0);
    leftBox.packStart(infoBox, true, true, 0);
    leftBox.packStart(flip, true, true, 5);
    miniBoard = new MiniBoard("");
    Box replay = new Box(Orientation.VERTICAL, 0);
    replay.add(miniBoard);
    Box controls = new Box(Orientation.HORIZONTAL, 5);
    Button fwd = new Button("\u21E8");
    Button bck = new Button("\u21E6");
    fwd.addOnClicked(delegate void (Button b) {changePos(true);});
    bck.addOnClicked(delegate void (Button b) {changePos(false);});
    moveNum = new Label("Move: 0");
    moveNum.setHexpand(true);
    Button getFen = new Button("Get Fen");
    getFen.addOnClicked(delegate void (Button b) {showStateFen();});
    controls.setHexpand(true);
    controls.add(bck);
    controls.add(moveNum);
    controls.add(getFen);
    controls.add(fwd);
    replay.add(controls);
    
    leftBox.packStart(replay, false, true, 0);
    mainBox.add(leftBox);
    add(mainBox);
    mixin (genStrings());
    
    setName("windowColor");
    moveNum.setName("labelColor");
    setDif.setName("labelColor");
    eval.setName("labelColor");
    difCustom.setName("labelColor");
    cutoff.setName("labelColor");
    depth.setName("labelColor");
    blackGame.setName("buttonColor");
    whiteGame.setName("buttonColor");
    twoGame.setName("buttonColor");
    loadGame.setName("buttonColor");
    fwd.setName("buttonColor");
    bck.setName("buttonColor");
    getFen.setName("buttonColor");
    difHard.setName("buttonColor");
    difNormal.setName("buttonColor");
    difEasy.setName("buttonColor");
    newGame.setName("buttonColor");
    flip.setName("buttonColor");
    // for (int i = 0; i < 64; i ++){
    //   if (i%2){
    // 	buttons[i].setName("posButtonLight");
    //   }
    //   else {
    // 	buttons[i].setName("posButtonDark");
    //   }
    // }
    
    showAll();
  }

  void setImages (ulong [6][2] pieces){
    for (int i = 0; i < 64; i ++){
      string imagePath = "chess_pieces/";
      ulong num = 1uL << i;
      for (int j = 0; j < 6; j ++){
	if ((pieces[0][j] & num) != 0){
	  imagePath ~= "w" ~ to!string(j);
	  break;
	}
	if ((pieces[1][j] & num) != 0){
	  imagePath ~= "b" ~ to!string(j);
	  break;
	}
      }
      if ((i % 2 == 0)^((i/8) % 2)){
	imagePath ~= "w.png";
      }
      else {
	imagePath ~= "b.png";
      }
      Image image = new Image(imagePath);
      if (!flipBoard)
	buttons[i].setImage(image);
      else
	buttons[63-i].setImage(image);
    }
    
    miniBoard.setMarkup( Chess_state.getMini(state.pieces));
  }
  // void setImages2 (ulong [6][2] pieces){
  //   for (int i = 0; i < 64; i ++){
  //     ulong num = 1uL << i;
  //     string str;
  //     bool flag = true;
  //     for (int j = 0; j < 6; j ++){
  // 	if ((pieces[0][j] & num) != 0){
  // 	  str = Chess_state.printPiece(j, true);
  // 	  flag = false;
  // 	  break;
  // 	}
  // 	if ((pieces[1][j] & num) != 0){
  // 	  str = Chess_state.printPiece(j, false);
  // 	  flag = false;
  // 	  break;
  // 	}
  //     }
  //     if (flag){
  // 	str = "\u2003\u2009";
  //     }
      
  //     if (!flipBoard)
  // 	buttons[i].setLabel(str);
  //     else
  // 	buttons[63-i].setLabel(str);
  //   }
    
  //   miniBoard.setMarkup( Chess_state.getMini(state.pieces));
  // }

  void setEnabled (ulong valid){
    for (int i = 0; i < 64; i ++){
      ulong num = 1uL << i;
      if (!flipBoard)
	buttons[i].setSensitive((valid & num) != 0);
      else
	buttons[63-i].setSensitive((valid & num) != 0);
    }
  }
  void buttonPressed (int pos){
    if (flipBoard){
      pos = 63 - pos;
    }
    if (prevPressed == -1){
      for (int i = 0; i < 16; i ++){
	if (validMoves[i].piecePos == pos){
	  setEnabled(validMoves[i].set | (1uL << pos));
	  break;
	}
      }
    }
    else if (prevPressed == pos){
      setEnabled(getValidMovingPieces());
    }
    else {
      state.makeMove(prevPressed, pos);
      allPositions ~= state;
      if ((pieceCount(allPositions[$-1]) != pieceCount(allPositions[$-2])) || (allPositions[$-1].pieces[0][0] != allPositions[$-2].pieces[0][0]) || (allPositions[$-1].pieces[1][0] != allPositions[$-2].pieces[1][0])){
	lastKill ~= 0;
      }
      else {
	lastKill ~= lastKill[$-1]+1;
      }
      showPosNum = cast(int)allPositions.length-2;
      changePos(true);
      if (state.hash in numTimes){
	numTimes[state.hash] ++;
      }
      else {
	numTimes[state.hash] = 1;
      }
      if (numTimes[state.hash] >= 3 || lastKill[$-1] == 50){
	makePopUp("Tie by repetition");
	setEnabled(0);
	return;
      }
      setImages(state.pieces);
      setEnabled((1uL << pos));
    }
  }
  void buttonReleased (int pos){
    if (flipBoard){
      pos = 63 - pos;
    }
    if (prevPressed == -1){
      prevPressed = pos;
    }
    else if (prevPressed == pos){
      prevPressed = -1;
    }
    else {
      if (playType == 2){
	validMoves = state.genValidMoves();
      }
      else {
	validMoves = state.genValidMoves();
	ulong legal = getValidMovingPieces();
	if (legal == 0){
	  if (state.squareIsUnderAttack2(state.pieces[state.isBlackTurn][5], (!state.isBlackTurn), state.occupied[0]|state.occupied[1])){
	    if (state.isBlackTurn){
	      makePopUp("Checkmate, White won");
	    }
	    else {
	      makePopUp("Checkmate, Black won");
	    }
	  }
	  else {
	    makePopUp("Stalemate");
	  }
	  setEnabled(0);
	  return;
	}
	doMove();
      }
      setImages(state.pieces);
      ulong legal = getValidMovingPieces();
      if (legal == 0){
	if (state.squareIsUnderAttack2(state.pieces[state.isBlackTurn][5], (!state.isBlackTurn), state.occupied[0]|state.occupied[1])){
	  if (state.isBlackTurn){
	    makePopUp("Checkmate, White won");
	  }
	  else {
	    makePopUp("Checkmate, Black won");
	  }
	}
	else {
	  makePopUp("Stalemate");
	}
	setEnabled(0);
	return;
      }
      setEnabled(legal);
      prevPressed = -1;
    }
  }
}

void setCss (){
  CssProvider provider;
  Display display;
  Screen screen;
  provider = new CssProvider();
  display = Display.getDefault();
  screen = display.getDefaultScreen();
  StyleContext.addProviderForScreen(screen, provider, GTK_STYLE_PROVIDER_PRIORITY_USER);
  provider.loadFromPath("source/styles.css");
}

ChessBoard board;

void main(string[] args)
{
  preProcess();
  blue = new PgAttributeList();
  white = new PgAttributeList();
  blue.change(PgAttribute.foregroundNew(10000, 10000, 60000));
  white.change(PgAttribute.foregroundNew(65000, 65000, 65000));
  Main.init(args);
  setCss();
  board = new ChessBoard();
  changeDifficulty(3000);
  makeNewGame();
  changePlayer(0);
  Main.run();
}


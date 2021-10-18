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
import gtk.Label;
import gtk.Entry;
import pango.PgAttributeList;
import pango.PgAttribute;

int prevPressed = -1;
MoveSet [16] validMoves;

int showPosNum = 0;

struct BasicMove {
  int initialPos;
  int finalPos;
  this (int a, int b){
    initialPos = a;
    finalPos = b;
  }
}

ulong [6][2][] allPositions;
// int [] evaluations;

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
    // pglist.change(PgAttribute.stretchNew(PangoStretch.ULTRA_CONDENSED));
    pglist.change(PgAttribute.familyNew("Comic Sans"));
    this.setAttributes(pglist);
  }
}

Timer cutoffTimer;
int playType = 2; //0 means computer is black, 1 means player is black, 2 means two player, 3 means computer vs computer
bool playerTurn = false; //false is white, true is black

Move getMove (bool isBlack){
  state.turnIsBlack = isBlack;
  synchronized{
    timeExceeded = false;
  }
  cutoffTimer = new Timer();
  cutoffTimer.start();
  return state.genBestMove(isBlack);
}

void doMove (bool isBlack){
  Move best = getMove(isBlack);
  // writeln("depth achieved ", state.currDepth-1);
  board.depth.setMarkup("<big>Depth of search: " ~to!string(state.currDepth-1) ~ "</big> ");
  if (best.score < 6000 && best.score > -6000){
    if (isBlack){
      board.eval.setMarkup("<big>Evaluation: "~ to!string(-best.score) ~" </big>");
    }
    else {
      board.eval.setMarkup("<big>Evaluation: "~ to!string(best.score) ~" </big>");
    }
  }
  state.makeMove(best, isBlack);
  // if (isBlack){
  //   evaluations ~= -best.score;
  //   evaluations ~= -best.score;
  // }
  // else{
  //   evaluations ~= best.score;
  //   evaluations ~= best.score;
  // }
  allPositions ~= state.pieces;
  showPosNum = cast(int)allPositions.length-2;
  changePos(true);
  if (state.hash in numTimes){
    numTimes[state.hash] ++;
  }
  else {
    numTimes[state.hash] = 1;
  }
  if (numTimes[state.hash] >= 3){
    makePopUp("Tie by repetition");
    board.setEnabled(0);
    makeNewGame(0);
    return;
  }
  validMoves = state.genValidMoves(!isBlack);
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
  // cutoff = msecs(dif);
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
  
}

void makeNewGame (int type){
  state = Chess_state(false);
  // evaluations.length = 0;
  allPositions.length = 0;
  allPositions ~= state.pieces;
  // evaluations ~= 0;
  showPosNum ++;
  numTimes.clear();
  prevPressed = -1;
  transpositionTable.clear();
  playType = type;
  playerTurn = false;
  if (playType == 1){
    doMove(false);
    playerTurn = true;
  }
  validMoves = state.genValidMoves(playerTurn);
  board.setImages(state.pieces);
  board.setEnabled(getValidMovingPieces());
  board.showAll();
}

class MessageWindow : MainWindow {
  this (string message){
    super(message);
    setDefaultSize(400, 300);
    Label label = new Label(message);
    add(label);
    showAll();
  }
}

void makePopUp (string message){
  MessageWindow window = new MessageWindow(message);
}
void changePos (bool isFwd){
  if (isFwd && showPosNum < allPositions.length - 1){
    showPosNum ++;
    board.miniBoard.setMarkup(Chess_state.getMini(allPositions[showPosNum]));
    board.moveNum.setMarkup("Move: " ~ to!string(showPosNum));
    // if (evaluations.length <= showPosNum){
    //   board.moveEval.setMarkup("");
    // }
    // else {
    //   board.moveEval.setMarkup("Evaluation: " ~to!string(evaluations[showPosNum]));
    // }
  }
  else if (!isFwd && showPosNum > 0){
    showPosNum --;
    board.miniBoard.setMarkup(Chess_state.getMini(allPositions[showPosNum]));
    board.moveNum.setMarkup("Move: " ~ to!string(showPosNum));
    // if (evaluations.length <= showPosNum){
    //   board.moveEval.setMarkup("");
    // }
    // else {
    //   board.moveEval.setMarkup("Evaluation: " ~to!string(evaluations[showPosNum]));
    // }
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
  // Label moveEval;
  
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
    Label newGame = new Label("<big> New Game </big>");
    newGame.setUseMarkup(true);
    Box menu = new Box(Orientation.VERTICAL, 10);
    Button newWhiteGame = new Button("Play as White");
    newWhiteGame.addOnClicked( delegate void (Button b) {makeNewGame(0);});
    Button newBlackGame = new Button("Play as Black");
    newBlackGame.addOnClicked( delegate void (Button b){makeNewGame(1);});
    Button newTwoGame = new Button("Play 2 player");
    newTwoGame.addOnClicked( delegate void (Button b){makeNewGame(2);});
    menu.packStart(newGame, true, true, 20);
    menu.packStart(newWhiteGame, true, true, 0);
    menu.packStart(newBlackGame, true, true, 0);
    menu.packStart(newTwoGame, true, true, 0);
    // menu.setHomogeneous(true);
    // add(menu);
    // Box secondaryBox = new Box(Orientation.VERTICAL, 1);
    // secondaryBox.add(vbox);
    // secondaryBox.add(menu);
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
    // difBox.packStart(new Label(""), true, true, 0);
    difBox.packStart(setDif, true, true, 20);
    difBox.packStart(difEasy, true, true, 0);
    difBox.packStart(difNormal, true, true, 0);
    difBox.packStart(difHard, true, true, 0);
    difBox.packStart(custom, true, true, 0);
    // difBox.setHomogeneous(true);
    eval = new Label("<big>Evaluation: - </big>");
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
    // moveEval = new Label("Evaluation:");
    // moveEval.setHexpand(true);
    // moveInfo.add(moveEval);
    // controls.setHomogeneous(true);
    controls.setHexpand(true);
    controls.add(bck);
    controls.add(moveNum);
    controls.add(fwd);
    replay.add(controls);
    
    leftBox.packStart(replay, false, true, 0);
    mainBox.add(leftBox);
    add(mainBox);
    mixin (genStrings());
    showAll();
  }

  void setImages (ulong [6][2] pieces){
    for (int i = 0; i < 64; i ++){
      string imagePath = "/home/ramanuj/code/chess/chess_pieces/";
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
      allPositions ~= state.pieces;
      showPosNum = cast(int)allPositions.length-2;
      changePos(true);
      if (state.hash in numTimes){
	numTimes[state.hash] ++;
      }
      else {
	numTimes[state.hash] = 1;
      }
      if (numTimes[state.hash] >= 3){
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
      playerTurn = !playerTurn;
      if (playType == 2){
	validMoves = state.genValidMoves(playerTurn);
      }
      else {
	validMoves = state.genValidMoves(playerTurn);
	ulong legal = getValidMovingPieces();
	if (legal == 0){
	  if (state.squareIsUnderAttack2(state.pieces[playerTurn][5], (!playerTurn), state.occupied[0]|state.occupied[1])){
	    if (playerTurn){
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
	doMove(playerTurn);
	playerTurn = !playerTurn;
      }
      setImages(state.pieces);
      ulong legal = getValidMovingPieces();
      if (legal == 0){
	if (state.squareIsUnderAttack2(state.pieces[playerTurn][5], (!playerTurn), state.occupied[0]|state.occupied[1])){
	  if (playerTurn){
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



ChessBoard board;

void main(string[] args)
{
  preProcess();
  Main.init(args);
  board = new ChessBoard();
  changeDifficulty(3000);
  makeNewGame(0);
  Main.run();
} // main()

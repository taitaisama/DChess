import std.stdio;
import chess.d;
import piece_maps.d;
import std.datetime.systime : SysTime, Clock;
import core.time : msecs, usecs, hnsecs, nsecs;
import core.thread.osthread: Thread;

Chess_state state;
bool blackTurn;
auto cutoff = msecs(3000);
string prevPosition;

class Timer : Thread {
  this (){
    super (&run);
  }
  
private:
  void run(){
    SysTime startTime = Clock.currTime();
    while (Clock.currTime() - startTime < cutoff) { }
    synchronized{
      timeExceeded = true;
    }
  }
}

Timer cutoffTimer;

Move getMove (bool isBlack){
  state.turnIsBlack = isBlack;
  synchronized{
    timeExceeded = false;
  }
  cutoffTimer = new Timer();
  cutoffTimer.start();
  return state.genBestMove(isBlack);
}


void communicate (){
  writeln("the ultimate chess engine by Ramanuj Goel");
  stdout.flush();
  while (true){
    string input = readln();
    if (input == "uci" || input == "uci\n"){
      writeln("id name taitaisama");
      writeln("id author Ranamnuj Goel");
      writeln("uciok");
      stdout.flush();
    }
    else if (input == "isready" || input == "isready\n"){
      writeln("readyok");
      stdout.flush();
    }
    else if (input == "ucinewgame" || input == "ucinewgame\n"){
      state.reset();
    }
    else if (input.length >= 8 && input[0 .. 8] == "position"){
      procPosition(input);
      state.print();
      stdout.flush();
    }
    else if (input.length >= 2 && input[0 .. 2] == "go"){
      procGo(input);
      Move best = getMove(blackTurn);
      writeln("bestmove ", cast(char)('h' - (best.initialPos%8)), (best.initialPos/8)+1, cast(char)('h' - (best.finalPos%8)), (best.finalPos/8)+1);
      stdout.flush();
    }
    else if (input == "quit\n"){
      break;
    }
    stdout.flush();
  }
}

void procPosition(string input){
  state.resetVals();
  assert (input.length >= 23 && input[0 .. 23] == "position startpos moves", "fen not supported");
  input = input[23 .. $] ~ " ";
  if (input[0] == ' '){
    input = input[1 .. $];
  }
  bool isBlack = false;
  for (int idx = 0; idx+3 < input.length; idx += 5){
    int initialPos = (input[idx+1] - '1')*8 + 'h' - input[idx];
    int finalPos = (input[idx+3] - '1')*8 + 'h' - input[idx+2];
    state.makeMove(initialPos, finalPos);
    isBlack = !isBlack;
  }
  // state.assert_state(7, isBlack);
  blackTurn = isBlack;
}

void procGo (string input){
  if (input.length >= 12 && input[0 .. 12] != "go movetime "){
    writeln("only move time mode is allowed, please change it by going into levels, adjust and set mode to time per move");
    writeln("defaulting to 4 seconds time");
    cutoff = msecs(3000);
    return;
  }
  input = input[12 .. $];
  import std.conv;
  if (input[$-1] == '\n'){
    input = input[0 .. $-1];
  }
  cutoff = msecs(to!int(input));
}

// void main (){
//   preProcess();
//   state = new Chess_state();
//   communicate();
// }

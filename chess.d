

import std.stdio;
import piece_maps.d;

extern (C) int ffsl(long a);

const int firstSaveSize = 5;
const int seconSaveSize = 5;

struct moveSet {
  int pieceType;
  ulong set;
  int piecePos;
  this (int t, ulong s, int pos){
    pieceType = t;
    set = s;
    piecePos = pos;
  }
}
struct move {
  
  int initialPos;
  int finalPos;
  int playType;
  int killType; //killtype = 6 means no kill
  int score;
  this (int a, int b, int c, int d, int e){
    initialPos = a;
    finalPos = b;
    playType = c;
    killType = d;
    score = e;
  }
  void print (){
    writeln(initialPos, ", ", finalPos, ", ", playType, ", ", killType, ", ", score);
  }
}

string makeKillFunctions (int type, bool isPawn, bool isBlack, bool isFirst){
    
  import std.conv;
  string start, end;
  if (isPawn) {
    start = "0"; end = "pidx";
  }
  else {
    start = "pidx"; end = "kidx";
  }
  string checkString;
  string call;
  if (isBlack){
    checkString = "pieces[0][" ~ to!string(type) ~ "]";
    call = "maxi";
  }
  else {
    checkString = "pieces[1][" ~ to!string(type) ~ "]";
    call = "mini";
  }
  string output = "
   for (int i =" ~ start ~  "; i < " ~ end ~ "; i ++){
      for (ulong b = moves[i].set & " ~ checkString ~ "; b!= 0; b &= (b-1)){
	int sq = ffsl(b);
        int score;";
  if (isPawn){
    output ~=
      "if (sq >= 56){
	  makePawnPromotion(" ~ to!string(isBlack) ~ ", " ~ to!string(type) ~ ", moves[i].piecePos, sq );
	  score = " ~ call ~ "(alpha, beta, depth-1);
	  unmakePawnPromotion(" ~ to!string(isBlack) ~ ", " ~ to!string(type) ~ ", moves[i].piecePos, sq );";
      if (isFirst){
	output ~= "
          insertMove(move(moves[i].piecePos, sq, 0, "~ to!string(type) ~ ", score), " ~ to!string(isBlack) ~ ");";
      }
    output ~= "
	}
	else {";
  }
  output ~= "
	makeKillMove(" ~ to!string(isBlack) ~ ", moves[i].pieceType, " ~ to!string(type) ~ ", moves[i].piecePos, sq);
	score = " ~ call ~ "(alpha, beta, depth-1);
	unmakeKillMove(" ~ to!string(isBlack) ~ ", moves[i].pieceType, " ~ to!string(type) ~ ", moves[i].piecePos, sq);";
  
  if (isFirst){
    output ~= "
          insertMove(move(moves[i].piecePos, sq, moves[i].pieceType, "~ to!string(type) ~ ", score), " ~ to!string(isBlack) ~ ");";
  }
  if (isPawn){
    output ~= "}";
  }
  if (!isFirst){
    if (isBlack){
      output ~= "
	if (score <= alpha) return alpha;
	if (score < beta) {
	  beta = score;
        }";
    }
    else {
      output ~= "if (score >= beta) return beta;
	if (score > alpha) {
	  alpha = score;
        }";
    }
  }
  output ~= "
      }
    }";
  return output;
}
int numStates = 0;

struct Chess_state {
  
  int currDepth;
  move bestMove;
  
  ulong [2] occupied; // white then black
  ulong [6][2] pieces;
  bool [2][2] castle; // left rigght
  int evaluation;

  move [firstSaveSize] bestMoves; //best 5, worst to best

  void insertMove (move m, bool isBlack){
    if (isBlack){
      if (bestMoves[0].score > m.score){
	bestMoves[0] = m;
      }
      else {
	return;
      }
    
      for (int i = 1; i < firstSaveSize && bestMoves[i].score > bestMoves[i-1].score; i ++){
	move temp = bestMoves[i];
	bestMoves[i] = bestMoves[i-1];
	bestMoves[i-1] = temp;
      }
    }
    else {
      if (bestMoves[0].score < m.score){
	bestMoves[0] = m;
      }
      else {
	return;
      }
    
      for (int i = 1; i < firstSaveSize && bestMoves[i].score < bestMoves[i-1].score; i ++){
	move temp = bestMoves[i];
	bestMoves[i] = bestMoves[i-1];
	bestMoves[i-1] = temp;
      }
    }
  }
  
  this (bool a){
    for (int i = 0; i < 16; i ++){
      occupied[0] |= (1uL << i);
    }
    for (int i = 8; i < 16; i ++){
      pieces[0][0] |= (1uL << i);
    }
    pieces[0][1] |= (1uL << 1);
    pieces[0][1] |= (1uL << 6);
    pieces[0][2] |= (1uL << 2);
    pieces[0][2] |= (1uL << 5);
    pieces[0][3] |= (1uL << 0);
    pieces[0][3] |= (1uL << 7);
    pieces[0][5] |= (1uL << 3);
    pieces[0][4] |= (1uL << 4);
    
    for (int i = 48; i < 64; i ++){
      occupied[1] |= (1uL << i);
    }
    for (int i = 48; i < 56; i ++){
      pieces[1][0] |= (1uL << i);
    }
    pieces[1][1] |= (1uL << 57);
    pieces[1][1] |= (1uL << 62);
    pieces[1][2] |= (1uL << 58);
    pieces[1][2] |= (1uL << 61);
    pieces[1][3] |= (1uL << 56);
    pieces[1][3] |= (1uL << 63);
    pieces[1][5] |= (1uL << 59);
    pieces[1][4] |= (1uL << 60);
    evaluation = 0;
    
  }

  this (int wkpos, int ppos, int bkpos){ //3, 36 35
    pieces[0][5] = (1uL << wkpos);
    pieces[1][5] = (1uL << bkpos);
    pieces[1][0] = (1uL << ppos);
  }

  this (ulong a, ulong b, int c, ulong d, ulong e, ulong f, ulong g, ulong h, ulong i, ulong j, ulong k, ulong l, ulong m, ulong n, ulong o){
    occupied[0] = a; occupied[1] = b; evaluation = c; pieces[0][0] = d; pieces[0][1] = e; pieces[0][2] = f;  pieces[0][3] = g; pieces[0][4] = h; pieces[0][5] = i; pieces[1][0] = j; pieces[1][1] = k; pieces[1][2] = l; pieces[1][3] = m; pieces[1][4] = n; pieces[1][5] = o;
  }
  
  void print (){
    writeln();
    // writeln(occupied[0], ", ", occupied[1], ", ", evaluation, ", ", pieces[0][0], ", ", pieces[0][1],", ", pieces[0][2], ", ", pieces[0][3], ", ", pieces[0][4], ", ", pieces[0][5], ", ", pieces[1][0], ", ", pieces[1][1], ", ", pieces[1][2], ", ", pieces[1][3], ", ", pieces[1][4], ", ", pieces[1][5]);
    for (int i = 63; i >= 0; i --){
      ulong pos = (1uL << i);
      bool flag = true;
      for (int j = 0; j < 6; j ++){
	if ((pos & pieces[0][j]) != 0){
	  printPiece(j, true);
	  flag = false;
	  break;
	}
	else if ((pos & pieces[1][j]) != 0){
	  printPiece(j, false);
	  flag = false;
	  break;
	}
      }
      if (flag){
	write("  ");
      }
      if (i % 8 == 0){
	writeln();
      }
    }
    writeln();
  }
  
  void printPiece (int piece, bool coloriswhite){
    if (coloriswhite){
      if (piece == 0){
	write("\u2659 ");
      }
      else if (piece == 1){
	write("\u2658 ");
      }
      else if (piece == 2){
	write("\u2657 ");
      }
      else if (piece == 3){
	write("\u2656 ");
      }
      else if (piece == 4){
	write("\u2655 ");
      }
      else if (piece == 5){
	write("\u2654 ");
      }
      else {
	assert (false);
      }
    }
    else {
      if (piece == 0){
	write("\u265F ");
      }
      else if (piece == 1){
	write("\u265E ");
      }
      else if (piece == 2){
	write("\u265D ");
      }
      else if (piece == 3){
	write("\u265C ");
      }
      else if (piece == 4){
	write("\u265B ");
      }
      else if (piece == 5){
	write("\u265A ");
      }
      else {
	assert (false);
      }
    }
  }

  void assert_state(){
    for (int i = 0; i < 6; i ++){
      for (int j = i+1; j < 6; j ++){
	ulong x = pieces[0][i] & pieces[0][j];
	if (x != 0){
	  writeln(i, " ", j);
	  printBoard(pieces[0][i]);
	  printBoard(pieces[0][j]);
	}
	assert (x == 0);
        x = pieces[1][i] & pieces[1][j];
	assert (x == 0);
      }
    }
    ulong wcalc = 0;
    ulong bcalc = 0;
    for (int i = 0; i < 6; i ++){
      wcalc |= pieces[0][i];
      bcalc |= pieces[1][i];
    }
    assert((wcalc & bcalc) == 0);
    assert(wcalc == occupied[0] && bcalc == occupied[1]);
    int calcEval = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	calcEval += positionEval[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	calcEval -= positionEval[1][i][sq];
      }
    }
    assert(calcEval == evaluation);
  }
  
  ulong pieceMoves (ulong occupied, int type, int pos){
    assert (type != 0);
    ulong attacks = pieceAttacks[type][pos];
    for (ulong b = occupied & blockersBeyond[type][pos]; b != 0; b &= (b-1)){
      int sq = ffsl(b);
      attacks &= ~arrBehind[pos][sq];
    } // castle is special in first layer
    return attacks;
  }
  
  ulong pawnMoves (ulong totalOccupied, int pos, bool isBlack){
    if (isBlack){
      ulong attacks = (1uL << (pos-8))&(~totalOccupied);
      int col = pos%8;
      if (pos/8 == 6 && attacks != 0){
	attacks |= (1uL << (pos-16))&(~totalOccupied);
      }
      if (col == 0){
	attacks |= (1uL << (pos-7))&occupied[0];
      }
      else if (col == 7){
	attacks |= (1uL << (pos-9))&occupied[0];
      }
      else {
	attacks |= ((1uL << (pos-9)) | (1uL << (pos-7)))&occupied[0];
      }
      return attacks;
    }
    else{
      ulong attacks = (1uL << (pos+8))&(~totalOccupied);
      int col = pos%8;
      if (pos/8 == 1 && attacks != 0){
	attacks |= (1uL << (pos+16))&(~totalOccupied);
      }
      if (col == 0){
	attacks |= (1uL << (pos+9))&occupied[1];
      }
      else if (col == 7){
	attacks |= (1uL << (pos+7))&occupied[1];
      }
      else {
	attacks |= ((1uL << (pos+9)) | (1uL << (pos+7)))&occupied[1];
      }
      return attacks;
    }
  }

  int castlePenalty (move m, bool isBlack){
    int penalty = 0;
    if (isBlack){
      if (castle[1][0]){
	if (m.playType == 5){
	  return 50;
	}
	else if (m.playType == 3 && m.initialPos == 56){
	  if (castle[1][1]){
	    return 15;
	  }
	  else {
	    return 50;
	  }
	}
      }
      else if (castle[1][1]){
	if (m.playType == 5){
	  return 50;
	}
	else if (m.playType == 3 && m.initialPos == 63){
	  if (castle[1][0]){
	    return 15;
	  }
	  else {
	    return 50;
	  }
	}
      }
    }
    else {
      if (castle[0][0]){
	if (m.playType == 5){
	  return 50;
	}
	else if (m.playType == 3 && m.initialPos == 0){
	  if (castle[0][1]){
	    return 15;
	  }
	  else {
	    return 50;
	  }
	}
      }
      else if (castle[0][1]){
	if (m.playType == 5){
	  return 50;
	}
	else if (m.playType == 3 && m.initialPos == 7){
	  if (castle[0][0]){
	    return 15;
	  }
	  else {
	    return 50;
	  }
	}
      }
    }
    return 0;
  }

  void makeCastle (bool isBlack, bool isRight){
    if (isBlack){
      if (isRight){
	pieces[1][5] = (1uL << 62);
	pieces[1][3] ^= (1uL << 63)|(1uL << 61);
	evaluation -= positionEval[1][5][62] - positionEval[1][5][59] + positionEval[1][3][61] - positionEval[1][3][63];
      }
      else {
	pieces[1][5] = (1uL << 57);
	pieces[1][3] ^= (1uL << 56)|(1uL << 58);
	evaluation -= positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
      }
      castle[1][1] = false;
      castle[1][0] = false;
    }
    else {
      if (isRight){
	pieces[1][5] = (1uL << 6);
	pieces[1][3] ^= (1uL << 7)|(1uL << 5);
	evaluation += positionEval[0][5][6] - positionEval[0][5][3] + positionEval[0][3][5] - positionEval[0][3][7];
      }
      else {
	pieces[1][5] = (1uL << 1);
	pieces[1][3] ^= (1uL << 0)|(1uL << 2);
	evaluation += positionEval[0][5][1] - positionEval[0][5][3] + positionEval[0][3][2] - positionEval[0][3][0];
      }
      castle[1][1] = false;
      castle[1][0] = false;
    }
  }
  
  void unmakeCastle (bool isBlack, bool isRight){
    if (isBlack){
      if (isRight){
	pieces[1][5] = (1uL << 59);
	pieces[1][3] ^= (1uL << 63)|(1uL << 61);
	evaluation += positionEval[1][5][62] - positionEval[1][5][59] + positionEval[1][3][61] - positionEval[1][3][63];
      }
      else {
	pieces[1][5] = (1uL << 59);
	pieces[1][3] ^= (1uL << 56)|(1uL << 58);
	evaluation += positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
      }
    }
    else {
      if (isRight){
	pieces[1][5] = (1uL << 3);
	pieces[1][3] ^= (1uL << 7)|(1uL << 5);
	evaluation -= positionEval[0][5][6] - positionEval[0][5][3] + positionEval[0][3][5] - positionEval[0][3][7];
      }
      else {
	pieces[1][5] = (1uL << 3);
	pieces[1][3] ^= (1uL << 0)|(1uL << 2);
	evaluation -= positionEval[0][5][1] - positionEval[0][5][3] + positionEval[0][3][2] - positionEval[0][3][0];
      }
    }
  }

  void makePawnPromotion (bool isBlack, int killType, int initialPos, int finalPos){
    ulong inpos = (1uL << initialPos);
    ulong fipos = (1uL << finalPos);
    pieces[isBlack][0] ^= inpos;
    pieces[isBlack][4] ^= fipos;
    occupied[isBlack] ^= (inpos | fipos);
    int evalChange = 0;
    evalChange += positionEval[isBlack][4][finalPos] - positionEval[isBlack][0][initialPos];
    if (killType < 6){
      pieces[(!isBlack)][killType] ^= fipos;
      occupied[(!isBlack)] ^= fipos;
      evalChange += positionEval[(!isBlack)][killType][finalPos];
    }
    if (isBlack) evaluation -= evalChange;
    else evaluation += evalChange;
  }
  
  void unmakePawnPromotion (bool isBlack, int killType, int initialPos, int finalPos){
    ulong inpos = (1uL << initialPos);
    ulong fipos = (1uL << finalPos);
    pieces[isBlack][0] ^= inpos;
    pieces[isBlack][4] ^= fipos;
    occupied[isBlack] ^= (inpos | fipos);
    int evalChange = positionEval[isBlack][4][finalPos] - positionEval[isBlack][0][initialPos];
    if (killType < 6){
      pieces[(!isBlack)][killType] ^= fipos;
      occupied[(!isBlack)] ^= fipos;
      evalChange += positionEval[(!isBlack)][killType][finalPos];
    }
    if (isBlack) evaluation += evalChange;
    else evaluation -= evalChange;
  }

  void makeQuietMove (bool isBlack, int type, int initialPos, int finalPos){
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][type] ^= change;
    occupied[isBlack] ^= change;
    int evalChange = positionEval[isBlack][type][finalPos] - positionEval[isBlack][type][initialPos];
    if (isBlack) evaluation -= evalChange;
    else evaluation += evalChange;
  }

  void unmakeQuietMove (bool isBlack, int type, int initialPos, int finalPos){
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][type] ^= change;
    occupied[isBlack] ^= change;
    int evalChange = positionEval[isBlack][type][finalPos] - positionEval[isBlack][type][initialPos];
    if (isBlack) evaluation += evalChange;
    else evaluation -= evalChange;
  }
  
  void makeKillMove (bool isBlack, int playType, int killType, int initialPos, int finalPos){
    ulong fipos = 1uL << finalPos;
    ulong change = (1uL << initialPos) | fipos;
    pieces[isBlack][playType] ^= change;
    occupied[isBlack] ^= change;
    occupied[(!isBlack)] ^= fipos;
    pieces[(!isBlack)][killType] ^= fipos;
    int evalChange = positionEval[isBlack][playType][finalPos] - positionEval[isBlack][playType][initialPos] + positionEval[(!isBlack)][killType][finalPos];
    if (isBlack) evaluation -= evalChange;
    else evaluation += evalChange;
  }

  void unmakeKillMove (bool isBlack, int playType, int killType, int initialPos, int finalPos){
    ulong fipos = 1uL << finalPos;
    ulong change = (1uL << initialPos) | fipos;
    pieces[isBlack][playType] ^= change;
    occupied[isBlack] ^= change;
    occupied[(!isBlack)] ^= fipos;
    pieces[(!isBlack)][killType] ^= fipos;
    int evalChange = positionEval[isBlack][playType][finalPos] - positionEval[isBlack][playType][initialPos] + positionEval[(!isBlack)][killType][finalPos];
    if (isBlack) evaluation += evalChange;
    else evaluation -= evalChange;
  }
  
  void makeMove(move m, bool isBlack){
    import std.math;
    if (m.playType == 5 && (abs(m.initialPos - m.finalPos) == 2 || abs(m.initialPos - m.finalPos) == 3)){
      if (isBlack){
	assert (m.initialPos == 59);
	if (m.finalPos == 56){
	  makeCastle(true, false);
	}
	else if (m.finalPos == 63){
	  makeCastle(true, true);
	}
	else {
	  assert(false);
	}
      }
      else {
	assert (m.initialPos == 3);
	if (m.finalPos == 0){
	  makeCastle(false, false);
	}
	else if (m.finalPos == 7){
	  makeCastle(false, true);
	}
	else {
	  assert(false);
	}
      }
      castle[isBlack][0] = false;
      castle[isBlack][1] = false;
      return;
    }
    if (m.playType == 0 && ((m.finalPos >= 56 && (!isBlack)) || (m.finalPos <= 7 && (isBlack)))){
      makePawnPromotion(isBlack, m.killType, m.initialPos, m.finalPos);
      return;
    }
    if (m.killType == 6) makeQuietMove(isBlack, m.playType, m.initialPos, m.finalPos);
    else makeKillMove(isBlack, m.playType, m.killType, m.initialPos, m.finalPos);
    if (m.playType == 5){
      castle[isBlack][0] = false;
      castle[isBlack][1] = false;
    }
    if (m.initialPos == 0 || m.finalPos == 0){
      castle[0][0] = false;
    }
    else if (m.initialPos == 7 || m.finalPos == 7){
      castle[0][1] = false;
    }
    else if (m.initialPos == 56 || m.finalPos == 56){
      castle[1][0] = false;
    }
    else if (m.initialPos == 63 || m.finalPos == 63){
      castle[1][1] = false;
    }
  }

  moveSet [16] genMoves (bool isBlack){
    moveSet [16] moves;
    //each piece one by one
    int idx = 0;
    ulong occupied = occupied[0] | occupied[1];
    for (ulong b = pieces[isBlack][0]; b != 0; b &= (b-1), idx ++){
      int sq = ffsl(b);
      moves[idx] = moveSet(0, pawnMoves(occupied, sq, isBlack), sq);
    }
    for (int j = 1; j < 6; j ++){
      for (ulong b = pieces[isBlack][j]; b != 0; b &= (b-1), idx ++){
	int sq = ffsl(b);
	moves[idx] = moveSet(j, pieceMoves(occupied, j, sq), sq);
      }
    }
    return moves;
  }
  

  int maxi (int alpha, int beta, int depth){
    // assert_state();
    if (depth == 0) return evaluation;
  
    moveSet [16] moves = genMoves(false);
    ulong kingPos = pieces[1][5];
    int kidx;
    for (kidx = 0; moves[kidx].pieceType != 5; kidx ++){
      if ((moves[kidx].set & kingPos) != 0){
	return int.max - 1;
      }
    }
    if ((moves[kidx].set & kingPos) != 0){
      return int.max - 1;
    }
    kidx ++;
    int pidx;
    for (pidx = 0; moves[pidx].pieceType == 1; pidx ++){}
    mixin(makeKillFunctions(4, true, false, false));
    mixin(makeKillFunctions(3, true, false, false));
    mixin(makeKillFunctions(2, true, false, false));
    mixin(makeKillFunctions(1, true, false, false));
    mixin(makeKillFunctions(0, true, false, false));
    mixin(makeKillFunctions(4, false, false, false));
    mixin(makeKillFunctions(3, false, false, false));
    mixin(makeKillFunctions(2, false, false, false));
    mixin(makeKillFunctions(1, false, false, false));
    mixin(makeKillFunctions(0, false, false, false));
   
    ulong tolOccupied = occupied[1] | occupied[0];
    for (int i = 0; i < kidx; i ++){
      for (ulong b = moves[i].set & ~tolOccupied; b!= 0; b &= (b-1)){
	int sq = ffsl(b);
	int score;
	if (moves[i].pieceType == 0 && sq >= 56){
	  makePawnPromotion(false, 6, moves[i].piecePos, sq);
	  score = mini(alpha, beta, depth-1);
	  unmakePawnPromotion(false, 6, moves[i].piecePos, sq);
	}
	else {
	  makeQuietMove(false, moves[i].pieceType, moves[i].piecePos, sq);
	  score = mini(alpha, beta, depth-1);
	  unmakeQuietMove(false, moves[i].pieceType, moves[i].piecePos, sq);
	}
	if (score >= beta) return beta;
	if (score > alpha) {
	  alpha = score;
	}
      }
    }
    return alpha;
  }

  int mini (int alpha, int beta, int depth){
    // assert_state();
    if (depth == 0) return  evaluation;
    moveSet [16] moves = genMoves(true);
    ulong kingPos = pieces[0][5];
    int kidx;
    for (kidx = 0; moves[kidx].pieceType != 5; kidx ++){
      if ((moves[kidx].set & kingPos) != 0){
	return int.min + 1;
      }
    }
    if ((moves[kidx].set & kingPos) != 0){
      return int.min + 1;
    }
    kidx ++;
    int pidx;
    for (pidx = 0; moves[pidx].pieceType == 1; pidx ++){}
    mixin(makeKillFunctions(4, true, true, false));
    mixin(makeKillFunctions(3, true, true, false));
    mixin(makeKillFunctions(2, true, true, false));
    mixin(makeKillFunctions(1, true, true, false));
    mixin(makeKillFunctions(0, true, true, false));
    mixin(makeKillFunctions(4, false, true, false));
    mixin(makeKillFunctions(3, false, true, false));
    mixin(makeKillFunctions(2, false, true, false));
    mixin(makeKillFunctions(1, false, true, false));
    mixin(makeKillFunctions(0, false, true, false));
    
    ulong tolOccupied = occupied[1] | occupied[0];
    for (int i = 0; i < kidx; i ++){
      for (ulong b = moves[i].set & ~tolOccupied; b!= 0; b &= (b-1)){
	int sq = ffsl(b);
	int score;
	if (moves[i].pieceType == 0 && sq >= 56){
	  makePawnPromotion(true, 6, moves[i].piecePos, sq);
	  score = maxi(alpha, beta, depth-1);
	  unmakePawnPromotion(true, 6, moves[i].piecePos, sq);
	}
	else {
	  makeQuietMove(true, moves[i].pieceType, moves[i].piecePos, sq);
	  score = maxi(alpha, beta, depth-1);
	  unmakeQuietMove(true, moves[i].pieceType, moves[i].piecePos, sq);
	}
	if (score <= alpha) return alpha;
	if (score < beta) {
	  beta = score;
	}
      }
    }
    return beta;
  }

  void minimax (int depth, bool isBlack){
    // assert_state();
    for (int i = 0; i < firstSaveSize; i ++){
      if (isBlack)
	bestMoves[i] = move(-1, -1, -1, -1, int.max);
      else 
	bestMoves[i] = move(-1, -1, -1, -1, int.min);
    }
    int alpha = int.min;
    int beta = int.max;
    ulong castle1, castle2;
    if (isBlack){
      castle1 = 432345564227567616uL;
      castle2 = 8070450532247928832uL;
    }
    else {
      castle1 = 6uL;
      castle2 = 112uL;
    }
    if (castle[isBlack][0]){
      if (((occupied[0] | occupied[1]) & castle1) == 0){
	makeCastle(isBlack, false);
	int score = mini(alpha, beta, depth-1);
	unmakeCastle(isBlack, false);
	if ( isBlack && score < beta) {
	  beta = score;
	}
	else if (!isBlack && score > alpha){
	  alpha = score;
	}
	if (isBlack){
	  insertMove(move(59, 56, 5, 6, score), isBlack);
	}
	else {
	  insertMove(move(3, 0, 5, 6, score), isBlack);
	}
      }
    }
    if (castle[isBlack][1]){
      if (((occupied[0] | occupied[1]) & castle2) == 0){
	makeCastle(isBlack, true);
	int score = mini(alpha, beta, depth-1);
	unmakeCastle(isBlack, true);
	if ( isBlack && score < beta) {
	  beta = score;
	}
	else if (!isBlack && score > alpha){
	  alpha = score;
	}
	if (isBlack){
	  insertMove(move(59, 63, 5, 6, score), isBlack);
	}
	else {
	  insertMove(move(3, 7, 5, 6, score), isBlack);
	}
      }
    }
    moveSet [16] moves = genMoves(isBlack);
    // printMoves(moves);
    int kidx;
    for (kidx = 0; moves[kidx].pieceType != 5; kidx ++){ }
    kidx ++;
    int pidx;
    for (pidx = 0; moves[pidx].pieceType == 1; pidx ++){}
    if (isBlack){
      mixin(makeKillFunctions(4, true, true, true));
      mixin(makeKillFunctions(3, true, true, true));
      mixin(makeKillFunctions(2, true, true, true));
      mixin(makeKillFunctions(1, true, true, true));
      mixin(makeKillFunctions(0, true, true, true));
      mixin(makeKillFunctions(4, false, true, true));
      mixin(makeKillFunctions(3, false, true, true));
      mixin(makeKillFunctions(2, false, true, true));
      mixin(makeKillFunctions(1, false, true, true));
      mixin(makeKillFunctions(0, false, true, true));
    }
    else {
      mixin(makeKillFunctions(4, true, false, true));
      mixin(makeKillFunctions(3, true, false, true));
      mixin(makeKillFunctions(2, true, false, true));
      mixin(makeKillFunctions(1, true, false, true));
      mixin(makeKillFunctions(0, true, false, true));
      mixin(makeKillFunctions(4, false, false, true));
      mixin(makeKillFunctions(3, false, false, true));
      mixin(makeKillFunctions(2, false, false, true));
      mixin(makeKillFunctions(1, false, false, true));
      mixin(makeKillFunctions(0, false, false, true));
    }
    ulong tolOccupied = occupied[1] | occupied[0];
    for (int i = 0; i < kidx; i ++){
      for (ulong b = moves[i].set & ~tolOccupied; b!= 0; b &= (b-1)){
	int sq = ffsl(b);
	int score;
	if (moves[i].pieceType == 0 && sq >= 56){
	  makePawnPromotion(isBlack, 6, moves[i].piecePos, sq);
	  if (isBlack)
	    score = maxi(alpha, beta, depth-1);
	  else 
	    score = mini(alpha, beta, depth-1);
	  unmakePawnPromotion(isBlack, 6, moves[i].piecePos, sq);
	}
	else {
	  makeQuietMove(isBlack, moves[i].pieceType, moves[i].piecePos, sq);
	  if (isBlack)
	    score = maxi(alpha, beta, depth-1);
	  else 
	    score = mini(alpha, beta, depth-1);
	  unmakeQuietMove(isBlack, moves[i].pieceType, moves[i].piecePos, sq);
	}
	insertMove(move(moves[i].piecePos, sq, moves[i].pieceType, 6, score), isBlack);
      }
    }
  }
}

void printMoves (moveSet [16] moves){
  for (int i = 0;  moves[i].pieceType != 5; i ++){
    writeln(moves[i].pieceType);
    printBoard(moves[i].set);
  }
}

Chess_state state = Chess_state(true);

void main (){
  
  import std.datetime.systime : SysTime, Clock;
  preProcess();
  import std.random;
  auto rnd = Random(89);
  state.print();
  state.currDepth = 7;
  // state = Chess_state(1083062716, 14503496356863213568, -50, 1083060480, 0, 2080, 132, 16, 8, 19915557193121792, 4611686018427387904, 65536, 9295429630892703744, 4398046511104, 576460752303423488);
  // state.print();
  // maxi(int.min, int.max, currDepth);
  // bestMove.print();
  // writeln(makeKillFunctions(3, false, false, false));
  while (true){
    // state.maxi(int.min, int.max, state.currDepth);
    // // state.bestMove.print();
    // state.makeMove(state.bestMove, false);
    // state.print();
    // state.mini(int.min, int.max, state.currDepth);
    // // state.bestMove.print();
    // state.makeMove(state.bestMove, true);
    // state.print();
    SysTime start = Clock.currTime();
    state.minimax(state.currDepth, false);
    state.makeMove(state.bestMoves[4], false);
    SysTime end = Clock.currTime();
    state.print();
    writeln(end-start);
    state.minimax(state.currDepth, true);
    state.makeMove(state.bestMoves[4], true);
    SysTime end2 = Clock.currTime();
    state.print();
    writeln(end2 - end);
  }
}

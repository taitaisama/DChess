

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
    castle[0][0] = true;
    castle[1][0] = true;
    castle[0][1] = true;
    castle[1][1] = true;
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
	if (x != 0){
	  writeln(i, " ", j);
	  printBoard(pieces[1][i]);
	  printBoard(pieces[1][j]);
	}
	assert (x == 0);
      }
    }
    ulong wcalc = 0;
    ulong bcalc = 0;
    for (int i = 0; i < 6; i ++){
      wcalc |= pieces[0][i];
      bcalc |= pieces[1][i];
    }
    if ((wcalc & bcalc) != 0){
      print();
    }
    assert((wcalc & bcalc) == 0);
    if (!(wcalc == occupied[0] && bcalc == occupied[1])){
      print();
    }
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

  void makeCastle (bool isBlack, bool isRight){
    // writeln("make caslte ", isBlack, " ", isRight);
    if (isBlack){
      if (isRight){
	ulong a = (1uL << 62)|(1uL << 59);
	ulong b = (1uL << 63)|(1uL << 61);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation -= positionEval[1][5][62] - positionEval[1][5][59] + positionEval[1][3][61] - positionEval[1][3][63];
      }
      else {
	ulong a = (1uL << 57)|(1uL << 59);
	ulong b = (1uL << 56)|(1uL << 58);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation -= positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
      }
    }
    else {
      if (isRight){
	ulong a = (1uL << 6)|(1uL << 3);
	ulong b = (1uL << 7)|(1uL << 5);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation += positionEval[0][5][6] - positionEval[0][5][3] + positionEval[0][3][5] - positionEval[0][3][7];
      }
      else {
	ulong a = (1uL << 1)|(1uL << 3);
	ulong b = (1uL << 0)|(1uL << 2);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation += positionEval[0][5][1] - positionEval[0][5][3] + positionEval[0][3][2] - positionEval[0][3][0];
      }
    }
  }
  
  void unmakeCastle (bool isBlack, bool isRight){
    if (isBlack){
      if (isRight){
	ulong a = (1uL << 62)|(1uL << 59);
	ulong b = (1uL << 63)|(1uL << 61);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation += positionEval[1][5][62] - positionEval[1][5][59] + positionEval[1][3][61] - positionEval[1][3][63];
      }
      else {
	ulong a = (1uL << 57)|(1uL << 59);
	ulong b = (1uL << 56)|(1uL << 58);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation += positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
      }
    }
    else {
      if (isRight){
	ulong a = (1uL << 6)|(1uL << 3);
	ulong b = (1uL << 7)|(1uL << 5);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation -= positionEval[0][5][6] - positionEval[0][5][3] + positionEval[0][3][5] - positionEval[0][3][7];
      }
      else {
	ulong a = (1uL << 1)|(1uL << 3);
	ulong b = (1uL << 0)|(1uL << 2);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
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
    if (m.playType == 5 && (abs(m.initialPos - m.finalPos) == 2 || abs(m.initialPos - m.finalPos) == 3|| abs(m.initialPos - m.finalPos) == 4)){
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
  int evaluate(){
    return evaluation;
  }
  void changeCastle (bool isBlack, int moveType, int finalsquare, int initialsquare){
    if (finalsquare == 0 || initialsquare == 0){
      castle[0][0] = false;
    }
    if (finalsquare == 7 || initialsquare == 7){
      castle[0][1] = false;
    }
    if (finalsquare == 56 || initialsquare == 56){
      castle[1][0] = false;
    }
    if (finalsquare == 63 || initialsquare == 63){
      castle[1][1] = false;
    }
    if (moveType == 5){
      castle[isBlack][0] = false;
      castle[isBlack][1] = false;
    }
  }
  int negamax (int alpha, int beta, int depth, bool isBlack){
    if (depth == 0) return evaluate();
    moveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
	if (isBlack) return -5000;
	else return 5000;
      }
    }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffsl(b);
	  bool [2][2] initCastle = castle;
	  changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].initialPos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].initialPos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].initialPos, sq);
	  }
	  else {
	    makeKillMove(isBlack, move[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].initialPos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakeKillMove(isBlack, move[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].initialPos, sq);
	  }
	  castle = initCastle;
	  if( score >= beta ) return beta;   
	  if( score > alpha ) alpha = score;
	}
      }
    }
    ulong totalOccupied = occupied[0] | occupied[1];
    ulong castleRight, castleLeft;
    if (isBlack){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (castle[isBlack][0] && (totalOccupied & castleLeft) == 0){
      castle[isBlack][0] = false;
      makeCastle(isBlack, false);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, false);
      castle[isBlack][0] = true;
      if( score >= beta ) return beta;   
      if( score > alpha ) alpha = score;
    }
    if (castle[isBlack][1] && (totalOccupied & castleRight) == 0){
      castle[isBlack][1] = false;
      makeCastle(isBlack, true);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, true);
      castle[isBlack][1] = true;
      if( score >= beta ) return beta;   
      if( score > alpha ) alpha = score;
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (int b = moves[movePieceIdx].set & totalOccupied; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	bool [2][2] initCastle = castle;
	changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].initialPos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(isBlack, 6, moves[movePieceIdx].initialPos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakePawnPromotion(isBlack, 6, moves[movePieceIdx].initialPos, sq);
	}
	else {
	  makeQuietMove(isBlack, move[movePieceIdx].pieceType, moves[movePieceIdx].initialPos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakeQuietMove(isBlack, move[movePieceIdx].pieceType, moves[movePieceIdx].initialPos, sq);
	}
	castle = initCastle;
	if( score >= beta ) return beta;   
	if( score > alpha ) alpha = score;
      }
    }
    return alpha;
  }

  void negaDriver (bool isBlack){
    int alpha = int.min;
    int beta = int.max;
    int depth = currDepth;
    moveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int i = 0; i < firstSaveSize; i ++){
      if (isBlack)
	bestMoves[i] = move(-1, -1, -1, -1, int.max);
      else
	bestMoves[i] = move(-1, -1, -1, -1, int.min);
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
	assert(false);
      }
    }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffsl(b);
	  bool [2][2] initCastle = castle;
	  changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].initialPos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].initialPos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].initialPos, sq);
	    insertMove(move(moves[movePieceIdx].initialPos, sq, 0, killPiece, score), isBlack);
	  }
	  else {
	    makeKillMove(isBlack, move[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].initialPos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakeKillMove(isBlack, move[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].initialPos, sq);
	    insertMove(move(moves[movePieceIdx].initialPos, sq, moves[movePieceIdx].pieceType, killPiece, score), isBlack);
	  }
	  castle = initCastle;
	  if( score >= beta ) return;   
	  if( score > alpha ) alpha = score;
	}
      }
    }
    ulong totalOccupied = occupied[0] | occupied[1];
    ulong castleRight, castleLeft;
    if (isBlack){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (castle[isBlack][0] && (totalOccupied & castleLeft) == 0){
      castle[isBlack][0] = false;
      makeCastle(isBlack, false);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, false);
      castle[isBlack][0] = true;
      if( score >= beta ) return;   
      if( score > alpha ) alpha = score;
      if (isBlack){
	insertMove(move(59, 63, 5, 6, score), isBlack);
      }
      else {
	insertMove(move(3, 7, 5, 6, score), isBlack);
      }
    }
    if (castle[isBlack][1] && (totalOccupied & castleRight) == 0){
      castle[isBlack][1] = false;
      makeCastle(isBlack, true);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, true);
      castle[isBlack][1] = true;
      if( score >= beta ) return;   
      if( score > alpha ) alpha = score;
      if (isBlack){
	insertMove(move(59, 56, 5, 6, score), isBlack);
      }
      else {
	insertMove(move(3, 0, 5, 6, score), isBlack);
      }
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (int b = moves[movePieceIdx].set & totalOccupied; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	bool [2][2] initCastle = castle;
	changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].initialPos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(isBlack, 6, moves[movePieceIdx].initialPos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakePawnPromotion(isBlack, 6, moves[movePieceIdx].initialPos, sq);
	}
	else {
	  makeQuietMove(isBlack, move[movePieceIdx].pieceType, moves[movePieceIdx].initialPos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakeQuietMove(isBlack, move[movePieceIdx].pieceType, moves[movePieceIdx].initialPos, sq);
	  insertMove(move(moves[movePieceIdx].initialPos, sq, moves[movePieceIdx].pieceType, 6, score), isBlack);
	}
	castle = initCastle;
	if( score >= beta ) return;   
	if( score > alpha ) alpha = score;
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
  state.currDepth = 6;
  while (true){
    SysTime start = Clock.currTime();
    state.negaDriver(false);
    state.makeMove(state.bestMoves[4], false);
    SysTime end = Clock.currTime();
    state.print();
    writeln(end-start);
    state.negaDriver(true);
    state.makeMove(state.bestMoves[4], true);
    SysTime end2 = Clock.currTime();
    state.print();
    writeln(end2 - end);
  }
}

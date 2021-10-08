

import std.stdio;
import piece_maps.d;

extern (C) int ffsl(long a);

const int firstSaveSize = 5;
const int seconSaveSize = 5;

struct MoveSet {
  int pieceType;
  ulong set;
  int piecePos;
  this (int t, ulong s, int pos){
    pieceType = t;
    set = s;
    piecePos = pos;
  }
}
struct Move {
  
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

data [ulong] transpositionTable;

struct data {
  Move move;
  int depth;
  this (Move m, int d){
    move = m;
    depth = d;
  }
}

struct Chess_state {
  
  int currDepth;
  Move bestMove;
  
  ulong [2] occupied; // white then black
  ulong [6][2] pieces;
  int castle; 
  int evaluation;
  ulong hash;

  Move [firstSaveSize] bestMoves; //best 5, worst to best

  void insertMove (Move m){
    if (bestMoves[0].score < m.score){
      bestMoves[0] = m;
    }
    else {
      return;
    }
    
    for (int i = 1; i < firstSaveSize && bestMoves[i].score < bestMoves[i-1].score; i ++){
      Move temp = bestMoves[i];
      bestMoves[i] = bestMoves[i-1];
      bestMoves[i-1] = temp;
    }
  }
  
  this (bool a){
    castle = 15; //0 for none, +1 for white left, +2 for white right, +4 for black left, +8 for black right
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
    hash = 6538936742870397337uL;
  }
  void setHash(){
    hash = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	hash ^= randomPieceNums[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	hash ^= randomPieceNums[1][i][sq];
      }
    }
    hash ^= randomCastleFlags[castle];
    hash ^= isBlackTurn;
    writeln(hash);
  }

  this (ulong a, ulong b, int c, ulong d, ulong e, ulong f, ulong g, ulong h, ulong i, ulong j, ulong k, ulong l, ulong m, ulong n, ulong o){
    occupied[0] = a; occupied[1] = b; evaluation = c; pieces[0][0] = d; pieces[0][1] = e; pieces[0][2] = f;  pieces[0][3] = g; pieces[0][4] = h; pieces[0][5] = i; pieces[1][0] = j; pieces[1][1] = k; pieces[1][2] = l; pieces[1][3] = m; pieces[1][4] = n; pieces[1][5] = o;
    castle = 15;
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

  int count (ulong b){
    int n = 0;
    while (b != 0){
      n += (b%2);
      b /= 2;
    }
    return n;
  }

  void assert_state(int num, bool isBlack){
    // assert_castle();
    if ((pieces[0][5] & (pieces[0][5]-1)) != 0){
      writeln(num);
      print();
      writeln(castle);
    }
    if (count(pieces[0][3]) > 2){
      writeln(num);
      print();
      writeln(castle);
    }
    assert((pieces[0][5] & (pieces[0][5]-1)) == 0);
    assert((pieces[1][5] & (pieces[1][5]-1)) == 0);
    assert(count(pieces[0][1]) <= 2);
    assert(count(pieces[1][1]) <= 2);
    assert(count(pieces[0][2]) <= 2);
    assert(count(pieces[1][2]) <= 2);
    assert(count(pieces[0][3]) <= 2);
    assert(count(pieces[1][3]) <= 2);
    if (count(pieces[0][0]) > 8){
      print();
      writeln(num);
    }
    assert(count(pieces[0][0]) <= 8);
    assert(count(pieces[1][0]) <= 8);
    for (int i = 0; i < 6; i ++){
      for (int j = i+1; j < 6; j ++){
	ulong x = pieces[0][i] & pieces[0][j];
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
    if (calcEval != evaluation){
      print();
      writeln(num);
      writeln(castle);
    }
    assert(calcEval == evaluation);
    ulong hashEval = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	hashEval ^= randomPieceNums[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffsl(b);
	hashEval ^= randomPieceNums[1][i][sq];
      }
    }
    if (isBlack){
      hashEval ^= isBlackTurn;
    }
    hashEval ^= randomCastleFlags[castle];
    // if (hashEval != hash){
    //   writeln(num);
    //   print();
    // }
    // assert(hashEval == hash);
  }
  
  ulong pieceMoves (ulong occupied, int type, int pos){
    assert (type != 0);
    ulong attacks = pieceAttacks[type][pos];
    for (ulong b = occupied & blockersBeyond[type][pos]; b != 0; b &= (b-1)){
      int sq = ffsl(b);
      attacks &= ~arrBehind[pos][sq];
    } 
    return attacks;
  }
  
  ulong pawnMoves (ulong totalOccupied, int pos, bool isBlack){
    ulong attacks = 0;
    if (isBlack){
      attacks = (1uL << (pos-8))&(~totalOccupied);
      if (pos/8 == 6 && attacks != 0){
	attacks |= (1uL << (pos-16))&(~totalOccupied);
      }
    }
    else {
      attacks = (1uL << (pos+8))&(~totalOccupied);
      if (pos/8 == 1 && attacks != 0){
	attacks |= (1uL << (pos+16))&(~totalOccupied);
      }
    }
    attacks |= pawnAttacks[isBlack][pos]&(occupied[(!isBlack)]);
    return attacks;
  }

  void assert_castle(){
    import std.conv;
    if ((castle & 1) != 0){// 
      assert(ffsl(pieces[0][5]) == 3);
      assert((pieces[0][3] | (1uL << 7)) != 0);
    }
    if ((castle & 2) != 0){
      assert(ffsl(pieces[0][5]) == 3);
      assert((pieces[0][3] | (1uL << 0)) != 0);
    }
    if ((castle & 4) != 0){
      assert(ffsl(pieces[1][5]) == 59);
      assert((pieces[1][3] | (1uL << 63)) != 0);
    }
    if ((castle & 8) != 0){
      assert(ffsl(pieces[1][5]) == 59);
      assert((pieces[1][3] | (1uL << 56)) != 0);
    }
  }

  void makeCastle (bool isBlack, bool isRight){
    if (isBlack){
      if (isRight){
	ulong a = (1uL << 57)|(1uL << 59);
	ulong b = (1uL << 56)|(1uL << 58);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation -= positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
	hash ^= randomPieceNums[1][5][57] ^ randomPieceNums[1][5][59] ^ randomPieceNums[1][3][58] ^ randomPieceNums[1][3][56];
      }
      else {
	ulong a = (1uL << 61)|(1uL << 59);
	ulong b = (1uL << 63)|(1uL << 60);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation -= positionEval[1][5][61] - positionEval[1][5][59] + positionEval[1][3][60] - positionEval[1][3][63];
	hash ^= randomPieceNums[1][5][61] ^ randomPieceNums[1][5][59] ^ randomPieceNums[1][3][60] ^ randomPieceNums[1][3][63];
      }
    }
    else {
      if (isRight){
	ulong a = (1uL << 1)|(1uL << 3);
	ulong b = (1uL << 0)|(1uL << 2);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation += positionEval[0][5][1] - positionEval[0][5][3] + positionEval[0][3][2] - positionEval[0][3][0];
	hash ^= randomPieceNums[0][5][1] ^ randomPieceNums[0][5][3] ^ randomPieceNums[0][3][2] ^ randomPieceNums[0][3][0];
      }
      else {
	ulong a = (1uL << 5)|(1uL << 3);
	ulong b = (1uL << 7)|(1uL << 4);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation += positionEval[0][5][5] - positionEval[0][5][3] + positionEval[0][3][4] - positionEval[0][3][7];
	hash ^= randomPieceNums[0][5][5] ^ randomPieceNums[0][5][3] ^ randomPieceNums[0][3][4] ^ randomPieceNums[0][3][7];
      }
    }
  }
  
  void unmakeCastle (bool isBlack, bool isRight){
    if (isBlack){
      if (isRight){
	ulong a = (1uL << 57)|(1uL << 59);
	ulong b = (1uL << 56)|(1uL << 58);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation += positionEval[1][5][57] - positionEval[1][5][59] + positionEval[1][3][58] - positionEval[1][3][56];
      }
      else {
	ulong a = (1uL << 61)|(1uL << 59);
	ulong b = (1uL << 63)|(1uL << 60);
	pieces[1][5] ^= a;
	pieces[1][3] ^= b;
	occupied[1] ^= a|b;
	evaluation += positionEval[1][5][61] - positionEval[1][5][59] + positionEval[1][3][60] - positionEval[1][3][63];
      }
    }
    else {
      if (isRight){
	ulong a = (1uL << 1)|(1uL << 3);
	ulong b = (1uL << 0)|(1uL << 2);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation -= positionEval[0][5][1] - positionEval[0][5][3] + positionEval[0][3][2] - positionEval[0][3][0];
      }
      else {
	ulong a = (1uL << 5)|(1uL << 3);
	ulong b = (1uL << 7)|(1uL << 4);
	pieces[0][5] ^= a;
	pieces[0][3] ^= b;
	occupied[0] ^= a|b;
	evaluation -= positionEval[0][5][5] - positionEval[0][5][3] + positionEval[0][3][4] - positionEval[0][3][7];
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
    hash ^= randomPieceNums[isBlack][4][finalPos] ^ randomPieceNums[isBlack][0][initialPos];
    if (killType < 6){
      pieces[(!isBlack)][killType] ^= fipos;
      occupied[(!isBlack)] ^= fipos;
      evalChange += positionEval[(!isBlack)][killType][finalPos];
      hash ^= randomPieceNums[(!isBlack)][killType][finalPos];
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
    hash ^= randomPieceNums[isBlack][type][finalPos] ^ randomPieceNums[isBlack][type][initialPos];
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
    hash ^= randomPieceNums[isBlack][playType][finalPos] ^ randomPieceNums[isBlack][playType][initialPos] ^ randomPieceNums[(!isBlack)][killType][finalPos];
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

  bool squareIsUnderAttack (int sq, bool isBlack, ulong tolOccupied){
    ulong pos = (1uL << sq);
    return (pieceAttacks[1][sq] & pieces[isBlack][1]) != 0 || //attacked by knight
      (pawnAttacks[(!isBlack)][sq] & pieces[isBlack][0]) != 0 || //attacked by pawn WRONG
      (pieceMoves(tolOccupied, 3, sq) & (pieces[isBlack][3] | pieces[isBlack][4])) != 0 || //attacked by rook or queen
      (pieceMoves(tolOccupied, 2, sq) & (pieces[isBlack][2] | pieces[isBlack][4])) != 0 || //attacked by bishop or queen
      (pieceMoves(tolOccupied, 5, sq) & pieces[isBlack][5]) != 0; //attacked by king
  }
  

  bool squareIsUnderAttack2 (ulong pos, bool isBlack, ulong tolOccupied){
    int sq = ffsl(pos);
    return (pieceAttacks[1][sq] & pieces[isBlack][1]) != 0 || //attacked by knight
      (pawnAttacks[(!isBlack)][sq] & pieces[isBlack][0]) != 0 || //attacked by pawn WRONG
      (pieceMoves(tolOccupied, 3, sq) & (pieces[isBlack][3] | pieces[isBlack][4])) != 0 || //attacked by rook or queen
      (pieceMoves(tolOccupied, 2, sq) & (pieces[isBlack][2] | pieces[isBlack][4])) != 0 || //attacked by bishop or queen
      (pieceMoves(tolOccupied, 5, sq) & pieces[isBlack][5]) != 0; //attacked by king
  }
  
  void makeMove(Move m, bool isBlack){
    import std.math;
    if (m.playType == 5 && (abs(m.initialPos - m.finalPos) == 2)){
      if (isBlack){
	assert (m.initialPos == 59);
	if (m.finalPos == 57){
	  makeCastle(true, true);
	}
	else if (m.finalPos == 61){
	  makeCastle(true, false);
	}
	else {
	  assert(false);
	}
      }
      else {
	assert (m.initialPos == 3);
	if (m.finalPos == 1){
	  makeCastle(false, true);
	}
	else if (m.finalPos == 5){
	  makeCastle(false, false);
	}
	else {
	  assert(false);
	}
      }
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      return;
    }
    if (m.playType == 0 && ((m.finalPos >= 56 && (!isBlack)) || (m.finalPos <= 7 && (isBlack)))){
      makePawnPromotion(isBlack, m.killType, m.initialPos, m.finalPos);
      return;
    }
    if (m.killType == 6) makeQuietMove(isBlack, m.playType, m.initialPos, m.finalPos);
    else makeKillMove(isBlack, m.playType, m.killType, m.initialPos, m.finalPos);
    hash ^= randomCastleFlags[castle];
    if (m.playType == 5){
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
    }
    if (m.initialPos == 0 || m.finalPos == 0){
      castle &= (13);
    }
    else if (m.initialPos == 7 || m.finalPos == 7){
      castle &= (14);
    }
    else if (m.initialPos == 56 || m.finalPos == 56){
      castle &= (7);
    }
    else if (m.initialPos == 63 || m.finalPos == 63){
      castle &= (11);
    }
    hash ^= randomCastleFlags[castle];
  }
  int quiesce (int alpha, int beta, bool isBlack){ //Do I really care about hash?
    int stand_pat = evaluate(isBlack);
    if (stand_pat >= beta){
      return beta;
    }
    if (stand_pat > alpha){
      alpha = stand_pat;
    }
    MoveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
	return 5000;
      }
    }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffsl(b);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -quiesce( -beta, -alpha, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  else {
	    makeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -quiesce( -beta, -alpha, (!isBlack));
	    unmakeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  if( score >= beta ) return beta;   
	  if( score > alpha ) alpha = score;
	}
      }
    }
    return alpha;
  }
  int evaluate(bool isBlack){
    if (isBlack) return -evaluation;
    else return evaluation;
  }
  void changeCastle (bool isBlack, int moveType, int finalsquare, int initialsquare){
    hash ^= randomCastleFlags[castle];
    if (((castle & 2) != 0) && (finalsquare == 0 || initialsquare == 0)){
      castle &= 13;
    }
    if (((castle & 1) != 0) && (finalsquare == 7 || initialsquare == 7)){
      castle &= 14;
    }
    if (((castle & 8) != 0) && (finalsquare == 56 || initialsquare == 56)){
      castle &= 7;
    }
    if (((castle & 4) != 0) && (finalsquare == 63 || initialsquare == 63)){
      castle &= 11;
    }
    if (moveType == 5){
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
    }
    hash ^= randomCastleFlags[castle];
  }
  
  MoveSet [16] genMoves (bool isBlack){
    MoveSet [16] moves;
    //each piece one by one
    int idx = 0;
    ulong occupied = occupied[0] | occupied[1];
    for (ulong b = pieces[isBlack][0]; b != 0; b &= (b-1), idx ++){
      int sq = ffsl(b);
      moves[idx] = MoveSet(0, pawnMoves(occupied, sq, isBlack), sq);
    }
    for (int j = 1; j < 6; j ++){
      for (ulong b = pieces[isBlack][j]; b != 0; b &= (b-1), idx ++){
	int sq = ffsl(b);
	moves[idx] = MoveSet(j, pieceMoves(occupied, j, sq), sq);
      }
    }
    return moves;
  }

  bool isCastlePossible (bool isBlack, bool isRight){
    bool isWhite = !isBlack;
    ulong tolOccupied = occupied[1] | occupied[0];
    if (isBlack){
      if (isRight){
	return !(squareIsUnderAttack(59, isWhite, tolOccupied) || squareIsUnderAttack(58, isWhite, tolOccupied) || squareIsUnderAttack(57, isWhite, tolOccupied));
      }
      else {
	return !(squareIsUnderAttack(59, isWhite, tolOccupied) || squareIsUnderAttack(60, isWhite, tolOccupied) || squareIsUnderAttack(61, isWhite, tolOccupied));
      }
    }
    else {
      if (isRight){
	return !(squareIsUnderAttack(3, isWhite, tolOccupied) || squareIsUnderAttack(2, isWhite, tolOccupied) || squareIsUnderAttack(1, isWhite, tolOccupied));
      }
      else {
	return !(squareIsUnderAttack(3, isWhite, tolOccupied) || squareIsUnderAttack(4, isWhite, tolOccupied) || squareIsUnderAttack(5, isWhite, tolOccupied));
      }
    }
  }
  
  int negamax (int alpha, int beta, int depth, bool isBlack){
    hash ^= isBlackTurn;
    // assert_state(1, isBlack);
    import std.math;
    Move bestMove = Move(-1, -1, -1, -1, -1);
    // if (hash in transpositionTable){
    //   data d = transpositionTable[hash];
    //   if (d.depth >= depth){
    // 	// writeln("1 returned with score ", d.move.score);
    // 	return d.move.score;
    //   }
    //   else {
    // 	if (d.move.playType == 5 && abs(d.move.initialPos - d.move.finalPos) == 2){
    // 	  int score;
    // 	  int prev = castle;
    // 	  ulong initHash = hash;
    // 	  hash ^= randomCastleFlags[castle];
    // 	  switch (d.move.finalPos){
    // 	  case 1:
    // 	    castle &= 3;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(false, true);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(false, true);
    // 	    break;
    // 	  case 5:
    // 	    castle &= 3;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(false, false);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(false, false);
    // 	    break;
    // 	  case 57:
    // 	    castle &= 12;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(true, true);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(true, true);
    // 	    break;
    // 	  case 61:
    // 	    castle &= 12;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(true, false);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(true, false);
    // 	    break;
    // 	  default:
    // 	    assert(false);
    // 	  }
    // 	  hash = initHash;
    // 	  castle = prev;
    // 	  if( score >= beta ) {
    // 	    d.move.score = score;
    // 	    transpositionTable[hash] = data(d.move, depth);
    // 	    // writeln("2 beta cutoff, score is ", score, "beta is ", beta);
    // 	    return beta;
    // 	  }  
    // 	  if( score > alpha ) {
    // 	    alpha = score;
    // 	    bestMove = d.move;
    // 	  }
    // 	}
    // 	else{
    // 	  int initCastle = castle;
    // 	  ulong initHash = hash;
    // 	  int score;
    // 	  changeCastle(isBlack, d.move.playType, d.move.finalPos, d.move.initialPos);
    // 	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    // 	      makePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	      unmakePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	  }
    // 	  else {
    // 	    if (d.move.killType == 6){
    // 	      makeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    // 	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	      unmakeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    // 	    }
    // 	    else {
    // 	      makeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	      unmakeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	    }
    // 	  }
    // 	  castle = initCastle;
    // 	  hash = initHash;
    // 	  if( score >= beta ) {
    // 	    d.move.score = score;
    // 	    transpositionTable[hash] = data(d.move, depth);
    // 	    // writeln("3 beta cutoff, score is ", score, "beta is ", beta);
    // 	    return beta;
    // 	  }   
    // 	  if( score > alpha ) {
    // 	    alpha = score;
    // 	    bestMove = d.move;
    // 	  }
    // 	}
    //   }
    // }
    // writeln("nega iteration :", depth);
    ulong initHash = hash;
    if (depth == 0) {
      return quiesce(alpha, beta, isBlack);
    }
    hash = initHash;
    ulong totalOccupied = occupied[0] | occupied[1];
    if (squareIsUnderAttack2(pieces[(!isBlack)][5], isBlack, totalOccupied)) return 5000;
    MoveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    // for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
    //   if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
    //     return 5000;
    //   }
    // }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffsl(b);
	  int initCastle = castle;
	  initHash = hash;
	  changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  else {
	    makeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  castle = initCastle;
	  hash = initHash;
	  if( score >= beta ) {
	    transpositionTable[hash] = data(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, score), depth);
	    // writeln("4 beta cutoff, score is ", score, "beta is ", beta);
	    return beta;
	  }   
	  if( score > alpha ) {
	    alpha = score;
	    bestMove = Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, score);
	  }
	}
      }
    }
    ulong castleRight, castleLeft;
    if (isBlack){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (((((castle & 1) != 0) && (!isBlack)) || (((castle & 4) != 0) && isBlack))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(isBlack, false)){
      int prev = castle;
      initHash = hash;
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(isBlack, false);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, false);
      hash = initHash;
      castle = prev;
      if( score >= beta ) {
	if (isBlack)
	  transpositionTable[hash] = data(Move(59, 61, 5, 6, score) , depth);
	else
	  transpositionTable[hash] = data(Move(3, 5, 5, 6, score) , depth);
	// writeln("5 castle beta cutoff, score is ", score, " beta is ", beta);
	return beta;
      }   
      if( score > alpha ) {
	alpha = score;
	if (isBlack)
	  bestMove = Move(59, 61, 5, 6, score);
	else
	  bestMove = Move(3, 5, 5, 6, score);
      }
    }
    if (((((castle & 2) != 0) && (!isBlack)) || (((castle & 8) != 0) && isBlack)) && (totalOccupied & castleRight) == 0&& isCastlePossible(isBlack, true)){
      int prev = castle;
      initHash = hash;
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(isBlack, true);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, true);
      hash = initHash;
      castle = prev;
      if( score >= beta ) {
	if (isBlack)
	  transpositionTable[hash] = data(Move(59, 57, 5, 6, score) , depth);
	else
	  transpositionTable[hash] = data(Move(3, 1, 5, 6, score) , depth);
	// writeln("6 castle beta cutoff, score is ", score, " beta is ", beta);
	return beta;
      }   
      if( score > alpha ) {
	alpha = score;
	if (isBlack)
	  bestMove = Move(59, 57, 5, 6, score);
	else
	  bestMove = Move(3, 1, 5, 6, score);
      }
    }
    
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (ulong b = moves[movePieceIdx].set & (~totalOccupied); b != 0; b &= (b-1)){
	int sq = ffsl(b);
        int initCastle = castle;
        initHash = hash;
	changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	}
	else {
	  makeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	}
	castle = initCastle;
	hash = initHash;
	if( score >= beta ) {
	  transpositionTable[hash] = data(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, score) , depth);
	  // writeln("7 quite beta cutoff, score is ", score, " beta is ", beta);
	  return beta;
	}   
	if( score > alpha ) {
	  alpha = score;
	  bestMove = Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, score);
	}
      }
    }
    if (bestMove.initialPos != -1){
      bestMove.score = alpha;
      transpositionTable[hash] = data(bestMove, depth);
    }
    // writeln(alpha);
    // writeln("alpha cutoff, alpha is ", alpha );
    return alpha;
  }

  void negaDriver (bool isBlack){
    hash ^= isBlackTurn;
    // assert_state(3, isBlack);
    int alpha = -10000;
    int beta = 10000;
    int depth = currDepth;
    import std.math;
    // if (hash in transpositionTable){
    //   data d = transpositionTable[hash];
    //   if (d.depth >= depth){
    //     insertMove(d.move);
    //   }
    //   else {
    // 	if (d.move.playType == 5 && abs(d.move.initialPos - d.move.finalPos) == 2){
    // 	  int score;
    // 	  int prev = castle;
    // 	  ulong initHash = hash;
    // 	  hash ^= randomCastleFlags[castle];
    // 	  switch (d.move.finalPos){
    // 	  case 1:
    // 	    castle &= 3;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(false, true);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(false, true);
    // 	    break;
    // 	  case 5:
    // 	    castle &= 3;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(false, false);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(false, false);
    // 	    break;
    // 	  case 57:
    // 	    castle &= 12;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(true, true);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(true, true);
    // 	    break;
    // 	  case 61:
    // 	    castle &= 12;
    // 	    hash ^= randomCastleFlags[castle];
    // 	    makeCastle(true, false);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakeCastle(true, false);
    // 	    break;
    // 	  default:
    // 	    assert(false);
    // 	  }
    // 	  hash = initHash;
    // 	  castle = prev;
    // 	  if( score > alpha ) {
    // 	    alpha = score;
    // 	    bestMove = d.move;
    // 	  }
    // 	}
    // 	else{
    // 	  int initCastle = castle;
    // 	  ulong initHash = hash;
    // 	  int score;
    // 	  changeCastle(isBlack, d.move.playType, d.move.finalPos, d.move.initialPos);
    // 	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    // 	    makePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	    unmakePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	  }
    // 	  else {
    // 	    if (d.move.killType == 6){
    // 	      makeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    // 	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	      unmakeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    // 	    }
    // 	    else {
    // 	      makeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    // 	      unmakeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    // 	    }
    // 	  }
    // 	  castle = initCastle;
    // 	  hash = initHash;
    // 	  if( score > alpha )  alpha = score;
    // 	}
    //   }
    // }
    MoveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int i = 0; i < firstSaveSize; i ++){
      bestMoves[i] = Move(-1, -1, -1, -1, int.min);
    }
    // for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
    //   if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
    // 	assert(false);
    //   }
    // }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffsl(b);
	  int initCastle = castle;
	  ulong initHash = hash;
	  changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    insertMove(Move(moves[movePieceIdx].piecePos, sq, 0, killPiece, score));
	  }
	  else {
	    makeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    insertMove(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, score));
	  }
	  castle = initCastle;
	  hash = initHash;  
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
    if (((((castle & 1) != 0) && (!isBlack)) || (((castle & 4) != 0) && isBlack))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(isBlack, false)){
      int prev = castle;
      ulong initHash = hash;
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(isBlack, false);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, false);
      hash = initHash;
      castle = prev;
      if( score > alpha ) alpha = score;
      if (isBlack){
	insertMove(Move(59, 61, 5, 6, score));
      }
      else {
	insertMove(Move(3, 5, 5, 6, score));
      }
    }
    if (((((castle & 2) != 0) && (!isBlack)) || (((castle & 8) != 0) && isBlack)) && (totalOccupied & castleRight) == 0&& isCastlePossible(isBlack, true)){
      int prev = castle;
      ulong initHash = hash;
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(isBlack, true);
      int score = -negamax( -beta, -alpha, depth-1, (!isBlack));
      unmakeCastle(isBlack, true);
      hash = initHash;
      castle = prev;
      if( score > alpha ) alpha = score;
      if (isBlack){
	insertMove(Move(59, 57, 5, 6, score));
      }
      else {
	insertMove(Move(3, 1, 5, 6, score));
      }
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (ulong b = moves[movePieceIdx].set & (~totalOccupied); b != 0; b &= (b-1)){
	int sq = ffsl(b);
	int initCastle = castle;
	ulong initHash = hash;
	changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	  insertMove(Move(moves[movePieceIdx].piecePos, sq, 0, 6, score));
	}
	else {
	  makeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  insertMove(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, score));
	}
	castle = initCastle;
	hash = initHash;  
	if( score > alpha ) alpha = score;
      }
    }
    transpositionTable[hash] = data(bestMoves[firstSaveSize-1], depth);
  }
}

void printMoves (MoveSet [16] moves){
  for (int i = 0;  moves[i].pieceType != 5; i ++){
    writeln(moves[i].pieceType);
    printBoard(moves[i].set);
  }
}

Chess_state state = Chess_state(true);

void main (){
  
  preProcess();
  state.setHash();
  import std.datetime.systime : SysTime, Clock;
  state.print();
  state.currDepth = 2;
  for  (int i = 0; i < 1; i ++){
    SysTime start = Clock.currTime();
    state.negaDriver(false);
    state.makeMove(state.bestMoves[4], false);
    SysTime end = Clock.currTime();
    writeln(end-start);
    state.print();
    state.negaDriver(true);
    state.makeMove(state.bestMoves[4], true);
    SysTime end2 = Clock.currTime();
    writeln(end2-end);
    state.print();
  }
}

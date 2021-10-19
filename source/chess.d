
module chess.d;
import std.stdio;
import piece_maps.d;

extern (C) int ffsl(long a);

int ffslminusone (long a){
  return ffsl(a) - 1;
}


__gshared bool timeExceeded;
__gshared bool flipBoard = false;

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


struct data {
  Move move;
  int depth;
  this (Move m, int d){
    move = m;
    depth = d;
  }
}

struct Chess_state  {
  
  int currDepth;
  // Move bestMove;
  
  ulong [2] occupied; // white then black
  ulong [6][2] pieces;
  ulong enPasant;
  int castle; 
  int evaluation;
  ulong hash;
  bool isBlackTurn;
  

  void reset(){
    resetVals();
  }

  void resetVals(){
    castle = 15; //0 for none, +1 for white left, +2 for white right, +4 for black left, +8 for black right
    occupied[0] = 65535uL;
    occupied[1] = 18446462598732840960uL;
    evaluation = 0uL;
    pieces[0][0] = 65280uL;
    pieces[0][1] = 66uL;
    pieces[0][2] = 36uL;
    pieces[0][3] = 129uL;
    pieces[0][4] = 16uL;
    pieces[0][5] = 8uL;
    pieces[1][0] = 71776119061217280uL;
    pieces[1][1] = 4755801206503243776uL;
    pieces[1][2] = 2594073385365405696uL;
    pieces[1][3] = 9295429630892703744uL;
    pieces[1][4] = 1152921504606846976uL;
    pieces[1][5] = 576460752303423488uL;
    enPasant = 0uL;
    hash = 10249543995982554652uL;
  }
  
  this (bool lol){
    reset();
  }
  void setHash(){
    hash = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	hash ^= randomPieceNums[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	hash ^= randomPieceNums[1][i][sq];
      }
    }
    hash ^= randomCastleFlags[castle];
    if (isBlackTurn){
      hash ^= randomTurnNum;
    }
  }
  void setEval (){
    evaluation = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	evaluation += positionEval[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	evaluation -= positionEval[1][i][sq];
      }
    }
  }

  this (ulong [6][2] p, int c, int en, bool b){
    pieces = p;
    castle = c;
    if (en != 0)
      enPasant = (1uL << en);
    isBlackTurn = b;
    setHash();
    setEval();
  }
  
  void print (){
    // writeln(occupied[0], ", ", occupied[1], ", ", evaluation, ", ", pieces[0][0], ", ", pieces[0][1],", ", pieces[0][2], ", ", pieces[0][3], ", ", pieces[0][4], ", ", pieces[0][5], ", ", pieces[1][0], ", ", pieces[1][1], ", ", pieces[1][2], ", ", pieces[1][3], ", ", pieces[1][4], ", ", pieces[1][5]);
    writeln(getMini(pieces));
  }
  public static string getMini (ulong [6][2] pieces){
    string b = "\u2004";
    if (!flipBoard){
      for (int i = 63; i >= 0; i --){
	ulong pos = (1uL << i);
	bool flag = true;
	for (int j = 0; j < 6; j ++){
	  if ((pos & pieces[0][j]) != 0){
	    b ~= printPiece(j, true);
	    flag = false;
	    break;
	  }
	  else if ((pos & pieces[1][j]) != 0){
	    b ~= printPiece(j, false);
	    flag = false;
	    break;
	  }
	}
	if (flag){
	  b ~= "\u2003\u2009";
	  // write("  ");
	}
	if (i % 8 == 0 && i != 0){
	  // writeln();
	  b ~= "\n\u2004";
	}
      }
    }
    else {
      for (int i = 0; i < 64; i ++){
	ulong pos = (1uL << i);
	bool flag = true;
	for (int j = 0; j < 6; j ++){
	  if ((pos & pieces[0][j]) != 0){
	    b ~= printPiece(j, true);
	    flag = false;
	    break;
	  }
	  else if ((pos & pieces[1][j]) != 0){
	    b ~= printPiece(j, false);
	    flag = false;
	    break;
	  }
	}
	if (flag){
	  b ~= "\u2003\u2009";
	}
	if (i % 8 == 7 && i != 63){
	  b ~= "\n\u2004";
	}
      }
    }
    return b;
  }
  void print (int depth){
    writeln();
    for (int j = 0; j < depth; j ++){
      write("    ");
    }
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
	write(" ");
      }
      if (i % 8 == 0){
	writeln();
	for (int j = 0; j < depth; j ++){
	  write("    ");
	}
      }
    }
    writeln();
  }
  
  public static string printPiece (int piece, bool coloriswhite){
    if (coloriswhite){
      if (piece == 0){
	return "\u2659\u2004";
      }
      else if (piece == 1){
	return "\u2658\u2004";
      }
      else if (piece == 2){
	return "\u2657\u2004";
      }
      else if (piece == 3){
	return "\u2656\u2004";
      }
      else if (piece == 4){
	return "\u2655\u2004";
      }
      else if (piece == 5){
	return "\u2654\u2004";
      }
      else {
	assert (false);
      }
    }
    else {
      if (piece == 0){
	return "\u265F\u2004";
      }
      else if (piece == 1){
	return "\u265E\u2004";
      }
      else if (piece == 2){
	return "\u265D\u2004";
      }
      else if (piece == 3){
	return "\u265C\u2004";
      }
      else if (piece == 4){
	return "\u265B\u2004";
      }
      else if (piece == 5){
	return "\u265A\u2004";
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

  void assert_state(int num){
    assert_castle();
    assert((pieces[0][5] & (pieces[0][5]-1)) == 0);
    assert((pieces[1][5] & (pieces[1][5]-1)) == 0);
    assert(count(pieces[0][1]) <= 2);
    assert(count(pieces[1][1]) <= 2);
    assert(count(pieces[0][2]) <= 2);
    assert(count(pieces[1][2]) <= 2);
    assert(count(pieces[0][3]) <= 2);
    assert(count(pieces[1][3]) <= 2);
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
    assert(wcalc == occupied[0] && bcalc == occupied[1]);
    int calcEval = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	calcEval += positionEval[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	calcEval -= positionEval[1][i][sq];
      }
    }
    assert(calcEval == evaluation);
    ulong hashEval = 0;
    for (int i = 0; i < 6; i ++){
      for (ulong b = pieces[0][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	hashEval ^= randomPieceNums[0][i][sq];
      }
      for (ulong b = pieces[1][i]; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	hashEval ^= randomPieceNums[1][i][sq];
      }
    }
    if (isBlackTurn){
      hashEval ^= randomTurnNum;
    }
    hashEval ^= randomCastleFlags[castle];
    hashEval ^= enPasant;
    
    assert(hashEval == hash);
  }
  
  ulong pieceMoves (ulong occupied, int type, int pos){
    assert (type != 0);
    ulong attacks = pieceAttacks[type][pos];
    for (ulong b = occupied & blockersBeyond[type][pos]; b != 0; b &= (b-1)){
      int sq = ffslminusone(b);
      attacks &= ~arrBehind[pos][sq];
    } 
    return attacks;
  }
  
  ulong pawnMoves (ulong totalOccupied, int pos){
    ulong attacks = 0;
    if (isBlackTurn){
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
    attacks |= pawnAttacks[isBlackTurn][pos]&((occupied[(!isBlackTurn)]) | enPasant);
    return attacks;
  }

  void assert_castle(){
    import std.conv;
    if ((castle & 1) != 0){
      assert(ffslminusone(pieces[0][5]) == 3);
      assert((pieces[0][3] | (1uL << 7)) != 0);
    }
    if ((castle & 2) != 0){
      assert(ffslminusone(pieces[0][5]) == 3);
      assert((pieces[0][3] | (1uL << 0)) != 0);
    }
    if ((castle & 4) != 0){
      assert(ffslminusone(pieces[1][5]) == 59);
      assert((pieces[1][3] | (1uL << 63)) != 0);
    }
    if ((castle & 8) != 0){
      assert(ffslminusone(pieces[1][5]) == 59);
      assert((pieces[1][3] | (1uL << 56)) != 0);
    }
  }

  void makeEnPasant (int initialPos, int finalPos){
    ulong a = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlackTurn][0] ^= a;
    occupied[isBlackTurn] ^= a;
    ulong b;
    if (isBlackTurn){
      b = (1uL << (finalPos+8));
      evaluation -= positionEval[1][0][finalPos] - positionEval[1][0][initialPos] + positionEval[0][0][finalPos+8];
      hash ^= randomPieceNums[1][0][finalPos] ^ randomPieceNums[1][0][initialPos] ^ randomPieceNums[0][0][finalPos+8];
    }
    else {
      b = (1uL << (finalPos-8));
      evaluation += positionEval[0][0][finalPos] - positionEval[0][0][initialPos] + positionEval[1][0][finalPos-8];
      hash ^= randomPieceNums[0][0][finalPos] ^ randomPieceNums[0][0][initialPos] ^ randomPieceNums[1][0][finalPos-8];
    }
    occupied[!(isBlackTurn)] ^= b;
    pieces[!(isBlackTurn)][0] ^= b;
    isBlackTurn = !isBlackTurn;
    hash ^= randomTurnNum;
  }

  void unmakeEnPasant (int initialPos, int finalPos){
    ulong a = (1uL << initialPos)|(1uL << finalPos);
    isBlackTurn = !isBlackTurn;
    pieces[isBlackTurn][0] ^= a;
    occupied[isBlackTurn] ^= a;
    ulong b;
    if (isBlackTurn){
      b = (1uL << (finalPos+8));
      evaluation += positionEval[1][0][finalPos] - positionEval[1][0][initialPos] + positionEval[0][0][finalPos+8];
    }
    else {
      b = (1uL << (finalPos-8));
      evaluation -= positionEval[0][0][finalPos] - positionEval[0][0][initialPos] + positionEval[1][0][finalPos-8];
    }
    occupied[!(isBlackTurn)] ^= b;
    pieces[!(isBlackTurn)][0] ^= b;
  }

  void makeCastle (bool isRight){
    hash ^= enPasant;
    enPasant = 0uL;
    if (isBlackTurn){
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
    isBlackTurn = !isBlackTurn;
    hash ^= randomTurnNum;
  }
  
  void unmakeCastle (bool isRight){
    isBlackTurn = !isBlackTurn;
    if (isBlackTurn){
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

  void makePawnPromotion (int killType, int initialPos, int finalPos){
    hash ^= enPasant;
    enPasant = 0uL;
    ulong inpos = (1uL << initialPos);
    ulong fipos = (1uL << finalPos);
    pieces[isBlackTurn][0] ^= inpos;
    pieces[isBlackTurn][4] ^= fipos;
    occupied[isBlackTurn] ^= (inpos | fipos);
    int evalChange = 0;
    evalChange += positionEval[isBlackTurn][4][finalPos] - positionEval[isBlackTurn][0][initialPos];
    hash ^= randomPieceNums[isBlackTurn][4][finalPos] ^ randomPieceNums[isBlackTurn][0][initialPos];
    if (killType < 6){
      pieces[(!isBlackTurn)][killType] ^= fipos;
      occupied[(!isBlackTurn)] ^= fipos;
      evalChange += positionEval[(!isBlackTurn)][killType][finalPos];
      hash ^= randomPieceNums[(!isBlackTurn)][killType][finalPos];
    }
    if (isBlackTurn) evaluation -= evalChange;
    else evaluation += evalChange;
    isBlackTurn = !isBlackTurn;
    hash ^= randomTurnNum;
  }
  
  void unmakePawnPromotion (int killType, int initialPos, int finalPos){
    isBlackTurn = !isBlackTurn;
    ulong inpos = (1uL << initialPos);
    ulong fipos = (1uL << finalPos);
    pieces[isBlackTurn][0] ^= inpos;
    pieces[isBlackTurn][4] ^= fipos;
    occupied[isBlackTurn] ^= (inpos | fipos);
    int evalChange = positionEval[isBlackTurn][4][finalPos] - positionEval[isBlackTurn][0][initialPos];
    if (killType < 6){
      pieces[(!isBlackTurn)][killType] ^= fipos;
      occupied[(!isBlackTurn)] ^= fipos;
      evalChange += positionEval[(!isBlackTurn)][killType][finalPos];
    }
    if (isBlackTurn) evaluation += evalChange;
    else evaluation -= evalChange;
  }

  void makeQuietMove (int type, int initialPos, int finalPos){
    import std.math;
    hash ^= enPasant;
    enPasant = 0uL;
    if (type == 0 && abs(initialPos - finalPos) != 8){
      if (abs(initialPos - finalPos) != 16){
	makeEnPasant(initialPos, finalPos);
	return;
      }
      else {
	if (isBlackTurn){
	  enPasant = (1uL << (initialPos - 8));
	}
	else {
	  enPasant = (1uL << (initialPos + 8));
	}
	hash ^= enPasant;
      }
    }
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlackTurn][type] ^= change;
    occupied[isBlackTurn] ^= change;
    int evalChange = positionEval[isBlackTurn][type][finalPos] - positionEval[isBlackTurn][type][initialPos];
    hash ^= randomPieceNums[isBlackTurn][type][finalPos] ^ randomPieceNums[isBlackTurn][type][initialPos];
    if (isBlackTurn) evaluation -= evalChange;
    else evaluation += evalChange;
    isBlackTurn = !isBlackTurn;
    hash ^= randomTurnNum;
  }

  void unmakeQuietMove (int type, int initialPos, int finalPos){
    isBlackTurn = !isBlackTurn;
    import std.math;
    if (type == 0 && abs(initialPos - finalPos) != 8){
      if (abs(initialPos - finalPos) != 16){
	isBlackTurn = !isBlackTurn;
	unmakeEnPasant(initialPos, finalPos);
	return;
      }
    }
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlackTurn][type] ^= change;
    occupied[isBlackTurn] ^= change;
    int evalChange = positionEval[isBlackTurn][type][finalPos] - positionEval[isBlackTurn][type][initialPos];
    if (isBlackTurn) evaluation += evalChange;
    else evaluation -= evalChange;
  }
  
  void makeKillMove (int playType, int killType, int initialPos, int finalPos){
    hash ^= enPasant;
    enPasant = 0uL;
    ulong fipos = 1uL << finalPos;
    ulong change = (1uL << initialPos) | fipos;
    pieces[isBlackTurn][playType] ^= change;
    occupied[isBlackTurn] ^= change;
    occupied[(!isBlackTurn)] ^= fipos;
    pieces[(!isBlackTurn)][killType] ^= fipos;
    int evalChange = positionEval[isBlackTurn][playType][finalPos] - positionEval[isBlackTurn][playType][initialPos] + positionEval[(!isBlackTurn)][killType][finalPos];
    hash ^= randomPieceNums[isBlackTurn][playType][finalPos] ^ randomPieceNums[isBlackTurn][playType][initialPos] ^ randomPieceNums[(!isBlackTurn)][killType][finalPos];
    if (isBlackTurn) evaluation -= evalChange;
    else evaluation += evalChange;
    isBlackTurn = !isBlackTurn;
    hash ^= randomTurnNum;
  }

  void unmakeKillMove (int playType, int killType, int initialPos, int finalPos){
    isBlackTurn = !isBlackTurn;
    ulong fipos = 1uL << finalPos;
    ulong change = (1uL << initialPos) | fipos;
    pieces[isBlackTurn][playType] ^= change;
    occupied[isBlackTurn] ^= change;
    occupied[(!isBlackTurn)] ^= fipos;
    pieces[(!isBlackTurn)][killType] ^= fipos;
    int evalChange = positionEval[isBlackTurn][playType][finalPos] - positionEval[isBlackTurn][playType][initialPos] + positionEval[(!isBlackTurn)][killType][finalPos];
    if (isBlackTurn) evaluation += evalChange;
    else evaluation -= evalChange;
  }

  bool squareIsUnderAttack (int sq, bool isBlackTurn, ulong tolOccupied){
    ulong pos = (1uL << sq);
    return (pieceAttacks[1][sq] & pieces[isBlackTurn][1]) != 0 || //attacked by knight
      (pawnAttacks[(!isBlackTurn)][sq] & pieces[isBlackTurn][0]) != 0 || //attacked by pawn WRONG
      (pieceMoves(tolOccupied, 3, sq) & (pieces[isBlackTurn][3] | pieces[isBlackTurn][4])) != 0 || //attacked by rook or queen
      (pieceMoves(tolOccupied, 2, sq) & (pieces[isBlackTurn][2] | pieces[isBlackTurn][4])) != 0 || //attacked by bishop or queen
      (pieceMoves(tolOccupied, 5, sq) & pieces[isBlackTurn][5]) != 0; //attacked by king
  }
  

  bool squareIsUnderAttack2 (ulong pos, bool isBlackTurn, ulong tolOccupied){
    int sq = ffslminusone(pos);
    return (pieceAttacks[1][sq] & pieces[isBlackTurn][1]) != 0 || //attacked by knight
      (pawnAttacks[(!isBlackTurn)][sq] & pieces[isBlackTurn][0]) != 0 || //attacked by pawn WRONG
      (pieceMoves(tolOccupied, 3, sq) & (pieces[isBlackTurn][3] | pieces[isBlackTurn][4])) != 0 || //attacked by rook or queen
      (pieceMoves(tolOccupied, 2, sq) & (pieces[isBlackTurn][2] | pieces[isBlackTurn][4])) != 0 || //attacked by bishop or queen
      (pieceMoves(tolOccupied, 5, sq) & pieces[isBlackTurn][5]) != 0; //attacked by king
  }

  void makeMove(int initialPos, int finalPos){
    ulong inPos = (1uL << initialPos);
    ulong fiPos = (1uL << finalPos);
    if ((occupied[0] & inPos) != 0){
      for (int i = 0; i < 6; i ++){
	if ((pieces[0][i] & inPos) != 0){
	  for (int j = 0; j < 6; j ++){
	    if ((pieces[1][j] & fiPos) != 0){
	      makeMove(Move(initialPos, finalPos, i, j, 0));
	      return;
	    }
	  }
	  makeMove(Move(initialPos, finalPos, i, 6, 0));
	  return;
	}
      }
    }
    else{
      for (int i = 0; i < 6; i ++){
	if ((pieces[1][i] & inPos) != 0){
	  for (int j = 0; j < 6; j ++){
	    if ((pieces[0][j] & fiPos) != 0){
	      makeMove(Move(initialPos, finalPos, i, j, 0));
	      return;
	    }
	  }
	  makeMove(Move(initialPos, finalPos, i, 6, 0));
	  return;
	}
      }
    }
    assert(false, "invalid move");
  }
  
  void makeMove(Move m){
    import std.math;
    if (m.playType == 5 && (abs(m.initialPos - m.finalPos) == 2)){
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	assert (m.initialPos == 59);
	if (m.finalPos == 57){
	  makeCastle(true);
	}
	else if (m.finalPos == 61){
	  makeCastle(false);
	}
	else {
	  assert(false);
	}
      }
      else {
	assert (m.initialPos == 3);
	if (m.finalPos == 1){
	  makeCastle(true);
	}
	else if (m.finalPos == 5){
	  makeCastle(false);
	}
	else {
	  assert(false);
	}
      }
      return;
    }
    if (m.playType == 5){
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
    }
    hash ^= randomCastleFlags[castle];
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
    if (m.playType == 0 && ((m.finalPos >= 56 && (!isBlackTurn)) || (m.finalPos <= 7 && (isBlackTurn)))){
      makePawnPromotion(m.killType, m.initialPos, m.finalPos);
      return;
    }
    if (m.killType == 6) makeQuietMove(m.playType, m.initialPos, m.finalPos);
    else makeKillMove(m.playType, m.killType, m.initialPos, m.finalPos);
  }
  int quiesce (int alpha, int beta){ //Do I really care about hash?
    int stand_pat = evaluate();
    if (stand_pat >= beta){
      return beta;
    }
    if (stand_pat > alpha){
      alpha = stand_pat;
    }
    MoveSet [16] moves = genMoves();
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      if ((moves[movePieceIdx].set & pieces[(!isBlackTurn)][5]) != 0) {
	return 5000;
      }
    }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlackTurn)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffslminusone(b);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -quiesce( -beta, -alpha);
	    unmakePawnPromotion( killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  else {
	    makeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -quiesce( -beta, -alpha);
	    unmakeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  if( score >= beta ) return beta;   
	  if( score > alpha ) alpha = score;
	}
      }
    }
    return alpha;
  }
  int evaluate(){
    if (isBlackTurn) return -evaluation;
    else return evaluation;
  }
  void changeCastle (int moveType, int finalsquare, int initialsquare){
    hash ^= randomCastleFlags[castle];
    if (finalsquare == 0 || initialsquare == 0){
      castle &= 13;
    }
    if (finalsquare == 7 || initialsquare == 7){
      castle &= 14;
    }
    if (finalsquare == 56 || initialsquare == 56){
      castle &= 7;
    }
    if (finalsquare == 63 || initialsquare == 63){
      castle &= 11;
    }
    if (moveType == 5){
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
    }
    hash ^= randomCastleFlags[castle];
  }
  
  MoveSet [16] genMoves (){
    MoveSet [16] moves;
    //each piece one by one
    int idx = 0;
    ulong occupied = occupied[0] | occupied[1];
    for (ulong b = pieces[isBlackTurn][0]; b != 0; b &= (b-1), idx ++){
      int sq = ffslminusone(b);
      moves[idx] = MoveSet(0, pawnMoves(occupied, sq), sq);
    }
    for (int j = 1; j < 6; j ++){
      for (ulong b = pieces[isBlackTurn][j]; b != 0; b &= (b-1), idx ++){
	int sq = ffslminusone(b);
	moves[idx] = MoveSet(j, pieceMoves(occupied, j, sq), sq);
      }
    }
    return moves;
  }

  bool isCastlePossible (bool isRight){
    bool isWhite = !isBlackTurn;
    ulong tolOccupied = occupied[1] | occupied[0];
    if (isBlackTurn){
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

  
  int negamax (int alpha, int beta, int depth){
    // assert_state(1);
    int maxScore = -5000;
    import std.math;
    if (timeExceeded){
      return alpha;
    }
    Move bestMove = Move(-1, -1, -1, -1, -1);
    if (hash in transpositionTable){
      data d = transpositionTable[hash];
      if (d.depth >= depth){
    	return d.move.score;
      }
      else {
    	if (d.move.playType == 5 && abs(d.move.initialPos - d.move.finalPos) == 2){
    	  int score;
    	  int initCastle = castle;
    	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
    	  hash ^= randomCastleFlags[castle];
    	  switch (d.move.finalPos){
    	  case 1:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(true);
    	    break;
    	  case 5:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(false);
    	    break;
    	  case 57:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(true);
    	    break;
    	  case 61:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(false);
    	    break;
    	  default:
    	    assert(false);
    	  }
    	  hash = initHash;
    	  castle = initCastle;
	  enPasant = initEnPasant;
	  if (score >= maxScore){
	    maxScore = score;
	  }
    	  if( score >= beta ) {
    	    return beta;
    	  }  
    	  if( score > alpha ) {
    	    alpha = score;
    	    bestMove = d.move;
    	  }
    	}
    	else{
    	  int initCastle = castle;
    	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
    	  int score;
    	  changeCastle( d.move.playType, d.move.finalPos, d.move.initialPos);
    	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    	      makePawnPromotion(d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1);
    	      unmakePawnPromotion(d.move.killType, d.move.initialPos, d.move.finalPos);
    	  }
    	  else {
    	    if (d.move.killType == 6){
    	      makeQuietMove(d.move.playType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1);
    	      unmakeQuietMove(d.move.playType, d.move.initialPos, d.move.finalPos);
    	    }
    	    else {
    	      makeKillMove(d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1);
    	      unmakeKillMove(d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	    }
    	  }
    	  castle = initCastle;
    	  hash = initHash;
	  enPasant = initEnPasant;
	  if (score >= maxScore){
	    maxScore = score;
	  }
    	  if( score >= beta ) {
    	    return beta;
    	  }   
    	  if( score > alpha ) {
    	    alpha = score;
    	    bestMove = d.move;
    	  }
    	}
      }
    }
    ulong initHash = hash;
    ulong initEnPasant = enPasant;
    if (depth == 0) {
      return quiesce(alpha, beta);
    }
    hash = initHash;
    enPasant = initEnPasant;
    ulong totalOccupied = occupied[0] | occupied[1];
    if (squareIsUnderAttack2(pieces[(!isBlackTurn)][5], isBlackTurn, totalOccupied)) return 5000;
    MoveSet [16] moves = genMoves();
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlackTurn)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffslminusone(b);
	  int initCastle = castle;
	  initHash = hash;
	  initEnPasant = enPasant;
	  changeCastle(moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1);
	    unmakePawnPromotion(killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  else {
	    makeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1);
	    unmakeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  castle = initCastle;
	  enPasant = initEnPasant;
	  hash = initHash;
	  if (score >= maxScore){
	    maxScore = score;
	  }
	  if( score >= beta ) {
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
    if (isBlackTurn){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (((((castle & 1) != 0) && (!isBlackTurn)) || (((castle & 4) != 0) && isBlackTurn))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(false)){
      int initCastle = castle;
      initHash = hash;
      initEnPasant = enPasant;
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(false);
      int score = -negamax( -beta, -alpha, depth-1);
      unmakeCastle(false);
      hash = initHash;
      castle = initCastle;
      enPasant = initEnPasant;
      if (score >= maxScore){
	maxScore = score;
      }
      if( score >= beta ) {
	return beta;
      }   
      if( score > alpha ) {
	alpha = score;
	if (isBlackTurn)
	  bestMove = Move(59, 61, 5, 6, score);
	else
	  bestMove = Move(3, 5, 5, 6, score);
      }
    }
    if (((((castle & 2) != 0) && (!isBlackTurn)) || (((castle & 8) != 0) && isBlackTurn)) && (totalOccupied & castleRight) == 0 && isCastlePossible(true)){
      int initCastle = castle;
      initHash = hash;
      initEnPasant = enPasant;
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(true);
      int score = -negamax( -beta, -alpha, depth-1);
      unmakeCastle(true);
      hash = initHash;
      castle = initCastle;
      enPasant = initEnPasant;
      if (score >= maxScore){
	maxScore = score;
      }
      if( score >= beta ) {
	return beta;
      }   
      if( score > alpha ) {
	alpha = score;
	if (isBlackTurn)
	  bestMove = Move(59, 57, 5, 6, score);
	else
	  bestMove = Move(3, 1, 5, 6, score);
      }
    }
    
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (ulong b = moves[movePieceIdx].set & (~totalOccupied); b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
        int initCastle = castle;
        initHash = hash;
        initEnPasant = enPasant;
	changeCastle(moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion( 6, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1);
	  unmakePawnPromotion(6, moves[movePieceIdx].piecePos, sq);
	}
	else {
	  makeQuietMove(moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1);
	  unmakeQuietMove(moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	}
	castle = initCastle;
	hash = initHash;
	enPasant = initEnPasant;
	if (score >= maxScore){
	  maxScore = score;
	}
	if( score >= beta ) {
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
    if (maxScore == -5000 && !squareIsUnderAttack2(pieces[isBlackTurn][5], !isBlackTurn, totalOccupied)){
      return 0;
    }
    return alpha;
  }

  Move negaDriver (){
    // assert_state(2);
    Move bestMove;
    int alpha = -10000;
    int beta = 10000;
    int depth = currDepth;
    import std.math;
    if (hash in transpositionTable){
      data d = transpositionTable[hash];
      if (d.depth >= depth){
	if (!checkIfRepetition(d.move)){
	  return d.move;
	}
      }
      else {
    	if (d.move.playType == 5 && abs(d.move.initialPos - d.move.finalPos) == 2){
    	  int score;
    	  int initCastle = castle;
    	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
    	  hash ^= randomCastleFlags[castle];
    	  switch (d.move.finalPos){
    	  case 1:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(true);
    	    break;
    	  case 5:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(false);
    	    break;
    	  case 57:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(true);
    	    break;
    	  case 61:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakeCastle(false);
    	    break;
    	  default:
    	    assert(false);
    	  }
    	  hash = initHash;
	  enPasant = initEnPasant;
    	  castle = initCastle;
    	  if( score > alpha ) {
	    alpha = score;
	    bestMove = d.move;
    	  }
    	}
    	else{
    	  int initCastle = castle;
    	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
    	  int score;
    	  changeCastle(d.move.playType, d.move.finalPos, d.move.initialPos);
    	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    	    makePawnPromotion(d.move.killType, d.move.initialPos, d.move.finalPos);
    	    score = -negamax( -beta, -alpha, depth-1);
    	    unmakePawnPromotion(d.move.killType, d.move.initialPos, d.move.finalPos);
    	  }
    	  else {
    	    if (d.move.killType == 6){
    	      makeQuietMove(d.move.playType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1);
    	      unmakeQuietMove(d.move.playType, d.move.initialPos, d.move.finalPos);
    	    }
    	    else {
    	      makeKillMove(d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1);
    	      unmakeKillMove(d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	    }
    	  }
    	  castle = initCastle;
    	  hash = initHash;
	  enPasant = initEnPasant;
    	  if( score > alpha ) {
	    if (checkIfRepetition(d.move)){
	      score = 0;
	      if (score > alpha){
		alpha = score;
		bestMove = d.move;
		bestMove.score = 0;
	      }
	    }
	    else {
	      alpha = score;
	      bestMove = d.move;
	    }
	  }
    	}
      }
    }
    MoveSet [16] moves = genMoves();
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlackTurn)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffslminusone(b);
	  int initCastle = castle;
	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
	  changeCastle(moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1);
	    unmakePawnPromotion(killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  else {
	    makeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1);
	    unmakeKillMove(moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	  }
	  castle = initCastle;
	  hash = initHash;
	  enPasant = initEnPasant;
	  if( score > alpha ){
	    Move m = Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, alpha);
	    alpha = score;
	    bestMove = m;
	  }
	}
      }
    }
    ulong totalOccupied = occupied[0] | occupied[1];
    ulong castleRight, castleLeft;
    if (isBlackTurn){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (((((castle & 1) != 0) && (!isBlackTurn)) || (((castle & 4) != 0) && isBlackTurn))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(false)){
      int initCastle = castle;
      ulong initHash = hash;
      ulong initEnPasant = enPasant;
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(false);
      int score = -negamax( -beta, -alpha, depth-1);
      unmakeCastle(false);
      hash = initHash;
      castle = initCastle;
      enPasant = initEnPasant;
      if( score > alpha ){
	alpha = score;
	if (isBlackTurn)
	  bestMove = Move(59, 61, 5, 6, score);
	else
	  bestMove = Move(3, 5, 5, 6, score);
      }
    }
    if (((((castle & 2) != 0) && (!isBlackTurn)) || (((castle & 8) != 0) && isBlackTurn)) && (totalOccupied & castleRight) == 0&& isCastlePossible(true)){
      int initCastle = castle;
      ulong initHash = hash;
      ulong initEnPasant = enPasant;
      hash ^= randomCastleFlags[castle];
      if (isBlackTurn){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
      makeCastle(true);
      int score = -negamax( -beta, -alpha, depth-1);
      unmakeCastle(true);
      hash = initHash;
      castle = initCastle;
      enPasant = initEnPasant;
      if( score > alpha ) {
	alpha = score;
	if (isBlackTurn)
	  bestMove = Move(59, 57, 5, 6, score);
	else
	  bestMove = Move(3, 1, 5, 6, score);
      }
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (ulong b = moves[movePieceIdx].set & (~totalOccupied); b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	int initCastle = castle;
	ulong initHash = hash;
	ulong initEnPasant = enPasant;
	changeCastle(moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(6, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1);
	  unmakePawnPromotion( 6, moves[movePieceIdx].piecePos, sq);
	}
	else {
	  makeQuietMove(moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1);
	  unmakeQuietMove(moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	}
	castle = initCastle;
	hash = initHash;
	enPasant = initEnPasant;
	if( score > alpha ) {
	  Move m = Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, alpha);
	  if (checkIfRepetition(m)){
	    score = 0;
	    m.score = 0;
	    if (score > alpha){
	      alpha = score;
	      bestMove = m;
	    }
	  }
	  else {
	    alpha = score;
	    bestMove = m;
	  }
	}
      }
    }
    if (timeExceeded){
      assert(transpositionTable[hash].depth == currDepth-1);
      return transpositionTable[hash].move;
    }
    transpositionTable[hash] = data(bestMove, depth);
    return bestMove;
  }
  
  Move genBestMove (){
    currDepth = 3;
    Move bestMove;
    while (true){
      bestMove = negaDriver();
      currDepth ++;
      synchronized{
      	if (timeExceeded){
      	  break;
      	}
      }
    }
    return bestMove;
  }
  MoveSet [16] genValidMoves (){
    auto moves = genMoves();
    int lastIdx = 1;
    MoveSet [16] validMoves;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){
      validMoves[lastIdx-1].pieceType = moves[lastIdx-1].pieceType;
      validMoves[lastIdx-1].piecePos = moves[lastIdx-1].piecePos;
      validMoves[lastIdx-1].set = 0;
    }
    validMoves[lastIdx-1].pieceType = moves[lastIdx-1].pieceType;
    validMoves[lastIdx-1].piecePos = moves[lastIdx-1].piecePos;
    validMoves[lastIdx-1].set = 0;
    int [16] positions;
    for (int i = 0; i < lastIdx; i ++){
      moves[i].set &= (~occupied[isBlackTurn]);
      bool flag = false;
      for (ulong b = moves[i].set; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	Chess_state init = state;
	init.makeMove(moves[i].piecePos, sq);
	if (!init.squareIsUnderAttack2(init.pieces[isBlackTurn][5], !isBlackTurn, (init.occupied[0]|init.occupied[1]))){
	  validMoves[i].set |= (1uL << sq);
	}
      } 
    }
    ulong totalOccupied = (occupied[0]|occupied[1]);
    ulong castleRight, castleLeft;
    if (isBlackTurn){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (((((castle & 1) != 0) && (!isBlackTurn)) || (((castle & 4) != 0) && isBlackTurn))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(false)){
      if (isBlackTurn){
	validMoves[lastIdx-1].set |= (1uL << 61);
      }
      else {
	validMoves[lastIdx-1].set |= (1uL << 5);
      }
    }
    if (((((castle & 2) != 0) && (!isBlackTurn)) || (((castle & 8) != 0) && isBlackTurn)) && (totalOccupied & castleRight) == 0&& isCastlePossible( true)){
      if (isBlackTurn){
	validMoves[lastIdx-1].set |= (1uL << 57);
      }
      else {
	validMoves[lastIdx-1].set |= (1uL << 1);
      }
    }
    return validMoves;
  } 
}
import std.typecons;
import std.conv;
Tuple!(Chess_state, "state", int, "lastKill", int, "moveNum") fenToState (string fen){
  import std.string: strip;
  Tuple!(Chess_state, "state", int, "lastKill", int, "moveNum") toReturn;
  fen = strip(fen);
  int pos = 0;
  int chessPos = 63;
  Chess_state st;
  for (int i = 0; i < 6; i ++){
    for (int j = 0; j < 2; j ++){
      st.pieces[j][i] = 0;
    }
  }
  for (int i = 0; i < 8; i ++){
    while (fen[pos] != '/' && fen[pos] != ' '){
      switch (fen[pos]){
      case 'p':
	st.pieces[1][0] |= (1uL << chessPos);
	break;
      case 'P':
	st.pieces[0][0] |= (1uL << chessPos);
	break;
      case 'n':
	st.pieces[1][1] |= (1uL << chessPos);
	break;
      case 'N':
	st.pieces[0][1] |= (1uL << chessPos);
	break;
      case 'b':
	st.pieces[1][2] |= (1uL << chessPos);
	break;
      case 'B':
	st.pieces[0][2] |= (1uL << chessPos);
	break;
      case 'r':
	st.pieces[1][3] |= (1uL << chessPos);
	break;
      case 'R':
	st.pieces[0][3] |= (1uL << chessPos);
	break;
      case 'q':
	st.pieces[1][4] |= (1uL << chessPos);
	break;
      case 'Q':
	st.pieces[0][4] |= (1uL << chessPos);
	break;
      case 'k':
	st.pieces[1][5] |= (1uL << chessPos);
	break;
      case 'K':
	st.pieces[0][5] |= (1uL << chessPos);
	break;
      default:
	chessPos -= fen[pos]-'1';
      }
      chessPos --;
      pos ++;
    }
    pos ++;
  }
  st.occupied[0] = 0;
  st.occupied[1] = 0;
  for (int i = 0; i < 6; i ++){
    st.occupied[0] |= st.pieces[0][i];
    st.occupied[1] |= st.pieces[1][i];
  }
  st.isBlackTurn = (fen[pos] == 'b');
  pos += 2;
  st.castle = 0;
  int i;
  for (i = pos; fen[i] != ' '; i ++){
      
  }
  for (int j = pos; j < i; j ++){
    if (fen[j] == 'K'){
      st.castle += 2;
    }
    else if (fen[j] == 'Q'){
      st.castle += 1;
    }
    else if (fen[j] == 'k'){
      st.castle += 8;
    }
    else if (fen[j] == 'q'){
      st.castle += 4;
    }
  }
  pos = i+1;
  if (fen[pos] != '-'){
    int x = 'h' - fen[pos];
    int y = 7 - cast(int)('8' - fen[pos+1]);
    st.enPasant = (1uL << (y*8 + x));
    pos += 3;
  }
  else {
    pos += 2;
  }
  st.setHash();
  st.setEval();
  toReturn.state = st;
  if (fen[pos+1] != ' '){
    int lastK = to!int(fen[pos .. pos+2]);
    toReturn.lastKill = lastK;
    pos += 3;
  }
  else {
    int lastK = to!int(fen[pos .. pos+1]);
    toReturn.lastKill = lastK;
    pos += 2;
  }
  int smn = to!int(fen[pos .. $]) - 1;
  toReturn.moveNum = smn*2;
  if (st.isBlackTurn){
    toReturn.moveNum ++;
  }
  return toReturn;
}

string stateToFen (Chess_state st, int lastK, int moveNum){
  string fen = "";
  int count = 0;
  import std.conv;
  for (int i = 63; i >= 0; i --){
    ulong pos = (1uL << i);
    if ((st.pieces[0][0] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'P';
    }
    else if ((st.pieces[1][0] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'p';
    }
    else if ((st.pieces[0][1] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'N';
    }
    else if ((st.pieces[1][1] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'n';
    }
    else if ((st.pieces[0][2] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'B';
    }
    else if ((st.pieces[1][2] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'b';
    }
    else if ((st.pieces[0][3] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'R';
    }
    else if ((st.pieces[1][3] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'r';
    }
    else if ((st.pieces[0][4] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'Q';
    }
    else if ((st.pieces[1][4] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'q';
    }
    else if ((st.pieces[0][5] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'K';
    }
    else if ((st.pieces[1][5] & pos) != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= 'k';
    }
    else {
      count ++;
    }
    if (i%8 == 0 && i != 0){
      if (count != 0){
	fen ~= to!string(count);
	count = 0;
      }
      fen ~= '/';
    }
  }
  fen ~= ' ';
  if (st.isBlackTurn){
    fen ~= 'b';
  }
  else {
    fen ~= 'w';
  }
  fen ~= ' ';
  if ((st.castle & 2) != 0){
    fen ~= 'K';
  }
  if ((st.castle & 1) != 0){
    fen ~= 'Q';
  }
  if ((st.castle & 8) != 0){
    fen ~= 'k';
  }
  if ((st.castle & 4) != 0){
    fen ~= 'q';
  }
  if (st.castle == 0){
    fen ~= '-';
  }
  fen ~= ' ';
  if (st.enPasant == 0){
    fen ~= '-';
  }
  else {
    int p = ffslminusone(st.enPasant);
    int x = p%8;
    int y = p/8;
    fen ~= cast(char)('h' - x);
    fen ~= to!string(y+1);
  }
  fen ~= ' ';
  fen ~= to!string(lastK) ~ " " ~ to!string(moveNum/2+1);
  return fen;
}

bool checkIfRepetition (Move m){
  Chess_state temp = state;
  temp.makeMove(m);
  if (temp.hash in numTimes && numTimes[temp.hash] >= 2){
    return true;
  }
  return false;
}
void printMoves (MoveSet [16] moves){
  for (int i = 0;  moves[i].pieceType != 5; i ++){
    writeln(moves[i].pieceType);
    printBoard(moves[i].set);
    printBoard((1uL << moves[i].piecePos));
  }
}

Chess_state state;
data [ulong] transpositionTable;
int [ulong] numTimes;


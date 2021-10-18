
module chess.d;
import std.stdio;
import piece_maps.d;

extern (C) int ffsl(long a);

int ffslminusone (long a){
  return ffsl(a) - 1;
}

// int prevSelected;

// extern (C++) ulong inputMove (int position, bool isBlack){
//   if (prevSelected == -1){
//     prevSelected = position;
//     ulong occ = state.occupied[0] | state.occupied[1];
//     for (int i = 0; i < 6; i ++){
//       if ((state.pieces[isBlack][i] >> position) % 2 == 1){
// 	return (pieceMove(occ, i, position) & (~occupied[isBlack]));
//       }
//     }
//     return 0;
//   }
//   else {
//     state.makeMove(prevSelected, position);
//     prevSelected = -1;
//     Move best = state.getMove(!isBlack);
//     state.makeMove(best, !isBlack);
//     return state.occupied[isBlack];
//   }
// }

// extern (C++) ulong * getPieces (){
//   return state.pieces;
// }

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
  bool turnIsBlack;
  

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
    // for (int i = 0; i < 16; i ++){
    //   occupied[0] |= (1uL << i);
    // }
    // for (int i = 8; i < 16; i ++){
    //   pieces[0][0] |= (1uL << i);
    // }
    // pieces[0][1] |= (1uL << 1);
    // pieces[0][1] |= (1uL << 6);
    // pieces[0][2] |= (1uL << 2);
    // pieces[0][2] |= (1uL << 5);
    // pieces[0][3] |= (1uL << 0);
    // pieces[0][3] |= (1uL << 7);
    // pieces[0][5] |= (1uL << 3);
    // pieces[0][4] |= (1uL << 4);
    
    // for (int i = 48; i < 64; i ++){
    //   occupied[1] |= (1uL << i);
    // }
    // for (int i = 48; i < 56; i ++){
    //   pieces[1][0] |= (1uL << i);
    // }
    // pieces[1][1] |= (1uL << 57);
    // pieces[1][1] |= (1uL << 62);
    // pieces[1][2] |= (1uL << 58);
    // pieces[1][2] |= (1uL << 61);
    // pieces[1][3] |= (1uL << 56);
    // pieces[1][3] |= (1uL << 63);
    // pieces[1][5] |= (1uL << 59);
    // pieces[1][4] |= (1uL << 60);
  }
  // Move [firstSaveSize] bestMoves; //best 5, worst to best

  // void insertMove (Move m){
  //   if (bestMoves[0].score < m.score){
  //     bestMoves[0] = m;
  //   }
  //   else {
  //     return;
  //   }
    
  //   for (int i = 1; i < firstSaveSize && bestMoves[i].score < bestMoves[i-1].score; i ++){
  //     Move temp = bestMoves[i];
  //     bestMoves[i] = bestMoves[i-1];
  //     bestMoves[i-1] = temp;
  //   }
  // }
  
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
    if (turnIsBlack){
      hash ^= isBlackTurn;
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

  this (ulong [6][2] p, int c, int en, bool isBlack){
    pieces = p;
    castle = c;
    if (en != 0)
      enPasant = (1uL << en);
    turnIsBlack = isBlack;
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
	  // write("  ");
	}
	if (i % 8 == 7 && i != 63){
	  // writeln();
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

  void assert_state(int num, bool isBlack){
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
    if (isBlack){
      hashEval ^= isBlackTurn;
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
    attacks |= pawnAttacks[isBlack][pos]&((occupied[(!isBlack)]) | enPasant);
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

  void makeEnPasant (bool isBlack, int initialPos, int finalPos){
    ulong a = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][0] ^= a;
    occupied[isBlack] ^= a;
    ulong b;
    if (isBlack){
      b = (1uL << (finalPos+8));
      evaluation -= positionEval[1][0][finalPos] - positionEval[1][0][initialPos] + positionEval[0][0][finalPos+8];
      hash ^= randomPieceNums[1][0][finalPos] ^ randomPieceNums[1][0][initialPos] ^ randomPieceNums[0][0][finalPos+8];
    }
    else {
      b = (1uL << (finalPos-8));
      evaluation += positionEval[0][0][finalPos] - positionEval[0][0][initialPos] + positionEval[1][0][finalPos-8];
      hash ^= randomPieceNums[0][0][finalPos] ^ randomPieceNums[0][0][initialPos] ^ randomPieceNums[1][0][finalPos-8];
    }
    occupied[!(isBlack)] ^= b;
    pieces[!(isBlack)][0] ^= b;
    hash ^= isBlackTurn;
  }

  void unmakeEnPasant (bool isBlack, int initialPos, int finalPos){
    ulong a = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][0] ^= a;
    occupied[isBlack] ^= a;
    ulong b;
    if (isBlack){
      b = (1uL << (finalPos+8));
      evaluation += positionEval[1][0][finalPos] - positionEval[1][0][initialPos] + positionEval[0][0][finalPos+8];
    }
    else {
      b = (1uL << (finalPos-8));
      evaluation -= positionEval[0][0][finalPos] - positionEval[0][0][initialPos] + positionEval[1][0][finalPos-8];
    }
    occupied[!(isBlack)] ^= b;
    pieces[!(isBlack)][0] ^= b;
  }

  void makeCastle (bool isBlack, bool isRight){
    hash ^= enPasant;
    enPasant = 0uL;
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
    hash ^= isBlackTurn;
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
    hash ^= enPasant;
    enPasant = 0uL;
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
    hash ^= isBlackTurn;
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
    import std.math;
    hash ^= enPasant;
    enPasant = 0uL;
    if (type == 0 && abs(initialPos - finalPos) != 8){
      if (abs(initialPos - finalPos) != 16){
	makeEnPasant(isBlack, initialPos, finalPos);
	return;
      }
      else {
	if (isBlack){
	  enPasant = (1uL << (initialPos - 8));
	}
	else {
	  enPasant = (1uL << (initialPos + 8));
	}
	hash ^= enPasant;
      }
    }
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][type] ^= change;
    occupied[isBlack] ^= change;
    int evalChange = positionEval[isBlack][type][finalPos] - positionEval[isBlack][type][initialPos];
    hash ^= randomPieceNums[isBlack][type][finalPos] ^ randomPieceNums[isBlack][type][initialPos];
    if (isBlack) evaluation -= evalChange;
    else evaluation += evalChange;
    hash ^= isBlackTurn;
  }

  void unmakeQuietMove (bool isBlack, int type, int initialPos, int finalPos){
    import std.math;
    if (type == 0 && abs(initialPos - finalPos) != 8){
      if (abs(initialPos - finalPos) != 16){
	unmakeEnPasant(isBlack, initialPos, finalPos);
	return;
      }
    }
    ulong change = (1uL << initialPos)|(1uL << finalPos);
    pieces[isBlack][type] ^= change;
    occupied[isBlack] ^= change;
    int evalChange = positionEval[isBlack][type][finalPos] - positionEval[isBlack][type][initialPos];
    if (isBlack) evaluation += evalChange;
    else evaluation -= evalChange;
  }
  
  void makeKillMove (bool isBlack, int playType, int killType, int initialPos, int finalPos){
    hash ^= enPasant;
    enPasant = 0uL;
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
    hash ^= isBlackTurn;
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
    int sq = ffslminusone(pos);
    return (pieceAttacks[1][sq] & pieces[isBlack][1]) != 0 || //attacked by knight
      (pawnAttacks[(!isBlack)][sq] & pieces[isBlack][0]) != 0 || //attacked by pawn WRONG
      (pieceMoves(tolOccupied, 3, sq) & (pieces[isBlack][3] | pieces[isBlack][4])) != 0 || //attacked by rook or queen
      (pieceMoves(tolOccupied, 2, sq) & (pieces[isBlack][2] | pieces[isBlack][4])) != 0 || //attacked by bishop or queen
      (pieceMoves(tolOccupied, 5, sq) & pieces[isBlack][5]) != 0; //attacked by king
  }

  void makeMove(int initialPos, int finalPos){
    ulong inPos = (1uL << initialPos);
    ulong fiPos = (1uL << finalPos);
    if ((occupied[0] & inPos) != 0){
      for (int i = 0; i < 6; i ++){
	if ((pieces[0][i] & inPos) != 0){
	  for (int j = 0; j < 6; j ++){
	    if ((pieces[1][j] & fiPos) != 0){
	      makeMove(Move(initialPos, finalPos, i, j, 0), false);
	      return;
	    }
	  }
	  makeMove(Move(initialPos, finalPos, i, 6, 0), false);
	  return;
	}
      }
    }
    else{
      for (int i = 0; i < 6; i ++){
	if ((pieces[1][i] & inPos) != 0){
	  for (int j = 0; j < 6; j ++){
	    if ((pieces[0][j] & fiPos) != 0){
	      makeMove(Move(initialPos, finalPos, i, j, 0), true);
	      return;
	    }
	  }
	  makeMove(Move(initialPos, finalPos, i, 6, 0), true);
	  return;
	}
      }
    }
    assert(false, "invalid move");
  }
  
  void makeMove(Move m, bool isBlack){
    import std.math;
    if (m.playType == 5 && (abs(m.initialPos - m.finalPos) == 2)){
      // writeln(m.initialPos, " " , m.finalPos, " " , m.playType);
      hash ^= randomCastleFlags[castle];
      if (isBlack){
	castle &= 3;
      }
      else {
	castle &= 12;
      }
      hash ^= randomCastleFlags[castle];
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
	  int sq = ffslminusone(b);
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
      int sq = ffslminusone(b);
      moves[idx] = MoveSet(0, pawnMoves(occupied, sq, isBlack), sq);
    }
    for (int j = 1; j < 6; j ++){
      for (ulong b = pieces[isBlack][j]; b != 0; b &= (b-1), idx ++){
	int sq = ffslminusone(b);
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
    // print(currDepth - depth);
    int maxScore = -5000;
    import std.math;
    if (timeExceeded){
      return alpha;
    }
    Move bestMove = Move(-1, -1, -1, -1, -1);
    if (hash in transpositionTable){
      data d = transpositionTable[hash];
      if (d.depth >= depth){
    	// for (int i = 0; i < currDepth - depth; i ++){
    	//   write("    ");
    	// }
    	// writeln("hash found, returned with score ", d.move.score);
    	// writeln(d.depth, " ", depth);
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
    	    makeCastle(false, true);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(false, true);
    	    break;
    	  case 5:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false, false);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(false, false);
    	    break;
    	  case 57:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true, true);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(true, true);
    	    break;
    	  case 61:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true, false);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(true, false);
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
    	    // d.move.score = score;
    	    // transpositionTable[hash] = data(d.move, depth);
    	    // for (int i = 0; i < currDepth - depth; i ++){
    	    //   write("    ");
    	    // }
    	    // writeln("hash castle beta cutoff, score is ", score, "beta is ", beta);
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
    	  changeCastle(isBlack, d.move.playType, d.move.finalPos, d.move.initialPos);
    	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    	      makePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	      unmakePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    	  }
    	  else {
    	    if (d.move.killType == 6){
    	      makeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	      unmakeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    	    }
    	    else {
    	      makeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	      unmakeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	    }
    	  }
    	  castle = initCastle;
    	  hash = initHash;
	  enPasant = initEnPasant;
	  if (score >= maxScore){
	    maxScore = score;
	  }
    	  if( score >= beta ) {
    	    // d.move.score = score;
    	    // transpositionTable[hash] = data(d.move, depth);
    	    // for (int i = 0; i < currDepth - depth; i ++){
    	    //   write("    ");
    	    // }
    	    // writeln("hash beta cutoff, score is ", score, "beta is ", beta);
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
      // for (int i = 0; i < currDepth - depth; i ++){
      // 	write("    ");
      // }
      // writeln("quiesce return ", quiesce(alpha, beta, isBlack));
      return quiesce(alpha, beta, isBlack);
    }
    hash = initHash;
    enPasant = initEnPasant;
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
	  int sq = ffslminusone(b);
	  int initCastle = castle;
	  initHash = hash;
	  initEnPasant = enPasant;
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
	  enPasant = initEnPasant;
	  hash = initHash;
	  if (score >= maxScore){
	    maxScore = score;
	  }
	  if( score >= beta ) {
	    // transpositionTable[hash] = data(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, score), depth);
	    // for (int i = 0; i < currDepth - depth; i ++){
	    //   write("    ");
	    // }
	    // writeln("kill move beta cutoff, score is ", score, "beta is ", beta);
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
      int initCastle = castle;
      initHash = hash;
      initEnPasant = enPasant;
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
      castle = initCastle;
      enPasant = initEnPasant;
      if (score >= maxScore){
	maxScore = score;
      }
      if( score >= beta ) {
	// if (isBlack)
	//   transpositionTable[hash] = data(Move(59, 61, 5, 6, score) , depth);
	// else
	//   transpositionTable[hash] = data(Move(3, 5, 5, 6, score) , depth);
	// for (int i = 0; i < currDepth - depth; i ++){
	//   write("    ");
	// }
	// writeln("left castle beta cutoff, score is ", score, " beta is ", beta);
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
    if (((((castle & 2) != 0) && (!isBlack)) || (((castle & 8) != 0) && isBlack)) && (totalOccupied & castleRight) == 0 && isCastlePossible(isBlack, true)){
      int initCastle = castle;
      initHash = hash;
      initEnPasant = enPasant;
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
      castle = initCastle;
      enPasant = initEnPasant;
      if (score >= maxScore){
	maxScore = score;
      }
      if( score >= beta ) {
	// if (isBlack)
	//   transpositionTable[hash] = data(Move(59, 57, 5, 6, score) , depth);
	// else
	//   transpositionTable[hash] = data(Move(3, 1, 5, 6, score) , depth);
	// for (int i = 0; i < currDepth - depth; i ++){
	//   write("    ");
	// }
	// writeln("right castle beta cutoff, score is ", score, " beta is ", beta);
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
	int sq = ffslminusone(b);
        int initCastle = castle;
        initHash = hash;
        initEnPasant = enPasant;
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
	enPasant = initEnPasant;
	if (score >= maxScore){
	  maxScore = score;
	}
	if( score >= beta ) {
	  // transpositionTable[hash] = data(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, score) , depth);
	  // for (int i = 0; i < currDepth - depth; i ++){
	  //   write("    ");
	  // }
	  // writeln("quite beta cutoff, score is ", score, " beta is ", beta);
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
    if (maxScore == -5000 && !squareIsUnderAttack2(pieces[isBlack][5], !isBlack, totalOccupied)){
      return 0;
    }
    // writeln(alpha);
    // for (int i = 0; i < currDepth - depth; i ++){
    //   write("    ");
    // }
    // writeln("alpha return, alpha is ", alpha );
    return alpha;
  }

  Move negaDriver (bool isBlack){
    Move bestMove;
    int alpha = -10000;
    int beta = 10000;
    int depth = currDepth;
    import std.math;
    if (hash in transpositionTable){
      data d = transpositionTable[hash];
      if (d.depth >= depth){
	if (!checkIfRepetition(d.move, isBlack)){
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
    	    makeCastle(false, true);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(false, true);
    	    break;
    	  case 5:
    	    castle &= 12;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(false, false);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(false, false);
    	    break;
    	  case 57:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true, true);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(true, true);
    	    break;
    	  case 61:
    	    castle &= 3;
    	    hash ^= randomCastleFlags[castle];
    	    makeCastle(true, false);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakeCastle(true, false);
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
    	  changeCastle(isBlack, d.move.playType, d.move.finalPos, d.move.initialPos);
    	  if (d.move.playType == 0 && (d.move.finalPos >= 56 || d.move.finalPos <= 7)){
    	    makePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	    unmakePawnPromotion(isBlack, d.move.killType, d.move.initialPos, d.move.finalPos);
    	  }
    	  else {
    	    if (d.move.killType == 6){
    	      makeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	      unmakeQuietMove(isBlack, d.move.playType, d.move.initialPos, d.move.finalPos);
    	    }
    	    else {
    	      makeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	      score = -negamax( -beta, -alpha, depth-1, (!isBlack));
    	      unmakeKillMove(isBlack, d.move.playType, d.move.killType, d.move.initialPos, d.move.finalPos);
    	    }
    	  }
    	  castle = initCastle;
    	  hash = initHash;
	  enPasant = initEnPasant;
    	  if( score > alpha ) {
	    if (checkIfRepetition(d.move, isBlack)){
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
    MoveSet [16] moves = genMoves(isBlack);
    int lastIdx = 1;
    for (; moves[lastIdx-1].pieceType != 5; lastIdx++){}
    // for (int i = 0; i < firstSaveSize; i ++){
    //   bestMoves[i] = Move(-1, -1, -1, -1, int.min);
    // }
    // for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
    //   if ((moves[movePieceIdx].set & pieces[(!isBlack)][5]) != 0) {
    // 	assert(false);
    //   }
    // }
    for (int killPiece = 4; killPiece >= 0; killPiece --){
      for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
	for (ulong b = moves[movePieceIdx].set & pieces[(!isBlack)][killPiece]; b != 0; b &= (b-1)){
	  int sq = ffslminusone(b);
	  int initCastle = castle;
	  ulong initHash = hash;
	  ulong initEnPasant = enPasant;
	  changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	  int score;
	  if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	    makePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakePawnPromotion(isBlack, killPiece, moves[movePieceIdx].piecePos, sq);
	    // insertMove(Move(moves[movePieceIdx].piecePos, sq, 0, killPiece, score));
	  }
	  else {
	    makeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	    unmakeKillMove(isBlack, moves[movePieceIdx].pieceType, killPiece, moves[movePieceIdx].piecePos, sq);
	    // insertMove(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, killPiece, score));
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
    if (isBlack){
      castleRight = 432345564227567616uL;
      castleLeft = 8070450532247928832uL;
    }
    else {
      castleRight = 6uL;
      castleLeft = 112uL;
    }
    if (((((castle & 1) != 0) && (!isBlack)) || (((castle & 4) != 0) && isBlack))  && (totalOccupied & castleLeft) == 0 && isCastlePossible(isBlack, false)){
      int initCastle = castle;
      ulong initHash = hash;
      ulong initEnPasant = enPasant;
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
      castle = initCastle;
      enPasant = initEnPasant;
      if( score > alpha ){
	alpha = score;
	if (isBlack)
	  bestMove = Move(59, 61, 5, 6, score);
	else
	  bestMove = Move(3, 5, 5, 6, score);
      }
      // if (isBlack){
      // 	insertMove(Move(59, 61, 5, 6, score));
      // }
      // else {
      // 	insertMove(Move(3, 5, 5, 6, score));
      // }
    }
    if (((((castle & 2) != 0) && (!isBlack)) || (((castle & 8) != 0) && isBlack)) && (totalOccupied & castleRight) == 0&& isCastlePossible(isBlack, true)){
      int initCastle = castle;
      ulong initHash = hash;
      ulong initEnPasant = enPasant;
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
      castle = initCastle;
      enPasant = initEnPasant;
      if( score > alpha ) {
	alpha = score;
	if (isBlack)
	  bestMove = Move(59, 57, 5, 6, score);
	else
	  bestMove = Move(3, 1, 5, 6, score);
      }
      // if (isBlack){
      // 	insertMove(Move(59, 57, 5, 6, score));
      // }
      // else {
      // 	insertMove(Move(3, 1, 5, 6, score));
      // }
    }
    for (int movePieceIdx = 0; movePieceIdx < lastIdx; movePieceIdx ++){
      for (ulong b = moves[movePieceIdx].set & (~totalOccupied); b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	int initCastle = castle;
	ulong initHash = hash;
	ulong initEnPasant = enPasant;
	changeCastle(isBlack, moves[movePieceIdx].pieceType, sq, moves[movePieceIdx].piecePos);
	int score;
	if (moves[movePieceIdx].pieceType == 0 && (sq <= 7 || sq >= 56)){
	  makePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakePawnPromotion(isBlack, 6, moves[movePieceIdx].piecePos, sq);
	  // insertMove(Move(moves[movePieceIdx].piecePos, sq, 0, 6, score));
	}
	else {
	  makeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  score = -negamax( -beta, -alpha, depth-1, (!isBlack));
	  unmakeQuietMove(isBlack, moves[movePieceIdx].pieceType, moves[movePieceIdx].piecePos, sq);
	  // insertMove(Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, score));
	}
	castle = initCastle;
	hash = initHash;
	enPasant = initEnPasant;
	if( score > alpha ) {
	  Move m = Move(moves[movePieceIdx].piecePos, sq, moves[movePieceIdx].pieceType, 6, alpha);
	  if (checkIfRepetition(m, isBlack)){
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
  
  Move genBestMove (bool isBlack){
    currDepth = 3;
    Move bestMove;
    while (true){
      bestMove = negaDriver(isBlack);
      currDepth ++;
      synchronized{
      	if (timeExceeded){
      	  break;
      	}
      }
    }
    return bestMove;
  }
  MoveSet [16] genValidMoves (bool isBlack){
    // assert_state(8, isBlack);
    auto moves = genMoves(isBlack);
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
      moves[i].set &= (~occupied[isBlack]);
      bool flag = false;
      for (ulong b = moves[i].set; b != 0; b &= (b-1)){
	int sq = ffslminusone(b);
	Chess_state init = state;
	// writeln(moves[i].piecePos, " ", sq);
	init.makeMove(moves[i].piecePos, sq);
	if (!init.squareIsUnderAttack2(init.pieces[isBlack][5], !isBlack, (init.occupied[isBlack]|init.occupied[!isBlack]))){
	  validMoves[i].set |= (1uL << sq);
	}
      } 
    }
    ulong totalOccupied = (occupied[isBlack]|occupied[!isBlack]);
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
      if (isBlack){
	validMoves[lastIdx-1].set |= (1uL << 61);
      }
      else {
	validMoves[lastIdx-1].set |= (1uL << 5);
      }
    }
    if (((((castle & 2) != 0) && (!isBlack)) || (((castle & 8) != 0) && isBlack)) && (totalOccupied & castleRight) == 0&& isCastlePossible(isBlack, true)){
      if (isBlack){
	validMoves[lastIdx-1].set |= (1uL << 57);
      }
      else {
	validMoves[lastIdx-1].set |= (1uL << 1);
      }
    }
    return validMoves;
  } 
}

Chess_state procFen (string fen){
  import std.string: strip;
  fen = strip(fen);
  
  for (int i = 0; i < 8; i ++){
    
  }
  assert(false);
}

bool checkIfRepetition (Move m, bool isBlack){
  Chess_state temp = state;
  temp.makeMove(m, isBlack);
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

// CHANGE TRANSPOSITION TABLES TO NOT STORE AT BETA CUTOFF

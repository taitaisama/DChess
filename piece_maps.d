module piece_maps.d;

int [64][6][2] positionEval; // white = 0, black = 1

ulong [64][6] pieceAttacks;
ulong [64][6] blockersBeyond;
ulong [64][64] arrBehind;

ulong [64][2] pawnAttacks; //second is isBlack

void processPositions (){
  //pawn
  positionEval[1][0] = [800,800,800,800,800,800,800,800,
			50, 50, 50, 50, 50, 50, 50, 50,
			10, 10, 20, 30, 30, 20, 10, 10,
			5,  5, 10, 25, 25, 10,  5,  5,
			0,  0,  0, 20, 20,  0,  0,  0,
			5, -5,-10,  0,  0,-10, -5,  5,
			5, 10, 10,-20,-20, 10, 10,  5,
			0,  0,  0,  0,  0,  0,  0,  0];

  //knight
  positionEval[1][1] = [-50,-40,-30,-30,-30,-30,-40,-50,
			-40,-20,  0,  0,  0,  0,-20,-40,
			-30,  0, 10, 15, 15, 10,  0,-30,
			-30,  5, 15, 20, 20, 15,  5,-30,
			-30,  0, 15, 20, 20, 15,  0,-30,
			-30,  5, 10, 15, 15, 10,  5,-30,
			-40,-20,  0,  5,  5,  0,-20,-40,
			-50,-40,-30,-30,-30,-30,-40,-50];

  //bishop
  positionEval[1][2] = [-20,-10,-10,-10,-10,-10,-10,-20,
			-10,  0,  0,  0,  0,  0,  0,-10,
			-10,  0,  5, 10, 10,  5,  0,-10,
			-10,  5,  5, 10, 10,  5,  5,-10,
			-10,  0, 10, 10, 10, 10,  0,-10,
			-10, 10, 10, 10, 10, 10, 10,-10,
			-10,  5,  0,  0,  0,  0,  5,-10,
			-20,-10,-10,-10,-10,-10,-10,-20];

  //rook
  positionEval[1][3] = [0,  0,  0,  0,  0,  0,  0,  0,
			5, 10, 10, 10, 10, 10, 10,  5,
			-5,  0,  0,  0,  0,  0,  0, -5,
			-5,  0,  0,  0,  0,  0,  0, -5,
			-5,  0,  0,  0,  0,  0,  0, -5,
			-5,  0,  0,  0,  0,  0,  0, -5,
			-5,  0,  0,  0,  0,  0,  0, -5,
			0,  0,  0,  5,  5,  0,  0,  0];

  //queen
  positionEval[1][4] = [-20,-10,-10, -5, -5,-10,-10,-20,
			-10,  0,  0,  0,  0,  0,  0,-10,
			-10,  0,  5,  5,  5,  5,  0,-10,
			-5,  0,  5,  5,  5,  5,  0, -5,
			0,  0,  5,  5,  5,  5,  0, -5,
			-10,  5,  5,  5,  5,  5,  0,-10,
			-10,  0,  5,  0,  0,  0,  0,-10,
			-20,-10,-10, -5, -5,-10,-10,-20];

  //king
  positionEval[1][5] = [-30,-40,-40,-50,-50,-40,-40,-30,
			-30,-40,-40,-50,-50,-40,-40,-30,
			-30,-40,-40,-50,-50,-40,-40,-30,
			-30,-40,-40,-50,-50,-40,-40,-30,
			-20,-30,-30,-40,-40,-30,-30,-20,
			-10,-20,-20,-20,-20,-20,-20,-10,
			20, 20,  0,  0,  0,  0, 20, 20,
			20, 30, 10,  0,  0, 10, 30, 20];

  for (int i = 0; i < 64; i ++){
    positionEval[1][0][i] += 100;
    positionEval[1][1][i] += 320;
    positionEval[1][2][i] += 330;
    positionEval[1][3][i] += 500;
    positionEval[1][4][i] += 900;
    positionEval[1][5][i] += 20000;
  }
  for (int i = 0; i < 6; i ++){
    for (int j = 0; j < 64; j ++){
      int newpos = 8*(7-(j/8)) + (j%8);
      positionEval[0][i][newpos] = positionEval[1][i][j];
    }
  }
}



void printBoard (ulong board){
  import std.stdio;
  for (int i = 7; i >= 0; i --){
    for (int j = 7; j >= 0; j --){
      if ((board >> (i*8+j))&1uL){
	write("O ");
      }
      else {
	write(". ");
      }
    }
    writeln();
  }
  writeln();
}

void preProcess (){
  processPositions();
  for (int i = 0; i < 64; i ++){
    pawnAttacks[0][i] = 0;
    pawnAttacks[1][i] = 0;
    int x = i/8;
    int y = i%8;
    ulong knight = 0;
    int x1 = x-1;
    int y1 = y-2;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x+1;
    y1 = y-2;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x+1;
    y1 = y+2;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x-1;
    y1 = y+2;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x-2;
    y1 = y-1;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x+2;
    y1 = y-1;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x+2;
    y1 = y+1;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    x1 = x-2;
    y1 = y+1;
    if (x1 >= 0 && y1 >= 0 && x1 < 8 && y1 < 8){
      knight |= (1uL << ((x1*8)+y1));
    }
    pieceAttacks[1][i] = knight;
    ulong king = 0;
    for (int j = -1; j < 2; j ++){
      for (int k = -1; k < 2; k ++){
	if (x + j < 8 && x + j >= 0 && y + k < 8 && y + k >= 0){
	  int newpos = (x+j)*8 + (y+k);
	  king |= (1uL << newpos);
	}
      }
    }
    king &= ~((1uL << i));
    pieceAttacks[5][i] = king;
    ulong bishop = 0;
    int z = x > y ? x : y;
    for (int j = 1; z + j < 8; j++){
      int newpos = (x+j)*8 + (y+j);
      bishop |= (1uL << newpos);
    }
    z = (7-x) > y ? (7-x) : y;
    for (int j = 1; z + j < 8; j++){
      int newpos = (x-j)*8 + (y+j);
      bishop |= (1uL << newpos);
    }
    z = x > (7-y) ? x : (7-y);
    for (int j = 1; z + j < 8; j++){
      int newpos = (x+j)*8 + (y-j);
      bishop |= (1uL << newpos);
    }
    z = (7-x) > (7-y) ? (7-x) : (7-y);
    for (int j = 1; z + j < 8; j++){
      int newpos = (x-j)*8 + (y-j);
      bishop |= (1uL << newpos);
    }
    pieceAttacks[2][i] = bishop;
    ulong rook = 0;
    for (int j = 1; x+j < 8; j ++){
      int newpos = (x+j)*8 + y;
      rook |= (1uL << newpos);
    }
    for (int j = 1; x-j >= 0; j ++){
      int newpos = (x-j)*8 + y;
      rook |= (1uL << newpos);
    }
    for (int j = 1; y+j < 8; j ++){
      int newpos = (x)*8 + y + j;
      rook |= (1uL << newpos);
    }
    for (int j = 1; y-j >= 0; j ++){
      int newpos = (x)*8 + y - j;
      rook |= (1uL << newpos);
    }
    pieceAttacks[3][i] = rook;
    pieceAttacks[4][i] = rook | bishop;
    ulong edges = 0;
    for (int j = 0; j < 8; j ++){
      edges |= (1uL << j);
      edges |= (1uL << j*8);
      edges |= (1uL << (j+56));
      edges |= (1uL << (j*8 + 7));
    }
    edges = ~edges;
    ulong rookStops = 0;
    rookStops |= 1uL << (x*8 + 7);
    rookStops |= 1uL << (x*8);
    rookStops |= 1uL << y;
    rookStops |= 1uL << (y + 56);
    rookStops = ~rookStops;
    blockersBeyond[1][i] = 0;
    blockersBeyond[2][i] = pieceAttacks[2][i] & edges;
    blockersBeyond[3][i] = pieceAttacks[3][i] & rookStops;
    blockersBeyond[4][i] = blockersBeyond[2][i] | blockersBeyond[3][i];
    blockersBeyond[5][i] = 0;
  }
  for (int x = 0; x < 8; x ++){
    for (int y = 1; y < 7; y ++){
      
      if (x == 0){
	pawnAttacks[0][x+(y*8)] |= (1uL << ((x+1)+8*(y+1)));
	pawnAttacks[1][x+(y*8)] |= (1uL << ((x+1)+8*(y-1)));
      }
      else if (x == 7){
	pawnAttacks[0][x+(y*8)] |= (1uL << ((x-1)+8*(y+1)));
	pawnAttacks[1][x+(y*8)] |= (1uL << ((x-1)+8*(y-1)));
      }
      else {
	pawnAttacks[0][x+(y*8)] |= (1uL << ((x+1)+8*(y+1)));
	pawnAttacks[1][x+(y*8)] |= (1uL << ((x+1)+8*(y-1)));
	pawnAttacks[0][x+(y*8)] |= (1uL << ((x-1)+8*(y+1)));
	pawnAttacks[1][x+(y*8)] |= (1uL << ((x-1)+8*(y-1)));
      }
    }
    //y = 0 for white
    pawnAttacks[0][x] |= (1uL << (x+1)+8);
    //y = 7 for black
    pawnAttacks[1][x+56] |= (1uL << (x+1)+48);
  }
  for (int i = 0; i < 64; i ++){
    for (int j = 0; j < 64; j ++){
      // i = main piece
      // j = second piece
      arrBehind[i][j] = 0;
      if (j == i){
	continue;
      }
      int x1 = i/8, y1 = i%8, x2 = j/8, y2 = j%8;
      if (x1 == x2){
	if (y1 < y2){
	  for (int k = y2+1; k < 8; k ++){
	    int newpos = x1*8 + k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
	else {
	  for (int k = y2-1; k >= 0; k --){
	    int newpos = x1*8 + k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
      }
      else if (y1 == y2) {
	if (x1 < x2){
	  for (int k = x2 + 1; k < 8; k ++){
	    int newpos = k*8 + y1;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
	else {
	  for (int k = x2 - 1; k >= 0; k --){
	    int newpos = k*8 + y1;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
      }
      else if (x2 - x1 == y2 - y1){
	if (x2 - x1 > 0){
	  int z = x2 > y2 ? x2 :  y2;
	  for (int k = 1; k + z < 8; k ++){
	    int newpos = (x2+k)*8 + y2 + k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
	else {
	  int z = (7-x2) > (7-y2) ? (7-x2) : (7- y2);
	  for (int k = 1; k + z < 8; k ++){
	    int newpos = (x2-k)*8 + y2 - k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
      }
      else if (x2 - x1 == y1 - y2){
	if (x2 - x1 > 0){
	  int z = x2 > (7-y2) ? x2 : (7-y2);
	  for (int k = 1; k + z < 8; k ++){
	    int newpos = (x2+k)*8 + y2 - k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
	else {
	  int z = (7-x2) > y2 ? (7-x2) : y2;
	  for (int k = 1; k + z < 8; k ++){
	    int newpos = (x2-k)*8 + y2 + k;
	    arrBehind[i][j] |= (1uL << newpos);
	  }
	}
      }
    }
  }
}

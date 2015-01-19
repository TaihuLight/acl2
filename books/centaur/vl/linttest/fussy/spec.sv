module top ;

  wire cond;
  wire [3:0] xx0, xx1, xx2;
  wire [2:0] yy0, yy1, yy2;


  // A couple of obvious places where we want to warn:

  wire [3:0] and_warn1 = xx0 & 32;     // warn since 32 is too big to fit into 4 bits
  wire [3:0] and_warn2 = xx0 & yy0;    // warn since the wires are different sizes

  // Warnings about the size of a zero are especially irritating:

  wire [3:0] and_normal1 = xx0 & 0;    // do not warn because this is common

  // Warnings about extension integers aren't ok since the whole point is that
  // they're "supposed to grow"

  wire [3:0] and_normal2 = xx0 & '0;
  wire [3:0] and_normal3 = xx0 & '1;


  // Some tricky cases.
  //   Zero is really special.  If we have the wrong size of a zero, that
  //   still doesn't seem worth bothering people about.

  wire [3:0] and_normal4 = xx0 & 2'b0;

  //   For other numbers,it's less clear what we should do.  Something
  //   like xx0 & 2'b11 is especially concerning because what if 2'b11
  //   is supposed to be a mask and the designer thinks he's getting the
  //   whole signal masked out, but forgets that he added a bit to xx0
  //   and it's three bits now instead of 2.
  //
  //   Because of this sort of thing, I think it *does* make sense to issue
  //   fussy warnings about bitwise stuff being applied to nonzero integers
  //   that are too small.

  wire [3:0] and_warn3 = xx0 & 2'b11;
  wire [3:0] and_warn4 = xx0 & 2'b10;
  wire [3:0] and_warn5 = xx0 & 2'b01;



  // When compound expressions involve plain integers, things get more
  // interesting.  The heuristics for figuring out when we do and don't want to
  // warn are a bit tricky.

  wire [3:0] andc_normal1 = xx0 & (cond ? xx1 : xx2);
  wire [3:0] andc_normal2 = xx0 & (cond ? xx1 : '0);
  wire [3:0] andc_normal3 = xx0 & (cond ? xx1 : '1);

  wire [3:0] andc_warn1 = xx0 & (2'b0 & 2'b1);
  wire [3:0] andc_warn2 = xx0 & (xx1[1:0] & 2'b11);
  wire [3:0] andc_warn3 = xx0 & (cond ? xx1 : 16); // Proper warning because 16 doesn't fit
  wire [3:0] andc_warn4 = xx0 & (cond ? xx1 : 32); // Proper warning because 32 doesn't fit.

  wire [3:0] andc_minor1 = xx0 & (cond ? xx1 : 0);  // Minor because it fits
  wire [3:0] andc_minor2 = xx0 & (cond ? xx1 : 15); // Minor because it fits






endmodule

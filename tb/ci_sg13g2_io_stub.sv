// SPDX-License-Identifier: Apache-2.0
// Declaration-only PadCell stand-ins for CI compilation without an IHP PDK.

module sg13g2_IOPadIOVdd ();
endmodule

module sg13g2_IOPadIOVss ();
endmodule

module sg13g2_IOPadVdd ();
endmodule

module sg13g2_IOPadVss ();
endmodule

module sg13g2_IOPadIn (
    input  wire pad,
    output wire p2c
);
endmodule

module sg13g2_IOPadOut30mA (
    output wire pad,
    input  wire c2p
);
endmodule

module sg13g2_IOPadInOut30mA (
    inout  wire pad,
    input  wire c2p,
    input  wire c2p_en,
    output wire p2c
);
endmodule

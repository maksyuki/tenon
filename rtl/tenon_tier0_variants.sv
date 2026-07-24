// SPDX-License-Identifier: Apache-2.0
// Fixed package variants. Do not change parameters without a new profile.

`default_nettype none

module tenon_tier0_qfn32 (
    inout wire        mgmt_clk_pad,
    inout wire        mgmt_rst_n_pad,
    inout wire        jtag_tck_pad,
    inout wire        jtag_tms_pad,
    inout wire        jtag_tdi_pad,
    inout wire        jtag_tdo_pad,
    inout wire        uart_rx_pad,
    inout wire        uart_tx_pad,
    inout wire [15:0] gpio_pad
);
  tenon_tier0_reference #(
      .GPIO_COUNT   (16),
      .PADS_PER_RAIL(2)
  ) u_reference (
      .*
  );
endmodule

module tenon_tier0_qfn64 (
    inout wire        mgmt_clk_pad,
    inout wire        mgmt_rst_n_pad,
    inout wire        jtag_tck_pad,
    inout wire        jtag_tms_pad,
    inout wire        jtag_tdi_pad,
    inout wire        jtag_tdo_pad,
    inout wire        uart_rx_pad,
    inout wire        uart_tx_pad,
    inout wire [39:0] gpio_pad
);
  tenon_tier0_reference #(
      .GPIO_COUNT   (40),
      .PADS_PER_RAIL(4)
  ) u_reference (
      .*
  );
endmodule

module tenon_tier0_qfn88 (
    inout wire        mgmt_clk_pad,
    inout wire        mgmt_rst_n_pad,
    inout wire        jtag_tck_pad,
    inout wire        jtag_tms_pad,
    inout wire        jtag_tdi_pad,
    inout wire        jtag_tdo_pad,
    inout wire        uart_rx_pad,
    inout wire        uart_tx_pad,
    inout wire [55:0] gpio_pad
);
  tenon_tier0_reference #(
      .GPIO_COUNT   (56),
      .PADS_PER_RAIL(6)
  ) u_reference (
      .*
  );
endmodule

module tenon_tier0_qfn128 (
    inout wire        mgmt_clk_pad,
    inout wire        mgmt_rst_n_pad,
    inout wire        jtag_tck_pad,
    inout wire        jtag_tms_pad,
    inout wire        jtag_tdi_pad,
    inout wire        jtag_tdo_pad,
    inout wire        uart_rx_pad,
    inout wire        uart_tx_pad,
    inout wire [87:0] gpio_pad
);
  tenon_tier0_reference #(
      .GPIO_COUNT   (88),
      .PADS_PER_RAIL(8)
  ) u_reference (
      .*
  );
endmodule

`default_nettype wire

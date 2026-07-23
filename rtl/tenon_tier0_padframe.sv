// SPDX-License-Identifier: Apache-2.0
// Tenon Tier0 reusable IHP SG13G2 padframe wrapper.

`default_nettype none

module tenon_tier0_padframe #(
    parameter integer GPIO_COUNT = 16,
    parameter integer PADS_PER_RAIL = 2
) (
    inout wire mgmt_clk_pad,
    inout wire mgmt_rst_n_pad,
    inout wire jtag_tck_pad,
    inout wire jtag_tms_pad,
    inout wire jtag_tdi_pad,
    inout wire jtag_tdo_pad,
    inout wire uart_rx_pad,
    inout wire uart_tx_pad,
    inout wire [GPIO_COUNT-1:0] gpio_pad,

    output wire mgmt_clk_i,
    output wire mgmt_rst_ni,
    output wire jtag_tck_i,
    output wire jtag_tms_i,
    output wire jtag_tdi_i,
    input  wire jtag_tdo_o,
    output wire uart_rx_i,
    input  wire uart_tx_o,
    output wire [GPIO_COUNT-1:0] gpio_i,
    input  wire [GPIO_COUNT-1:0] gpio_o,
    input  wire [GPIO_COUNT-1:0] gpio_oe
);

    // IHP's LibreLane synthesis model omits power ports. Physical VDD/VSS and
    // IOVDD/IOVSS connectivity is created by the LEF plus flow/pdn.tcl.
    genvar index;
    generate
        for (index = 0; index < PADS_PER_RAIL; index = index + 1) begin : u_iovdd_pads
            (* keep = "true" *) sg13g2_IOPadIOVdd u_pad ();
        end
        for (index = 0; index < PADS_PER_RAIL; index = index + 1) begin : u_iovss_pads
            (* keep = "true" *) sg13g2_IOPadIOVss u_pad ();
        end
        for (index = 0; index < PADS_PER_RAIL; index = index + 1) begin : u_vdd_pads
            (* keep = "true" *) sg13g2_IOPadVdd u_pad ();
        end
        for (index = 0; index < PADS_PER_RAIL; index = index + 1) begin : u_vss_pads
            (* keep = "true" *) sg13g2_IOPadVss u_pad ();
        end
    endgenerate

    (* keep = "true" *) sg13g2_IOPadIn u_mgmt_clk_pad (
        .pad(mgmt_clk_pad), .p2c(mgmt_clk_i)
    );
    (* keep = "true" *) sg13g2_IOPadIn u_mgmt_rst_n_pad (
        .pad(mgmt_rst_n_pad), .p2c(mgmt_rst_ni)
    );
    (* keep = "true" *) sg13g2_IOPadIn u_jtag_tck_pad (
        .pad(jtag_tck_pad), .p2c(jtag_tck_i)
    );
    (* keep = "true" *) sg13g2_IOPadIn u_jtag_tms_pad (
        .pad(jtag_tms_pad), .p2c(jtag_tms_i)
    );
    (* keep = "true" *) sg13g2_IOPadIn u_jtag_tdi_pad (
        .pad(jtag_tdi_pad), .p2c(jtag_tdi_i)
    );
    (* keep = "true" *) sg13g2_IOPadOut30mA u_jtag_tdo_pad (
        .pad(jtag_tdo_pad), .c2p(jtag_tdo_o)
    );
    (* keep = "true" *) sg13g2_IOPadIn u_uart_rx_pad (
        .pad(uart_rx_pad), .p2c(uart_rx_i)
    );
    (* keep = "true" *) sg13g2_IOPadOut30mA u_uart_tx_pad (
        .pad(uart_tx_pad), .c2p(uart_tx_o)
    );

    generate
        for (index = 0; index < GPIO_COUNT; index = index + 1) begin : u_gpio_pads
            (* keep = "true" *) sg13g2_IOPadInOut30mA u_pad (
                .pad(gpio_pad[index]),
                .c2p(gpio_o[index]),
                .c2p_en(gpio_oe[index]),
                .p2c(gpio_i[index])
            );
        end
    endgenerate

endmodule

`default_nettype wire

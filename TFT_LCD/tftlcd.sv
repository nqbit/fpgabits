module tftlcd (
    input         i_clk,
    input         i_enable,
    input [23:0]  i_pixel,

    output [15:0] o_hpixel,
    output [15:0] o_vpixel,
    output        o_HSYNC,
    output        o_VSYNC,
    output        o_DE,
    output        o_CLK,
    output [7:0]  o_RED,
    output [7:0]  o_GREEN,
    output [7:0]  o_BLUE
    );

    // Frame Horizontal Backporch Width
    parameter FRAME_HBP = 88;

    // Frame Horizontal Width
    parameter FRAME_H = 800;

    // Frame Horizontal Frontporch Width
    parameter FRAME_HFP = 40;

    // Frame Vertical Backporch Height
    parameter FRAME_VBP = 32;

    // Frame Vertical Height
    parameter FRAME_V = 480;

    // Frame Vertical Frontporch Height
    parameter FRAME_VFP = 13;

    logic           VCLK;
    logic [31:0]    VCOUNT;
    logic [31:0]    HCOUNT;

    initial begin
        o_HSYNC = 0;
        o_VSYNC = 0;

        VCLK = 0;
        VCOUNT = 0;
        HCOUNT = 0;
    end

    assign o_CLK = i_clk && i_enable;

    always_ff @(posedge VCLK) begin
        o_VSYNC = (VCOUNT >= 0) && (VCOUNT <=4);
        if (VCOUNT == FRAME_VBP + FRAME_V + FRAME_VFP) begin
            VCOUNT = 0;
        end else begin
            VCOUNT = VCOUNT + 1;
        end

        if (VCOUNT >= FRAME_VBP + 100 && VCOUNT < FRAME_VBP + 60 + 100) begin
            o_vpixel = VCOUNT - FRAME_VBP;
        end
    end

    always_ff @(posedge o_CLK) begin
        o_DE = ((VCOUNT < FRAME_V + FRAME_VBP) &&
                (VCOUNT > FRAME_VBP) &&
                (HCOUNT < FRAME_H + FRAME_HBP) &&
                (HCOUNT > FRAME_HBP));
        o_HSYNC = (HCOUNT == 0);

        if (HCOUNT >= FRAME_HBP + 100 && HCOUNT < FRAME_HBP + 80 + 100) begin
            o_hpixel = HCOUNT - FRAME_HBP;
        end

        o_RED = i_pixel[7:0];
        o_GREEN = i_pixel[15:8];
        o_BLUE = i_pixel[23:16];

        if (HCOUNT == FRAME_HBP + FRAME_H + FRAME_HFP) begin
            HCOUNT = 0;
            VCLK = 1;
        end else begin
            HCOUNT = HCOUNT + 1;
            VCLK = 0;
        end
    end
endmodule

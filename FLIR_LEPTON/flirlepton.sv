module flirlepton(
    input  CLK_25,
    output CAM_CS,
    output CAM_CLK,
    input  CAM_MISO,
    );

    // State to keep track of camera comms.
    enum {
        STATE_PRE_PACKET,
        STATE_BEGIN_PACKET,
        STATE_READ_PACKET,
        STATE_TOCK,
        STATE_DISPLAY_PACKET,
        STATE_POST_PACKET,
        STATE_BAD_PACKET,
        STATE_SHIFT_DATA
        } state;

    // TODO(nqbit): Revisit image buffering.
    // Image buffer.
    logic [7:0] packet[164];

    // A value that keeps track of the number of bits read and indicates when a
    // packet is finished.
    logic [31:0] count;

    // Packet count.
    logic [31:0] pc;

    // Bit being shifted out.
    logic [7:0] pc_sub;

    // A value to used for keeping track of the clock line delay.
    logic [31:0] cs_delay;

    // TODO(nqit): Add a CRC check too.
    // A value representing the number of good packets received.
    logic [31:0] goodpacket;

    // A value to faciliate shifting out frames.
    logic [7:0] pixc;

    wire [7:0] p0;
    assign p0 = packet[0] & 8'h0F;

    always_ff @(posedge CLK_25) begin
        case (state)
            STATE_PRE_PACKET:begin
                CAM_CS = 1;
                CAM_CLK = 0;

                pc = 0;
                pc_sub = 0;
                state = STATE_BEGIN_PACKET;
            end

            STATE_BEGIN_PACKET:begin
                CAM_CS = 0;
                CAM_CLK = 0;

                if (cs_delay == 30) begin
                    state = STATE_READ_PACKET;
                    cs_delay = 0;
                end else begin
                    cs_delay++;
                    state = STATE_BEGIN_PACKET;
                end
            end

            STATE_READ_PACKET:begin
                CAM_CS = 0;
                CAM_CLK = 1;
                packet[pc][7 - pc_sub] = CAM_MISO;
                if (pc_sub == 7) begin
                    pc_sub = 0;
                    pc = pc + 1;
                end else begin
                    pc_sub = pc_sub + 1;
                end

                if (count == 1311) begin
                    state = STATE_DISPLAY_PACKET;
                    count = 0;
                end else begin
                    count++;
                    state = STATE_TOCK;
                end
            end

            STATE_TOCK:begin
                CAM_CLK = 0;
                state = STATE_READ_PACKET;
            end

            STATE_DISPLAY_PACKET:begin
                CAM_CLK = 0;

                if (p0 == 8'h0F) begin
                    state = STATE_POST_PACKET;
                end else if (p0 == 8'h00 &&
                             packet[1] < 8'd60) begin
                    goodpacket++;
                    state = STATE_SHIFT_DATA;
                end else begin
                    state = STATE_BAD_PACKET;
                end
            end

            STATE_SHIFT_DATA:begin
                CAM_CS = 1;

                // Shifted out data to another frame buffer for double buffering
                // Add your own mix here.
                // frame[packet[1]][pixc] = {packet[pixc*2 + 5],
                // packet[pixc*2 + 5], packet[pixc*2 + 5]
                if (pixc == 79) begin
                    pixc = 0;
                    state = STATE_PRE_PACKET;
                end else begin
                    pixc++;
                end
            end

            STATE_BAD_PACKET:begin
                // TODO(nqbit): Fail better.
                CAM_CS = 1;
            end

            STATE_POST_PACKET:begin
                CAM_CS = 1;
                if (cs_delay == 30) begin
                    state = STATE_PRE_PACKET;
                    cs_delay = 0;
                end else begin
                    cs_delay++;
                    state = STATE_POST_PACKET;
                end
            end
        endcase
    end
endmodule

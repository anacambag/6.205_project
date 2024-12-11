module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/anacamba/Desktop/6.205/lab05/sim/sim_build/image_sprite.fst");
    $dumpvars(0, image_sprite);
end
endmodule

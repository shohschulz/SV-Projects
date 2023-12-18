//Top Level module of the Flappy Bird Game
import Constants::*;
module DE1_SoC(
    CLOCK_50, KEY, SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, VGA_R, VGA_G, VGA_B,
    VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS);
  input logic CLOCK_50;
  input logic [3:0] KEY;
  input logic [9:0] SW;
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  output VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS;
  output [7:0] VGA_R, VGA_G, VGA_B;
    
    logic clock100;
	 logic clock2Dot5;
	 logic reset;
	 logic userPress;
Clock_divider #(.DIVISOR(500000)) scrolling (.clock_in(CLOCK_50),.clock_out(clock100)); //100hz
Clock_divider #(.DIVISOR(20000000)) scoreTracking (.clock_in(CLOCK_50),.clock_out(clock2Dot5)); //2.5hz

//User input , 2xDFF to avoid metastability
    assign reset = SW[8];
    assign userPress = ~KEY[3];
    assign collisionPress = ~KEY[2];
    logic registeredUserPress;
    logic registeredCollisionPress;
	 logic [8:0] height; 
UserInput user (.clk(CLOCK_50), .reset, .q(registeredUserPress), .d(userPress));
UserInput user1 (.clk(CLOCK_50), .reset, .q(registeredCollisionPress), .d(collisionPress));
bird bird (.clk(clock100), .reset, .up(registeredUserPress), .height, .collision);
	
VideoBird videoVersion (.bird_height(height), .BirdLeft(birdLeft), .BirdRight(birdRight), .BirdTop(birdTop), .BirdBot(birdBot));     
    logic [9:0] x1, x2, x3;
    logic [8:0] yBot1, yTop1, yBot2, yTop2, yBot3, yTop3;
Obstacle obs1 (.clk(clock100), .reset, 
.startingYBottom(Constants::OBSTACLE_STARTING_HEIGHT_BOT), .startingX(Constants::OBSTACLE_STARTING_DISTANCE1), 
.startingYTop(Constants::OBSTACLE_STARTING_HEIGHT_TOP),
.yBot(yBot1), .x(x1), .yTop(yTop1), .collision(done)
);
Obstacle obs2 (.clk(clock100), .reset, 
.startingYBottom(Constants::OBSTACLE_STARTING_HEIGHT_BOT), .startingX(Constants::OBSTACLE_STARTING_DISTANCE2), 
.startingYTop(Constants::OBSTACLE_STARTING_HEIGHT_TOP),
.yBot(yBot2), .x(x2), .yTop(yTop2), .collision(done)
);
Obstacle obs3 (.clk(clock100), .reset, 
.startingYBottom(Constants::OBSTACLE_STARTING_HEIGHT_BOT), .startingX(Constants::OBSTACLE_STARTING_DISTANCE3), 
.startingYTop(Constants::OBSTACLE_STARTING_HEIGHT_TOP),
.yBot(yBot3), .x(x3), .yTop(yTop3), .collision(done)
);
    logic [8:0] birdTop, birdBot; //y (max, min)
    logic [8:0] birdLeft, birdRight; // x min max
    logic [8:0] yScreenMax, yScreenMin; 
    logic [8:0] finalYBot1, finalYTop1;
    logic [9:0] finalObsLeft1, finalObsRight1;
    logic [8:0] finalYBot2, finalYTop2;
    logic [9:0] finalObsLeft2, finalObsRight2;
    logic [8:0] finalYBot3, finalYTop3;
    logic [9:0] finalObsLeft3, finalObsRight3;
    assign yScreenMax = 9'd480;
    assign yScreenMin = 1'b0;
ObstacleVideoFormat addMoreSignals1 (.x(x1), .yBot(yBot1), .yTop(yTop1), 
.finalObsLeft(finalObsLeft1), .finalObsRight(finalObsRight1),
.finalYBot(finalYBot1), .finalYTop(finalYTop1));
ObstacleVideoFormat addMoreSignals2 (.x(x2), .yBot(yBot2), .yTop(yTop2), 
.finalObsLeft(finalObsLeft2), .finalObsRight(finalObsRight2),
.finalYBot(finalYBot2), .finalYTop(finalYTop2));
ObstacleVideoFormat addMoreSignals3 (.x(x3), .yBot(yBot3), .yTop(yTop3), 
.finalObsLeft(finalObsLeft3), .finalObsRight(finalObsRight3),
.finalYBot(finalYBot3), .finalYTop(finalYTop3));
    
    logic collision;
CollisionUnit collide (.reset, .birdTop, .birdBot, .birdLeft, .birdRight,
.finalYBot1, .finalYTop1, .finalObsLeft1, .finalObsRight1,
.finalYBot2, .finalYTop2, .finalObsLeft2, .finalObsRight2,
.finalYBot3, .finalYTop3, .finalObsLeft3, .finalObsRight3,
.yScreenMin, .yScreenMax, .collision);

    logic done; 
GameStateTracker FSM (.clk(CLOCK_50), .reset, .collision, .done, .up(registeredUserPress)); //want it to hold done state for a while
    logic [9:0] x;
	 logic [8:0] y; 
	 logic [7:0] r, g, b;
    logic [7:0] redGameOver, greenGameOver, yellowGameOver;
preGameDriver coloringLogic (.reset, .x, .y, .redGameOver, .greenGameOver, .yellowGameOver, 
.birdTop, .birdBot, .birdLeft, .birdRight, //bird dimensions
.finalObsLeft1, .finalObsRight1, .finalYBot1, .finalYTop1, //obstacle1 dimensions
.finalObsLeft2, .finalObsRight2, .finalYBot2, .finalYTop2, //obstacle2 dimensions
.finalObsLeft3, .finalObsRight3, .finalYBot3, .finalYTop3, //obstacle2 dimensions
.yScreenMax, .yScreenMin, //Screen dimensions
.done, .r, .g, .b);


video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50, .reset, .x, .y, .r, .g, .b,
			 .VGA_R, .VGA_G, .VGA_B, .VGA_BLANK_N,
			 .VGA_CLK, .VGA_HS, .VGA_SYNC_N, .VGA_VS);
    logic [4:0] count;
    logic [9:0] largest_values[2:0];
    logic [9:0] score;
counter cyclethroughMemory (.out(count), .clk(clock100), .reset, .collision); //fast clk

gameOverStorage memory (.address(count), .clock(CLOCK_50), .data(score), .wren(collision), .largest_values); //fast clk

ScoreCounterLogic currentScore(.clk(clock2Dot5), .reset, .done, .finalObsRight1, .finalObsRight2, .finalObsRight3,
.score(score));
    logic [29:0] out;
finalScoreStorage finalScore (.clk(CLOCK_50), .collision(done), .largest_values, .score, .out); //want displayed for a second or so
//score display
seg7 hex5(.hex(out[27:24]), .leds(HEX5));
seg7 hex4(.hex(out[23:20]), .leds(HEX4));

seg7 hex3(.hex(out[17:14]), .leds(HEX3));
seg7 hex2(.hex(out[13:10]), .leds(HEX2));

seg7 hex1 (.hex(out[7:4]), .leds(HEX1));
seg7 hex0 (.hex(out[3:0]), .leds(HEX0));

endmodule

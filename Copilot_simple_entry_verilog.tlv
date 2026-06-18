\m5_TLV_version 1d: tl-x.org
\m5
   / A development template for:
   /
   / /------------------------------------------------------------------------------\
   / | The Second Annual Makerchip ASIC Design Showdown, Summer 2026, Eleven Towers |
   / \------------------------------------------------------------------------------/
   /
   / Find details in the repository README.md, and
   / register at https://www.redwoodeda.com/showdown-info.
   /
   / Each player modifies this template to provide their own custom player
   / control circuitry. This template is for players using Verilog. A TL-Verilog-based
   / template is provided separately. Monitor the Showdown Slack channel for updates.
   /
   / Just 3 steps:
   /   - Prepare: Replace all YOUR_GITHUB_ID and YOUR_PLAYER_NAME.
   /   - Code: Code your logic where identified below.
   /   - Submit: Submit by the deadline (Mon. July 27, 11 PM IST/1:30 PM EDT), updated to the latest template.

   use(m5-1.0)
   
   macro(team_testplayer_verilog_module, ['
      module team_testplayer_verilog (
         input wire clk,
         input wire reset,
         // === Game Context ===
         input wire [2:0] num_players,              // Number of players in the game (2-5)
         input wire [2:0] my_player_index,          // Your player index (0-4)
         input wire [2:0] current_player,           // Index of current player (whose turn it is)
         input wire my_turn,                        // Asserted when it's your turn
         input wire [7:0] rolls_this_turn,          // Number of rolls taken this turn (valid when my_turn)
         // === Your Tower State ===
         input wire [3:0] tower_start_floor [12:2],    // Your locked-in floor on each tower
         input wire [3:0] tower_climb_floor [12:2],    // Your current turn floor on each tower (valid when my_turn)
         input wire [3:0] tower_height [12:2],         // Goal height to claim each tower
         input wire [3:0] turn_start_tower_floor [12:2],  // Your floor on each tower when this turn started
         input wire tower_climbing [12:2],             // Whether you've begun climbing this tower this turn
         input wire tower_claimed [12:2],              // Has any player claimed this tower?
         input wire [1:0] climbing_cnt,                // Number of towers you're currently climbing (max 3)
         input wire [2:0] claimed_cnt,                 // Number of towers you've claimed so far
         // === Pairing Options ===
         input wire [3:0] pairing_sum [2:0][1:0],      // Sum of dice for each pairing''s pairs
         // === Outputs ===
         output wire [15:0] pairing_score [2:0],       // Score for each of 3 pairings (higher is better)
         output wire [0:0] priority_pair [2:0],        // Which pair (0 or 1) gets priority for each pairing
         output wire end_turn                          // Assert to end turn voluntarily
      );

      // /------------------------------\
      // | Test Player Verilog Strategy |
      // \------------------------------/

      // Calculate score for each pairing
      // Strategy: Prefer progress and towers close to completion
      
      wire [3:0] progress [2:0][1:0];      // Progress for each pair in each pairing
      wire [3:0] remaining [2:0][1:0];     // Remaining floors for each pair
      wire [7:0] pair_value [2:0][1:0];    // Value of each pair
      wire good_progress;
      
      genvar p, i;
      generate
         for (p = 0; p < 3; p = p + 1) begin : pairing
            for (i = 0; i < 2; i = i + 1) begin : pair
               // Get tower properties for this pair's sum
               wire [3:0] sum = pairing_sum[p][i];
               wire [3:0] start_floor = tower_start_floor[sum];
               wire [3:0] climb_floor = tower_climb_floor[sum];
               wire [3:0] height = tower_height[sum];
               
               // Calculate progress and remaining floors
               assign progress[p][i] = climb_floor - start_floor;
               assign remaining[p][i] = height - climb_floor;
               
               // Pair value: prefer progress and short remaining distance
               assign pair_value[p][i] = {4'd0, progress[p][i]} + (8'd10 - {4'd0, remaining[p][i]});
            end
            
            // Score is sum of both pairs' values
            assign pairing_score[p] = {8'd0, pair_value[p][0]} + {8'd0, pair_value[p][1]};
            
            // If only one pair can build, prefer the one closer to completion
            assign priority_pair[p] = (pair_value[p][1] > pair_value[p][0]) ? 1'b1 : 1'b0;
         end
      endgenerate
      
      // Good progress = climbing at least 2 towers
      assign good_progress = climbing_cnt >= 2'd2;
      
      // End turn after 4 rolls, or after 3 rolls if making good progress
      assign end_turn = (rolls_this_turn >= 8'd4) || 
                        (good_progress && rolls_this_turn >= 8'd3);

      endmodule
   '])

   var(_SIG_ROOT, path_TBD)  /// Root path for Verilog signals for VIZ.

// [Optional]
// Visualization of your logic.
\TLV team_testplayer_verilog_viz(/_top, /_me, #player)
   \viz_js
      box: {width: 40, height: 100, strokeWidth: 1},
      where: {left: 50, top: 0, width: 40, height: 100},
      render() {
         // IMPORTANT! Show only during your turn (play nice with other players)
         m5_player_color(#player)
         let o = this.getObjects()
         o.box.set({stroke: player_color})
         o.box.group.set({opacity: '$my_turn'.asBool() ? 1 : 0})
         
         // Access signals for visualization  
         let rolls = '$rolls_this_turn'.asInt();
         let climbing_cnt = '$climbing_cnt'.asInt();
         let claimed_cnt = '$claimed_cnt'.asInt();
         let end_turn = '$end_turn'.asBool();
         let good_progress = climbing_cnt >= 2;  // Calculate locally
         
         // Get pairing scores
         let score0 = '/pairing[0]$score'.asInt();
         let score1 = '/pairing[1]$score'.asInt();
         let score2 = '/pairing[2]$score'.asInt();
         let best_score = Math.max(score0, score1, score2);
         
         // Get which towers are being climbed
         let climbing_towers = [];
         for (let t = 2; t <= 12; t++) {
            if ('/tower[t]$climbing'.asBool()) {
               climbing_towers.push(t);
            }
         }
         
         // Create visualization objects
         return [
            new fabric.Rect({
               left: 0, top: 0, width: 100, height: 100,
               fill: "#f0f0f0", strokeWidth: 0
            }),
            new fabric.Text("Test Player (V)", {
               left: 50, top: 5, originX: "center",
               fontSize: 7, fontFamily: "Roboto", fontWeight: "bold"
            }),
            new fabric.Text("Roll " + rolls + "/4 | Climb: " + climbing_cnt, {
               left: 50, top: 17, originX: "center",
               fontSize: 6, fontFamily: "Roboto"
            }),
            new fabric.Text(climbing_towers.length > 0 ? "Towers: " + climbing_towers.join(",") : "", {
               left: 50, top: 25, originX: "center",
               fontSize: 5, fontFamily: "Roboto", fill: "#666"
            }),
            new fabric.Text("Claimed: " + claimed_cnt + "/3", {
               left: 50, top: 33, originX: "center",
               fontSize: 6, fontFamily: "Roboto",
               fill: claimed_cnt >= 3 ? "#00aa00" : "#000000"
            }),
            new fabric.Text("Pairing Scores:", {
               left: 5, top: 43,
               fontSize: 5, fontFamily: "Roboto", fontWeight: "bold"
            }),
            new fabric.Text("0: " + score0, {
               left: 10, top: 51,
               fontSize: 5, fontFamily: "Roboto",
               fill: score0 === best_score ? "#0000ff" : "#666666",
               fontWeight: score0 === best_score ? "bold" : "normal"
            }),
            new fabric.Text("1: " + score1, {
               left: 10, top: 58,
               fontSize: 5, fontFamily: "Roboto",
               fill: score1 === best_score ? "#0000ff" : "#666666",
               fontWeight: score1 === best_score ? "bold" : "normal"
            }),
            new fabric.Text("2: " + score2, {
               left: 10, top: 65,
               fontSize: 5, fontFamily: "Roboto",
               fill: score2 === best_score ? "#0000ff" : "#666666",
               fontWeight: score2 === best_score ? "bold" : "normal"
            }),
            new fabric.Text(end_turn ? "ENDING TURN" : "Rolling...", {
               left: 50, top: 75, originX: "center",
               fontSize: 6, fontFamily: "Roboto", fontWeight: "bold",
               fill: end_turn ? "#cc0000" : "#00aa00"
            }),
            new fabric.Text(
               rolls >= 4 ? "(hit roll limit)" :
               (good_progress && rolls >= 3) ? "(good progress)" : "",
               {
                  left: 50, top: 85, originX: "center",
                  fontSize: 5, fontFamily: "Roboto", fill: "#666"
               }
            )
         ];
      }


\TLV team_testplayer_verilog(/_top, /_me, #player)
   m5+verilog_wrapper(/_top, /_me, #player, testplayer_verilog)
   m5+team_testplayer_verilog_viz(/_top, /_me, #player)


// Compete!
// This defines the competition to simulate (for development).
// When this file is included as a library (for competition), this code is ignored.
\SV
   // Include the Eleven Towers framework.
   m4_include_lib(['https://raw.githubusercontent.com/rweda/showdown-2026-eleven-towers/a7a75ffde289282804aae012bd1dcbef179adb78/eleven_towers_lib.tlv'])
   // Include other opponent files (based on eleven_towers_[verilog_]template.tlv) using GitHub raw URLs (similar to eleven_towers_lib.tlv, above).
   // ...

   m5_makerchip_module
\TLV
   // Enlist players for the game.
   
   // Your player. Provide:
   //   - your GitHub ID (as in your module name, above)
   //   - your player name--anything you like (that isn't crude or disrespectful)
   m5_define_player(testplayer_verilog, Test Player Verilog)
   // Choose your opponent(s) (up to you + 4 opponents).
   // To include code for other opponents, add a `include_lib` above.
   // Note that inactive players must be commented with "///", not "//", to prevent M5 macro evaluation.
   ///m5_define_player(random, Random 1)
   m5_define_player(seven, Seven Strategy)
   // Instantiate the Eleven Towers game.
   m5+eleven_towers_game(/top)
\SV
   endmodule
   
   // Declare Verilog module.
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 0)_module, ['m5_call(team_\m5_get_ago(github_id, 0)_module)'])
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 1)_module, ['m5_call(team_\m5_get_ago(github_id, 1)_module)'])

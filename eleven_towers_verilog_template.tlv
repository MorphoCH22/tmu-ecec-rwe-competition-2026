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
   /
   /
   / Module Interface:
   /
   / Your module receives the following inputs:
   /   clk, reset: Standard clock and reset signals
   /
   /   // === Game Context ===
   /   num_players[2:0]: Number of players in the game (2-5)
   /   my_player_index: This player's index (0-4)
   /   current_player: Index of current player (whose turn it is)
   /   my_turn: Asserted when it's your turn
   /   rolls_this_turn[7:0]: Number of rolls taken this turn (valid when my_turn)
   /
   /   // === Your Tower State ===
   /   tower_start_floor[12:2][3:0]: Your locked-in floor on each tower
   /   tower_climb_floor[12:2][3:0]: Your current turn floor on each tower (valid when my_turn)
   /   tower_height[12:2][3:0]: Goal height to claim each tower
   /   turn_start_tower_floor[12:2][3:0]: Your floor on each tower when this turn started
   /   tower_climbing[12:2]: Whether you've begun climbing this tower this turn
   /   tower_claimed[12:2]: Has any player claimed this tower?
   /   climbing_cnt[1:0]: Number of towers you're currently climbing (max 3)
   /   claimed_cnt[2:0]: Number of towers you've claimed so far
   /
   /   // === Pairing Options ===
   /   pairing_sum[2:0][1:0][3:0]: Sum of dice for each pairing's pairs
   /
   / Your module must provide the following outputs:
   /   pairing_score[2:0][15:0]: Score for each of 3 pairings (higher is better)
   /   priority_pair[2:0][0:0]: Which pair (0 or 1) gets priority for each pairing
   /   end_turn: Assert to end turn voluntarily
   /
   / Notes:
   /   - Towers are indexed [12:2] representing sums 2 through 12
   /   - Pairings are indexed [2:0] representing the 3 ways to pair 4 dice
   /   - Each pairing has 2 pairs [1:0], each containing 2 dice
   /   - Outputs should be combinational; highest score pairing is chosen
   /   - If my_turn is not asserted, outputs are ignored
   /
   / See also the game parameters and interface documentation in `eleven_towers_lib.tlv`.

   use(m5-1.0)
   
   macro(team_1269580875_module, ['
      module team_1269580875 (
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
      // | Your Verilog logic goes here |
      // \------------------------------/

      // TODO: make this a reg that changes per clock cycle
      wire [3:0] distance_from_top [12:2];
      assign distance_from_top  = tower_height - tower_climb_floor;
      
      // Example: Simple strategy - score each pairing randomly and end turn after 5 rolls
      
      // Random scoring for each pairing (replace with your strategy)
      // Highest score pair gets picked, in order of first pairs to last pairs
      
      // Check for most optimal pairing_sum that leads to smallest distance_from_top?
      assign pairing_score[0] = 16'd100;
      assign pairing_score[1] = 16'd200;
      assign pairing_score[2] = 16'd150;
      
      // Priority pair selection (replace with your logic)
      assign priority_pair[0] = 1'b0;
      assign priority_pair[1] = 1'b0;
      assign priority_pair[2] = 1'b0;
      
      // End turn strategy (replace with your logic)
      // Always end at 3 or tower completion
      // Maybe factor in number of towers climbing too
      // TODO: Something like end_turn = (rolls_this_turn >= 8'd3) || (distance_from_top[12:2] == 0)
      assign end_turn = (rolls_this_turn >= 8'd3);

      endmodule
   '])

   var(_SIG_ROOT, path_TBD)  /// Root path for Verilog signals for VIZ.

// [Optional]
// Visualization of your logic.
\TLV team_1269580875_viz(/_top, /_me, #player)
   /// Define m5_mySigVal() for accessing Verilog signals in your module.
   /// Called similar to sigVal() but without the need for the Verilog module path and without quotes.
   /// Example: m5_mySigVal(rolls_this_turn)  // names as seen in WAVEFORM w/ "." as hierarchy separator
   m5_macro(mySigVal, ['['this.sigVal("team_1269580875_']#player.$']['1['")']'])
   \viz_js
      box: {width: 40, height: 100, strokeWidth: 1},
      where: {left: 50, top: 0, width: 40, height: 100},
      render() {
         // IMPORTANT! Show only during your turn (play nice with other players)
         m5_player_color(#player)
         let o = this.getObjects()
         o.box.set({stroke: player_color})
         o.box.group.set({opacity: '$my_turn'.asBool() ? 1 : 0})
         
         // Access your signals for visualization
         // Note: For Verilog modules, access signals using this.sigVal("team_1269580875.signal_name")
         const rolls = m5_mySigVal(rolls_this_turn).asInt();

         // Return fabric.js objects to display
         return [
            new fabric.Text(`Roll ${rolls}`, {
               left: 20, top: 40, originX: "center",
               fontSize: 8, fontFamily: "Roboto"
            })
         ];
      }


\TLV team_1269580875(/_top, /_me, #player)
   m5+verilog_wrapper(/_top, /_me, #player, 1269580875)
   ///m5+team_1269580875_viz(/_top, /_me, #player)   /// Uncomment line ("///") to enable custom visualization



// Compete!
// This defines the competition to simulate (for development).
// When this file is included as a library (for competition), this code is ignored.
\SV
   // Include the Eleven Towers framework.
   // TODO: Update to a specific SHA in rweda repo after finalizing the framework for the season.
   m4_include_lib(['https://raw.githubusercontent.com/rweda/showdown-2026-eleven-towers/a7a75ffde289282804aae012bd1dcbef179adb78/eleven_towers_lib.tlv'])
   // Include other opponent files (based on eleven_towers_[verilog_]template.tlv) using GitHub raw URLs (similar to eleven_towers_lib.tlv, above).
   // ...

   m5_makerchip_module
\TLV
   // Enlist players for the game.
   
   // Your player. Provide:
   //   - your GitHub ID (as in your module name, above)
   //   - your player name--anything you like (that isn't crude or disrespectful)
   m5_define_player(1269580875, TMU_ECEC)
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

// This file must not exceed 6,000 lines. The expanded NAV-TLV code must not exceed 9,000 lines.
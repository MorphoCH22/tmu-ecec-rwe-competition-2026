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
   / control circuitry. This template is for players using TL-Verilog. A Verilog-based
   / template is provided separately. Monitor the Showdown Slack channel for updates.
   /
   / Just 3 steps:
   /   - Prepare: Replace all YOUR_GITHUB_ID and YOUR_PLAYER_NAME.
   /   - Code: Code your logic where identified below.
   /   - Submit: Submit by the deadline (Mon. July 27, 11 PM IST/1:30 PM EDT), updated to the latest template.
   /
   /
   / Your circuit should drive the following signals:
   /   /pairing[2:0]
   /      $score[15:0]: Score for each of the 3 possible dice pairings (higher score = better).
   /                    The pairing with the highest score is chosen.
   /      $priority_pair[0:0]: Which pair (0 or 1) gets priority if only one can start building.
   /   $end_turn: Assert to voluntarily end your turn and bank progress.
   /
   / Based on the following inputs (accessible within /_me scope, e.g. /_me$my_turn):
   /   $my_turn: Asserted when it's your turn.
   /   $rolls_this_turn[7:0]: Number of rolls taken this turn (valid when $my_turn).
   /   $num_players[2:0]: Number of players in the game (2-5).
   /   $my_player_index: This player's index (0-4).
   /   $current_player: Index of current player (whose turn it is).
   /   /pairing[2:0] -- 3 possible pairings of the dice
   /      /pair[1:0] -- 2 pairs per pairing
   /         /die[1:0] -- 2 dice per pair
   /            $value[2:0]: Die value (1-6)
   /         $sum[3:0]: Sum of the pair (determines tower)
   /         // Properties of the $sum tower (that this pair would build):
   /         $start_floor[3:0]: Your locked-in floor for this tower at turn start.
   /         $climb_floor[3:0]: Current climb floor for this tower during turn.
   /         $tower_height[3:0]: Goal floor to claim this tower.
   /   /tower[12:2] -- Your tower state (valid when $my_turn)
   /      $tower_height[3:0]: Goal floor to claim this tower.
   /      $turn_start_floor[3:0]: Your locked-in floor when turn started.
   /      $climb_floor[3:0]: Current floor during this turn (before ending turn).
   /      $climbing: Whether you've begun climbing this tower this turn.
   /      $claimed: Has any player claimed this tower? (blocks further building)
   /   $climbing_cnt[1:0]: Number of towers you're climbing this turn (max 3).
   /   $claimed_cnt[2:0]: Number of towers you've claimed so far.
   / And from the /_top scope (e.g. /_top/player[#player]/tower[2]$floor):
   /   /player[m5_PLAYER_MAX:0] -- All players' state ([#player] is yourself)
   /      /tower[12:2] -- Each tower's state for this player
   /         $max[3:0]: Max floor of this tower (same for all players).
   /         $floor[3:0]: Locked-in floor for this player.
   /         $claimed: Whether this player has claimed this tower.

   use(m5-1.0)


// Modify this TL-Verilog macro to implement your control circuitry.
// Replace YOUR_GITHUB_ID with your GitHub ID, excluding non-word characters (alphabetic, numeric,
// and "_" only)
// Args (these are text substituted):
//   /_top: The top-level game scope, which contains the entire game state.
//   /_me: This player logic scope (the scope of the /TLV team_* macro)
//   #player: This player's index (0, 1, ...)
// See example opponent logic in `eleven_towers_lib.tlv` for reference.
\TLV team_testplayer(/_top, /_me, #player)
   
   //-----------------------\
   //  Your Code Goes Here  |
   //-----------------------/
   
   // Simple strategy: Prefer taller towers and quit after 3-5 rolls depending on progress
   ?$my_turn
      /pairing[2:0]
         /pair[1:0]
            // Properties available directly in /pair scope (from template):
            // $sum, $start_floor, $climb_floor, $tower_height
            // Calculate how close we are to claiming this tower
            $remaining_floors[3:0] = $tower_height - $climb_floor;
            // Prefer towers we're making progress on
            $progress[3:0] = $climb_floor - $start_floor;
            // Simple value: prefer progress and shorter remaining distance
            $pair_value[7:0] = {4'd0, $progress} + (8'd10 - {4'd0, $remaining_floors});
         
         // Score is sum of both pairs' values
         $score[15:0] = {8'd0, /pair[0]$pair_value} + {8'd0, /pair[1]$pair_value};
         
         // If only one pair can build, prefer the one closer to completion
         $priority_pair[0:0] = /pair[1]$pair_value > /pair[0]$pair_value ? 1'b1 : 1'b0;
      
      // Simple end-turn logic: stop after 4 rolls, or earlier if we've made good progress
      $good_progress = $climbing_cnt >= 2'd2;  // Climbing at least 2 towers
      $end_turn = ($rolls_this_turn >= 8'd4) || 
                  ($good_progress && $rolls_this_turn >= 8'd3);
   
   
   // [Optional]
   // Custom visualization for debugging (appears to the right of game board)
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
         let good_progress = '$good_progress'.asBool();
         
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
            new fabric.Text("Test Player", {
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
   //   - your GitHub ID (as in your \TLV team_* macro, above)
   //   - your player name--anything you like (that isn't crude or disrespectful)
   m5_define_player(testplayer, Test Player)
   
   // Choose your opponent(s) (up to you + 4 opponents).
   // "random" and "seven" are example opponents defined in eleven_towers_lib.tlv.
   // To include code for other opponents, add a `include_lib` above.
   // Note that inactive players must be commented with "///", not "//", to prevent M5 macro evaluation.
   ///m5_define_player(random, Random Player)
   m5_define_player(seven, Seven Strategy)
   
   // Instantiate the Eleven Towers game.
   m5+eleven_towers_game(/top)
\SV
   endmodule

\m5_TLV_version 1d --inlineGen: tl-x.org
\m5
   / The Second Annual Makerchip ASIC Showdown, Summer 2026: Eleven Towers
   / This file is the library providing the content.
   / See the repo's README.md for more information.

   / A library for Makerchip that provides a game with gameplay similar to the
   / Can't Stop game from Parker Brothers.
   
   use(m5-1.0)
   
   
   / Provide a library defining a team's control circuit, name, and ID.
   fn(team_raw_tlv, ?TlvFile, {
      / Include submitted TLV URL, reporting an error if it produces text output.
      if_null(m4_include_lib(m5_TlvFile), [
         error(['The following TL-Verilog library produced output text. Ignoring']m5_nl    m5_TlvFile)
      ])
      on_return(var, github_id, m5_github_id)   /// Preserve what the library defined after it gets popped by the return.
      on_return(var, team_name, m5_team_name)   ///   "
   })
   
   var(num_players, 0)  // incremented as defined
   
   / Define which TLV macro to use for this player.
   / E.g. m5_define_player(random, Joe Random)  /// to define a "Joe Random" player with predefined random behavior from m5_player_random
   fn(define_player, PlayerId, PlayerName, {
      on_return(var, github_id, m5_PlayerId)
      on_return(var, player_name, m5_PlayerName)
      on_return(increment, ['num_players'])
   })

   // Output a list of player color hex codes, using the given delimiter.
   fn(player_colors, Delim, {
      ~for(Color, ['d01010, d0d010, 109010, 1010d0, d06010'], {
         ~if(m5_LoopCnt != 0, ['m5_Delim'])
         ~Color
      })
   })

   macro(index_by_player, ['m5_get_ago($1, m5_calc(m5_PLAYER_MAX - $2))'])

   / Macro to get player color from render().
   / $1: Player index
   macro(player_color, ['let player_color = this.getScope("game").context.player_color[$1]'])

   macro(DefaultTeamVizBoxAndWhere, ['box: {width: 210, height: 105, left: -55, top: -2.5, strokeWidth: 0}, where: {left: 0, top: 0, width: 80, height: 120},'])
   

   macro(configure, [
      define_hier(PLAYER, m5_num_players)

      var(die_size, 7.2)
      var(die_stroke_width, 0)
      var(pip_radius, 0.78)
      /Characterize the layout of pieces on the tower.
      var(piece_height, 10)
      var(piece_width, 10)
      var(piece_layout_left, (2.5 - 0.2 * m5_PLAYER_CNT))
      var(tower_separation, (11 + m5_PLAYER_CNT * 1.5))
      var(piece_layout_top, -1.0)
      var(tower_left, (m5_tower_separation - m5_piece_width) / 2)
      var(active_tower_width, m5_piece_width)

      / Push random players and names if github_id's are not already defined.
      repeat(m5_PLAYER_CNT, [
         if(m5_depth_of(github_id) < m5_PLAYER_CNT, [
            var(github_id, random)
         ])
      ])
      repeat(m5_PLAYER_CNT, [
         if(m5_depth_of(player_name) < m5_PLAYER_CNT, [
            var(player_name, Random Player m5_LoopCnt)
         ])
      ])

      var(Uniquifier, 0)   /// Used to provide unique names.
   ])
   
// --------------- For the Verilog template ---------------
// 
// The verilog_wrapper expects a SystemVerilog module with the following interface:
//
// module team_<GITHUB_ID> (
//    input wire clk,
//    input wire reset,
//    // === Game Context ===
//    input wire [2:0] num_players,                 // Number of players in the game (2-5)
//    input wire [m5_PLAYER_INDEX_RANGE] my_player_index, // This player's index (0-4)
//    input wire [m5_PLAYER_INDEX_RANGE] current_player,  // Index of current player (whose turn it is)
//    input wire my_turn,                           // Asserted when it's this player's turn
//    input wire [7:0] rolls_this_turn,             // Number of rolls taken this turn (valid when my_turn)
//    // === My Tower State ===
//    input wire [3:0] tower_start_floor [12:2],    // My locked-in floor on each tower
//    input wire [3:0] tower_climb_floor [12:2],    // My current turn floor on each tower (valid when my_turn)
//    input wire [3:0] tower_height [12:2],         // Goal height to claim each tower
//    input wire [3:0] turn_start_tower_floor [12:2],  // My floor on each tower when this turn started
//    input wire tower_climbing [12:2],             // Whether I've begun climbing this tower this turn
//    input wire tower_claimed [12:2],              // Has any player claimed this tower?
//    input wire [1:0] climbing_cnt,                // Number of towers I'm currently climbing (max 3)
//    input wire [2:0] claimed_cnt,                 // Number of towers I've claimed so far
//    // === Pairing Options ===
//    input wire [3:0] pairing_sum [2:0][1:0],      // Sum of dice for each pairing's pairs
//    // === Outputs ===
//    output wire [15:0] pairing_score [2:0],       // Score for each of 3 pairings (higher is better)
//    output wire [0:0] priority_pair [2:0],        // Which pair (0 or 1) gets priority for each pairing
//    output wire end_turn                          // Assert to end turn voluntarily
// );
//
// Notes:
//   - Towers are indexed [12:2] representing sums 2 through 12
//   - Pairings are indexed [2:0] representing the 3 ways to pair 4 dice
//   - Each pairing has 2 pairs [1:0], each containing 2 dice
//   - Score should be combinational; highest score pairing is chosen
//   - If my_turn is not asserted, outputs are ignored

\TLV verilog_wrapper(/_top, /_player, _player_num, _github_id)
   \SV_plus
      // Intermediate unpacked arrays for module connections
      logic [3:0] id['_']_player_num['']tower_start_floor [12:2];
      logic [3:0] id['_']_player_num['']tower_climb_floor [12:2];
      logic [3:0] id['_']_player_num['']tower_height [12:2];
      logic [3:0] id['_']_player_num['']turn_start_tower_floor [12:2];
      logic id['_']_player_num['']tower_climbing [12:2];
      logic id['_']_player_num['']tower_claimed [12:2];
      logic [3:0] id['_']_player_num['']pairing_sum [2:0][1:0];
      
      // Output signal arrays
      logic [15:0] id['_']_player_num['']pairing_score [2:0];    // Score for each pairing
      logic [0:0]  id['_']_player_num['']priority_pair [2:0];    // Priority pair for each pairing
      logic        id['_']_player_num['']end_turn;               // End turn signal
      
      // Instantiate the player's SystemVerilog module
      team_['']_github_id team_['']_github_id['_']_player_num[''](
         // Inputs:
         .clk(clk),
         .reset(/_player$reset),
         // Game context
         .num_players(/_player$num_players),
         .my_player_index(/_player$my_player_index),
         .current_player(/_player$current_player),
         .my_turn(/_player$my_turn),
         .rolls_this_turn(/_player$rolls_this_turn),
         // My tower state (unpacked arrays)
         .tower_start_floor(id['_']_player_num['']tower_start_floor),
         .tower_climb_floor(id['_']_player_num['']tower_climb_floor),
         .tower_height(id['_']_player_num['']tower_height),
         .turn_start_tower_floor(id['_']_player_num['']turn_start_tower_floor),
         .tower_climbing(id['_']_player_num['']tower_climbing),
         .tower_claimed(id['_']_player_num['']tower_claimed),
         .climbing_cnt(/_player$climbing_cnt),
         .claimed_cnt(/_player$claimed_cnt),
         // Pairing options (unpacked array)
         .pairing_sum(id['_']_player_num['']pairing_sum),
         // Outputs:
         .pairing_score(id['_']_player_num['']pairing_score),
         .priority_pair(id['_']_player_num['']priority_pair),
         .end_turn(id['_']_player_num['']end_turn)
      );
   
   // Connect tower arrays element-by-element
   /tower[12:2]
      *id['_']_player_num['']tower_start_floor\[#tower\] = /_top/player[_player_num]/tower[#tower]$Floor;
      *id['_']_player_num['']tower_climb_floor\[#tower\] = /_top/active_player/tower[#tower]$ClimbFloor;
      *id['_']_player_num['']tower_height\[#tower\] = /_top/active_player/tower[#tower]$tower_height;
      *id['_']_player_num['']turn_start_tower_floor\[#tower\] = /_top/player[_player_num]/tower[#tower]$TurnStartFloor;
      *id['_']_player_num['']tower_climbing\[#tower\] = /_top/active_player/tower[#tower]$climbing;
      *id['_']_player_num['']tower_claimed\[#tower\] = /_top/active_player/tower[#tower]$claimed;
   
   // Connect pairing arrays element-by-element
   /pairing[2:0]
      /pair[1:0]
         *id['_']_player_num['']pairing_sum\[#pairing\]\[#pair\] = /_top/pairing[#pairing]/pair[#pair]$sum;
      
      // Map SystemVerilog outputs back to TLV signals
      $score[15:0] = *id['_']_player_num['']pairing_score\[#pairing\];
      $priority_pair[0:0] = *id['_']_player_num['']priority_pair\[#pairing\];
   
   $end_turn = *id['_']_player_num['']end_turn;

//
// Simple example opponents:
//
// Random Opponent
// Chooses random scores and ends turn randomly.
\TLV team_random(/_top, /_me, #player)
   /pairing[2:0]
      m4_rand($rand, 31, 0, pairing)
      $score[7:0] = $rand % 256;
      $priority_pair[0:0] = 1'b0;
   m4_rand($rand_end_turn, 0, 0)  // [0:0] (vs. boolean)
   $end_turn = $rand_end_turn;

// Prioritize 7 Opponent
// Choose a pairing with seven if possible, or without seven if seven is claimed.
// Roll 5 times until 7 is claimed, then 3.
\TLV team_seven(/_top, /_me, #player)
   // Has any player claimed tower 7?
   ?$my_turn
      $claimed7 = /tower[7]$claimed;
      // Have I rolled a 7 pairing?
      /pairing[2:0]
         /pair[1:0]
            $is7 = $sum == 4'd7;
         $score[0:0] = | /pair[*]$is7 ^ /_me$claimed7;
         $priority_pair[0:0] = 1'b0;
      $limit[7:0] = $claimed7 ? 8'd3 : 8'd5;
      $end_turn = $rolls_this_turn >= $limit || ($claimed7 && /tower[7]$climbing);
   
   // Example custom visualization
   \viz_js
      box: {width: 40, height: 100, strokeWidth: 1},
      where: {left: 50, top: 0, width: 40, height: 100},
      render() {
         // IMPORTANT! (Play nice with others.)
         // Show (with colored border) only if it's my turn.
         m5_player_color(#player)
         let o = this.getObjects()
         o.box.set({stroke: player_color})
         o.box.group.set({opacity: '$my_turn'.asBool() ? 1 : 0})
         
         // Represent these signals
         let claimed7 = '$claimed7'.asBool();
         let rolls = '$rolls_this_turn'.asInt();
         let limit = '$limit'.asInt();
         
         // Create and return the visualization objects.
         return [
            new fabric.Rect({
               left: 0, top: 0, width: 100, height: 100,
               fill: "#f0f0f0", strokeWidth: 0
            }),
            new fabric.Text("Seven Strategy", {
               left: 50, top: 10, originX: "center",
               fontSize: 7, fontFamily: "Roboto", fontWeight: "bold"
            }),
            new fabric.Text(`Tower 7: ${claimed7 ? "Claimed" : "Available"}`, {
               left: 50, top: 30, originX: "center",
               fontSize: 6, fontFamily: "Roboto",
               fill: claimed7 ? "#cc0000" : "#00aa00"
            }),
            new fabric.Text(`Roll ${rolls} / ${limit}`, {
               left: 50, top: 45, originX: "center",
               fontSize: 6, fontFamily: "Roboto"
            })
         ];
      }


// Logic shared by /_top/player#
\TLV player_logic(/_top, #player_num)
   /player['']#player_num
      $reset = /_top$reset;
      // Game context (providing consistent access as pipesignals)
      $num_players[2:0] = m5_PLAYER_CNT;
      $my_player_index[m5_PLAYER_INDEX_RANGE] = #player_num;
      $current_player[m5_PLAYER_INDEX_RANGE] = /_top$Player;
      
      $my_turn = #player_num == /_top$Player;
      ?$my_turn
         $ANY = /_top/active_player$ANY;
         $rolls_this_turn[7:0] = /_top/active_player$RollCnt;  // (pipesignal variant for consistency)
      /tower[12:2]
         $my_turn = /player['']#player_num$my_turn;
         $turn_start_floor[3:0] = /_top/player[#player_num]/tower[#tower]$TurnStartFloor;  // (pipesignal variant for consistency)
         ?$my_turn
            $ANY = /_top/active_player/tower[#tower]$ANY;
            $climb_floor[3:0] = /_top/active_player/tower[#tower]$ClimbFloor;
            `BOGUS_USE($floor $climb_floor $climbing $tower_height $turn_start_floor $claimed)   // (to make visible in DIAGRAM and avoid no-use warnings)
      `BOGUS_USE($climbing_cnt $claimed_cnt $color $rolls_this_turn $num_players $my_player_index $current_player)
      `BOGUS_USE($reset $my_turn)
      /pairing[2:0]
         //$ANY = /_top/pairing$ANY;
         /pair[1:0]
            $ANY = /_top/pairing/pair$ANY;
            /die[1:0]
               $ANY = /_top/pairing/pair/die$ANY;
               `BOGUS_USE($value)
         /* verilator lint_save */
         /* verilator lint_off width */
         $score16[15:0] = $score;
         /* verilator lint_restore */
      m5_var(my_github_id, m5_index_by_player(github_id, #player_num))
      m5+call(team_\m5_my_github_id, /_top, /player['']#player_num, #player_num)

\TLV define_players(/_top)
   m5_if(m5_PLAYER_CNT > 0, ['m5+player_logic(/_top, 0)'])
   m5_if(m5_PLAYER_CNT > 1, ['m5+player_logic(/_top, 1)'])
   m5_if(m5_PLAYER_CNT > 2, ['m5+player_logic(/_top, 2)'])
   m5_if(m5_PLAYER_CNT > 3, ['m5+player_logic(/_top, 3)'])
   m5_if(m5_PLAYER_CNT > 4, ['m5+player_logic(/_top, 4)'])
   ///// TODO: We're using fixed indentation here. Need to update tlv_lib to use M5.
   ///m5_repeat(m5_num_players, ['m5_nl()                  m5+player_logic(/_top, m5_LoopCnt)m5_nl'])

\TLV eleven_towers_game(/_top)
   |game
      @1
         m5+eleven_towers_logic(|game)
         *passed = $passed;
         *failed = $failed;

\TLV eleven_towers_logic(/_top)
   m5_configure()
   
   $reset = *reset;
   
   \SV_plus
      logic[3:0] *max[12:2] = {4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd10, 4'd8, 4'd6, 4'd4, 4'd2};
      logic[23:0] *colors[0:4] = {24'h\m5_player_colors([', 24'h'])};
   
   
   // -------------------------
   // Game State
   
   // Which player's turn is it?
   $next_player[m5_PLAYER_INDEX_RANGE] =
        $Player == m5_PLAYER_MAX ? m5_PLAYER_INDEX_HIGH'd0 :
                                   $Player + m5_PLAYER_INDEX_HIGH'd1;
   $Player[m5_PLAYER_INDEX_RANGE] <=
        $reset                   ? 1'b0 :
        /active_player$turn_over ? $next_player :
                                   $RETAIN;
   
   /active_player
      $color[23:0] = *colors\[/_top$Player\];
      
      // Track rolls this turn
      $RollCnt[7:0] <= $reset ? 8'b0 :
                       $turn_over ? 8'b0 :
                                    $RollCnt + 8'b1;
      
      /tower[12:2]
         \viz_js
            box: {width: m5_tower_separation, height: 170, strokeWidth: 0},
            layout: "horizontal",
            init() {
               this.tower_heights = [2, 4, 6, 8, 10, 12, 10, 8, 6, 4, 2]
               
               this.top = function (pos) {
                  return 2 + 12 * (13 - pos)
               }
               
               this.makeRect = function (pos, color, z) {
                  return new fabric.Rect({left: m5_tower_left + z * m5_piece_layout_left, top: this.top(pos) + z * m5_piece_layout_top,
                                          width: m5_active_tower_width, height: m5_piece_height,
                                          fill: color, strokeWidth: 0,
                                        })
               }
               
               let ret = {}
               
               // Towers.
               let height = this.tower_heights[this.getIndex() - 2]
               for (let i = 1; i <= height + 1; i++) {
                  ret[i] = this.makeRect(i, pos == height + 1 ? "#303030" : "#707070", 0)
               }
               
               // Tower numbers.
               let props = {originX: "center", originY: "center", fill: "white", fontSize: 6, fontFamily: "Roboto"}
               let index_str = this.getIndex().toString()
               ret.tower_num_circle = new fabric.Circle({radius: 6, left: m5_tower_separation / 2, top: this.top(0) + m5_piece_height / 2,
                                                         originX: "center", originY: "center", fill: "transparent"})
               ret.tower_num_bottom = new fabric.Text(index_str, {left: m5_tower_separation / 2, top: this.top(0) + m5_piece_height / 2, ...props})
               ret.tower_num_top = new fabric.Text(index_str, {left: m5_tower_separation / 2, top: this.top(height + 1) + m5_piece_height / 2, ...props})
               this.tower_num_top_set = false
               
               return ret
            },
            render() {
               let tower = this.getIndex()
               let objs = this.getObjects()
               let active_player = '/_top$Player'.asInt()
               
               //
               // Tower background and highlighting.
               //
               
               // Background square gray colors.
               for (let i = 1; i <= '$max'.asInt() + 1; i++) {
                  objs[i].set({fill: (i == '$max'.asInt() + 1
                                         ? ('$next_climbing'.asBool() ? "#a0a0a0" : "#303030")
                                         : "#707070"
                  )})
               }
               
               // Circle the pair numbers.
               let pair0_matches = '/chosen_pair[0]$matches'.asBool()
               let pair1_matches = '/chosen_pair[1]$matches'.asBool()
               let both_match = pair0_matches && pair1_matches
               let color = both_match    ? "#808080A0" :
                           pair0_matches ? "#FFFFFF60" :
                           pair1_matches ? "#00000060" :
                                           "transparent"
               objs.tower_num_circle.set({fill: color})
               
               
               //
               // Place player pieces.
               //
               
               // Determine the pieces in this tower.
               let pieces = []  // each entry, if defined, is a list of pieces for the indexed height.
               for (let player = 0; player < m5_PLAYER_CNT; player++) {
                  let floor = '/_top/player[player]/tower[tower]$Floor'.asInt()
                  if (pieces[floor]) {
                     pieces[floor].push(player)
                  } else {
                     pieces[floor] = [player]
                  }
               }
               
               // Remove [0], which is not on the board.
               delete pieces[0]
               
               // Properly order and create the pieces.
               let ret = []
               for (let floor in pieces) {
                  
                  // If there are multiple pieces at this floor, determine their proper order.
                  if (pieces.length > 1) {
                     // Need to determine order.
                     let ordered = []  // pieces[floor] properly ordered
                     // Search back in time, removing players.
                     let step = 0
                     do {
                        pieces[floor].forEach((player, i) => {
                           // If this player was played this step, remove it from pieces[floor]
                           // and add it to ordered.
                           let h = '/_top/player[player]/tower[tower]$Floor'.step(step).asInt(null)
                           if (h === null) {
                              console.log(`\VIZ BUG: Didn''t find cycle at which player ${player} reached floor ${floor} in tower ${tower}.`)
                              pieces[floor] = []
                           } else if (h != floor) {
                              pieces[floor].splice(i, 1)
                              ordered.unshift(player)
                           }
                        })
                        step--
                     } while(pieces[floor].length)
                     // Replace pieces[floor] with the properly ordered list.
                     pieces[floor] = ordered
                  }
                  
                  // Create the pieces.
                  pieces[floor].forEach((player, i) => {
                     console.log(`Piece: tower: ${tower}, floor: ${floor}, player: ${player}, i: ${i}`)
                     m5_player_color(player)
                     ret.push(this.makeRect(floor, player_color, i))
                  })
               }
               
               // Add the turn marker, if there is one.
               let climb_floor = '$my_next_climb_floor'.asInt()
               if (climb_floor > '/_top/player[active_player]/tower[tower]$Floor'.asInt()) {
                  ret.push(this.makeRect(climb_floor, "white", pieces[climb_floor] ? pieces[climb_floor].length : 0))
               }
               
               return ret
            },
            where: {left: -m5_tower_separation * 5.5, top: 0},
      \viz_js
         box: {left: -105, top: 0, width: 210, height: 170, strokeWidth: 0},
         where: {left: -40, top: 17, width: 80, height: 56, justifyX: "center", justifyY: "top"},
            
   /m5_PLAYER_HIER
      /tower[12:2]
         $max[3:0] = *max\[#tower\];
         $tower_height[3:0] = *max\[#tower\] + 1;
         // Track height at turn start (for progress assessment)
         $TurnStartFloor[3:0] <=
              /_top$reset ? 4'b0 :
              /_top/active_player$turn_over && /_top$next_player == #player ? $Floor :
                            $RETAIN;
         $Floor[3:0] <=
              /_top$reset ? 4'b0 :
              ! /_top/active_player$end_turn || /_top/active_player$bust
                          ? $RETAIN :
              // successful end-of-turn
              /_top$Player == #player  // for me
                          ? /_top/active_player/tower$my_next_climb_floor :
              // for my opponent
              /_top/active_player/tower$my_next_climb_floor >= $tower_height
                          // and this tower is complete for them
                          ? 4'b0 :
              // and they did not complete this tower
                            $RETAIN;
         $floor[3:0] = $Floor;  // Just to avoid the need for users to understand state signals.
         // Reached the max (claimed the tower).
         $claimed = $Floor == $tower_height;
   
   // -------------------------
   // Dice
   
   // Four rolled dice values.
   /die[3:0]
      \SV_plus
         always_ff @(posedge clk) begin
            $$rand[31:0] <= \$random;
         end
      $value[2:0] = $rand[31:0] % 6 + 1;
      \viz_js
         box: {width: 10, height: 10, strokeWidth: 0},
         render() {
            let top_context = this.getScope("m5_strip_prefix(/_top)").context
            let pip_color = this.getIndex("die") == 0 || '/_top/active_player/pairing[(this.getIndex("die") + 2) % 3]$chosen'.asBool() ? "white" : "black"
            return [top_context.die('/_top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
         },
         where: {left: -12.5, top: 73, width: 25, height: 10, justifyX: "center", justifyY: "bottom"}
   
   // Possible die pairings:
   //   Pair: 0       1
   //   Die:0  1    0  1
   //   0: [0, 1], [2, 3]
   //   1: [0, 2], [1, 3]
   //   2: [0, 3], [1, 2]
   /pairing[2:0]
      /pair[1:0]
         $sum[3:0] = /die[0]$value + /die[1]$value;
         // Locked-in floor.
         $start_floor[3:0] = /_top/player[/_top$Player]/tower[$sum]$Floor;
         // Floor within turn.
         $climb_floor[3:0] = /_top/active_player/tower[$sum]$ClimbFloor;
         $tower_height[3:0] = *max\[$sum\] + 1;
         // These may or may not be used by the players.
         `BOGUS_USE($start_floor $climb_floor $tower_height)
         /die[1:0]
            $value[2:0] = /_top/die[
                 #pair == 0 ? #pairing * #die + #die \:
                 #die == 0  ? (#pairing == 0 ? 2 \: 1) \:
                              (#pairing == 2 ? 2 \: 3)
               ]$value;

   \viz_js
      box: {left: -50, top: 0, width: 100, height: 100, fill: "#40a070", strokeWidth: 0},
      init() {
         // Player colors.
         this.player_color = ["#m5_player_colors(['", "#'])"]
         
         // Create a die.
         this.die = (player, pip_color, value, left, top, scale) => {
            pip = function (left, top) {
               return new fabric.Circle(
                  {left, top, radius: m5_pip_radius,
                   fill: pip_color, strokeWidth: 0, originX: "center", originY: "center"
                  }
               )
            }
            let die = new fabric.Group(
               [new fabric.Rect(
                  {width: m5_die_size + m5_die_stroke_width, height: m5_die_size + m5_die_stroke_width,
                   rx: 0.8, ry: 0.8,
                   originX: "center", originY: "center",
                   fill: this.player_color[player], strokeWidth: m5_die_stroke_width, stroke: "gray",
                  }
                )
               ],
               {left, top, scaleX: scale, scaleY: scale, originX: "center", originY: "center"}
            )
            if (value % 2) {
               // Add center pip.
               die.add(pip(0, 0))
            }
            let edge_delta = 2
            if (value > 1) {
               die.add(pip(edge_delta, -edge_delta))
               die.add(pip(-edge_delta, edge_delta))
            }
            if (value > 3) {
               die.add(pip(edge_delta, edge_delta))
               die.add(pip(-edge_delta, -edge_delta))
            }
            if (value == 6) {
               die.add(pip(-edge_delta, 0))
               die.add(pip(edge_delta, 0))
            }
            die.addWithUpdate()
            return die
         }
         
         return {}
      },
   m5+define_players(/_top)
   
   /active_player
      $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt$ANY : ']) /_top/player\m5_calc(m5_num_players-1)$ANY;
      /pairing[2:0]
         \viz_js
            box: {left: -26, top: -7, width: 52, height: 14, strokeWidth: 0, rx: 3, ry: 3},
            layout: {left: 0, top: 15},
            renderFill() {
               return '$chosen'.asBool() ? "#A0A0D0" : "transparent"
            },
            render() {
               return [new fabric.Text('$score16'.asInt().toString(), {
                                       left: -27, top: 0, originX: "right", originY: "center",
                                       fontSize: 7, fontFamily: "Roboto", fill: "black"})]
            },
            where: {left: -8, top: 86, width: 16, height: 10, justifyX: "center", justifyY: "bottom"},
         $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing$ANY;
         `BOGUS_USE($score16 $priority_pair)
         // Compare with next, giving priority
         $better_than_next = $score16 >  /pairing[(#pairing + 1) % 3]$score16;
         $equal_to_next    = $score16 == /pairing[(#pairing + 1) % 3]$score16;
         // Choice, prioritizing 0.
         $chosen =
            #pairing == 0 ? (/pairing[0]$better_than_next ||
                             /pairing[0]$equal_to_next) &&
                            ! /pairing[2]$better_than_next :
            #pairing == 1 ? ! /pairing[0]$chosen &&
                            (/pairing[1]$better_than_next ||
                             /pairing[1]$equal_to_next) :
                            ! /pairing[0]$chosen &&
                            ! /pairing[1]$chosen;
         /pair[1:0]
            \viz_js
               box: {strokeWidth: 0},
               layout: {left: 25, top: 0},
               where: {left: -22.5, top: -5, width: 45, height: 10},
            $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing/pair$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing/pair$ANY;
            `BOGUS_USE($sum)
            /die[1:0]
               $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing/pair/die$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing/pair/die$ANY;
               \viz_js
                  box: {width: 10, height: 10, strokeWidth: 0},
                  layout: "horizontal",
                  render() {
                     let top_context = this.getScope("m5_strip_prefix(/_top)").context
                     let pip_color = this.getIndex("pair") ? "black" : "white"
                     return [top_context.die('/_top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
                  },
      $chosen_pairing[1:0] = /active_player/pairing[0]$chosen ? 2'd0 :
                             /active_player/pairing[1]$chosen ? 2'd1 :
                                                                2'd2;
      /chosen_pairing
         $ANY = /active_player/pairing[/active_player$chosen_pairing]$ANY;
         /pair[1:0]
            $ANY = /active_player/pairing[/active_player$chosen_pairing]/pair$ANY;
            `BOGUS_USE($sum)
      /tower[12:2]
         $ANY = /_top/player[/_top$Player]/tower$ANY;
         $tower_height[3:0] = *max\[#tower\] + 1;
         // Blocked if any player has claimed it.
         // Specifically for 2-player.
         ///other_players_tower
         //   $ANY = /_top/player[! /_top$Player]/tower$ANY;
         // Determine whether this tower is claimed.
         /m5_PLAYER_HIER
            $claimed = /_top/player/tower$claimed;
         $claimed = | /player[*]$claimed;
         // TODO: Consider exposing $climb signal for bust prediction per pairing
         // TODO: Could automatically exclude pairings that would bust
         // Update height, incrementing +1 for each matching pair,
         // then capping at max and switching on end turn.
         /chosen_pair[1:0]
            $matches = /active_player/chosen_pairing/pair[#chosen_pair]$sum == #tower;
            $delta[3:0] = {3'b0, $matches};
            $priority = /active_player/chosen_pairing$priority_pair == #chosen_pair;
            // This is a priority pair that claims a new tower.
            $new_priority_tower =   $priority && $matches && ! /tower$claimed && ! /tower$climbing && /active_player$climbing_cnt                  != 2'd3;
            // This pair causes this tower to grow.
            $climb = $matches && ! /tower$claimed &&
                    (/tower$climbing || $new_priority_tower || /active_player$active_climb_cnt_for_low_priority != 2'd3);
         $new_priority_tower = | /chosen_pair[*]$new_priority_tower;
         $climb = | /chosen_pair[*]$climb;   // Either pair results in climbing.
         $delta[3:0] = /chosen_pair[0]$delta +
                       /chosen_pair[1]$delta;
         $floor_plus_delta[3:0] = $ClimbFloor + $delta;
         $my_next_climb_floor[3:0] =
              //$claimed
              //     ? 4'b0 :
              ! $climb
                   ? $ClimbFloor :
              $floor_plus_delta >= $tower_height
                   ? $tower_height :
                     $floor_plus_delta;
         $claim = $my_next_climb_floor == $tower_height;
         $ClimbFloor[3:0] <=
              /_top$reset              ? 4'b0 :
              // If end turn, set floor for next player.
              /active_player$turn_over ? /_top/player[(/_top$Player + m5_PLAYER_INDEX_HIGH'd1) % m5_PLAYER_CNT]/tower<<1$Floor :
                                         $my_next_climb_floor;
         $climbing = $ClimbFloor != $Floor;
         $next_climbing = $my_next_climb_floor != $Floor;   // (for VIZ only)
         `BOGUS_USE($next_climbing)
         // Count towers being actively built (max 3) and towers that are claimed (max 4), accumulating from tower 2 upward
         $active_climb_cnt_accum[1:0] =
              {1'b0, $climbing} +
              (#tower == 2 ? 2'b0 : /tower[#tower == 2 ? 12 \: #tower - 1]$active_climb_cnt_accum);
         $claimed_tower_cnt_accum[2:0] =
              {2'b0, $claim} +
              (#tower == 2 ? 3'b0 : /tower[#tower == 2 ? 12 \: #tower - 1]$claimed_tower_cnt_accum);
      $climbing_cnt[1:0] = /tower[12]$active_climb_cnt_accum;
      $claimed_cnt[2:0] = /tower[12]$claimed_tower_cnt_accum;
      $new_priority_tower = | /tower[*]$new_priority_tower;
      // Active tower count including the current high-priority pair (for consideration by the low-priority pair).
      $active_climb_cnt_for_low_priority[1:0] = $climbing_cnt + {1'b0, $new_priority_tower};
      $win = $claimed_cnt[2:0] >= 3;
      
      // Bust if no tower heights change.
      $bust = ! | /tower[*]$climb;
      $turn_over = $end_turn || $bust;
   
      \viz_js
         box: {strokeWidth: 0},
         template: {
            action: [
               "Text", "", {
                  left: 18, top: 72,
                  fontSize: 8, fontFamily: "Roboto", fill: "black"
               }
            ]
         },
         render() {
            this.getObjects().action.set('$bust'.asBool()
                                            ? {text: "✖", fill: "red"} :
                                         '$end_turn'.asBool()
                                            ? {text: "✓", fill: "green"} :
                                         //default
                                              {text: "…", fill: "#101010"})
         },
         where: {}
   
   // --------------------
   // VIZ-Only
   
   /header_player[m5_PLAYER_RANGE]
      \viz_js
         box: {width: 100, height: 15, fill: "#a0e0a0", strokeWidth: 0},
         init() {
            return {
               circle: new fabric.Circle({
                    left: 4.5, top: 2.5,
                    radius: 5, strokeWidth: 1,
                    fill: "gray",
                    stroke: "#00000080"}),
               id: new fabric.Text("-", {
                    left: 17, top: 4,
                    fontSize: 7, fontFamily: "Roboto", fill: "black"
               }),
            }
         },
         render() {
            // Can't do this in init() because this.getIndex isn't currently available.
            let o = this.getObjects()
            let i = this.getIndex()
            m5_player_color(i)
            o.circle.set({fill: player_color,
                          stroke: '/_top/active_player$win'.asBool() && ('/_top$Player'.asInt() == i) ? "cyan" : "gray"})
            o.id.set({text: i == 0 ? "m5_index_by_player(player_name, 0)" :
                            i == 1 ? "m5_index_by_player(player_name, 1)" :
                            i == 2 ? "m5_index_by_player(player_name, 2)" :
                            i == 3 ? "m5_index_by_player(player_name, 3)" :
                                     "m5_index_by_player(player_name, 4)"})
         },
         where: {left: -25, top: 3, width: 50, height: 8, justifyX: "center", justifyY: "bottom"},
   
   /winner
      // Determine which player won
      $won = /_top/active_player$win;
      $winning_color[23:0] = /_top/active_player$color;
      
      \viz_js
         box: {left: -105, top: 0, width: 210, height: 170, strokeWidth: 0},
         render() {
            let won = '$won'.asBool()
            
            if (won) {
               // Convert color from 24-bit hex to CSS format
               let color24 = '$winning_color'.asInt()
               let r = (color24 >> 16) & 0xFF
               let g = (color24 >> 8) & 0xFF
               let b = color24 & 0xFF
               let playerColor = `rgb(${r}, ${g}, ${b})`
               
               // Create celebration objects in a group with transparency
               return [new fabric.Group([
                  // Backdrop circle in player color
                  new fabric.Circle({
                     left: 0, top: 0,
                     radius: 80,
                     originX: "center",
                     originY: "center",
                     fill: playerColor
                  }),
                  // Trophy emoji
                  new fabric.Text("🏆", {
                     left: 0, top: 10,
                     fontSize: 90,
                     fontFamily: "Arial",
                     originX: "center",
                     originY: "center"
                  }),
                  // Winner text
                  new fabric.Text("WINNER!", {
                     left: 0, top: -55,
                     fontSize: 28,
                     fontFamily: "Arial Black",
                     fontWeight: "bold",
                     originX: "center",
                     originY: "center",
                     fill: playerColor,
                     stroke: "#000",
                     strokeWidth: 2
                  })
               ], {
                  left: 0,
                  top: 28,
                  originX: "center",
                  originY: "center",
                  opacity: 0.5  // Set transparency on the entire group
               })]
            }
            return []
         },
         where: {left: -40, top: 29, width: 80, height: 56, justifyX: "center", justifyY: "top"}

   $passed = /winner$won;
   $failed = *cyc_cnt > 400;

   
   
\SV
   m5_makerchip_module
\TLV
   // Define players/teams.
   m5_define_player(random, Random 1)
   m5_define_player(random, Random 2)
   m5_define_player(seven, Seven)      // Player 0
   
   // Instantiate the Showdown environment.
   m5+eleven_towers_game(/top)
\SV
   endmodule

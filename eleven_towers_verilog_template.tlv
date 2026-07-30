\m5_TLV_version 1d: tl-x.org
\m5
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
         input wire [3:0] pairing_sum [2:0][1:0],      // Sum of dice for each pairing's pairs
         // === Outputs ===
         output wire [15:0] pairing_score [2:0],       // Score for each of 3 pairings (higher is better)
         output wire [0:0] priority_pair [2:0],        // Which pair (0 or 1) gets priority for each pairing
         output wire end_turn                          // Assert to end turn voluntarily
      );

      // PROBABILITY CONSTANTS
      localparam [8:0] roll_probabilities [12:2] = '{171, 302, 461, 580, 727, 834, 727, 580, 461, 302, 171};

      // TOWER DISTANCE CALCULATIONS
      logic [3:0] tower_distance [12:2];
      logic tower_completed [12:2];
      logic tower_one_away [12:2];
      logic tower_two_away [12:2];      

      // ELIGIBLE TOWER CALCULATIONS
      logic eligible_towers [12:2];                     // IF TOWER IS ELIGIBLE
      
      // SCORING TIER CONSTANTS
      localparam [15:0] TIER_DOUBLE_FINISH = 16'd80000; // finish two towers
      localparam [15:0] TIER_FINISH_NOW    = 16'd60000; // distance==1
      localparam [15:0] TIER_CLIMB_TWICE   = 16'd40000; // climb a tower twice
      localparam [15:0] TIER_TWO_TOWERS    = 16'd20000; // two different towers
      localparam [15:0] TIER_ONE_TOWER     = 16'd10000; // one legal lower

      // SCORING VARS
      logic [15:0] base_pairing_scores [2:0];
      logic [9:0] added_probabilities [2:0];
      logic [15:0] final_pairing_scores [2:0];
      
      // CONDITIONS FOR TURN END & STRATEGY
      logic double_finish;
      logic finish_now;

      // 1. Calculate tower_distance and status
      always_comb begin
         integer i;
         for (i = 2; i <= 12; i = i + 1) begin
            tower_distance[i] = tower_height[i] - tower_climb_floor[i];
            tower_completed[i] = my_turn && (tower_distance[i] == 4'd0);
            tower_one_away[i] = my_turn && (tower_distance[i] == 4'd1);
            tower_two_away[i] = my_turn && (tower_distance[i] == 4'd2);
         end
      end

      // 2. Compute Eligible Towers
      always_comb begin
         integer tower;
         for (tower = 2; tower <= 12; tower = tower + 1) begin
            eligible_towers[tower] = !tower_claimed[tower] && 
                  !tower_completed[tower] && (tower_climbing[tower] || (climbing_cnt < 2'd3));
         end
      end

      // 3. Evaluate Pairings and Assign Tier Scores
      always_comb begin
         integer h;
         logic [3:0] sum0, sum1, dist0, dist1;
         logic elig0, elig1;

         double_finish = 1'b0;
         finish_now = 1'b0;

         for (h = 0; h < 3; h = h + 1) begin
            sum0 = pairing_sum[h][0];
            sum1 = pairing_sum[h][1];
            added_probabilities[h] = roll_probabilities[sum0] + roll_probabilities[sum1];
            
            dist0 = tower_distance[sum0];
            dist1 = tower_distance[sum1];
            elig0 = eligible_towers[sum0];
            elig1 = eligible_towers[sum1];

            base_pairing_scores[h] = 16'd0;

            if (elig0 && elig1) begin
               if ((sum0 != sum1) && (dist0 == 4'd1) && (dist1 == 4'd1)) begin
                  base_pairing_scores[h] = TIER_DOUBLE_FINISH;
                  double_finish = 1'b1;
               end else if ((sum0 != sum1) && ((dist0 == 4'd1) || (dist1 == 4'd1))) begin
                  base_pairing_scores[h] = TIER_FINISH_NOW;
                  finish_now = 1'b1;
               end else if ((sum0 == sum1) && (dist0 == 4'd2)) begin
                  base_pairing_scores[h] = TIER_FINISH_NOW;
                  finish_now = 1'b1;
               end else if (sum0 == sum1) begin
                  base_pairing_scores[h] = TIER_CLIMB_TWICE;
               end else begin
                  base_pairing_scores[h] = TIER_TWO_TOWERS;
               end
            end else if (elig0 || elig1) begin
               if ((elig0 && dist0 == 4'd1) || (elig1 && dist1 == 4'd1)) begin
                  base_pairing_scores[h] = TIER_FINISH_NOW;
                  finish_now = 1'b1;
               end else begin
                  base_pairing_scores[h] = TIER_ONE_TOWER;
               end
            end
         end
      end

      // 4. Score Calculation & Priority Pair Assignment
      logic [0:0] priority_pair_reg[2:0];

      always_comb begin
         integer p;
         for (p = 0; p < 3; p = p + 1) begin
            if (base_pairing_scores[p] != 16'd0) begin
               final_pairing_scores[p] = base_pairing_scores[p] + {6'd0, added_probabilities[p]};
            end else begin
               final_pairing_scores[p] = 16'd0;
            end

            if (roll_probabilities[pairing_sum[p][0]] >= roll_probabilities[pairing_sum[p][1]]) begin
               priority_pair_reg[p] = 1'b0;
            end else begin
               priority_pair_reg[p] = 1'b1; 
            end
         end
      end

      assign pairing_score[0] = final_pairing_scores[0];
      assign pairing_score[1] = final_pairing_scores[1];
      assign pairing_score[2] = final_pairing_scores[2];

      assign priority_pair[0] = priority_pair_reg[0];
      assign priority_pair[1] = priority_pair_reg[1];
      assign priority_pair[2] = priority_pair_reg[2];

      // 5. Turn Ending Logic
      localparam [7:0] ROLLS_THRESHOLD_FULL = 8'd5;    // climbing_cnt == 3
      localparam [7:0] ROLLS_THRESHOLD_PARTIAL = 8'd6; // climbing_cnt < 3

      logic any_tower_complete_now;
      logic rolls_threshold_hit;
      logic [7:0] current_threshold;

      always_comb begin
         integer t;
         any_tower_complete_now = 1'b0;
         for (t = 2; t <= 12; t = t + 1) begin
            if (tower_climbing[t] && tower_completed[t]) begin
               any_tower_complete_now = 1'b1;
            end
         end
      end

      always_comb begin
         current_threshold = (climbing_cnt == 2'd3) ? ROLLS_THRESHOLD_FULL : ROLLS_THRESHOLD_PARTIAL;
         rolls_threshold_hit = (rolls_this_turn >= current_threshold);
      end

      assign end_turn = my_turn && (rolls_threshold_hit || any_tower_complete_now || double_finish || finish_now);
      
      endmodule
   '])

   var(_SIG_ROOT, path_TBD)

\TLV team_1269580875_viz(/_top, /_me, #player)
   m5_macro(mySigVal, ['['this.sigVal("team_1269580875_']#player.$']['1['")']'])
   \viz_js
      box: {width: 40, height: 100, strokeWidth: 1},
      where: {left: 50, top: 0, width: 40, height: 100},
      render() {
         m5_player_color(#player)
         let o = this.getObjects()
         o.box.set({stroke: player_color})
         o.box.group.set({opacity: '$my_turn'.asBool() ? 1 : 0})
         
         const rolls = m5_mySigVal(rolls_this_turn).asInt();

         return [
            new fabric.Text(`Roll ${rolls}`, {
               left: 20, top: 40, originX: "center",
               fontSize: 8, fontFamily: "Roboto"
            })
         ];
      }

\TLV team_1269580875(/_top, /_me, #player)
   m5+verilog_wrapper(/_top, /_me, #player, 1269580875)

\SV
   m4_include_lib(['https://raw.githubusercontent.com/rweda/showdown-2026-eleven-towers/a7a75ffde289282804aae012bd1dcbef179adb78/eleven_towers_lib.tlv'])

   m5_makerchip_module
\TLV
   m5_define_player(1269580875, TMU_ECEC)
   m5_define_player(seven, Seven Strategy)
   m5+eleven_towers_game(/top)
\SV
   endmodule
   
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 0)_module, ['m5_call(team_\m5_get_ago(github_id, 0)_module)'])
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 1)_module, ['m5_call(team_\m5_get_ago(github_id, 1)_module)'])
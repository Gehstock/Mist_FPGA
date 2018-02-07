`include "defs.vh"



`define POINT_IN_BOX(box1, box2)\
(box1.x >= box2.x) && (box1.x < (box2.x+box2.width)) &&\
(box1.y >= box2.y) && (box1.y < (box2.y+box2.height))

`define Y_CROSSES_BOX(box1, box2)\
(box1.y >= box2.y) && (box1.y < (box2.y+box2.height))


`define BOX_CROSS(box1, box2)\
(box1.x < (box2.x+box2.width)) &&\
(box2.x < (box1.x+box1.width)) &&\
(box1.y < (box2.y+box2.height)) &&\
(box2.y < (box1.y+box1.height))




typedef struct {
    logic           [10:0]  x;
    logic           [10:0]  y;
    logic           [10:0]  width;
    logic           [10:0]  height;
    logic           [3:0]   exact_x;
    logic signed    [7:0]   movement;
    entity_type_t           etype;
    logic                   show;
    logic           [7:0]   die_step;
} entity_t;


typedef struct {
    logic           [24:0]  scroll_pos;
    logic signed    [10:0]  change_x;
} river_flow_t;

typedef struct {
    logic           [24:0]  scroll_pos;
    entity_type_t   etype;
    logic           [10:0]  x;
    logic signed    [7:0]   movement;
} entity_flow_t;


typedef struct {
    logic           [24:0]  pos;
    logic           [24:0]  river_addr; // адрес в river_flow с которого
                                        // в данный момент идет прорисовка реки
    logic           [10:0]  river_x_start;
    logic           [24:0]  island_addr;
    logic           [10:0]  island_x_start;
    logic           [24:0]  entity_addr;// адрес в entity_flow с которого в данный момент
                                        // берется информация по кораблям, самолетам, ...
} scroll_t;


typedef struct {
    bit [(`SPRITE_MISSILE_WIDTH*4)-1:0] missile [0:`SPRITE_MISSILE_HEIGHT-1];
} sprites_t;

typedef struct {
    logic [31:0]    ship_addr;
    logic [31:0]    plane_addr;
    logic [31:0]    helicopter_addr;
    logic [31:0]    building_addr;
    logic [31:0]    fuel_addr;
} rom_sprites_t;

typedef struct {
    logic [3:0]     ship;
    logic [3:0]     plane;
    logic [3:0]     helicopter;
    logic [3:0]     building;
    logic [3:0]     fuel;
    logic [3:0]     player;
} rgb_sprites_t;

typedef struct {
    logic           [10:0]  x;
    logic           [10:0]  y;
    logic           [10:0]  width;
    logic           [10:0]  height;
    logic           [7:0]   die_step;
} box_t;

typedef struct {
    logic           [10:0]  x;
    logic           [10:0]  missile_x;
    logic signed    [11:0]  missile_y;
    logic           [7:0]   die_step;
    logic signed    [15:0]  fuel;
    logic           [31:0]  sprite_addr;
} player_t;


typedef struct { 
    logic signed    [10:0]  movement;
    logic                   shot;
    logic                   slow;
} cmd_t;


typedef struct {
    scroll_t        scroll;
    river_flow_t    river_flow  [`RIVER_FLOW_SIZE];
    river_flow_t    island_flow [`ISLAND_FLOW_SIZE];
    entity_flow_t   entity_flow [`ENTITY_FLOW_SIZE];
    entity_t        entities    [`ENTITIES_ON_FRAME];
    sprites_t       sprites;
    rom_sprites_t   rom_sprites;
    rgb_sprites_t   rgb_sprites;
    player_t        player;
    box_t           player_box;
    box_t           missile_box;
    cmd_t           cmd;
    logic           play;
} game_t;




typedef struct { 
    logic   [10:0] x;
    logic   [10:0] y;
    logic   rgb_enable;
    logic   H_SYNC_CLK;
    logic   V_SYNC_CLK;
} screen_t;


`define GET_RGB(sprite, entity)\
entity.die_step[1]? 4'b000 :\
(sprite[screen.y-entity.y] >> ((screen.x-entity.x)<<2)) & 4'b1111

`define ROM_RGB(sprite_addr, rgb_sprite, shift_width, entity)\
begin\
    sprite_addr = ((screen.y - entity.y) << shift_width) +\
        (entity.movement <= 0 ? (screen.x - entity.x) : (entity.width - screen.x + entity.x - 1));\
    rgb <= entity.die_step[1]? 4'b000 : rgb_sprite;\
end


module draw_sprites (
    output logic [3:0]      rgb,
    output rom_sprites_t    rom_sprites,
    input                   clk,
    input entity_t          entities [`ENTITIES_ON_FRAME],
    input sprites_t         sprites,
    input screen_t          screen,
    input game_t            game
);
    always @(posedge clk)
    begin
        for( int i = 0; i <= `ENTITIES_ON_FRAME; i = i + 1 )
          begin
            if( i == `ENTITIES_ON_FRAME )
                rgb <= 0;
            else if( entities[i].show && `POINT_IN_BOX(screen, entities[i]) )
              begin
                case( entities[i].etype )
                    SHIP:       `ROM_RGB(rom_sprites.ship_addr, game.rgb_sprites.ship, 7, entities[i])
                    BUILDING:   `ROM_RGB(rom_sprites.building_addr, game.rgb_sprites.building, 6, entities[i])
                    PLANE:      `ROM_RGB(rom_sprites.plane_addr, game.rgb_sprites.plane, 7, entities[i])
                    HELICOPTER: `ROM_RGB(rom_sprites.helicopter_addr, game.rgb_sprites.helicopter, 6, entities[i])
                    FUEL:       `ROM_RGB(rom_sprites.fuel_addr, game.rgb_sprites.fuel, 6, entities[i])
                    BRIDGE:     rgb <=  entities[i].die_step[1]? 4'b000 :
                                        ((screen.y - entities[i].y) > (`BRIDGE_HEIGHT/2-3) &&
                                        (screen.y - entities[i].y) < (`BRIDGE_HEIGHT/2+3)) ? 4'b0110 : 4'b1000;
                    default:
                        begin
                            rgb <= 0;
                        end
                endcase
                break;
              end
          end 
    end
endmodule


module draw_player (
    output logic [3:0]      rgb,
    output logic [31:0]     player_addr,
    input                   clk,
    input game_t            game,
    input screen_t          screen
);
    box_t fuel_box;
    box_t fuel_gauge_box;

    // Риска на индикаторе топлива
    assign fuel_gauge_box.x         = `FUEL_EMPTY_X + game.player.fuel[15:4];
    assign fuel_gauge_box.y         = `FUEL_Y + 2;
    assign fuel_gauge_box.width     = 5;
    assign fuel_gauge_box.height    = `FUEL_HEIGHT - 4;
    
    // Индикатор топлива
    assign fuel_box.x               = `FUEL_EMPTY_X;
    assign fuel_box.y               = `FUEL_Y;
    assign fuel_box.width           = `FUEL_WIDTH;
    assign fuel_box.height          = `FUEL_HEIGHT;
    
    always @(posedge clk)
    begin
        if( `POINT_IN_BOX(screen, game.player_box) )
          begin
            player_addr = ((screen.y-game.player_box.y) << 6) + (screen.x - game.player_box.x);
            rgb <= game.player_box.die_step[1]? 4'b000 : game.rgb_sprites.player;
          end
        else
          begin
            player_addr = 0;
            if( `POINT_IN_BOX(screen, fuel_gauge_box) )
                rgb <= 4'b0011;
            else if( `POINT_IN_BOX(screen, fuel_box) )
                rgb <= 4'b1000;
            else
                rgb <= 4'b0000;
          end
    end
endmodule

module draw_missile (
    output logic [3:0]  rgb,
    input               clk,
    input game_t        game,
    input sprites_t     sprites,
    input screen_t      screen
);
    always @(posedge clk)
    begin
        if( game.missile_box.x && `POINT_IN_BOX(screen, game.missile_box) )
            rgb <= `GET_RGB(sprites.missile, game.missile_box);
        else
            rgb <= 0;
    end
endmodule

        
module play (
    input                   clk,
    input                   rst,
    input screen_t          screen,
    input game_t            game,
    input entity_flow_t     entity_flow [`ENTITY_FLOW_SIZE],
    output wire             play_game,
    output wire [2:0]       rgb,
    output scroll_t         scroll,
    output entity_t         entities [`ENTITIES_ON_FRAME],
    output player_t         player,
    output rom_sprites_t    rom_sprites
);
    wire    [10:0]      x;
    wire    [10:0]      y;
    reg     [7:0]       line_end;
    reg     [3:0]       step;
    reg     [3:0]       scroll_counter;
    reg     [31:0]      frame_counter;
    
    reg     [10:0]      river_x;
    reg     [10:0]      river_x2;
    reg     [24:0]      river_addr;

    reg     [10:0]      island_x;
    reg     [24:0]      island_addr;
    wire    [10:0]      island_x_left;
    wire    [10:0]      island_x_right;

    reg     [7:0]       ship_index;
    wire    [3:0]       rgb_sprite;
    wire    [2:0]       rgb_world;
    wire    [3:0]       rgb_player;
    wire    [3:0]       rgb_missile;
    wire                slow;

    assign x                = screen.x;
    assign y                = screen.y;
    assign river_x2         = `SCREEN_MAX_X - river_x;
    assign island_x_left    = `SCREEN_CENTER_X - island_x;
    assign island_x_right   = `SCREEN_CENTER_X + island_x;
    
    assign rgb = rgb_missile    ?   rgb_missile[2:0] :
                 rgb_player     ?   rgb_player[2:0] : 
                 rgb_sprite     ?   rgb_sprite[2:0] :
                                    rgb_world;

    assign slow             = game.cmd.slow && (scroll_counter < `SLOW_SCROLL_SPEED);
    

    draw_sprites draw_sprites (
        .rgb            ( rgb_sprite        ),
        .rom_sprites    ( rom_sprites       ),
        .entities       ( entities          ),
        .sprites        ( game.sprites      ),
        .screen         ( screen            ),
        .game           ( game              ),
        .clk            ( clk               )
    );

    draw_player draw_player (
        .rgb            ( rgb_player        ),
        .player_addr    ( player.sprite_addr ),
        .game           ( game              ),
        .screen         ( screen            ),
        .clk            ( clk               )
    );

    draw_missile draw_missile (
        .rgb            ( rgb_missile       ),
        .game           ( game              ),
        .sprites        ( game.sprites      ),
        .screen         ( screen            ),
        .clk            ( clk               )
    );

    always @(posedge clk)
    begin
    if( (x == `SCREEN_MAX_X) && (y == `SCREEN_MAX_Y) && (step == 0) )
        begin
            step <= 4'h1;
            scroll_counter <= '0;
        end
    case( step )
      4'h1 :
            begin
            step <= 4'h2;
            if( !play_game )
              begin
                play_game               <= 1;
                scroll.pos              <= 0;
                scroll.river_addr       <= 0;
                scroll.river_x_start    <= 0;
                scroll.island_addr      <= 0;
                scroll.island_x_start   <= 0;
                scroll.entity_addr      <= 0;
                player.die_step         <= 0;
                player.missile_x        <= 0;
                player.x                <= 0;
                player.fuel             <= `FUEL_FULL;
                for( int i = 0; i < `ENTITIES_ON_FRAME; i = i + 1 )
                    entities[i].show    <= 0;
              end
            end
      4'h2 : // Закончилась прорисовка фрейма
            if( frame_counter >= (`SCROLL_EVERY_FRAMES-1) )
                begin
                    frame_counter   <= 0;
                    if( slow )
                        step        <= 4'h6;
                    else
                      begin
                        step        <= 4'h3;
                        scroll.pos  <= scroll.pos + 'd1;
                      end
                end
            else
            // Если надо ничего не делать несколько фреймов (очень медленная игра)
                begin
                    step            <= 4'h8;
                    frame_counter   <= frame_counter + 'd1;
                end
      4'h3 :
            begin
                step <= 4'h4;
                // Дошли до точки изменения направления реки в river_flow ?
                if( scroll.pos >= game.river_flow[scroll.river_addr+1].scroll_pos )
                    scroll.river_addr <= scroll.river_addr + 1;
                // Изменение направления берега острова
                if( scroll.pos >= game.island_flow[scroll.island_addr+1].scroll_pos )
                    scroll.island_addr <= scroll.island_addr + 1;
                // Появился новый враг? Сдвинем FIFO объектов, самый старый выкинем
                if( scroll.pos == entity_flow[scroll.entity_addr].scroll_pos )
                    entities[1:`ENTITIES_ON_FRAME-1] <= entities[0:`ENTITIES_ON_FRAME-2];
            end
      4'h4 :    // Если на предыдущем шаге появился новый враг - закинем в FIFO его данные
            begin
                step <= 4'h5;
                if( scroll.pos == entity_flow[scroll.entity_addr].scroll_pos )
                  begin
                    entities[0].show        <= 1;
                    entities[0].x           <= entity_flow[scroll.entity_addr].x;
                    entities[0].exact_x     <= 0;
                    entities[0].y           <= 0;
                    entities[0].etype       <= entity_flow[scroll.entity_addr].etype;
                    entities[0].movement    <= entity_flow[scroll.entity_addr].movement;
                    entities[0].die_step    <= 0;
                    
                    case( entity_flow[scroll.entity_addr].etype )
                        SHIP:
                            begin
                                entities[0].width   <= `SPRITE_SHIP_WIDTH;
                                entities[0].height  <= `SPRITE_SHIP_HEIGHT;
                            end
                        PLANE:
                            begin
                                entities[0].width   <= `SPRITE_PLANE_WIDTH;
                                entities[0].height  <= `SPRITE_PLANE_HEIGHT;
                                // Самолеты будут вылетать с края экрана
                                entities[0].x       <= entity_flow[scroll.entity_addr].movement > 0? 0 : `SCREEN_MAX_X;
                                // А поле X переназначим на отложенный вылет
                                entities[0].y       <= entity_flow[scroll.entity_addr].x;
                            end
                        HELICOPTER:
                            begin
                                entities[0].width   <= `SPRITE_HELICOPTER_WIDTH;
                                entities[0].height  <= `SPRITE_HELICOPTER_HEIGHT;
                            end
                        FUEL:
                            begin
                                entities[0].width   <= `SPRITE_FUEL_WIDTH;
                                entities[0].height  <= `SPRITE_FUEL_HEIGHT;
                            end
                        BRIDGE:
                            begin
                                entities[0].x       <= scroll.river_x_start + `LAND_START_POS;
                                entities[0].width   <= `SCREEN_MAX_X - scroll.river_x_start - `LAND_START_POS 
                                                                     - scroll.river_x_start - `LAND_START_POS;
                                entities[0].height  <= `BRIDGE_HEIGHT;
                            end
                        BUILDING:
                            begin
                                entities[0].width   <= `SPRITE_BUILDING_WIDTH;
                                entities[0].height  <= `SPRITE_BUILDING_HEIGHT;
                            end
                        default:
                            begin
                                entities[0].width   <= 0;
                                entities[0].height  <= 0;
                            end
                    endcase

                    scroll.entity_addr  <= scroll.entity_addr + 1;
                  end
            end
      4'h5 :
            begin
                step <= 4'h6;
                if( player.fuel > `FUEL_FULL )
                    player.fuel <= `FUEL_FULL;
                scroll.river_x_start <= scroll.river_x_start + game.river_flow[scroll.river_addr].change_x;
                scroll.island_x_start <= scroll.island_x_start + game.island_flow[scroll.island_addr].change_x;
            end
      4'h6 : // Перемещение, подбитие, таран врагов
            begin
                step <= 4'h7;
                for( int i = 0; i < `ENTITIES_ON_FRAME; i = i + 1 )
                  begin
                    // Враг ранее был подбит
                    if( entities[i].die_step )
                        // Подержим в таком состоянии немного на экране
                        if( entities[i].die_step == 100 )
                            entities[i].show <= 0;
                        else
                          begin // Уменьшаем скролинг - получаем эффект отлета от ракеты
                            if( (entities[i].etype == BRIDGE) || scroll_counter[0] )
                                entities[i].y <= entities[i].y + 1;
                            entities[i].die_step <= entities[i].die_step + 1;
                          end
                    else if( (entities[i].y < `SCREEN_MAX_Y) && entities[i].show )
                      begin
                        // Ракета попала в объект
                        if( `BOX_CROSS(game.missile_box, entities[i]) )
                          begin
                            entities[i].die_step    <= 1;
                            player.missile_x        <= 0;
                          end
                        // Игрок врезался в объект
                        else if( `BOX_CROSS(game.player_box, entities[i]) )
                          begin
                            if( entities[i].etype == FUEL )
                              begin
                                player.fuel <= player.fuel + `FUEL_UP_SPEED;
                                entities[i].y <= entities[i].y + 1;
                              end
                            else
                              begin
                                // Если игрок уже погиб, не меняем время до рестарта
                                if( !player.die_step )
                                    player.die_step <= 1;
                                entities[i].die_step <= 1;
                              end
                          end
                        else if( !slow )
                            entities[i].y <= entities[i].y + 1;
                      end
                    else
                        entities[i].show <= 0;

                    // Перемещение = movement/16 пикселей на фрейм, т.е можно < 1
                    {entities[i].x, entities[i].exact_x} <=
                    {entities[i].x, entities[i].exact_x} + 15'(signed'(entities[i].movement));
                  end
            end
      4'h7 : // Возвращаемся на шаг 1 если нужно сделать несколько скроллингов за 1 фрейм
            begin
                if( (scroll.pos < `SCREEN_MAX_Y) && (scroll_counter < `START_SCROLL_SPEED) )
                  begin
                    scroll_counter <= scroll_counter + 4'd1;
                    step <= 4'h1;
                  end
                else if( scroll_counter < `FRAME_EVERY_SCROLLS )
                  begin
                    scroll_counter <= scroll_counter + 4'd1;
                    step <= 4'h1;
                  end
                else
                    step <= 4'h8;
            end
      4'h8 :
            begin
                step <= 4'h9;
                // Перемещение игрока
                if( !player.die_step )
                    player.x <= player.x + game.cmd.movement;
                // Уменьшение топлива. Уменьшаем с обычной скоростью всегда, чтобы не замедляли полет постоянно
                player.fuel <= player.fuel - `FUEL_DOWN_SPEED;
            end
      4'h9 :
            begin
                step <= 4'ha;
                // Выстрел игрока
                if( game.cmd.shot && (player.missile_y < `REMISSILE_Y_POS) )
                  begin
                    player.missile_x <= game.player_box.x + `PLAYER_WIDTH/2 - `SPRITE_MISSILE_WIDTH/2;
                    player.missile_y <= `MISSILE_Y_START;
                  end
                else if( player.missile_y > 0 )
                    player.missile_y <= player.missile_y - `MISSILE_SPEED;
                else
                    player.missile_x <= 0;
                // Закончилось топливо
                if( (player.fuel <= 0) && !(player.die_step) )
                  begin
                    player.fuel <= 0;
                    player.die_step <= 1;
                  end
            end
      4'ha :    // Стартовые значения для прорисовки фрейма
            begin
                step        <= 4'hb;
                river_x     <= scroll.river_x_start + `LAND_START_POS;
                river_addr  <= scroll.river_addr;
                island_x    <= scroll.island_x_start;
                island_addr <= scroll.island_addr;
            end
      4'hb :    
            begin
                step <= 4'hc;
                if( player.die_step )
                  begin
                    if( player.die_step == 60 )
                      begin
                        play_game <= 0;
                      end
                    else
                        player.die_step <= player.die_step + 1;
                  end
            end
      default:
            begin
                if( x == 0 )
                    step <= 4'h0;
                if( (x == `SCREEN_MAX_X) && (line_end == 0) )
                    line_end <= 8'd1;
                case ( line_end )
                    8'd1 :
                            begin
                                line_end <= 8'd2;
                                if( (y < `SCREEN_MAX_Y) && (scroll.pos >= y) )
                                  begin
                                    if( (scroll.pos - y) < game.river_flow[river_addr].scroll_pos   )
                                        river_addr <= river_addr - 1;
                                    if( (scroll.pos - y) < game.island_flow[island_addr].scroll_pos )
                                        island_addr <= island_addr - 1;
                                  end
                            end
                    8'd2:
                            begin
                                line_end <= 8'd3;
                                if( (river_addr >= 0) && (y < `SCREEN_MAX_Y))
                                    river_x <= river_x - game.river_flow[river_addr].change_x;
                                if( (island_addr >= 0) && (y < `SCREEN_MAX_Y))
                                    island_x <= island_x - game.island_flow[island_addr].change_x;
                            end
                    8'd3:   // Индекс корабля по текущему Y чтобы на следующем шаге проверять доплытие до берега
                            // Это экономней чем делать все в цикле, но добавляется ограничение: 1 корабль на одной позиции Y
                            begin
                                for( int i = 0; i <= `ENTITIES_ON_FRAME; i = i + 1 )
                                    if( i == `ENTITIES_ON_FRAME )
                                      begin
                                        //ship_index    <= 0;
                                        line_end    <= 8'd6;
                                      end
                                    else if( `Y_CROSSES_BOX(screen, entities[i]) && (
                                            (entities[i].etype == SHIP) ||
                                            (entities[i].etype == HELICOPTER)
                                    ))
                                      begin
                                        ship_index  <= i;
                                        line_end    <= 8'd4;
                                        break;
                                      end
                            end
                    8'd4:   // Корабль доплыл до берега?
                            begin
                                if( entities[ship_index].x < (river_x + `SAND_WIDTH) )
                                  begin
                                    entities[ship_index].x <= river_x + `SAND_WIDTH;
                                    line_end <= 8'd5;
                                  end
                                else if( (entities[ship_index].x + entities[ship_index].width) > (river_x2 - `SAND_WIDTH) )
                                  begin
                                    entities[ship_index].x <= river_x2 - `SAND_WIDTH - entities[ship_index].width;
                                    line_end <= 8'd5;
                                  end
                                else
                                    line_end <= 8'd6;
                            end
                    8'd5:   // Корабль доплыл до берега. Изменим направление
                            begin
                                line_end <= 8'd6;
                                entities[ship_index].movement <= -entities[ship_index].movement;
                            end
                    8'd6:   // Игрок врезался в берег или остров?
                            begin
                                line_end <= 8'd7;
                                if(
                                    (!player.die_step) &&
                                    `Y_CROSSES_BOX(screen, game.player_box) &&
                                    (
                                        (game.player_box.x <= river_x) ||
                                        ((game.player_box.x + game.player_box.width) > river_x2) ||
                                        (
                                            island_x &&
                                            (game.player_box.x >= island_x_left) &&
                                            ((game.player_box.x + game.player_box.width) < island_x_right)
                                        )
                                    )
                                )
                                    player.die_step <= 1;
                                // Ракета попала в берег или остров?
                                if(
                                    `Y_CROSSES_BOX(screen, game.missile_box) &&
                                    (
                                        (game.missile_box.x <= river_x) ||
                                        ((game.missile_box.x + game.missile_box.width) > river_x2) ||
                                        (
                                            island_x &&
                                            (game.missile_box.x >= island_x_left) &&
                                            ((game.missile_box.x + game.missile_box.width) < island_x_right)
                                        )
                                    )
                                )
                                    player.missile_x <= 0;
                            end
                    default:
                            begin
                                if( x == 0 )
                                    line_end  <= 3'd0;
                                if( scroll.pos > y )
                                    rgb_world <=
                                             (x < river_x) ? `LAND_COLOR :
                                             (x < (river_x + `SAND_WIDTH)) ? `SAND_COLOR :
                                             (x < island_x_left) ? `RIVER_COLOR :
                                             (x < island_x_right) ? `LAND_COLOR :
                                             (x < (river_x2 - `SAND_WIDTH)) ? `RIVER_COLOR :
                                             (x >= river_x2) ? `LAND_COLOR : `SAND_COLOR ;
                                else
                                    rgb_world <= `TRANSPARENT_COLOR;
                            end
                endcase
            end
    endcase
    end
endmodule


module init (
    input                   clk,
    input                   rst,
    output  river_flow_t    river_flow  [`RIVER_FLOW_SIZE],
    output  river_flow_t    island_flow [`ISLAND_FLOW_SIZE],
    output  entity_flow_t   entity_flow [`ENTITY_FLOW_SIZE],
    output  sprites_t       sprites
);  
    always @(posedge clk)
    if( !rst )
      begin
        river_flow          <= `RIVER_FLOW;
        island_flow         <= `ISLAND_FLOW;
        entity_flow         <= `ENTITY_FLOW;
        sprites.missile     <= `MISSILE_SPRITE;
      end
endmodule

module RiverRaid (
	input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,	 
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
	input         SPI_SS4,
   input         CONF_DATA0
);

`include "rtl\build_id.v" 

	 localparam CONF_STR = {
		  "River Raid;;",
		  "O23,Scandoubler Fx,None,CRT 25%,CRT 50%;",
		  //"T5,Reset;",
		  "V,v0.1.",`BUILD_DATE
};

    game_t game;
    screen_t screen;
	 wire clk;
	 wire clk_pix;
	 wire rst = status[0] | status[5] |buttons[1];
    wire [2:0]      cur_rgb;

    logic [7:0]     ps2_received_data;
    logic           ps2_received_data_en;
    logic           ps2_key_up_action;

    wire HSync = screen.H_SYNC_CLK;
    wire VSync = screen.V_SYNC_CLK;
	 wire r = screen.rgb_enable? cur_rgb[0] : 1'b0;
	 wire g = screen.rgb_enable? cur_rgb[1] : 1'b0;
	 wire b = screen.rgb_enable? cur_rgb[2] : 1'b0;
	 wire [2:0] VGA_BO ={r,r,r};
	 wire [2:0] VGA_GO ={g,g,g};
	 wire [2:0] VGA_RO ={b,b,b};
    assign game.player_box.x        = game.player.x + `PLAYER_START_X;
    assign game.player_box.y        = `PLAYER_Y;
    assign game.player_box.width    = `PLAYER_WIDTH;
    assign game.player_box.height   = `PLAYER_HEIGHT;
    assign game.player_box.die_step = game.player.die_step;

    assign game.missile_box.x       = game.player.missile_x;
    assign game.missile_box.y       = game.player.missile_y[10:0];
    assign game.missile_box.width   = `SPRITE_MISSILE_WIDTH;
    assign game.missile_box.height  = `SPRITE_MISSILE_HEIGHT;
	 
	 wire        scandoubler_disable;
	 wire        ypbpr;
	 wire        ps2_kbd_clk, ps2_kbd_data;
	 wire [31:0] status;
	 wire  [1:0] buttons;
	 wire  [1:0] switches;
	 wire  [7:0] joyA;
	 wire  [7:0] joyB;
	 wire  [7:0] kbd_joy;
	 wire vga_clk;
	 
	 assign LED = 1'b1;
	 
	 mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys(clk),
	.conf_str(CONF_STR),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SCK(SPI_SCK),
	.SPI_SS2(SPI_SS2),
	.SPI_DO(SPI_DO),
	.SPI_DI(SPI_DI),
	.scandoubler_disable(scandoubler_disable),
	.status(status),
	.buttons(buttons),
	.switches(switches),
	.joystick_0(joyA),
	.joystick_1(joyB),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.ypbpr(ypbpr)
);

video_mixer #(.LINE_LENGTH(1024), .HALF_DEPTH(1)) video_mixer
(
	.*,
	.clk_sys(clk),
	.ce_pix(vga_clk),
	.ce_pix_actual(vga_clk),
	.scanlines({status[3:2] == 2, status[3:2] == 1}),
	.scandoubler_disable(1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0),
	.hq2x(),
	.R(VGA_RO),
	.G(VGA_GO),
	.B(VGA_BO)
);

    pll_108 pll_108 (
        .inclk0             ( CLOCK_27  ),
        .c0                 ( vga_clk   ),
		  .c1             	 ( clk       ),
        .areset             ( rst      )
    );
        
    vga_time_generator vga_time_generator (
        .clk                ( vga_clk           ),
        .reset_n            ( 1                 ),
        .h_disp             ( `H_DISP           ),
        .h_fporch           ( `H_FPORCH         ),
        .h_sync             ( `H_SYNC           ),
        .h_bporch           ( `H_BPORCH         ),

        .v_disp             ( `V_DISP           ),
        .v_fporch           ( `V_FPORCH         ),
        .v_sync             ( `V_SYNC           ),
        .v_bporch           ( `V_BPORCH         ),
        .hs_polarity        ( 1'b0              ),
        .vs_polarity        ( 1'b0              ),
        .frame_interlaced   ( 1'b0              ),

        .vga_hs             ( screen.H_SYNC_CLK ),
        .vga_vs             ( screen.V_SYNC_CLK ),
        .vga_de             ( screen.rgb_enable ),
        .pixel_x            ( screen.x          ),
        .pixel_y            ( screen.y          )
    );

    sprite_ship sprite_ship (
        .clock              ( vga_clk                           ),
        .address            ( game.rom_sprites.ship_addr        ),
        .q                  ( game.rgb_sprites.ship             )
    );

    sprite_plane sprite_plane (
        .clock              ( vga_clk                           ),
        .address            ( game.rom_sprites.plane_addr       ),
        .q                  ( game.rgb_sprites.plane            )
    );
    
    sprite_helicopter sprite_helicopter (
        .clock              ( vga_clk                           ),
        .address            ( game.rom_sprites.helicopter_addr  ),
        .q                  ( game.rgb_sprites.helicopter       )
    );


    sprite_building sprite_building (
        .clock              ( vga_clk                           ),
        .address            ( game.rom_sprites.building_addr    ),
        .q                  ( game.rgb_sprites.building         )
    );

    sprite_fuel sprite_fuel (
        .clock              ( vga_clk                           ),
        .address            ( game.rom_sprites.fuel_addr        ),
        .q                  ( game.rgb_sprites.fuel             )
    );

    sprite_player sprite_player (
        .clock              ( vga_clk                           ),
        .address            ( game.player.sprite_addr           ),
        .q                  ( game.rgb_sprites.player           )
    );

    play play (
        .clk                ( vga_clk           ),
        .rst                ( rst               ),
        .rgb                ( cur_rgb           ),
        .screen             ( screen            ),
        .game               ( game              ),
        .scroll             ( game.scroll       ),
        .entity_flow        ( game.entity_flow  ),
        .entities           ( game.entities     ),
        .rom_sprites        ( game.rom_sprites  ),
        .player             ( game.player       ),
        .play_game          ( game.play         )
    );

    
    init init (
        .clk                ( vga_clk           ),
        .rst                ( rst               ),
        .river_flow         ( game.river_flow   ),
        .island_flow        ( game.island_flow  ),
        .entity_flow        ( game.entity_flow  ),
        .sprites            ( game.sprites      )
    );
//will be removed fix Keyboard module down below
    PS2_Controller ps2( 
      .CLOCK_50             ( clk               ),
      .reset                ( 0                 ),
      .PS2_CLK              ( ps2_kbd_clk       ),
      .PS2_DAT              ( ps2_kbd_data      ),
      .received_data        ( ps2_received_data ),
      .received_data_en     ( ps2_received_data_en )
    );
	 
	// Inaccurate 
	/* keyboard  keyboard
	(
		.clk(clk),
		.reset(0),
		.ps2_kbd_clk(ps2_kbd_clk),
		.ps2_kbd_data(ps2_kbd_data),
		.joystick(kbd_joy),
		.code( ps2_received_data ),
		.input_strobe( ps2_received_data_en )
	);*/
	
	
//Joystick	
/*	 always @(posedge clk)
	 begin
	game.cmd.shot = kbd_joy[0] | joyA[4] |joyB[4];
	game.cmd.slow = kbd_joy[5] | joyA[2] |joyB[2];
// this will not work
//	if (kbd_joy[6])// | joyA[1] |joyB[1])
//		if( game.cmd.movement < 0 ) game.cmd.movement <= 0; else game.cmd.movement   <= -`PLAYER_SPEED;
//	if (kbd_joy[7])// | joyA[3] |joyB[3])
//		if( game.cmd.movement > 0 ) game.cmd.movement <= 0; else game.cmd.movement   <= +`PLAYER_SPEED;
	end*/
	
	//will be remooved
reg [15:0] counter;	
    always @(posedge ps2_received_data_en)
    begin
       
        if( ps2_received_data == 8'hF0 )
            ps2_key_up_action <= 1;
        else begin
            ps2_key_up_action <=0;
            if( ps2_key_up_action )
                case( ps2_received_data )
                    8'h6B : if( game.cmd.movement < 0 ) game.cmd.movement <= 0;//left
                    8'h74 : if( game.cmd.movement > 0 ) game.cmd.movement <= 0;//right
                    8'h29 : game.cmd.shot       <=  0;//Fire
                    8'h72 : game.cmd.slow       <=  0;//down
                endcase
           else begin   
                case( ps2_received_data )
                    8'h6B : game.cmd.movement   <= -`PLAYER_SPEED;
                    8'h74 : game.cmd.movement   <=  `PLAYER_SPEED;
                    8'h29 : game.cmd.shot       <=  1;
                    8'h72 : game.cmd.slow       <=  1;
                endcase
            end
        end
        
    end
	 
	 always @(posedge clk)
		if (game.cmd.shot==1) 
			if(counter==56817) counter <= 0; 
			else counter <= counter+1;		

	 assign AUDIO_L = counter[15];	 
	 assign AUDIO_R = AUDIO_L;
	 
endmodule

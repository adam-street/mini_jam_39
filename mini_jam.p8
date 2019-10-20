pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
debug1 = nil
debug2 = nil
debug3 = nil
debug4 = nil
debug5 = nil

-- globals
input = {}
game_state = 1

function _update()
    input = get_input()

    -- menu
    if (game_state == 1) then
        if (input.b1 or input.b2) then
            game_state = 2
            reset_game()
            create_level()
        end
    end

    -- playing game
    if (game_state == 2) then
        -- player turn
        if (player_turn) then

            if (player.action != nil) then
                take_action(player)
                if (player.action != nil and player.action.finished == true) then
                    end_turn()
                    player.action = nil
                end
            else
                if (input.x != 0) then
                    selected_card_index += input.x
                    if (selected_card_index < 1) selected_card_index = #cards
                    if (selected_card_index > #cards) selected_card_index = 1

                    for i=1,#cards do
                        cards[i].selected = false
                        if (i == selected_card_index) cards[i].selected = true
                    end
                end

                if (input.b1) then
                    if (cards[selected_card_index].action == -1) then
                        draw_hand()
                        end_turn()
                    else
                        player.action = cards[selected_card_index].action
                        player.target_x = player.x + player.action.dx
                        player.target_y = player.y + player.action.dy
                        del(cards, cards[selected_card_index])

                        if (#cards == 1) then
                            draw_hand()
                        end

                        selected_card_index = 1
                        cards[selected_card_index].selected = true
                    end
                end

                if (input.b2) then
                    if (cards[selected_card_index].action != -1) then
                        flip_card(cards[selected_card_index])
                    else
                        draw_hand()
                    end
                end
            end

        -- monster turn
        else
            
            -- move all non player actors and check if they are finished
            local f = true
            for i=1, #actors do
                local a = actors[i]
                if (a != null and a.is_player == false) then
                    take_action(a)
                    if (a.action.finished == false) f = false
                end
            end

            -- end monster's turn
            if (f) then
                end_turn()
            end
        end

        move_camera()
    end

    -- level complete screen
    if (game_state == 3) then
        -- game_state = 1
        
        create_level()
        game_state = 2
    end

    -- level complete screen
    if (game_state == 4) then
        game_state = 1
    end
end

function _draw()
    cls()

    if (game_state == 1) then
        map(16,0)
    end

    if (game_state == 2) then
        draw_map()
        draw_actors()
        draw_cards()
    end

    if (game_state == 3) then
        map(0, 0)
    end

    if (game_state == 4) then
    end

    -- debug
    -- print(debug1)
    -- print(debug2)
    -- print(debug3)
    -- print(debug4)
    -- print(debug5)
    -- print(time())
end

--
-- game functions
--
function reset_game()
    -- actor lists
    actors = {}
    player = {}
    player_turn = true
    actor_move_speed = 0.25

    -- level settings
    g_h = 4
    g_w = 4
    g_map = {}

    -- monster settings
    monster_count = 0
    monster_attact_distance = 4
    monster_max_move_distance = 3

    -- player settings
    cards = {}
    selected_card_index = 1
    player_max_distance = 3
    player_shuffles = 10
    player_flips = 3
    player_handsize = 4

    -- camera settings
    cam_x = 0
    cam_y = 0
end

function create_level()
    g_h += 4
    g_w += 4
    monster_count += 2

    player_turn = true
    g_map = {}
    actors = {}
    player = {}

    -- create map
    create_map()

    -- create player 
    local c = get_open_cell()

    player = create_actor(3, c.x, c.y, true)
    g_map[c.x][c.y].current_actor = player
    player.pxc = c.x
    player.pyc = c.y
    add(actors, player)
    
    draw_hand()

    -- create monsters
    for i=1, monster_count do
        local c = get_open_cell()
        local a = create_actor(4, c.x, c.y, false)
        g_map[c.x][c.y].current_actor = a
        a.pxc = c.x
        a.pyc = c.y
        add(actors, a)
    end
end

--
-- map functions
--
function create_map()
    local m = {}
    for x=1,g_h do
        m[x] = {}
        for y=1,g_w do

            -- all edges are walls
            if (y == 1 or x == 1 or y == g_h or x == g_w) then
                m[x][y] = create_wall_tile(false)
                goto ⌂
            end
            
            -- random fill rest
            if (rnd(100) + 1 < 70) then
                m[x][y] = create_floor_tile()
            else 
                m[x][y] = create_wall_tile(true)
            end

            -- randomize sprite flip and mirror
            m[x][y].flp = rnd(2) > 1
            m[x][y].mir = rnd(2) > 1

            ::⌂::
        end
    end
    g_map = m

    -- fill any floor singles
    for x=1,g_h do
        for y=1,g_w do

            local t = get_tiles_around(x, y)
            if (
                t.tr != null and t.tr.type == 'wall' and
                t.tl != null and t.tl.type == 'wall' and
                t.tt != null and t.tt.type == 'wall' and
                t.tb != null and t.tb.type == 'wall'
            ) then
                g_map[x][y] = create_wall_tile(true)
            end
        end
    end

    -- remove any wall singles
    for x=1,g_h do
        for y=1,g_w do

            local t = get_tiles_around(x, y)
            if (
                t.tr != null and t.tr.type == 'floor' and
                t.tl != null and t.tl.type == 'floor' and
                t.tt != null and t.tt.type == 'floor' and
                t.tb != null and t.tb.type == 'floor'
            ) then
                g_map[x][y] = create_floor_tile()
            end
        end
    end

    -- add key
    local c = get_open_cell()
    g_map[c.x][c.y].object = create_item(54, 'key', true)

    -- add door
    local c = get_open_cell()
    g_map[c.x][c.y].object = create_item(55, 'door', false)

end

function draw_map()
    for x=1,#g_map do
        for y=1,#g_map[x] do
            local tile = g_map[x][y]

            spr(
                tile.s,
                x * 8,
                y * 8,
                1, 
                1,
                tile.flp,
                tile.mir
            )

            if (tile.object != nil) then
                spr(tile.object.s, x * 8, y * 8)
            end
        end
    end
end

function create_wall_tile(can_break)
    local t = {}
    t.type = 'wall'
    t.flp = false
    t.mir = false
    t.s = 1

    t.object = nil
    t.current_actor = nil
    t.breakable = can_break

    return t
end

function create_floor_tile()
    local t = {}
    t.type = 'floor'
    t.flp = false
    t.mir = false
    t.s = 2

    t.object = nil
    t.current_actor = nil
    t.breakable = false

    return t
end

--
-- ai functions
--
function decide_action(a)

    -- get distance to player
    local d = distance_between(a.x, a.y, player.x, player.y)

    local t = get_tiles_around(a.x, a.y)
    local tr = t.tr.type == 'floor'
    local tl = t.tr.type == 'floor'
    local tt = t.tt.type == 'floor'
    local tb = t.tb.type == 'floor'

    local dx = 0
    local dy = 0

    -- attack player
    if (d < monster_attact_distance) then

        local xv = flr(player.x - a.x)
        local yv = flr(player.y - a.y)

        if (xv != 0 and yv != 0) then
            if (rnd(100) > 50) then
                if (xv > 0) dx = 1
                if (xv < 0) dx = -1
            else
                if (yv > 0) dy = 1
                if (yv < 0) dy = -1
            end
        elseif (xv != 0) then
            if (xv > 0) dx = 1
            if (xv < 0) dx = -1
        else
            if (yv > 0) dy = 1
            if (yv < 0) dy = -1
        end

    -- random move
    else

        local dir_found = false
        local rc = 0
        repeat
            dx = 0
            dy = 0

            -- get random direction
            if (rnd(100) > 50) then
                if (rnd(100) > 50) then
                    dx = 1
                else
                    dx = -1
                end
            else
                if (rnd(100) > 50) then
                    dy = 1
                else
                    dy = -1
                end
            end

            -- check if clear in that direction
            if (dx > 0 and tr) dir_found = true 
            if (dx < 0 and tl) dir_found = true 
            if (dy > 0 and tb) dir_found = true 
            if (dy < 0 and tt) dir_found = true

            rc += 1
        until dir_found == true or rc > 50

    end


    local m = flr(rnd(monster_max_move_distance)) + 1
    a.action = create_move_action(dx * m, dy * m)

    a.target_x = a.x + a.action.dx
    a.target_y = a.y + a.action.dy
end

--
-- actions functions
--
function create_move_action(dx, dy)
    local a = {}
    a.type = "move"
    a.finished = false

    a.dx = dx
    a.dy = dy

    return a
end

function take_action(a)
    if (a.action != nil and a.action.type == 'move') then

        -- get current cell
        local cx = flr(a.x)
        local cy = flr(a.y)
        local ct = g_map[cx][cy]

        -- check if over item cell
        if (ct.object != nil) then
            -- enter door if player and has key
            if (ct.object.t == 'door' and a.is_player and a.holding != nil and a.holding.t == 'key') then
                game_state = 3
            end

            -- pickup item
            if (ct.object.pickable == true and a.holding == nil) then
                a.holding = ct.object
                ct.object = nil
            end
        end

        -- check if over wall cell
        if (ct.type == 'wall') then
            if (ct.breakable == true and a.is_player) then
                a.target_x = cx
                a.target_y = cy
                g_map[cx][cy] = create_floor_tile()
            else
                a.target_x = a.pxc
                a.target_y = a.pyc
            end
        end

        -- clear old tile
        g_map[a.pxc][a.pyc].current_actor = nil


        -- check if actor is over another
        if (ct.current_actor != nil) then
            if (ct.current_actor.is_player) then
                game_state = 4
            else
                if (ct.current_actor.holding != nil) then
                    g_map[ct.current_actor.x][ct.current_actor.y].object = ct.current_actor.holding
                end

                del(actors, ct.current_actor)
            end
        else
            ct.current_actor = a
        end

        -- calc remaining move
        local rx = abs(a.target_x - a.x)
        local ry = abs(a.target_y - a.y)

        -- stap to grid
        if (rx < 0.1 and ry < 0.1) then
            rx = 0
            ry = 0
            a.x = a.target_x
            a.y = a.target_y
        end

        -- check if we are done with turn
        if (rx == 0 and ry == 0) then
            a.action.finished = true
        else
            move_to_target(a)
        end

        -- save last pos
        a.pxc = cx
        a.pyc = cy
    end
end

function end_turn()
    if (player_turn) then
        player_turn = false

        for i=1,#actors do
            local a = actors[i]
            if (a != nil and a.is_player == false) then
                decide_action(a)
            end
        end
    else
        player_turn = true
    end
end

function move_to_target(a)
    if (a.x < a.target_x) a.x += a.spd
    if (a.x > a.target_x) a.x -= a.spd
    if (a.y < a.target_y) a.y += a.spd
    if (a.y > a.target_y) a.y -= a.spd
end

---
-- actor functions
---
function create_actor(s, x, y, is_player)
    local a = {}
    a.x = x
    a.y = y
    a.s = s
    a.spd = actor_move_speed
    a.is_player = is_player
    a.action = nil
    a.target_x = nil
    a.target_y = nil
    a.holding = nil
    a.pxc = nil
    a.pyc = nil

    return a
end

function draw_actors()
    for i=1, #actors do
        local a = actors[i]
        spr(a.s, a.x * 8, a.y * 8)

        -- draw what actor is holding
        if (a.holding != nil) then
            spr(a.holding.s, a.x * 8, a.y * 8)
        end

        -- draw target location if not player
        -- if (a.is_player == false and a.action != nil) then
        --     if (a.action.finished != true) spr(6, a.target_x * 8, a.target_y * 8)
        -- end
    end
end

---
--- card functions
---
function create_card()
    local card = {}
    local rd = flr(rnd(4)) + 1
    local m = flr(rnd(player_max_distance)) + 1

    if (rd == 1) then
        dx = 1
        dy = 0
        card.s = 21
    elseif (rd == 2) then
        dx = -1
        dy = 0
        card.s = 20
    elseif (rd == 3) then
        dx = 0
        dy = 1
        card.s = 19
    else
        dx = 0
        dy = -1
        card.s = 18
    end

    card.action = create_move_action(dx * m, dy * m)
    card.ms = 33 + m
    card.selected = false

    return card
end

function create_deck()
    local card = {}
    card.action = -1
    return card
end

function draw_hand()
    cards = {}

    for i=1,player_handsize do
        cards[i] = create_card()
    end

    add(cards, create_deck())
    selected_card_index = 1
    cards[1].selected = true
end

function draw_cards()
    x = (cam_x * 8) - 25
    y = 50 + (cam_y * 8)

    for i=1, #cards do

        local card_selected = cards[i].selected

        -- draw deck
        if (cards[i].action == -1) then

            if (card_selected) then
                spr(23, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
            else
                spr(22, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
            end

        else

            if (card_selected) then
                spr(17, x, y - 5, 1, 2)
                spr(cards[i].s, x, y - 5)
                spr(cards[i].ms, x, (y + 8) - 5)
            else
                spr(16, x, y, 1, 2)
                spr(cards[i].s, x, y)
                spr(cards[i].ms, x, y + 8)           
            end

        end

        x += 10
    end
end

function flip_card(c)
    debug4 = c.action.dx
    
    if (c.action.dx < 0) then
        c.action = create_move_action(1 * abs(c.action.dx), c.action.dy)
        c.s = 21
        return
    end

    if (c.action.dx > 0) then
        c.action = create_move_action(-1 * abs(c.action.dx), c.action.dy)
        c.s = 20
        return
    end

    if (c.action.dy < 0) then
        c.action = create_move_action(c.action.dx, 1 * abs(c.action.dy))
        c.s = 19
        return
    end

    if (c.action.dy > 0) then
        c.action = create_move_action(c.action.dx, -1 * abs(c.action.dy))
        c.s = 18
        return
    end

end

---
--- item functions
---
function create_item(s, t, can_pickup)
    local i = {}
    i.s = s
    i.t = t
    i.pickable = can_pickup

    return i
end

---
--- helper functions
---
function get_open_cell()
    local c = {}
    repeat
        c.x = flr(rnd(g_h) + 1)
        c.y = flr(rnd(g_w) + 1)
    until g_map[c.x][c.y].type == 'floor' and g_map[c.x][c.y].current_actor == nil and g_map[c.x][c.y].object == nil

    return c
end

function get_input()
    local input = {}
    input.x = 0
    input.y = 0
    input.b1 = false
    input.b2 = false

    if(btnp(➡️)) input.x += 1
    if(btnp(⬅️)) input.x -= 1
    if(btnp(⬇️)) input.y += 1
    if(btnp(⬆️)) input.y -= 1

    if(btnp(🅾️)) input.b1 = true
    if(btnp(❎)) input.b2 = true

    return input
end

function move_camera()
    cam_x = player.x
    cam_y = player.y

    camera((cam_x * 8) - 60, (cam_y * 8) - 60)
end

function distance_between(x1,y1,x2,y2)
    return sqrt((x2-x1)^2 + (y2-y1)^2)
end

function get_tiles_around(x, y)
    local d = {}

    if (g_map[x + 1] != nil) then
        if (g_map[x + 1][y] != nil) then
            d.tr = g_map[x + 1][y]
        end
    end

    if (g_map[x - 1] != nil) then
        if (g_map[x - 1][y] != nil) then
            d.tl = g_map[x - 1][y]
        end
    end

    if (g_map[x][y + 1] != nil) then
        d.tt = g_map[x][y - 1]
    end

    if (g_map[x][y - 1] != nil) then
        d.tb = g_map[x][y + 1]
    end

    return d
end

__gfx__
0000000011555511555555550099990000bbbb00044444008800008800000000555555555555555555555555dddddddddddddddddddddddddddddddd00000000
000000005511115551555515099999990baaaab004ffff40800000080000000055dddddddddddddddddddd55dddddddd555d555d5d5d555ddddddddd00000000
0070070011111111555555550ffdfdf0baaa77ab0ff4f4f000800800000000005d55555dddddddddd5555dd5ddddddddd5dd5d5d5d5d5ddddddddddd00000000
00077000111111115515555500ffff00baaa71ab0ffffff000088000000000005d5ddd5dddddddddd5ddd5d5ddddddddd5dd555d55dd555ddddddddd00000000
000770005511115555555515000ff000baaa77ab00ffff0000088000000000005d5ddd5dddddddddd5ddd5d5ddddddddd5dd5d5d5d5d5ddddddddddd00000000
00700700115555115555555508888880baaaaaab0333333000800800000000005d5ddd5dddddddddd5ddd5d5ddddddddd5dd5d5d5d5d5ddddddddddd00000000
000000001151151155155155f088880fbaaaaaab0033330080000008000000005d5555dddddddddddd5555d5ddddddddd5dd5d5d5d5d555ddddddddd00000000
00000000551111555555555500c00c000bbbbbb00020020088000088000000005dddddddddddddddddddddd5dddddddddddddddddddddddddddddddd00000000
0dddddd009999990000000000000000000000000000000000dddddd0099999905d5dddddddddddddddddd5d5dddddddddddddddddddddddddddddddd00000000
d555555d9555555900000000000000000000000000000000d655556d965555695dd5dddddddddddddddd5dd5dddd555d555d555d555d555d555ddddd00000000
d555555d9555555900066000006666000006660000666000d565565d956556595dd5dddddddddddddddd5dd5dddd5d5d5d5dd5ddd5dd5d5d5d5ddddd00000000
d555555d9555555900666600006666000066660000666600d556655d955665595dd5dddddddddddddddd5dd5dddd555d5d5dd5ddd5dd5d5d5d5ddddd00000000
d555555d9555555900666600006666000066660000666600d565565d956556595d5dddddddddddddddddd5d5dddd5ddd5d5dd5ddd5dd5d5d5d5ddddd00000000
d555555d9555555900666600000660000006660000666000d565565d956556595dd5dddddddddddddddd5dd5dddd5ddd5d5dd5ddd5dd5d5d5d5ddddd00000000
d555555d9555555900000000000000000000000000000000d556655d955665595dd5dddddddddddddddd5dd5dddd5ddd555dd5dd555d555d5d5ddddd00000000
d5dddd5d95dddd5900000000000000000000000000000000d565565d956556595dd5dddddddddddddddd5dd5dddddddddddddddddddddddddddddddd00000000
d555555d9555555900000000000000000000000000000000d655556d965555695dddddddddddddddddddddd5ddd9799999999dddddd9799999999ddd00000000
d555555d95555559000660000066660000666600006006005dddddd5599999955d5555dddddddddddd5555d5dd999999999999dddd999999999999dd00000000
d555555d9555555900006000000006000000060000600600d555555dd555555d5d5ddd5dddddddddd5ddd5d5dd7d99999999d7dddd7d99999999d7dd00000000
d555555d95555559000060000066660000666600006666005dddddd55dddddd55d5ddd5dddddddddd5ddd5d5dddddddddddddddddddddddddddddddd00000000
d555555d9555555900006000006000000000060000000600d555555dd555555d5d5ddd5dddddddddd5ddd5d5dd7d8dddddd8d7dddd7dcddddddcd7dd00000000
d555555d95555559000060000066660000666600000006005dddddd55dddddd55dd5555dddddddddd5555dd5dd7d88888888d7dddd7dccccccccd7dd00000000
d555555d9555555900000000000000000000000000000000d555555dd555555d55dddddddddddddddddddd55dd7d88888888d7dddd7dccccccccd7dd00000000
0dddddd009999990000000000000000000000000000000000dddddd00dddddd0555555555555555555555555dd7d88888888d7dddd7dccccccccd7dd00000000
0000000000700700ddd444dddd444ddd0000000000000000000000000066660011111111dddddddddddddddddd7d88888888d7dddd7dccccccccd7dd00000000
0000000007000070ddd111dddd111ddd0000000000000000000000000644446011111111dd55555dd55555dddd7d88888888d7dddd7dccccccccd7dd00000000
0000000070000007dd14441dd14441dd0000000000000000000000006444444611111111d55d5d5555ddd55ddd7d88888888d7dddd7dccccccccd7dd00000000
0000000000000000d168888116cccc1d0000000000000000000000006444444611111111d555d55555d5d55ddd7d88888888d7dddd7dccccccccd7dd00000000
0000000000000000d168888116cccc1d0000000000000000000000006494444611111111d55d5d5555ddd55ddd7d88888888d7dddd7dccccccccd7dd00000000
0000000070000007d18888811ccccc1d0000000000000000000090006444444611111111dd55555dd55555dddd7dd888888dd7dddd7ddccccccdd7dd00000000
0000000007000070d18888811ccccc1d0000000000000000000909996444444611111111ddddddddddddddddddd7dddddddd7dddddd7dddddddd7ddd00000000
0000000000777700dd11111dd11111dd0000000000000000000090096444444611111111dddddddddddddddddddd77777777dddddddd77777777dddd00000000
dddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd55555ddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddd55ddd55ddddddddddddddddd555d555d555d555d55500000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddd55d5d55ddddddddddddddddd5dddd5dd5d5d5d5dd5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddd55ddd55ddddddddddddddddd555dd5dd555d555dd5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd55555dddddddddddddddddddd5dd5dd5d5d55ddd5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddddd5dd5dd5d5d5d5dd5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddd555dd5dd5d5d5d5dd5d00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddd5dd555d555d555d555d555d555ddd55dd555d5d5dd0000000000000000000000000000000000000000000000000000000000000000
ddddd55555ddddddd5d5d5d5d5dddd5dd5d5d5ddd5dddd5dddd5d5d5ddd5d5dd0000000000000000000000000000000000000000000000000000000000000000
dddd55d5d55ddddd555dd5ddd555dd5dd55dd555d555dd5dddd5d5d555d5d5dd0000000000000000000000000000000000000000000000000000000000000000
dddd555d555dddddd555d5ddddd5dd5dd5d5d5ddd5dddd5dddd5d5d5ddd5d5dd0000000000000000000000000000000000000000000000000000000000000000
dddd55d5d55ddddddddddd55d555dd5dd5d5d555d555dd5dd5d55dd555dd5ddd0000000000000000000000000000000000000000000000000000000000000000
ddddd55555dddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd5555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd55555ddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd55d5d55dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd555d555dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd55d5d55dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd55555ddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111111111111111111111111111dddddddd11111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddd11111111dddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddd11111111dddddddd11111111dddddddddddddddd1111111111111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd11111111dddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd111111111111111111111111dddddddddddddddd111111111111111111111111dddddddddddddddd11111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddddddddddd11111111dddddddddddddddd111111111111111111111111dddddddddddddddddddddddd1111111111111111
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddddddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
0000000011111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111111dddddddd11111111dddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
000000001111111111111111dddddddd11111111dddddddddddddddddddddddddddddddd11111111dddddddddddddddddddddddd11111111dddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddddddddddd11111111dddddddddddddddddddddddddddddddd1111111111111111dddddddd
0000000011111111dddddddddddddddddddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddd11111111
0000000011111111dddddddddddddddddddddddd11111111dddddddd11111111dddddddd1111111111111111dddddddddddddddddddddddddddddddd11111111

__map__
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010202020202020202020201010101010102020202020202020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010101010202020202020202020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020809090909090909090a0202010102020809090909090909090a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010202181919190c0d1919191a0202010102021819191919191919191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102021819191b1c1d1e19191a0202010102021819191919191919191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102021819190909090919191a0202010102021819090909090909191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020218192b2c19192d2e191a0202010102021819194344451919191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020218193b3c19193d3e191a0202010102021819191960611919191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102021819505119194041191a0202010102021819191919191919191a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102022829292929292929292a0202010102022829525354555657292a020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020101020202020202020202020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010101010202020202020202020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010202020202020202020201010101010102020202020202020202010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000140301603017030190201b0201f02023020270203200034000370003a00013000130001600015000190001c0001e000200000c000120000d0000d0000e000120000e0000f0000f0000f0001000010000
000500002b0402e030310200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

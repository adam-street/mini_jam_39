pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

game_map = nil
gamp_map_height = 10
game_map_width = 10

wall_spr = 1
floor_spr = 2
player = {}

actions = {18,19,20,21}
modifiers = {34,35,36,37}

cards = {}
card_weights = {1,1,1,1}
hand_size = 4
selected_card = 1
max_card_flips = 300
card_flips = max_card_flips

key_x = nil
key_y = nil
key_held = false

door_x = nil
door_y = nil

-- debug
cam_x = 0
cam_y = 0

function _init()
    poke(0x5f2e, 1)

    -- darkmode
    for x=1,15 do
        pal(x, x+128, 1)
    end

    create_level()
end

function create_level()
    player = create_actor(1, 1)
    game_map = create_map(gamp_map_height, game_map_width)

    repeat 
        player.x = flr(rnd(game_map_width) + 1)
        player.y = flr(rnd(gamp_map_height)) + 1
    until game_map[player.x][player.y].s != 1

    player.sprite = 3
    move_camera()
    draw_hand()
end

function _update()
    input = get_input()

    if (input.b1 and #cards > 0) then
        move_player(player, cards[selected_card])

        if (cards[selected_card].action == -1) then
            draw_hand()
        else
            del(cards, cards[selected_card])
        end
    end

    if (input.b2) then
        if (card_flips > 0 and cards[selected_card].action != -1) then
            sfx(0)
            flip_card(cards[selected_card])
            card_flips -= 1
        else
            -- error sfx here
        end
    end

    if (input.x != 0 and #cards > 0) then
        sfx(0)
        -- set all cards to not selected
        for i=1,#cards do
            cards[i].selected = false
        end

        -- select card
        selected_card += input.x
    end

    -- wrap selection
    if(selected_card > #cards) selected_card = 1
    if(selected_card < 1) selected_card = #cards

    -- mark selected card
    if (#cards > 0) cards[selected_card].selected = true
end

function _draw()
    cls()

    draw_map(game_map)

    -- draw door
    spr(55, door_x * 8, door_y * 8)

    -- draw player
    draw_actor(player)
    
    -- draw key
    spr(54, key_x * 8, key_y * 8)

    -- draw view circle
    -- todo
    -- draw bottom dock
    -- todo
    
    draw_cards()
end

function move_camera()
    cam_x = player.x
    cam_y = player.y

    camera((cam_x * 8) - 60, (cam_y * 8) - 60)
end

function draw_hand()

    -- weight for unused cards
    for i=1,#cards do
        if (cards[i].action == 18) card_weights[1] -= 1
        if (cards[i].action == 19) card_weights[2] -= 1
        if (cards[i].action == 20) card_weights[3] -= 1
        if (cards[i].action == 21) card_weights[4] -= 1
    end

    cards = {}
    card_flips = max_card_flips

    -- draw new hand
    for i=1,hand_size do
        s = weighted_select(card_weights)
        card_weights[s] += 1

        cards[i] = create_card(actions[s], modifiers[flr(rnd(#modifiers)) + 1])
        -- cards[i] = create_card(actions[s], 1)
    end

    deck = {}
    deck.action = -1
    card.selected = false
    add(cards, deck)
    
end

function weighted_select(weights)
    totals = {}
    running_total = 0

    for i=1, #weights do
        running_total += weights[i]
        add(totals, running_total)
    end

    r = rnd(1) * running_total

    for i=1, #totals do
        if (r < totals[i]) return i
    end
end

function create_map(h, w)
    m = {}

    -- random placement
    for x=1,h do
        m[x] = {}
        for y=1,w do
            m[x][y] = {}
            
            -- set wall hp
            m[x][y].hp = flr(rnd(3) + 1)

            -- all edges are walls
            if (y == 1 or x == 1 or y == h or x == w) then
                m[x][y].s = wall_spr
                m[x][y].hp = 99999
                goto ⌂
            end

            -- random fill rest
            if (rnd(100) + 1 < 45) then
                m[x][y].s = floor_spr
            else 
                m[x][y].s = wall_spr
            end

            -- randomize sprite flip and mirror
            m[x][y].f = rnd(2) > 1
            m[x][y].m = rnd(2) > 1

            ::⌂::
        end
    end

    -- add walls
    for x=1,h do
        for y=1,w do
            if (m[x][y].s == 1 and x > 1 and x < w and y > 1 and y < h) then
                nc = 0
                if (m[x+1][y].s == 2) nc += 1
                if (m[x-1][y].s == 2) nc += 1
                if (m[x][y+1].s == 2) nc += 1
                if (m[x][y-1].s == 2) nc += 1

                if (nc < 1) m[x][y].s = 1
            end
        end
    end 

    -- remove walls
    for x=1,h do
        for y=1,w do
            if (m[x][y].s == 1 and x > 1 and x < w and y > 1 and y < h) then
                nc = 0
                if (m[x+1][y].s == 1) nc += 1
                if (m[x-1][y].s == 1) nc += 1
                if (m[x][y+1].s == 1) nc += 1
                if (m[x][y-1].s == 1) nc += 1
                if (m[x-1][y-1].s == 2) nc += 1
                if (m[x+1][y+1].s == 2) nc += 1
                if (m[x+1][y-1].s == 2) nc += 1
                if (m[x-1][y+1].s == 2) nc += 1

                if (nc < 4) m[x][y].s = 2
            end
        end
    end

    -- remove walls
    for x=1,h do
        for y=1,w do
            if (m[x][y].s == 1 and x > 1 and x < w and y > 1 and y < h) then
                nc = 0
                if (m[x+1][y].s == 1) nc += 1
                if (m[x-1][y].s == 1) nc += 1
                if (m[x][y+1].s == 1) nc += 1
                if (m[x][y-1].s == 1) nc += 1

                if (nc < 2) m[x][y].s = 2
            end
        end
    end

    -- place key randomly    
    repeat 
        x = flr(rnd(w)) + 1
        y = flr(rnd(h)) + 1
    until m[x][y].s != 1

    key_x = x
    key_y = y

    -- place door randomly
    repeat 
        x = flr(rnd(w)) + 1
        y = flr(rnd(h)) + 1
    until m[x][y].s != 1

    door_x = x
    door_y = y

    return m
end

function draw_map(m)
    for x=1,#m do
        for y=1,#m[x] do
            s = m[x][y].s
            
            -- fuzz wall tiles
            -- if (s == 1 and rnd(100) + 1 > 90) then
            --     m[x][y].f = rnd(2) > 1
            --     m[x][y].m = rnd(2) > 1
            -- end

            spr(s, x * 8, y * 8, 1, 1, m[x][y].f, m[x][y].m)
        end
    end 
end

function get_input()
    input = {}
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

function create_card(a, m)
    card = {}
    card.action = a
    card.modifier = m
    card.selected = false
    return card
end

function draw_card(x,y,c)
    if (c.selected) then
        s = 17
        y -= 5
    else
        s = 16
    end

    spr(s, x, y, 1, 2)
    spr(c.action, x, y)
    spr(c.modifier, x, y + 8)
end

function flip_card(c)
    if (c.action == 18) c.action = 19
    if (c.action == 20) c.action = 21

    if (c.action == 19) c.action = 18
    if (c.action == 21) c.action = 20
end

-- prints hand to screen
function draw_cards()
    x = (cam_x * 8) - 25
    y = 50 + (cam_y * 8)
    for i=1, #cards do
        if(cards[i].action == -1) then
            -- draw deck
            if (cards[i].selected) then
                spr(25, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
            else
                spr(24, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
            end
        else
            draw_card(x, y, cards[i])
            x += 10
        end
    end
end

function create_actor(x, y)
    a = {}
    a.x = x
    a.y = y

    return a
end

function move_player(a, c)
    x = 0
    y = 0
    m = 0

    -- action mapping
    if (c.action == 18) y = -1
    if (c.action == 19) y = 1
    if (c.action == 20) x = -1
    if (c.action == 21) x = 1

    -- modifier mapping
    if (c.modifier == 34) m = 1
    if (c.modifier == 35) m = 2
    if (c.modifier == 36) m = 3
    if (c.modifier == 37) m = 4

    -- check for collision
    xc = abs(x * m)
    repeat
        if (player.x + x > game_map_width - 1 or player.x + x < 2) then
            xc = 0
        else
            tile = game_map[player.x + x][player.y]
            if (tile.s != 2) then

                -- if hit wall 
                if (tile.s == 1) then
                    tile.s = 2
                end

                xc = 0
            else
                player.x += x
                xc -= 1
            end
        end
    until xc == 0

    yc = abs(y * m)
    repeat
        if (player.y + y > gamp_map_height + 1 or player.y + y < 1) then
            yc = 0
        else
            tile = game_map[player.x][player.y + y]
            if (tile.s != 2) then

                -- if hit wall 
                if (tile.s == 1) then
                    tile.s = 2
                end
                
                yc = 0
            else
                player.y += y
                yc -= 1
            end
        end
    until yc == 0

    -- check if over key
    if (player.x == key_x and player.y == key_y) then
        if (key_held == false) sfx(1)
        key_held = true
    end

    if (key_held) then
        key_x = player.x
        key_y = player.y
    end

    -- check if over door with key
    if (player.x == door_x and player.y == door_y and key_held ) then
        sfx(1)
        create_level()
    end

    move_camera()
end

function draw_actor(a)
    spr(a.sprite, a.x * 8, a.y * 8)
end

__gfx__
0000000011555511555555550444440000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000551111555155551504ffff400baaaab00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070011111111555555550ff4f4f0baaa77ab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700011111111551555550ffffff0baaa71ab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000551111555555551500ffff00baaa77ab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700115555115555555503333330baaaaaab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000115115115515515500333300baaaaaab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005511115555555555002002000bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd009999990000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d96555569000000000000000000000000000000000000000000000000
d555555d95555559000770000077770000077700007770000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559007777000077770000777700007777000000000000000000d556655d95566559000000000000000000000000000000000000000000000000
d555555d95555559007777000077770000777700007777000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559007777000007700000077700007770000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d556655d95566559000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d96555569000000000000000000000000000000000000000000000000
d555555d955555590007700000777700007777000070070000000000000000005dddddd559999995000000000000000000000000000000000000000000000000
d555555d95555559000070000000070000000700007007000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
d555555d955555590000700000777700007777000077770000000000000000005dddddd55dddddd5000000000000000000000000000000000000000000000000
d555555d95555559000070000070000000000700000007000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
d555555d955555590000700000777700007777000000070000000000000000005dddddd55dddddd5000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd00dddddd0000000000000000000000000000000000000000000000000
000000000000000000044000000440000004400000044000000eee00004444000000000000000000000000000000000000000000000000000000000000000000
000000000000000000044000000440000004400000044000000e0000044444400000000000000000000000000000000000000000000000000000000000000000
000000000000000001688810016bbb10016ccc1001699910000eee00444444440000000000000000000000000000000000000000000000000000000000000000
000000000000000016688881166bbbb1166cccc116699991000e0000444444440000000000000000000000000000000000000000000000000000000000000000
0000000000000000188888811bbbbbb11cccccc119999991000e0000499444440000000000000000000000000000000000000000000000000000000000000000
00000000000000000188881001bbbb1001cccc100199991000eeee00499444440000000000000000000000000000000000000000000000000000000000000000
00000000000000000011110000111100001111000011110000e00e00444444440000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000eeee00444444440000000000000000000000000000000000000000000000000000000000000000
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

__sfx__
00010000140301603017030190201b0201f02023020270203200034000370003a00013000130001600015000190001c0001e000200000c000120000d0000d0000e000120000e0000f0000f0000f0001000010000
000500002b0402e030310200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

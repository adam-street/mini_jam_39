pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

game_map = nil
gamp_map_height = 8
game_map_width = 8

wall_spr = 1
floor_spr = 2
player = {}

actions = {18,19,20,21}
modifiers = {34,35,36,37}

cards = {}
hand_size = 8
selected_card = 1

key_x = nil
key_y = nil

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

    player = create_actor(flr(rnd(game_map_width) + 1), flr(rnd(gamp_map_height)) + 1)
    game_map = create_map(gamp_map_height, game_map_width)

    player.sprite = 3
    move_camera()
    draw_hand()
end

function _update60()
    input = get_input()

    if (input.b1 and #cards > 0) then
        move_player(player, cards[selected_card])
        del(cards, cards[selected_card])
    end

    if (input.b2) then
        draw_hand()
    end

    if (input.x != 0 and #cards > 0) then

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
    draw_actor(player)
    
    -- draw key
    spr(54, key_x * 8, key_y * 8)

     -- draw door
    spr(55, door_x * 8, door_y * 8)

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

    -- weights
    w = {10,10,10,10}

    for i=1,hand_size do

        s = weighted_select(w)
        w[s] += 1

        cards[i] = create_card(actions[s], modifiers[flr(rnd(#modifiers)) + 1])
        -- cards[i] = create_card(actions[s], 1)
    end
    
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
    x = flr(rnd(w)) + 1
    y = flr(rnd(h)) + 1
    
    key_x = x
    key_y = y

    -- place door randomly
    x = flr(rnd(w)) + 1
    y = flr(rnd(h)) + 1
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

-- prints hand to screen
function draw_cards()
    x = (cam_x * 8) - 25
    y = 50 + (cam_y * 8)
    for i=1, #cards do
        draw_card(x, y, cards[i])
        x += 10
    end

    -- draw deck
    spr(24, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
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
        tile = game_map[player.x + x][player.y]
        if (tile.s != 2) then

            -- if hit wall 
            if (tile.s == 1) then
                tile.hp -= xc
                if (tile.hp <= 0) tile.s = 2
                if (tile.hp < 0) xc = abs(tile.hp)
            else
                xc = 0
            end
            
        else
            player.x += x
            xc -= 1
        end
    until xc == 0

    yc = abs(y * m)
    repeat
        tile = game_map[player.x][player.y + y]
        if (tile.s != 2) then

            -- if hit wall 
            if (tile.s == 1) then
                tile.hp -= yc
                if (tile.hp <= 0) tile.s = 2
                if (tile.hp < 0) yc = abs(tile.hp)
            else
                yc = 0
            end

        else
            player.y += y
            yc -= 1
        end
    until yc == 0

    move_camera()
end

function draw_actor(a)
    spr(a.sprite, a.x * 8, a.y * 8)
end

__gfx__
00000000011101011111133104444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000001111113104ffff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000000001111331310ff4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700010000001111111110ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000100000001111111300ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700100000011131111303333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000013111311300333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010011011111113300200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd000000000000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d00000000000000000000000000000000000000000000000000000000
d555555d95555559000770000077770000077700007770000000000000000000d565565d00000000000000000000000000000000000000000000000000000000
d555555d95555559007777000077770000777700007777000000000000000000d556655d00000000000000000000000000000000000000000000000000000000
d555555d95555559007777000077770000777700007777000000000000000000d565565d00000000000000000000000000000000000000000000000000000000
d555555d95555559007777000007700000077700007770000000000000000000d565565d00000000000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d556655d00000000000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d565565d00000000000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d00000000000000000000000000000000000000000000000000000000
d555555d955555590007700000777700007777000070070000000000000000005dddddd500000000000000000000000000000000000000000000000000000000
d555555d95555559000070000000070000000700007007000000000000000000d555555d00000000000000000000000000000000000000000000000000000000
d555555d955555590000700000777700007777000077770000000000000000005dddddd500000000000000000000000000000000000000000000000000000000
d555555d95555559000070000070000000000700000007000000000000000000d555555d00000000000000000000000000000000000000000000000000000000
d555555d955555590000700000777700007777000000070000000000000000005dddddd500000000000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d555555d00000000000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd000000000000000000000000000000000000000000000000000000000
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


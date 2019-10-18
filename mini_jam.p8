pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

game_map = nil
gamp_map_height = 56
game_map_width = 56

wall_spr = 1
floor_spr = 2
player = {}

actions = {18,19,20,21}
modifiers = {34,35,36,37}

cards = {}
selected_card = 1

-- debug
cam_x = 0
cam_y = 0

function _init()
    poke(0x5f2e, 1)

    -- darkmode
    for x=1,15 do
        pal(x, x+128, 1)
    end

    game_map = create_map(gamp_map_height, game_map_width)

    player = create_actor(2, 2)
    player.sprite = 3
    move_camera()

    cards[1] = create_card()
    cards[2] = create_card()
    cards[3] = create_card()
end

function _update60()
    input = get_input()

    if (input.x != 0) then

        -- set all cards to not selected
        for i=1,#cards do
            cards[i].selected = false
        end

        -- select card
        selected_card += input.x

        -- wrap selection
        if(selected_card > #cards) selected_card = 1
        if(selected_card < 1) selected_card = #cards
    end

    if (input.y < 0) then
        move_player(player, cards[selected_card])
        cards[selected_card] = create_card()
    end

    if (input.y > 0) then
        cards[selected_card] = create_card()
    end

    -- mark selected card
    cards[selected_card].selected = true
end

function _draw()
    cls()
    draw_map(game_map)
    draw_actor(player)
    
    -- draw view circle
    -- todo
    -- draw bottom dock
    -- todo
    
    draw_cards()

    -- debug
    print(game_map[player.x][player.y].s)
end

function move_camera()
    cam_x = player.x
    cam_y = player.y

    camera((cam_x * 8) - 60, (cam_y * 8) - 60)
end

function create_map(h, w)
    m = {}

    -- random placement
    for x=1,h do
        m[x] = {}
        for y=1,w do
            m[x][y] = {}
            
            -- all edges are walls
            if (y == 1 or x == 1 or y == h or x == w) then
                m[x][y].s = wall_spr
                goto ⌂
            end

            -- random fill rest
            if (rnd(100) + 1 < 75) then
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

    -- cleanup
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

function create_card()
    card = {}
    card.action = actions[flr(rnd(#actions)) + 1]
    card.modifier = modifiers[flr(rnd(#modifiers)) + 1]
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

function draw_cards()
    x = (cam_x * 8) - 10
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
        if (game_map[player.x + x][player.y].s == 1) then
            xc = 0
        else
            player.x += x
            xc -= 1
        end
    until xc == 0

    yc = abs(y * m)
    repeat
        if (game_map[player.x][player.y + y].s == 1) then
            yc = 0
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
000000000111010111111331cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001000000011111131cffffffc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000111133131cf6ff6fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001000000111111111cffffffc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001000000011111113cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700100000011131111300cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000013111311300cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001001101111111330c0000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000004400000044000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000004400000044000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000001688810016bbb10016ccc100169991000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000016688881166bbbb1166cccc11669999100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000188888811bbbbbb11cccccc11999999100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000188881001bbbb1001cccc100199991000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000011110000111100001111000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


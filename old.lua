pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

game_map = nil
gamp_map_height = 4
game_map_width = 4

wall_spr = 1
floor_spr = 2
player = {}

actions = {18,19,20,21}
modifiers = {34,35,36}

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

cam_x = 0
cam_y = 0

monster_count = 1
attack_distance = 6
monsters = {}

debug = 0

function _init()
    poke(0x5f2e, 1)

    -- darkmode
    for x=1,15 do
        pal(x, x+128, 1)
    end

    create_level()
end

function create_level()
    gamp_map_height += 3
    game_map_width += 3

    player = create_actor(1, 1)
    player.is_player = true
    game_map = create_map(gamp_map_height, game_map_width)

    repeat 
        player.x = flr(rnd(game_map_width) + 1)
        player.y = flr(rnd(gamp_map_height)) + 1
    until game_map[player.x][player.y].s != 1

    spawn_monsters()

    player.sprite = 3
    move_camera()
    draw_hand()
end

function _update()
    input = get_input()

    if (input.b1 and #cards > 0) then
        move_actor(player, cards[selected_card])

        for i=1,#monsters do
            move_monster(monsters[i])
        end

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

            for i=1,#monsters do
            move_monster(monsters[i])
            end
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

    -- draw monstes
    draw_monsters(monsters)
    
    -- draw key
    spr(54, key_x * 8, key_y * 8)

    -- draw view circle
    -- todo
    -- draw bottom dock
    -- todo
    
    draw_cards()

    print(debug)
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
        -- s = weighted_select(card_weights)
        -- card_weights[s] += 1

        s = flr(rnd(#actions) + 1)

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
    if (c.action == 18) c.action = 19 return
    if (c.action == 20) c.action = 21 return

    if (c.action == 19) c.action = 18 return
    if (c.action == 21) c.action = 20 return
end

-- prints hand to screen
function draw_cards()
    x = (cam_x * 8) - 25
    y = 50 + (cam_y * 8)
    for i=1, #cards do

        spr(cards[i].s, x, y)
        x += 10

        -- if(cards[i].action == -1) then
        --     -- draw deck
        --     if (cards[i].selected) then
        --         spr(25, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
        --     else
        --         spr(24, 58 + (cam_x * 8), 50 + (cam_y * 8), 1, 2)
        --     end
        -- else
        --     draw_card(x, y, cards[i])
        --     x += 10
        -- end
    end
end

function create_actor(x, y)
    a = {}
    a.x = x
    a.y = y

    return a
end

function move_actor(act, c)
    mm = map_action(c)

    r = check_collision(act, mm.x, mm.y, mm.m, false)
    act.x = r.x
    act.y = r.y

    if (act.is_player == true) then
        -- check if over key
        if (act.x == key_x and act.y == key_y) then
            if (key_held == false) sfx(1)
            key_held = true
        end

        if (key_held) then
            key_x = act.x
            key_y = act.y
        end

        -- check if over door with key
        if (act.x == door_x and act.y == door_y and key_held ) then
            sfx(1)
            create_level()
        end

        move_camera()
    end
end

function map_action(c)
    r = {}
    r.x = 0
    r.y = 0
    r.m = 0

    -- action mapping
    if (c.action == 18) r.y = -1
    if (c.action == 19) r.y = 1
    if (c.action == 20) r.x = -1
    if (c.action == 21) r.x = 1

    -- modifier mapping
    if (c.modifier == 34) r.m = 1
    if (c.modifier == 35) r.m = 2
    if (c.modifier == 36) r.m = 3
    if (c.modifier == 37) r.m = 4

    return r
end

function check_collision(a, dx, dy, c, marker)

    x = a.x
    y = a.y

    -- check for collision
    xc = abs(dx * c)
    repeat
        if (x + dx > game_map_width - 1 or x + dx < 2) then
            xc = 0
        else
            tile = game_map[x + dx][y]
            if (tile.s != 2) then

                -- if hit wall 
                if (tile.s == 1 and marker == false) then
                    tile.s = 2
                end

                xc = 0
            else
                x += dx
                xc -= 1
            end
        end
    until xc == 0

    yc = abs(y * c)
    repeat
        if (y + dy > gamp_map_height + 1 or y + dy < 1) then
            yc = 0
        else
            tile = game_map[x][y + dy]
            if (tile.s != 2) then

                -- if hit wall 
                if (tile.s == 1 and marker == false) then
                    tile.s = 2
                end
                
                yc = 0
            else
                y += dy
                yc -= 1
            end
        end
    until yc == 0

    r = {}
    r.x = x
    r.y = y
    return r
end

function draw_actor(a)
    spr(a.sprite, a.x * 8, a.y * 8)
end

function spawn_monsters()
    for i=1,monster_count do
        add(monsters, spawn_monster())
    end
end

function spawn_monster()

    repeat 
        x = flr(rnd(game_map_width)) + 1
        y = flr(rnd(gamp_map_height)) + 1
    until game_map[x][y].s != 1

    m = create_actor(x, y)
    m.sprite = 4
    m.distance = get_distance(m.x, m.y, player.x, player.y)
    m.is_player = false

    get_monster_next_move(m)
    return zm
end

function draw_monsters(m)
    for i=1,#m do
        draw_actor(monsters[i])
        spr(6, monsters[i].next_x * 8, monsters[i].next_y * 8)
    end
end

function move_monster(m)
    move_actor(m, m.next_move)
    get_monster_next_move(m)
end

function get_monster_next_move(m)
    m.next_move = create_card(actions[flr(rnd(#actions)) + 1], modifiers[flr(rnd(#modifiers)) + 1])
    
    mm = map_action(m.next_move)
    r = check_collision(m, mm.x, mm.y, mm.m, true)
    m.next_x = r.x
    m.next_y = r.y

    debug = m.next_y


    -- m.distance = get_distance(m.x, m.y, player.x, player.y)
    -- if (m.distance <= attack_distance) then
    -- else
    -- end
end

function get_distance(x1, y1, x2, y2)
    return flr(sqrt((x2-x1)^2 + (y2-y1)^2))
end

__gfx__
0000000011555511555555550099990000bbbb000444440088000088000000000000000000000000000000000000000000000000000000000000000000000000
000000005511115551555515099999990baaaab004ffff4080000008000000000000000000000000000000000000000000000000000000000000000000000000
0070070011111111555555550ffdfdf0baaa77ab0ff4f4f000800800000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111115515555500ffff00baaa71ab0ffffff000088000000000000000000000000000000000000000000000000000000000000000000000000000
000770005511115555555515000ff000baaa77ab00ffff0000088000000000000000000000000000000000000000000000000000000000000000000000000000
00700700115555115555555508888880baaaaaab0333333000800800000000000000000000000000000000000000000000000000000000000000000000000000
000000001151151155155155f088880fbaaaaaab0033330080000008000000000000000000000000000000000000000000000000000000000000000000000000
00000000551111555555555500c00c000bbbbbb00020020088000088000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd009999990000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d96555569000000000000000000000000000000000000000000000000
d555555d95555559000660000066660000066600006660000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559006666000066660000666600006666000000000000000000d556655d95566559000000000000000000000000000000000000000000000000
d555555d95555559006666000066660000666600006666000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559006666000006600000066600006660000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d556655d95566559000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d565565d95655659000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d655556d96555569000000000000000000000000000000000000000000000000
d555555d955555590006600000666600006666000060060000000000000000005dddddd559999995000000000000000000000000000000000000000000000000
d555555d95555559000060000000060000000600006006000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
d555555d955555590000600000666600006666000066660000000000000000005dddddd55dddddd5000000000000000000000000000000000000000000000000
d555555d95555559000060000060000000000600000006000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
d555555d955555590000600000666600006666000000060000000000000000005dddddd55dddddd5000000000000000000000000000000000000000000000000
d555555d95555559000000000000000000000000000000000000000000000000d555555dd555555d000000000000000000000000000000000000000000000000
0dddddd0099999900000000000000000000000000000000000000000000000000dddddd00dddddd0000000000000000000000000000000000000000000000000
00000000007007000004400000044000000440000004400000000000006666000000000000000000000000000000000000000000000000000000000000000000
00000000070000700004400000044000000440000004400000000000064444600000000000000000000000000000000000000000000000000000000000000000
000000007000000701688810016bbb10016ccc100169991000000000644444460000000000000000000000000000000000000000000000000000000000000000
000000000000000016688881166bbbb1166cccc11669999100000000644444460000000000000000000000000000000000000000000000000000000000000000
0000000000000000188888811bbbbbb11cccccc11999999100000000649444460000000000000000000000000000000000000000000000000000000000000000
00000000700000070188881001bbbb1001cccc100199991000009000644444460000000000000000000000000000000000000000000000000000000000000000
00000000070000700011110000111100001111000011110000090999644444460000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000000000000000000000000000009009644444460000000000000000000000000000000000000000000000000000000000000000
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

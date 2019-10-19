
game_map = nil
gamp_map_height = 3
game_map_width = 3

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

cam_x = 0
cam_y = 0

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

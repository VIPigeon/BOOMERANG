
require "math"

RIGHT = 0
LEFT = 1
C = 8
solid = {4, 5}
-- X = 116
X = 64
Y = 64
count_move = 0

At = {
    count = 0,
    rotate = 0,
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
    sprite = 0,
    diagonal = false,
}

Plr = {
    mirror = RIGHT,
    hero = 0,
    hero_later = 16,
    A = false,
    B = false,
    Btime = false,
    move = false,
    attack = false,
    x = X,
    y = Y,
    dir = 3,
    v = 1,
}

function BtnProc()
    Plr.move = true
    if btn(2) and btn(0) then
        Plr.dir = 20
    elseif btn(3) and btn(0) then -- 
        Plr.dir = 30
    elseif btn(2) and btn(1) then
        Plr.dir = 21
    elseif btn(3) and btn(1) then
        Plr.dir = 31
    elseif btn(0) then
        Plr.dir = 0 -- up
    elseif btn(1) then
        Plr.dir = 1 -- down
    elseif btn(2) then
        Plr.dir = 2 -- left
    elseif btn(3) then
        Plr.dir = 3 -- right
    else Plr.move = false
    end
    Plr.A = false; Plr.B = false
    if btnp(4) then Plr.A = true end
    if btnp(5) then Plr.attack = true; rotate_attack() end
    -- if btn(5) then Plr.Btime = true else Plr.Btime = false end
end

function true_dir(d)
    if Plr.dir == d then return true end
    if (Plr.dir == 21 or Plr.dir == 31) and d == 1 then return true end
    if (Plr.dir == 21 or Plr.dir == 20) and d == 2 then return true end
    if (Plr.dir == 20 or Plr.dir == 30) and d == 0 then return true end
    if (Plr.dir == 31 or Plr.dir == 30) and d == 3 then return true end
    return false
end

function are_solid(cells)
    for i = 1, #solid do
        for j = 1, #cells do
            if cells[j]==solid[i] then return true
            end
        end
    end
    return false
end

function can_move(x1, y1)
    local x2 = (x1+C-1) // C
    local y2 = (y1+C-1) // C
    x1 = x1 // C
    y1 = y1 // C
    return not are_solid({mget(x1, y1), mget(x1, y2),
        mget(x2, y1), mget(x2, y2)})
end

function move()
    if Plr.move then
        if Plr.dir==20 and can_move(Plr.x-Plr.v, Plr.y-Plr.v) then
            Plr.x = Plr.x - Plr.v; Plr.y = Plr.y - Plr.v
        elseif Plr.dir==30 and can_move(Plr.x+Plr.v, Plr.y-Plr.v) then
            Plr.x = Plr.x + Plr.v; Plr.y = Plr.y - Plr.v
        elseif Plr.dir==31 and can_move(Plr.x+Plr.v, Plr.y+Plr.v) then
            Plr.x = Plr.x + Plr.v; Plr.y = Plr.y + Plr.v
        elseif Plr.dir==21 and can_move(Plr.x-Plr.v, Plr.y+Plr.v) then
            Plr.x = Plr.x - Plr.v; Plr.y = Plr.y + Plr.v
        elseif true_dir(0) and can_move(Plr.x, Plr.y-Plr.v) then
            -- up
            Plr.y = Plr.y - Plr.v
        elseif true_dir(1) and can_move(Plr.x, Plr.y+Plr.v) then
            -- down
            Plr.y = Plr.y + Plr.v
        elseif true_dir(2) and can_move(Plr.x-Plr.v, Plr.y) then
            -- left
            Plr.x = Plr.x - Plr.v
        elseif true_dir(3) and can_move(Plr.x+Plr.v, Plr.y) then
            -- right
            Plr.x = Plr.x + Plr.v
        end
    end
end

-- function returnHero(n)
--     Plr.hero_later = n
--     return n
-- end

function animation_move()
    if Plr.move then count_move = math.fmod(count_move + 1, 32)
        else count_move = 0 end
    if count_move // 8 == 0 or count_move // 8 == 2 then
        return 32 end
    if count_move // 8 == 1 then return 0 end
    if count_move // 8 == 3 then return 16 end
end

function rotate_attack()
    if true_dir(0) then
        At.rotate = 3
        At.x1 = X-4; At.y1 = Y-8-4
        At.x2 = X+4; At.y2 = Y-8-4
    elseif true_dir(1) then
        At.rotate = 1
        At.x1 = X+4; At.y1 = Y+8+4
        At.x2 = X-4; At.y2 = Y+8+4
    elseif true_dir(2) then
        At.rotate = 2
        At.x1 = X-8-4; At.y1 = Y+4
        At.x2 = X-8-4; At.y2 = Y-4
    elseif true_dir(3) then
        At.rotate = 0
        At.x1 = X+8+4; At.y1 = Y-4
        At.x2 = X+8+4; At.y2 = Y+4
    end
end

function animation_attack()
    if Plr.attack and At.count < 13 then
        At.count = At.count + 1
    else At.count = 0; Plr.attack = false; At.sprite = 6
        return true end
    At.sprite = 80 + At.count
end

function show_hero()
    if Plr.dir==2 or Plr.dir==20 or Plr.dir==21 then Plr.mirror=LEFT
    elseif Plr.dir==3 or Plr.dir==30 or Plr.dir==31 then 
        Plr.mirror=RIGHT
    end
    if Plr.dir==1 then Plr.hero=2
    elseif Plr.dir==0 then Plr.hero=3
    end
    if Plr.dir==20 or Plr.dir==30 then Plr.hero=1
    elseif Plr.dir==21 or Plr.dir==31 then Plr.hero=0
    end
    if Plr.dir==2 or Plr.dir==3 then
        if Plr.hero==2 then Plr.hero=0
        elseif Plr.hero==3 then Plr.hero=1 end
    end
end

function TIC()
    cls(0)
    -- map(0, 0, 30, 17, 0, 0, -1, 1, nil)
    BtnProc()
    move()
    an_move = animation_move()
    animation_attack()
    if Plr.attack then Plr.v = 0.5
    else Plr.v = 1 end
    show_hero()
    map(0, 0, 60, 34, -Plr.x + X, -Plr.y + Y, -1, 1, nil)
    rect(136, 0, 240-136, 136, 0)
    -- sync()
    spr(Plr.hero+an_move, X, Y, 7, 1, Plr.mirror, 0, 1, 1)
    spr(At.sprite, At.x1, At.y1, 7, 1, 0, At.rotate, 1, 1)
    spr(At.sprite + 16, At.x2, At.y2, 7, 1, 0, At.rotate, 1, 1)
    -- sync()
end

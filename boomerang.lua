
C0 = 0  -- прозрачный цвет


--  блок со сменой цвета палитры
ADDR = 0x3FC0
eADDR = 0x4000
function exportpal(pal)
    for i=1,#pal do
        poke4((eADDR*2)+64+#pal-i,tonumber(pal:sub(i,i),16))
    end 
end
function savePalette()
    palette = ""
    for i=0, 15 do
        for j=0, 2 do
            palette = palette..string.format("%02x",peek(ADDR+(i*3)+j))
        end
    end
end
function colorChange(pn)
    -- pn: palette number
    local id = 0  -- id цвета
    poke(ADDR+(id*3)+2, peek(ADDR+(pn*3)+2))  -- red
    poke(ADDR+(id*3)+1, peek(ADDR+(pn*3)+1))  -- green
    poke(ADDR+(id*3), peek(ADDR+(pn*3)))  -- blue

    id = 8
    poke(ADDR+(id*3)+2, peek(ADDR+(pn*3)+24+2))  -- red
    poke(ADDR+(id*3)+1, peek(ADDR+(pn*3)+24+1))  -- green
    poke(ADDR+(id*3), peek(ADDR+(pn*3)+24))  -- blue

    savePalette()
    exportpal(palette)
end
--
function negative_colorChange(pn)
    -- pn: palette number
    local id = 8  -- id цвета
    poke(ADDR+(id*3)+2, peek(ADDR+(pn*3)+2))  -- red
    poke(ADDR+(id*3)+1, peek(ADDR+(pn*3)+1))  -- green
    poke(ADDR+(id*3), peek(ADDR+(pn*3)))  -- blue

    id = 0
    poke(ADDR+(id*3)+2, peek(ADDR+(pn*3)+24+2))  -- red
    poke(ADDR+(id*3)+1, peek(ADDR+(pn*3)+24+1))  -- green
    poke(ADDR+(id*3), peek(ADDR+(pn*3)+24))  -- blue

    savePalette()
    exportpal(palette)
end


function math.sign(x)
    if x<0 then
        return -1
    end
    if x>0 then
        return 1
    end
    return 0
end


function make_angles()
    a0 = Body:new(ANGLE:copy(), 0, 16*8)
    a1 = Body:new(ANGLE:copy(), 29*8, 16*8)
    a1.flip = 1
    a2 = Body:new(ANGLE:copy(), 0, 0)
    a2.flip = 2
    a3 = Body:new(ANGLE:copy(), 29*8, 0)
    a3.flip = 3
    return {a0, a1, a2, a3}
end


function sq_distance(x1, y1, x2, y2)
    -- возвращает квадрат расстояния между точками
    return math.abs(x1 - x2)^2 + math.abs(y1 - y2)^2
end


function sq_point_ortsegment_distance(x, y, x1, y1, x2, y2)
    -- отрезок ортогональный
    if (x == x1 and x == x2) or (y == y1 and y == y2) then
        return 0
    end
    if x1 <= x and x <= x2 then
        return math.min(sq_distance(x, y, x1, y1), sq_distance(x, y, x2, y2), sq_distance(x, y, x, y1))
    end
    if y1 <= y and y <= y2 then
        return math.min(sq_distance(x, y, x1, y1), sq_distance(x, y, x2, y2), sq_distance(x, y, x1, y))
    end
    return math.min(sq_distance(x, y, x1, y1), sq_distance(x, y, x2, y2))
end


function fence(x, left, right)
    if x < left then
        return left
    end
    if x > right then
        return right
    end
    return x
end


function animation_generation(t)
    -- #t -- делитель 60
    res = {}
    for _, pict in ipairs(t) do
        for i=1, 60 // (#t) do
            table.insert(res, pict)
        end
    end
    return res
end


function plr_death_anim()
    res = {}
    for i=272, 278 do
        for _=1, 8 do
            table.insert(res, i)
        end
    end
    for _=1, 4 do
        table.insert(res, 279)
    end
    return res
end

function boss_opening_mouth_anim()
    res = {}
    for _, f in ipairs({384, 387, 390}) do
        for i = 1, 10 do
            table.insert(res, f)
        end
    end
    return res
end

function boss_beard_anim()
    return animation_generation({
        {1, 2, 3, 4, 5},
        {1, 2, 3, 4, 5},
        {-1, 2, 3, 4, 5},
        {-1, 2, 3, 4, 5},
        {-1, -2, -3, 4, 5},
        {-1, -2, -3, 4, 5},
        {1, -2, -3, -4, -5},
        {1, -2, -3, -4, -5},
        {1, 2, 3, -4, -5},
        {1, 2, 3, -4, -5}
    })
end


function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.reverse(t)
    res = {}
    for i = #t, 1, -1 do
        table.insert(res, t[i])
    end
    return res
end

--
Hitbox = {}
function Hitbox:new(x1, y1, x2, y2)
    obj = {
        x1 = x1, y1 = y1,
        x2 = x2, y2 = y2
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Hitbox:collide(hb)
    if hb.x1 >= self.x2 or self.x1 >= hb.x2 or
            hb.y1 >= self.y2 or self.y1 >= hb.y2 then
        return false
    end
    return true
end

function Hitbox:set_xy(x, y)
    dx = x - self.x1
    dy = y - self.y1
    self.x1 = x; self.y1 = y
    self.x2 = self.x2 + dx
    self.y2 = self.y2 + dy
end
--


-- Не имеет ничего общего с Hitbox кроме принципа работы
HitCircle = table.shallow_copy(Hitbox)
function HitCircle:new(x, y, d)
    obj = {
        x = x, y = y,  -- left top pixel
        d = d,  -- diameter
        hb = Hitbox:new(x, y, x+d, y+d)  -- для упрощения расчетов
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function HitCircle:collide(hb)
    if not self.hb:collide(hb) then
        return false
    end
    local d = self.d
    -- is center in hb
    if hb.x1 <= self.x + d/2 and self.x + d/2 <= hb.x2 and
            hb.y1 <= self.y + d/2 and self.y + d/2 <= hb.y2 then
        return true
    end
    -- is hb side collide circle
    if sq_point_ortsegment_distance(self.x + d/2, self.y + d/2, hb.x1, hb.y1, hb.x1, hb.y2) <= d^2 / 4 then
        return true
    end
    if sq_point_ortsegment_distance(self.x + d/2, self.y + d/2, hb.x2, hb.y1, hb.x2, hb.y2) <= d^2 / 4 then
        return true
    end
    if sq_point_ortsegment_distance(self.x + d/2, self.y + d/2, hb.x1, hb.y1, hb.x2, hb.y1) <= d^2 / 4 then
        return true
    end
    if sq_point_ortsegment_distance(self.x + d/2, self.y + d/2, hb.x1, hb.y2, hb.x2, hb.y2) <= d^2 / 4 then
        return true
    end
    return false
end

function HitCircle:set_xy(x, y)
    self.x = x
    self.y = y
    self.hb:set_xy(x, y)
end
--


--
Sprite = {}
function Sprite:new(animation, size)
    obj = {
        animation = animation,
        frame = 1,  -- номер кадра
        size = size  -- размер спрайта
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Sprite:next_frame()
    self.frame = self.frame % #self.animation + 1
end

function Sprite:draw(x, y, flip)
    -- print(self.animation[self.frame], 20, 20, 5)
    -- print(self.frame, 40, 40, 3)
    spr(self.animation[self.frame], x, y, C0, 1, flip, 0, self.size, self.size)
end

function Sprite:animation_end()
    return self.frame == #self.animation
end

function Sprite:copy()
    return Sprite:new(self.animation, self.size)
end
--


--  базовый класс
Body = {}
function Body:new(sprite, x, y)
    obj = {
        sprite = sprite,
        hitbox = 'nil',
        flip = 0,
        x = x, y = y,
        hp = 0, born_flag = true
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Body:is_dead()
    return (self.hp == 0)
end

function Body:take_damage(damage)
    self.hp = fence(self.hp - damage, 0, self.hp)
end

function Body:draw()
    self.sprite:draw(self.x, self.y, self.flip)
end

function Body:born_update()
    self:draw()
    -- trace('born')
    if self.sprite:animation_end() then
        self.born_flag = false
        return false
    end
    self.sprite:next_frame()
    return true
end
--


--
Player = table.shallow_copy(Body)
Player.stay_a = Sprite:new(animation_generation({257}), 1)
Player.run_a = Sprite:new(animation_generation({256, 257, 258, 259, 256, 257, 258, 259, 256, 257, 258, 259}), 1)
Player.death_a = Sprite:new(animation_generation(plr_death_anim()), 1)
Player.born_a = Sprite:new(table.reverse(animation_generation(plr_death_anim())), 1)
Player.hat_a = Sprite:new(animation_generation({279}), 1)

function Player:new(x, y)
    obj = {
        sprite = Player.born_a:copy(),
        start_x = x, start_y = y,
        x = x, y = y,
        last_dx = 1, last_dy = 0,
        dx = 0, dy = 0, v = 1,
        flip = 0,  -- направление при отрисовке спрайта
        hitbox = Hitbox:new(x+2, y+1, x+5, y+7),
        hp = 1,
        born_flag = true,
        boomerang = false
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Player:update()
    if self:is_dead() then
        self:death_update()
        return
    end
    if self.born_flag then
        if not self:born_update() then  -- если рождение закончилось
            self.sprite = Player.stay_a:copy()
        end
        return
    end

    flag = false
    if math.abs(self.dx) + math.abs(self.dy) ~= 0 then  -- is moving
        flag = true
    end

    self.dx = 0; self.dy = 0
    if btn(0) then
        self.dy = self.dy - 1
    end
    if btn(1) then
        self.dy = self.dy + 1
    end
    if btn(2) then
        self.dx = self.dx - 1
    end
    if btn(3) then
        self.dx = self.dx + 1
    end

    k = 1
    if self.dx * self.dy ~= 0 then
        k = 1 / math.sqrt(2)
    end

    if math.abs(self.dx) + math.abs(self.dy) ~= 0 then  -- is moving
        self.last_dx = self.dx; self.last_dy = self.dy
        if not flag then
            self.sprite = Player.run_a:copy()
        end
    else
        self.sprite = Player.stay_a:copy()
    end

    if self.dx == -1 then
        self.flip = 1
    elseif self.dx == 1 then
        self.flip = 0
    end

    self.sprite:next_frame()
    self.x = fence(self.x + self.dx * self.v * k, 0, 240 - 8)
    self.y = fence(self.y + self.dy * self.v * k, 0, 136 - 8)
    self.hitbox:set_xy(self.x+2, self.y+1)
    self:draw()

    if btnp(4) and not self.boomerang then
        self:shoot()
    end
    if self.boomerang then
        self.boomerang:focus(self.x, self.y)
        self.boomerang:update()
        if self.boomerang.hitbox:collide(self.hitbox) and
                self.boomerang.v < self.v then
            self.boomerang = false
        end
    end
end

function Player:shoot()
    self.boomerang = Boomerang:new(self.x, self.y, self.last_dx, self.last_dy)
end

function Player:death_update()
    self.sprite:next_frame()
    if self.sprite.frame == 60 then
        self.sprite = Player.hat_a:copy()
    end
    self:draw()
end

function Player:death()
    -- self.dead = true
    self.sprite = Player.death_a:copy()
end

function Player:set_start_stats()
    self.hp = 1
    self.boomerang = false
    self.x = self.start_x
    self.y = self.start_y
    self.sprite = Player.born_a:copy()
    self.born_flag = true
    self.hitbox = Hitbox:new(self.x+2, self.y+1, self.x+5, self.y+7)
end
--


--
Boomerang = table.shallow_copy(Body)
BOOMERANG_A = Sprite:new(animation_generation({264, 265, 266, 264, 265, 266, 264, 265, 266, 264, 265, 266}), 1)
function Boomerang:new(x, y, dx, dy)
    obj = {  -- dx, dy in [-1, 1]
        sprite = BOOMERANG_A:copy(),
        x = x, y = y,
        dx = dx, dy = dy,
        v = 1.8, k = 1,
        px = 0, py = 0,
        hitbox = Hitbox:new(x+2, y+2, x+5, y+5)
    }
    obj['flip'] = -fence(dx, -1, 0)
    if obj['dx'] * obj['dy'] ~= 0 then
        obj['k'] = 1 / math.sqrt(2)
    end
    obj['dv'] = obj['v'] / 90
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj-- body
end

function Boomerang:update()
    self.sprite:next_frame()
    self.v = self.v - self.dv
    if self.v < 0 then
        self:reverse_update()
        return
    end
    self.x = self.x + self.v * self.dx * self.k
    self.y = self.y + self.v * self.dy * self.k
    self.hitbox:set_xy(self.x + 2, self.y + 2)
    self:draw()
end

function Boomerang:focus(x, y)
    self.px = x; self.py = y
end

function Boomerang:reverse_update()
    fx = self.px; fy = self.py
    x = self.x; y = self.y
    if fx == x then
        fx = fx + 0.0000001
    end
    d = math.abs(fy - y) / math.abs(fx - x)
    dx = self.v / math.sqrt(1 + d*d)
    dy = dx * d

    kx = 1; ky = 1
    if fx < x then
        kx = -1
    end
    if fy < y then
        ky = -1
    end
    self.x = self.x - kx * dx
    self.y = self.y - ky * dy
    self.hitbox:set_xy(self.x + 2, self.y + 2)
    self:draw()
end
--


--
Enemy = table.shallow_copy(Body)
Enemy.stay_a = Sprite:new(animation_generation({261}), 1)
Enemy.suffer_a = Sprite:new(animation_generation({262, 263, 262, 263, 262, 263, 262, 263, 262, 263, 262, 263}), 1)
Enemy.death_a = Sprite:new(animation_generation({288, 289, 290, 291, 292, 293}), 1)
Enemy.born_a = Sprite:new(table.reverse(animation_generation({288, 289, 290, 291, 292, 293})), 1)
function Enemy:new(x, y)
    obj = {
        sprite = Enemy.born_a:copy(),
        x = x, y = y, hp = 24,
        px = 0, py = 0,  -- положение игрока
        flip = math.random(0, 1), -- направление при отрисовке спрайта
        charge = 0,  -- заряд выстрела
        hitbox = Hitbox:new(x+1, y+1, x+5, y+6),
        born_flag = true, death_flag = true
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Enemy:update()
    if self.born_flag then
        if not self:born_update() then
            self.sprite = Enemy.stay_a:copy()
        end
        return
    end
    if self:is_dead() and self.death_flag then
        self.death_flag = false
        self.sprite = Enemy.death_a:copy()
    end
    self.sprite:next_frame()
    self:draw()
end

function Enemy:shoot()
    if self.born_flag then
        return false
    end

    self.charge = self.charge + 1 - fence(math.random(0, 7), 0, 1)
    if self.charge >= 12 then
        self.charge = 0
        return Bullet:new(self.x, self.y, self.px + math.random(-4, 12), self.py + math.random(-4, 12))
    end
    return false
end

function Enemy:focus(x, y)
    self.px = x; self.py = y
end

function Enemy:suffer()
    if self:is_dead() then
        return
    end
    self:take_damage(1)
    -- if not (already suffer)
    if not table.contains(self.sprite.animation, 262) then
        self.sprite = Enemy.suffer_a:copy()
    end
end

function Enemy:chill()
    if self:is_dead() then
        return
    end
    if self.born_flag then
        return
    end
    self.sprite = Enemy.stay_a:copy()
end
--


--
Bomber = table.shallow_copy(Enemy)
Bomber.default_a = Sprite:new({280}, 1)
Bomber.suffer_a = Sprite:new(animation_generation({282, 281, 282, 281, 282, 281, 282, 281, 282, 281, 282, 281}), 1)
Bomber.death_a = Sprite:new(animation_generation({294, 295, 296, 297, 298, 299}), 1)
Bomber.born_a = Sprite:new(table.reverse(animation_generation({294, 295, 296, 297, 298, 299})), 1)
Bomber.preparation_a = Sprite:new({}, 1)
function Bomber:new(x, y)
    obj = {
        sprite = Bomber.born_a:copy(),
        x = x, y = y, hp = 52,
        px = 0, py = 0,  -- положение игрока
        flip = math.random(0, 1), -- направление при отрисовке спрайта
        charge = 0,  -- заряд выстрела
        hitbox = Hitbox:new(x+1, y+2, x+6, y+6),
        born_flag = true, death_flag = true,
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Bomber:update()
    if self.born_flag then
        if not self:born_update() then
            self.sprite = Bomber.default_a:copy()
        end
        return
    end
    if self:is_dead() and self.death_flag then
        self.death_flag = false
        self.sprite = Bomber.death_a:copy()
    end
    if self.charge >= 10 then
        PIXEL:draw(self.x, self.y+3)
        PIXEL:draw(self.x, self.y+4)
        PIXEL:draw(self.x+7, self.y+3)
        PIXEL:draw(self.x+7, self.y+4)
    end

    self.sprite:next_frame()
    self:draw()
end

function Bomber:shoot()
    if self.born_flag then
        return false
    end

    if self.charge >= 10 then
        self.charge = self.charge + 1
    else
        self.charge = self.charge + 1 - fence(math.random(0, 9), 0, 1)
    end
    if self.charge == 40 then
        self.charge = 0
        return Bomb:new(self.x, self.y, self.px + 5, self.py + 5)
    end
    return false
end

function Bomber:suffer()
    if self:is_dead() then
        return
    end
    self:take_damage(1)
    -- if not (already suffer)
    if not table.contains(self.sprite.animation, 282) then
        self.sprite = Bomber.suffer_a:copy()
    end
end

function Bomber:chill()
    if self:is_dead() then
        return
    end
    if self.born_flag then
        return
    end
    self.sprite = Bomber.default_a:copy()
end
--


--
Boss = table.shallow_copy(Enemy)
Boss.default_a = Sprite:new({452}, 3)
Boss.opening_mouth_a = Sprite:new(boss_opening_mouth_anim(), 3)
Boss.openned_mouth_a = Sprite:new({390}, 3)
-- Boss.suffer_a = Sprite:new(animation_generation({456, 460, 456, 460, 456, 460, 456, 460, 456, 460, 456, 460}), 3)
Boss.attack_a = Sprite:new({393}, 3)
Boss.right_beard = {
    {x = 13, y = 18},
    {x = 14, y = 17},
    {x = 15, y = 16},
    {x = 16, y = 15},
    {x = 17, y = 14}
}
Boss.left_beard = {
    {x = 10, y = 18},
    {x = 9, y = 17},
    {x = 8, y = 16},
    {x = 7, y = 15},
    {x = 6, y = 13}
}
Boss.beard_a = boss_beard_anim()
Boss.attack_modes = {'shotgun', 'minigun', 'mortar'}
PIXEL = Sprite:new({269}, 1)
Boss.start_v = 0.4
Boss.start_hp = 200
Boss.sunglasses = Sprite:new({128}, 3)

function Boss:new(x, y)
    obj = {
        sprite = Boss.default_a,
        x = x, y = y, v = Boss.start_v,
        beard_frame = 1,
        hair_cnt = 0, hair_y = {0, 0, 0, 0, 0},
        hitbox = Hitbox:new(x+4, y+4, x+19, y+16),
        px = 0, py = 0, hp = Boss.start_hp,
        mode = 'default',
        charge = 0, attack_mode = 'nil',
        mortar_charge = 0,
        suffer_flag = false
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Boss:update()
    -- trace(self.mode)
    -- moving
    if self.y <= 1 or self.y+18 >= 136-1 then
        self.v = -self.v
    end
    self.y = self.y + self.v
    self.hitbox:set_xy(self.x+4, self.y+4)
    -- hair animation
    self.hair_cnt = self.hair_cnt + 1
    if self.hair_cnt == 6 then
        self.hair_cnt = 0
        for i = 1, 5 do
            self.hair_y[i] = math.random(0, 1)
        end
    end
    for i = 0, 4 do
        if self.v > 0 then
            PIXEL:draw(self.x + i*4, self.y + self.hair_y[i+1], 0)
        else
            PIXEL:draw(self.x + i*4, self.y + self.hair_y[i+1] + 1, 0)
        end
    end
    -- beard animation
    self.beard_frame = (self.beard_frame + 1) % #Boss.beard_a + 1
    for _, i in ipairs(Boss.beard_a[self.beard_frame]) do
        if i < 0 then
            PIXEL:draw(self.x + Boss.left_beard[-i].x, self.y + Boss.left_beard[-i].y, 0)
        else
            PIXEL:draw(self.x + Boss.right_beard[i].x, self.y + Boss.right_beard[i].y, 0)
        end
    end
    -- drawing
    self.sprite:next_frame()
    self:draw()
    self:draw_health_bar()
    Boss.sunglasses:draw(self.x + 3, self.y + (self.suffer_flag and 5 or 6), 0)
    -- mode
    if self.mode == 'default' then
        self:default_update()
    elseif self.mode == 'opening_mouth' then
        self:opening_mouth_update()
    elseif self.mode == 'openned_mouth' then
        self:openned_mouth_update()
    elseif self.mode == 'attack' then
        self:attack_update()
    -- elseif self.mode == 'suffer' then
    --     self:suffer_update()
    end
end

function Boss:default_update()
    self.charge = self.charge + 1 - fence(math.random(0, 6), 0, 1)
    if self.charge >= 10 then
        self.charge = 0
        self.mode = 'opening_mouth'
        self.sprite = Boss.opening_mouth_a:copy()
    end
end

function Boss:opening_mouth_update()
    if self.sprite:animation_end() then
        self.mode = 'openned_mouth'
        self.attack_mode = Boss.attack_modes[math.random(1, 3)]
        self.sprite = Boss.openned_mouth_a:copy()
        if self.attack_mode == 'mortar' then
            self.v = math.sign(self.v) * Boss.start_v * 2.5
        end
    end
end

function Boss:openned_mouth_update()
    if self.charge >= 100 then
        self.mode = 'attack'
        self.sprite = Boss.attack_a:copy()
        self.charge = 0
    end
    if self.attack_mode == 'shotgun' then
        self.charge = self.charge + 100/5
    elseif self.attack_mode == 'minigun' then
        self.charge = self.charge + 100/30
    elseif self.attack_mode == 'mortar' then
        self.charge = self.charge + 100/60
    end
end

function Boss:attack_update()
    if self.charge >= 100 then
        self.charge = 0
        self.mode = 'default'
        self.sprite = Boss.default_a:copy()
        self.v = math.sign(self.v) * Boss.start_v
        return
    end
    if self.attack_mode == 'shotgun' then
        self.charge = self.charge + 100/10
    elseif self.attack_mode == 'minigun' then
        self.charge = self.charge + 100/90
    elseif self.attack_mode == 'mortar' then
        self.charge = self.charge + 100/120
        self.mortar_charge = self.mortar_charge + 1
    end
end

function Boss:draw()
    Boss.sunglasses:draw(self.x + 3, self.y + (self.suffer_flag and 5 or 6), 0)
    self.sprite:draw(self.x, self.y, self.flip)
    self:draw_health_bar()
end

-- function Boss:suffer_update()
--     -- nothing
-- end

function Boss:suffer()
    self:take_damage(1)
    -- if self.mode == 'attack' then
    --     return
    -- end
    -- if self.mode == 'openned_mouth' then
    --     self.mode = 'suffer'
    --     return
    -- end
    -- if self.mode ~= 'suffer' then
    --     self.mode = 'suffer'
    --     -- self.charge = 0
    --     self.sprite = Boss.suffer_a:copy()
    -- end
    self.suffer_flag = true
end

function Boss:chill()
    self.suffer_flag = false
    -- if self.mode == 'suffer' then
    --     self.mode = 'default'
    --     self.sprite = Boss.default_a:copy()
    -- end
    -- if table.contains(self.sprite.animation, 460) then
    --     self.sprite = Boss.default_a:copy()
    -- end
end

function Boss:shoot()
    if self.mode ~= 'attack' then
        return false
    end
    if self.attack_mode == 'shotgun' then
        return Bullet:new(self.x+13, self.y+13, self.px + math.random(-24, 30), self.py + math.random(-24, 30))
    elseif self.attack_mode == 'minigun' then
        if math.random(0, 5) == 0 then
            return Bullet:new(self.x+13, self.y+13, self.px+math.random(2, 4), self.py+math.random(2, 4))
        end
    elseif self.attack_mode == 'mortar' then
        if self.mortar_charge >= 12 then
            self.mortar_charge = 0
            return Bomb:new(self.x+13, self.y+13, math.random(50, 210), self.y+13)
        end
    end
    return false
end

function Boss:draw_health_bar()
    rect(234, 2, 4, 132, 8)
    rect(235, 3, 2, 130 - 130 * self.hp / self.start_hp, 0)
end
--


--
Bomb = table.shallow_copy(Enemy)
Bomb.flight_a = Sprite:new({267}, 1)
Bomb.detonate_a = Sprite:new(animation_generation({268, 267, 268, 267, 268, 267, 268, 267, 268, 267, 268, 267}), 1)
Bomb.boom_a = Sprite:new({304}, 4)
Bomb.vanish_a = Sprite:new(animation_generation({308, 312, 316}), 4)
function Bomb:new(x, y, fx, fy)
    obj = {
        sprite = Bomb.flight_a:copy(),
        x = x, y = y,
        detonate_charge = 0,
        mode = 'flight',
        hitbox = Hitbox:new(x, y, x+2, y+2),
        hitcircle = HitCircle:new(x-10, y-10, 25),
        fx = fx, fy = fy, v = 1,
        dx = 0, dy = 0,
        plr_hitbox = Hitbox:new(2, 1, 5, 7),
        hp = 1, marker = 'bomb'
    }
    if fx == x then
        fx = fx + 0.0000001
    end
    d = math.abs(fy - y) / math.abs(fx - x)
    dx = obj['v'] / math.sqrt(1 + d*d)
    dy = dx * d

    kx = 1; ky = 1
    if fx < x then
        kx = -1
    end
    if fy < y then
        ky = -1
    end
    obj['dx'] = kx * dx
    obj['dy'] = ky * dy
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Bomb:update()
    if self.mode == 'flight' then
        self:flight_update()
        return
    end
    if self.mode == 'chill' then
        self:chill_update()
        return
    end
    if self.mode == 'detonate' then
        self:detonate_update()
        return
    end
    if self.mode == 'boom' then
        self:boom_update()
        return
    end
    if self.mode == 'vanish' then
        self:vanish_update()
        return
    end
end

function Bomb:flight_update()
    if (self.dx < 0 and self.x <= self.fx) or
            (self.dx > 0 and self.x >= self.fx) or
            (self.dy < 0 and self.y <= self.fy) or
            (self.dy > 0 and self.y >= self.fy) then
        self.mode = 'chill'
        self:draw()
        return
    end
    self.x = self.x + self.dx
    self.y = self.y + self.dy
    self.hitbox:set_xy(self.x, self.y)
    self.hitcircle:set_xy(self.x - 10, self.y - 10)
    self:draw()
end

function Bomb:chill_update()
    self:draw()
    -- now bomb is detonate immediately
    -- if self.hitcircle:collide(self.plr_hitbox) then
    if true then
        self.mode = 'detonate'
        self.sprite = Bomb.detonate_a:copy()
    end
end

function Bomb:detonate_update()
    if self.detonate_charge >= 60 then
        self.mode = 'boom'
        self.sprite = Bomb.boom_a:copy()
        self.x = self.x - 10
        self.y = self.y - 10
        return
    end
    self.detonate_charge = self.detonate_charge + 1
    self.sprite:next_frame()
    self:draw()
end

function Bomb:boom_update()
    if self.detonate_charge <= 0 then
        self.mode = 'vanish'
        self:take_damage(1)
        self.sprite = Bomb.vanish_a:copy()
    end
    self.detonate_charge = self.detonate_charge - 2
    self:draw()
end

function Bomb:vanish_update()
    -- if self.sprite:animation_end() then
    --     self:take_damage(1)
    -- end
    self.sprite:next_frame()
    self:draw()
end

function Bomb:focus(x, y)
    self.plr_hitbox:set_xy(x+2, y+1)
end
--


--
Bullet = table.shallow_copy(Body)
Bullet.flight_a = Sprite:new({260}, 1)
function Bullet:new(x, y, fx, fy)
    obj = {
        sprite = Bullet.flight_a, flip = 0,
        x = x, y = y,
        dx = 0, dy = 0,
        v = 1, marker = 'bullet',
        hitbox = Hitbox:new(x, y, x+1, y+1)
    }

    if fx == x then
        fx = fx + 0.0000001
    end
    d = math.abs(fy - y) / math.abs(fx - x)
    dx = obj['v'] / math.sqrt(1 + d*d)
    dy = dx * d

    kx = 1; ky = 1
    if fx < x then
        kx = -1
    end
    if fy < y then
        ky = -1
    end
    obj['dx'] = kx * dx
    obj['dy'] = ky * dy

    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Bullet:update()
    self.x = self.x + self.dx
    self.y = self.y + self.dy
    self.hitbox:set_xy(self.x, self.y)
    self.sprite:next_frame()
    self:draw()
end
--


--
DialogWindow = {}
function DialogWindow:new(message_strings, x, y, width, height)
    obj = {
        message = message_strings,
        x = x, y = y,
        width = width, height = height,
        pos = false
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function DialogWindow:update()
    -- drawing
    rect(self.x, self.y, self.width, self.height, 8)
    rect(self.x+2, self.y+2, self.width-4, self.height-4, 0)
    local x = self.x + 10
    local y = self.y + 4
    for i, s in ipairs(self.message) do
        print(s, x, y + 8*(i-1), 8)
    end
    local y2 = self.y + self.height - 12
    if self.pos then
        print('~Ok        Cancel', x, y2, 8)  
    else
        print(' Ok       ~Cancel', x, y2, 8)  
    end
    -- btns
    if btnp(2) or btnp(3) then
        self.pos = not self.pos
    end
end

function DialogWindow:get_command()
    if btnp(4) then
        -- if self.pos then
        --     return 'Ok'
        -- end
        -- return 'Cancel'
        return (self.pos) and 'Ok' or 'Cancel'
    end
    return false
end
--


--
Game = {}
ENEMIES_PER_LVL = {2, 2, 4, 6, 4, 5, 7, 1}
BOMBERS_PER_LVL = {0, 0, 0, 1, 1, 2, 2, 1}
COORDS_MENU = {20, 28, 36}
COORDS_PALETTE_MENU = {20, 28, 36, 44, 52, 60 ,68, 76}
COORDS_DIFFICULTY_MENU = {20, 28, 36}
PALETTES = {'Old', 'Velvet', 'Tetris', 'Milk', 'Green', 'Chess', 'Invisible!'}
ANGLE = Sprite:new({0}, 1)

function Game:new()
    obj = {
        lvl = 1, mode = 'menu',
        enemies = {},
        bullets = {},
        bombs = {},
        plr = Player:new(120, 64),
        menu_pos = 1, count = 0,
        secret_palette = 0, current_palette = 6,
        boss = false, angles = make_angles(),
        difficulty = 'normal', dialog_window = 'nil',
        boss = false
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Game:build_enemies(k, m)
    for i=1, k do
        x = 15; y = 8
        while not self:build_enemies_check(x, y) do
            x = math.random(0, 29)
            y = math.random(0, 16)
        end
        table.insert(self.enemies, Enemy:new(x * 8, y * 8))
    end
    for i=1, m do
        x = 15; y = 8
        while not self:build_enemies_check(x, y) do
            x = math.random(0, 29)
            y = math.random(0, 16)
        end
        table.insert(self.enemies, Bomber:new(x * 8, y * 8))
    end
end

function Game:build_lvl()
    self.pts = 0  -- nevermind
    self.count = 0
    self.plr:set_start_stats()
    self.enemies = {}
    self.bullets = {}
    self.bombs = {}
    if self.lvl == 1 then
        self:build_start_lvl()
        return
    end
    if self.lvl == 7 then
        self:build_boss_lvl()
        return
    end
    self:build_enemies(ENEMIES_PER_LVL[self.lvl], BOMBERS_PER_LVL[self.lvl])
end

function Game:update()
    for _, d in ipairs(self.angles) do
        d:draw()
    end
    if self.dialog_window ~= 'nil' then
        self:dialog_window_update()
        return
    end
    if self.mode == 'action' then
        self:action_update()
        return
    end
    if self.mode == 'death' then
        self:death_update()
        return
    end
    if self.mode == 'menu' then
        self:menu_update()
        return
    end
    if self.mode == 'palette_menu' then
        self:palette_menu_update()
        return
    end
    if self.mode == 'difficulty_menu' then
        self:difficulty_menu_update()
        return
    end
    if self.mode == 'lvl_complete' then
        self:lvl_complete_update()
        return
    end
end

function Game:build_boss_lvl()
    self.boss = true
    table.insert(self.enemies, Boss:new(20, 20))
end

function Game:build_start_lvl()
    table.insert(self.enemies, Enemy:new(16, 80))
end

function Game:menu_update()
    print('Level ' .. tostring(self.lvl) .. ' / 8', 2, 2, 8)
    print('Use arrows and [z] to choose', 2, 118, 8)
    -- ниже -- пункты меню
    print('Play', 120, 20, 8)
    print('Change palette', 120, 28, 8)
    print('Change difficulty', 120, 36, 8)
    print('~', 112, COORDS_MENU[self.menu_pos], 8)

    if btnp(0) then
        self.menu_pos = (#COORDS_MENU + self.menu_pos - 2) % #COORDS_MENU + 1
    end
    if btnp(1) then
        self.menu_pos = self.menu_pos % #COORDS_MENU + 1
    end

    if btnp(4) then
        if self.menu_pos == 1 then
            self.mode = 'action'
            self:build_lvl()
        elseif self.menu_pos == 2 then
            self.mode = 'palette_menu'
        elseif self.menu_pos == 3 then
            self.mode = 'difficulty_menu'
            self.menu_pos = 2
        end
    end
end

function Game:palette_menu_update()
    print('Level ' .. tostring(self.lvl) .. ' / 8', 2, 2, 8)
    print('Use arrows and [z] to choose', 2, 118, 8)

    print('Back', 120, 20, 8)
    for i = 1, 6 do
        if i == self.current_palette then
            print(PALETTES[i] .. '!', 120, COORDS_PALETTE_MENU[i + 1], 8)
        else
            print(PALETTES[i], 120, COORDS_PALETTE_MENU[i + 1], 8)
        end
    end
    print(PALETTES[7], 120, COORDS_PALETTE_MENU[8], self.secret_palette)

    if btnp(0) then
        self.menu_pos = (#COORDS_PALETTE_MENU + self.menu_pos - 2) % #COORDS_PALETTE_MENU + 1
    end
    if btnp(1) then
        self.menu_pos = self.menu_pos % #COORDS_PALETTE_MENU + 1
    end
    if btnp(4) then
        if self.menu_pos == 1 then
            self.mode = 'menu'
        else
            if self.menu_pos == 8 then self.secret_palette = 8 else self.secret_palette = 0 end
            colorChange(self.menu_pos - 1)
            self.current_palette = self.menu_pos - 1
        end
    end
    -- for test
    -- if btnp(5) then
    --     negative_colorChange(self.current_palette)
    -- end
    --
    print('~', 112, COORDS_PALETTE_MENU[self.menu_pos], 8)    
end

function Game:difficulty_menu_update()
    print('Level ' .. tostring(self.lvl) .. ' / 8', 2, 2, 8)
    print('Use arrows and [z] to choose', 2, 118, 8)
    -- ниже -- пункты меню
    print('Back', 120, 20, 8)
    if self.difficulty == 'normal' then
        print('Normal!', 120, 28, 8)
    else
        print('Normal', 120, 28, 8)
    end
    if self.difficulty == 'hard' then
        print('Hard!', 120, 36, 8)
    else
        print('Hard', 120, 36, 8)
    end
    print('~', 112, COORDS_DIFFICULTY_MENU[self.menu_pos], 8)

    if btnp(0) then
        self.menu_pos = (#COORDS_DIFFICULTY_MENU + self.menu_pos - 2) % #COORDS_DIFFICULTY_MENU + 1
    end
    if btnp(1) then
        self.menu_pos = self.menu_pos % #COORDS_DIFFICULTY_MENU + 1
    end
    if btnp(4) then
        if self.menu_pos == 1 then
            self.mode = 'menu'
        else
            self.dialog_window = DialogWindow:new({'The Game will start', 'from first level.', 'Are you sure?'}, 60, 30, 120, 80)
        end
    end
end

function Game:dialog_window_update()
    self.dialog_window:update()
    if self.mode == 'difficulty_menu' then
        if btnp(4) then
            if self.dialog_window:get_command() == 'Ok' then
                self.dialog_window = 'nil'
                self.lvl = 1
                if self.menu_pos == 2 then
                    self.difficulty = 'normal'
                elseif self.menu_pos == 3 then
                    self.difficulty = 'hard'
                end
            elseif self.dialog_window:get_command() == 'Cancel' then
                self.dialog_window = 'nil'
            end
        end
    end
end

function Game:action_update()
    if self:lvl_complete_check() then
        self:lvl_complete()
        return
    end

    self.plr:update()

    if self.lvl == 1 then
        rect(0, 0, 240, 26, 8)
        print('Use arrows to move', 80, 8, 0)
        print('Press [z] to throw', 80, 16, 0)
        if self.plr.y < 26 then
            self.plr.y = 26
            self.plr.hitbox:set_xy(self.plr.x, self.plr.y)
        end
    elseif self.lvl == 2 then
        rect(0, 0, 240, 26, 8)
        print('More time the boomerang flies', 30, 8, 0)
        print('through the enemy = more damage', 30, 16, 0)
        if self.plr.y < 26 then
            self.plr.y = 26
            self.plr.hitbox:set_xy(self.plr.x, self.plr.y)
        end
    end

    for _, e in ipairs(self.enemies) do
        e:focus(self.plr.x, self.plr.y)
        e:update()
        bullet = e:shoot()
        if bullet and self.lvl ~= 1 then
            if bullet.marker == 'bomb' then
                table.insert(self.bombs, bullet)
            else
                table.insert(self.bullets, bullet)
            end
        end
        if self.plr.boomerang and 
                self.plr.boomerang.hitbox:collide(e.hitbox) then
            e:suffer()
        else
            e:chill()
        end
        if self.plr.hitbox:collide(e.hitbox) then
            self:death()
        end
        if e:is_dead() and e.sprite:animation_end() then
            table.remove(self.enemies, _)
            self.pts = self.pts + 1
        end
    end

    for _, b in ipairs(self.bombs) do
        b:focus(self.plr.x, self.plr.y)
        b:update()
        if (b.mode == 'flight' or b.mode == 'chill') and self.plr.hitbox:collide(b.hitbox) then
            self:death()
        end
        if b:is_dead() and b.sprite:animation_end() then
            table.remove(self.bombs, _)
        end
        if b.mode == 'boom' and b.hitcircle:collide(self.plr.hitbox) then
            self:death()
        end
        if b.mode == 'boom' then
            for _, e in ipairs(self.enemies) do
                if b.hitcircle:collide(e.hitbox) then
                   e:take_damage(30) 
                end
            end
        end
    end

    for _, b in ipairs(self.bullets) do
        if self.plr.hitbox:collide(b.hitbox) then
            self:death()
        end
        b:update()
        if b.x < 0 or b.x > 240 or b.y < 0 or b.y > 136 then
            table.remove(self.bullets, _)
        end
    end
end

function Game:death_update()
    if self.count == 150 then
        self.mode = 'menu'
        return
    end
    for _, b in ipairs(self.bombs) do
        b:update()
        if b:is_dead() and b.sprite:animation_end() then
            table.remove(self.bombs, _)
        end
    end

    self.plr:update()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
    for _, b in ipairs(self.bombs) do
        b:draw()
    end 
    self.count = self.count + 1
end

function Game:death()
    self.mode = 'death'
    self.plr:take_damage(1)
    self.plr:death()
end

function Game:build_enemies_check(x, y)
    if (x == 16 and y == 29)  or 
            (x == 0 and y == 29)  or 
            (x == 16 and y == 0)  or 
            (x == 0 and y == 0) then
        return false
    end
    if x <= 16 and y <= 8 and x >= 14 and y >= 6 then
        return false
    end
    for _, e in ipairs(self.enemies) do
        if x == e.x // 8 and y == e.y // 8 then
            return false
        end
    end
    return true
end

function Game:lvl_complete_check()
    return #self.enemies == 0
end

function Game:lvl_complete()
    if self.lvl == 8 then
        self:game_final()
    end
    self.pts = 0
    self.count = 0
    self.lvl = self.lvl + 1
    self.mode = 'lvl_complete'
end

function Game:lvl_complete_update()
    if self.count == 120 then
        self.count = 0
        self.mode = 'menu'
        return
    end

    for _, b in ipairs(self.bullets) do
        b:draw()
    end
    for _, b in ipairs(self.bombs) do
        b:draw()
    end 
    self.plr:draw()
    -- self.plr:update()
    self.count = self.count + 1
end

function Game:game_final()
    -- body
end
--


game = Game:new()
game.lvl = 3
function TIC()
    cls(C0)
    game:update()
end

-- <TILES>
-- 000:8000000080000000800000008000000080000000800000008000000088888888
-- 128:0888888880008088000008880000000000000000000000000000000000000000
-- 129:8888888880080888000088800000000000000000000000000000000000000000
-- 130:8000000000000000000000000000000000000000000000000000000000000000
-- 192:0000000008000800008000800008000800088888000000000000888800080008
-- 193:0000000008000800008000800008000888888888000000008888888808880080
-- 194:0000000008000000008000000008000088880000000000008888000088800000
-- 208:0000080000008880000088880000088800000088000000080000000800000000
-- 209:8880000800008800888088088880080888880008888888888888888888888888
-- 210:8800000000080000888800008880000088800000880000008800000080000000
-- 225:0888888800888880000888000000000000000000000000000000000000000000
-- </TILES>

-- <SPRITES>
-- 000:0000000000888800888888880088880000888800088888008088880000088000
-- 001:0000000000888800888888880088880000888800088888008088880000800800
-- 002:0088880088888888008888000088880008888800808888000800008000000000
-- 003:0088880088888888000888000088880000888800088888008088880000800800
-- 004:8800000088000000000000000000000000000000000000000000000000000000
-- 005:8008000008008000088888000808080008888800088888000088800000080000
-- 006:8008000008008000088888000808080008808800088088000088800000080000
-- 007:8008000008008000088888000808080008808800088088000088800000000000
-- 008:0000000000000000000888000088000000800000008000000000000000000000
-- 009:0000000000000000008880000000880000000800000008000000000000000000
-- 010:0000000000000000000008000000080000008800008880000000000000000000
-- 011:0800000080800000080000000000000000000000000000000000000000000000
-- 012:8080000000000000808000000000000000000000000000000000000000000000
-- 013:8000000000000000000000000000000000000000000000000000000000000000
-- 016:0000000000888800888888880088800000888800088880008088880000800000
-- 017:0000000000888800888888880088800000880800088880008088080000800000
-- 018:0000000000888800888888880080800000880800088080008088080000800000
-- 019:0000000000888800888888880080800000080800088080008008080000800000
-- 020:0000000000888800888888880000800000080000008080008008000000800000
-- 021:0000000000888800888888880000000000080000008000008008000000000000
-- 022:0000000000000000008888008888888800000000008000000008000000000000
-- 023:0000000000000000000000000088880088888888000000000000000000000000
-- 024:0008080800808080088888800808808008888880088888800088880000088000
-- 025:0008080800808080088888800808808008800880088008800080080000088000
-- 026:0008080800808080088888800808808008800880088008800088880000088000
-- 027:0008080800808080088888808808808888888888088888800088880000088000
-- 032:0000000008008000088888000808080008808800088088000088800000000000
-- 033:0000000000000000088880000808080008808800088088000088800000000000
-- 034:0000000000000000008880000808080008808800008088000088000000000000
-- 035:0000000000000000008080000808080000808000008080000008000000000000
-- 036:0000000000000000008080000800000000808000000000000008000000000000
-- 037:0000000000000000008000000000000000008000000000000008000000000000
-- 038:0000000000808080088888800808808008800880008008800080080000088000
-- 039:0000000000808000008888800808808008800880008008000080080000088000
-- 040:0000000000000000008888000808808008800880008008000080080000088000
-- 041:0000000000000000008008000808808000800800008008000080080000088000
-- 042:0000000000000000000008000808000000000800008000000000080000080000
-- 043:0000000000000000000008000800000000000000000000000000080000000000
-- 048:0000000000000008000008880000888800088888008888880088888808888888
-- 049:0888888888888888888888888888888888888888888888888888888888888888
-- 050:0000000088000000888800008888800088888800888888808888888088888888
-- 052:0000000000000000000008080000808000080808008080800008080800808080
-- 053:0808080880808080080808088080808008080808808080800808080880808080
-- 054:0000000080000000080800008080800008080800808080800808080080808080
-- 056:0000000000000000000000000000000000000808000080800000000000000080
-- 057:0000000000000080000000008000008000080808000080800808080880800000
-- 058:0000000000000000080000000000000008000000808080000808080000008080
-- 060:0000000000000000000000000000000000000800000000800000000000000000
-- 061:0000000000000000000000008000000000080808000000800008000000000000
-- 062:0000000000000000000000000000000008000000000000000800000000000000
-- 064:0888888888888888888888888888888888888888888888888888888888888888
-- 065:8888888888888888888888888888888888888888888888888888888888888888
-- 066:8888888888888888888888888888888888888888888888888888888888888888
-- 067:0000000080000000800000008000000080000000800000008000000080000000
-- 068:0808080880808080080808088080808008080808808080800808080880808080
-- 069:0808080880888880088888888888888808888888888888880888888880888880
-- 070:0808080880808080080808088080808008080808808080800808080880808080
-- 071:0000000080000000000000008000000000000000800000000000000080000000
-- 072:0008000800000080080808000000808008080808008080000008000800008000
-- 073:0800080880008080080808088080808000080808800000800808080880808080
-- 074:0808080080008000000808008080008008000808008080800008080080008080
-- 076:0008000000000000000000000000800008080000000000000008000800000000
-- 077:0800000800000000080008000080808000000008000000000808000000000080
-- 078:0800000080008000000008000080000000000000000000000008000080008000
-- 080:0888888808888888008888880088888800088888000088880000088800000008
-- 081:8888888888888888888888888888888888888888888888888888888888888888
-- 082:8888888888888888888888808888888088888800888880008888000088000000
-- 084:0808080800808080000808080080808000080808000080800000080800000000
-- 085:0808080880808080080808088080808008080808808080800808080880808080
-- 086:0808080880808080080808008080808008080800808080000808000080000000
-- 088:0000080800808080000800000000808000000000000000800000000000000000
-- 089:0800080080800000080808080080008008080808808080000808080800808080
-- 090:0008080080808080080800008080800000080000800000000800000080000000
-- 092:0000080800000000000000000000008000000000000000000000000000000000
-- 093:0000080000800000080008000000000000080800808000000000000000000000
-- 094:0000000000008000080000000000000000000000000000000000000000000000
-- 097:0888888800000000000000000000000000000000000000000000000000000000
-- 101:0808080800000000000000000000000000000000000000000000000000000000
-- 128:0000000008000800008000800008000800088888000000000000000000000000
-- 129:0000000008000800008000800008000888888888000000000000000000000000
-- 130:0000000008000000008000000008000088880000000000000000000000000000
-- 131:0000000008000800008000800008000800088888000000000000000000000000
-- 132:0000000008000800008000800008000888888888000000000000000000000000
-- 133:0000000008000000008000000008000088880000000000000000000000000000
-- 134:0000000008000800008000800008000800088888000000000000000000000000
-- 135:0000000008000800008000800008000888888888000000000000000000000000
-- 136:0000000008000000008000000008000088880000000000000000000000000000
-- 137:0000000008000800008000800008000800088888000000000000000000000000
-- 138:0000000008000800008000800008000888888888000000000000000000000000
-- 139:0000000008000000008000000008000088880000000000000000000000000000
-- 140:0000000008000800008000800008000800088888000000000000000000000000
-- 141:0000000008000800008000800008000888888888000000000000000000000000
-- 142:0000000008000000008000000008000088880000000000000000000000000000
-- 144:0000080000008880000088880000088800000088000000080000000800000000
-- 145:0000000000008800888088088880080888880008888888888888088888888888
-- 146:0000000000080000888800008880000088800000880000008000000000000000
-- 147:0000080000008880000088880000088800000088000000080000000800000000
-- 148:0000000000008800888088088880000888888808888808888880008888880888
-- 149:0000000000080000888800008880000088800000880000008000000000000000
-- 150:0000080000008880000088880000088800000088000000080000000800000000
-- 151:0000000000008800888088088880000888888888888000888880808888800088
-- 152:0000000000080000888800008880000088800000880000008000000000000000
-- 153:0000080000008880000088880000088800000088000000080000000800000000
-- 154:0000000000008800888088088880000888888888888880088880080888888008
-- 155:0000000000080000888800008880000088800000880000008000000000000000
-- 156:0000080000008880000088880000088800000088000000080000000800000000
-- 157:0000000000008800888088088880000888888888888800088888080888880008
-- 158:0000000000080000888800008880000088800000880000008000000000000000
-- 161:0888888000888800000880000000000000000000000000000000000000000000
-- 164:0888888000888800000880000000000000000000000000000000000000000000
-- 167:0888888000888800000880000000000000000000000000000000000000000000
-- 170:0888888000888800000880000000000000000000000000000000000000000000
-- 173:0888888000888800000880000000000000000000000000000000000000000000
-- 192:0000000008000800008000800008000800088888000000000000000000000000
-- 193:0000000008000800008000800008000888888888000000000000000000000000
-- 194:0000000008000000008000000008000088880000000000000000000000000000
-- 196:0000000008000800008000800008000800088888000000000000000000000000
-- 197:0000000008000800008000800008000888888888000000000000000000000000
-- 198:0000000008000000008000000008000088880000000000000000000000000000
-- 200:0000000008000800008000800008000800088888000000000000000000000000
-- 201:0000000008000800008000800008000888888888000000000000000000000000
-- 202:0000000008000000008000000008000088880000000000000000000000000000
-- 204:0000000008000800008000800008000800088888000000000000000000000000
-- 205:0000000008000800008000800008000888888888000000000000000000000000
-- 206:0000000008000000008000000008000088880000000000000000000000000000
-- 208:0000080000008880000088880000088800000088000000080000000800000000
-- 209:0000000000008800888088088880080888880008888888888888888888888888
-- 210:0000000000080000888800008880000088800000880000008800000080000000
-- 212:0000080000008880000088880000088800000088000000080000000800000000
-- 213:0000000000008800888088088880080888880008888888888888888888888888
-- 214:0000000000080000888800008880000088800000880000008000000000000000
-- 216:0000080000008880000088880000088800000088000000080000000800000000
-- 217:0000000000008800888088088880000888888888888000888880808888800088
-- 218:0000000000080000888800008880000088800000880000008800000080000000
-- 220:0000080000008880000088880000088800000088000000080000000800000000
-- 221:0000000000008800888088088880000888888888888800088888080888880008
-- 222:0000000000080000888800008880000088800000880000008800000080000000
-- 225:0888888800888880000888000000000000000000000000000000000000000000
-- 229:0888888000888800000880000000000000000000000000000000000000000000
-- 233:0888888800888880000888000000000000000000000000000000000000000000
-- 237:0888888800888880000888000000000000000000000000000000000000000000
-- </SPRITES>

-- <MAP>
-- 000:101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:100000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <PALETTE>
-- 000:0000002e3037a69aca40501030238746878f000000300030ffffffebe5ce6f4367d0d058fffdaf94e344fffffff89020
-- </PALETTE>


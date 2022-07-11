
C0 = 0  -- прозрачный цвет
-- COLORS1 = {bit = '000000', Milk = '302387', Green = '46878f'}
-- COLORS2 = {bit = 'ffffff', Milk = 'fffdaf', Green = '94e344'}


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
PLAYER_STAY_A = Sprite:new(animation_generation({257}), 1)
PLAYER_RUN_A = Sprite:new(animation_generation({256, 257, 258, 259, 256, 257, 258, 259, 256, 257, 258, 259}), 1)
PLAYER_DEATH_A = Sprite:new(animation_generation(plr_death_anim()), 1)
PLAYER_BORN_A = Sprite:new(table.reverse(animation_generation(plr_death_anim())), 1)
PLAYER_HAT_A = Sprite:new(animation_generation({279}), 1)

function Player:new(x, y)
    obj = {
        sprite = PLAYER_BORN_A:copy(),
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
            self.sprite = PLAYER_STAY_A:copy()
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
            self.sprite = PLAYER_RUN_A:copy()
        end
    else
        self.sprite = PLAYER_STAY_A:copy()
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
        self.sprite = PLAYER_HAT_A:copy()
    end
    self:draw()
end

function Player:death()
    -- self.dead = true
    self.sprite = PLAYER_DEATH_A:copy()
end

function Player:set_start_stats()
    self.hp = 1
    self.boomerang = false
    self.x = self.start_x
    self.y = self.start_y
    self.sprite = PLAYER_BORN_A:copy()
    self.born_flag = true
    hitbox = Hitbox:new(self.x+2, self.y+1, self.x+5, self.y+7)
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
        v = 1.6, k = 1,
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
Enemy.suffer_a = Sprite:new(animation_generation({262, 261, 262, 261, 262, 261, 262, 261, 262, 261, 262, 261}), 1)
Enemy.death_a = Sprite:new(animation_generation({288, 289, 290, 291, 292, 293}), 1)
Enemy.born_a = Sprite:new(table.reverse(animation_generation({288, 289, 290, 291, 292, 293})), 1)
function Enemy:new(x, y)
    obj = {
        sprite = Enemy.born_a:copy(),
        x = x, y = y, hp = 20,
        px = 0, py = 0,  -- положение игрока
        flip = 0, -- направление при отрисовке спрайта
        charge = 0,  -- заряд выстрела
        hitbox = Hitbox:new(x+1, y+1, x+6, y+7),
        hp = 20, born_flag = true
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
    if self:is_dead() and table.contains(self.sprite.animation, 261) then
        self.sprite = Enemy.death_a:copy()
    end
    self.sprite:next_frame()
    self:draw()
end

function Enemy:shoot()
    if self.born_flag then
        return false
    end

    self.charge = self.charge + 1 - fence(math.random(0, 9), 0, 1)
    if self.charge == 10 then
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
AngryEnemy = table.shallow_copy(Enemy)

function AngryEnemy:shoot()
    if self.born_flag then
        return false
    end

    self.charge = self.charge + 1 - fence(math.random(0, 5), 0, 1)
    if self.charge == 10 then
        self.charge = 0
        return Bullet:new(self.x, self.y, self.px + math.random(-4, 12), self.py + math.random(-4, 12))
    end
    return false
end
--


--
Boss = table.shallow_copy(Enemy)

function Boss:new()
    -- body
end
--


--
Bullet = table.shallow_copy(Body)
BULLET_A = Sprite:new(animation_generation({260}), 1)
function Bullet:new(x, y, fx, fy)
    obj = {
        sprite = BULLET_A, flip = 0,
        x = x, y = y,
        dx = 0, dy = 0,
        v = 1,
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
Game = {}
ENEMIES_PER_LVL = {1, 3, 5, 1, 6, 7, 8, 2}
COORDS_MENU = {20, 28}
COORDS_PALETTE_MENU = {20, 28, 36, 44, 52, 60 ,68, 76, 84}
PALETTES = {'Old', 'Halloween', 'Tetris', 'Milk', 'Green', 'Velvet', '1bit'}
function Game:new()
    obj = {
        lvl = 1, mode = 'menu',
        enemies = {},
        bullets = {},
        plr = Player:new(120, 64),
        pts = 0, menu_pos = 1, count = 0
    }
    -- чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function Game:build_enemies(k)
    for i=1, k do
        x = 15; y = 8
        while not self:build_enemies_check(x, y) do
            x = math.random(0, 29)
            y = math.random(0, 16)
        end
        table.insert(self.enemies, Enemy:new(x * 8, y * 8))
    end
end

function Game:build_lvl()
    self.pts = 0
    self.count = 0
    self.plr:set_start_stats()
    self.enemies = {}
    self.bullets = {}
    if self.lvl == 4 then
        --
        return
    end
    if self.lvl == 8 then
        --
        return
    end
    self:build_enemies(ENEMIES_PER_LVL[self.lvl])
end

function Game:update()
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
    if self.mode == 'lvl_complete' then
        self:lvl_complete_update()
        return
    end
end

function Game:menu_update()
    print('Level ', 2, 2, 8)
    print(self.lvl, 35, 2, 8)
    print('/ 8', 44, 2, 8)

    print('Use arrows to move', 2, 118, 8)
    print('Use [z] to throw', 2, 128, 8)
    -- ниже -- пункты меню
    print('Play', 120, 20, 8)
    print('Change palette', 120, 28, 8)
    print('~', 112, COORDS_MENU[self.menu_pos], 8)

    if btnp(0) then
        self.menu_pos = (#COORDS_MENU + self.menu_pos - 2) % #COORDS_MENU + 1
    end
    if btnp(1) then
        self.menu_pos = self.menu_pos % #COORDS_MENU + 1
    end

    if btnp(4) then
        if self.menu_pos == 1 then
            self:build_lvl()
            self.mode = 'action'
        elseif self.menu_pos == 2 then
            self.mode = 'palette_menu'
        end
    end
end

function Game:palette_menu_update()
    print('Level ', 2, 2, 8)
    print(self.lvl, 35, 2, 8)
    print('/ 8', 44, 2, 8)
    print('Use arrows to move', 2, 118, 8)
    print('Use [z] to throw', 2, 128, 8)

    print('Back', 120, 20, 8)
    for i = 1, 7 do
        print(PALETTES[i], 120, COORDS_PALETTE_MENU[i + 1], 8)
    end
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
            colorChange(self.menu_pos - 1)
        end
    end 
    print('~', 112, COORDS_PALETTE_MENU[self.menu_pos], 8)    
end

function Game:action_update()
    if self:lvl_complete_check() then
        self:lvl_complete()
        return
    end

    self.plr:update()
    for _, e in ipairs(self.enemies) do
        e:focus(self.plr.x, self.plr.y)
        e:update()
        bullet = e:shoot()
        if bullet then
            table.insert(self.bullets, bullet)
        end

        if self.plr.boomerang and 
                self.plr.boomerang.hitbox:collide(e.hitbox) then
            e:suffer()
        else
            e:chill()
        end
        if e:is_dead() and e.sprite.frame == 60 then
            table.remove(self.enemies, _)
            self.pts = self.pts + 1
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

    self.plr:update()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end
    self.count = self.count + 1
end

function Game:death()
    self.mode = 'death'
    self.plr:take_damage(1)
    self.plr:death()
end

function Game:build_enemies_check(x, y)
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
    return self.pts == ENEMIES_PER_LVL[self.lvl]
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
    if self.count == 150 then
        self.count = 0
        self.mode = 'menu'
        return
    end

    self.plr:update()
    self.count = self.count + 1
end

function Game:game_final()
    -- body
end
--


game = Game:new()
function TIC()
    cls(C0)
    game:update()
end

-- <SPRITES>
-- 000:0000000000888800888888880088880000888800088888008088880000088000
-- 001:0000000000888800888888880088880000888800088888008088880000800800
-- 002:0088880088888888008888000088880008888800808888000800008000000000
-- 003:0088880088888888000888000088880000888800088888008088880000800800
-- 004:8800000088000000000000000000000000000000000000000000000000000000
-- 005:0000000008000080008888000080080000888800000880000088880008000080
-- 006:0800008000888800008008000088880000088000008888000800008000000000
-- 008:0000000000000000000888000088000000800000008000000000000000000000
-- 009:0000000000000000008880000000880000000800000008000000000000000000
-- 010:0000000000000000000008000000080000008800008880000000000000000000
-- 016:0000000000888800888888880088800000888800088880008088880000800000
-- 017:0000000000888800888888880088800000880800088880008088080000800000
-- 018:0000000000888800888888880080800000880800088080008088080000800000
-- 019:0000000000888800888888880080800000080800088080008008080000800000
-- 020:0000000000888800888888880000800000080000008080008008000000800000
-- 021:0000000000888800888888880000000000080000008000008008000000000000
-- 022:0000000000000000008888008888888800000000008000000008000000000000
-- 023:0000000000000000000000000088880088888888000000000000000000000000
-- 032:0000000008000000008888000080080000888800000880000088880008000000
-- 033:0000000008000000008880000080080000888000000880000088800008000000
-- 034:0000000008000000008800000080080000880000000880000088000008000000
-- 035:0000000008000000008800000080000000880000000080000088000008000000
-- 036:0000000008000000000800000080000000080000000000000008000008000000
-- 037:0000000008000000000000000080000000000000000000000000000008000000
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
-- 000:0000002e303730003040501030238746878fa69aca000000ffffffebe5cef89020d0d058fffdaf94e3446f4367ffffff
-- </PALETTE>


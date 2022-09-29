local setmetatable = setmetatable
local math_floor = up.math.floor
local pairs = pairs


local mt = {}
mt.__index = mt
mt.type = 'unit'
up.unit_class = mt

local unitType = {
    'hero',
    'building',
    'unknown',
    'unit',
}

-- attr
local attrType = {
    ['hp_max']='hp_max',
    ['hp_cur'] = 'hp_cur',
    ['mp_max']='mp_max',
    ['mp_cur'] = 'mp_cur',
    ['hp_rec']='hp_rec',
    ['mp_rec']='mp_rec',
    ['ori_speed']='ori_speed',
    ['attack_phy']='attack_phy',
    ['defense_phy']='defense_phy',
    ['pene_phy']='pene_phy',
    ['pene_phy_ratio']='pene_phy_ratio',
    ['vampire_phy']='vampire_phy',
    ['attack_mag']='attack_mag',
    ['defense_mag']='defense_mag',
    ['pene_mag']='pene_mag',
    ['pene_mag_ratio']='pene_mag_ratio',
    ['vampire_mag']='vampire_mag',
    ['attack_speed']='attack_speed',
    ['critical_chance']='critical_chance',
    ['critical_dmg']='critical_dmg',
    ['cd_reduce']='cd_reduce',
    ['hit_rate']='hit_rate',
    ['dodge_rate']='dodge_rate',
    ['extra_dmg']='extra_dmg',
    ['dmg_reduction']='dmg_reduction',
    ['gainvalue']='gainvalue',
    ['resilience']='resilience',
    ['heal_effect']='heal_effect',
    ['body_size']='body_size',
    ['alarm_range']='alarm_range',
    ['cancel_alarm_range']='cancel_alarm_range',
    ['vision_rng']='vision_rng',
    ['vision_night']='vision_night',
    ['rotate_speed']='rotate_speed',
	['strength'] = "strength",
	['agility'] = "agility",
	['intelligence'] = "intelligence",
	['main'] = "main",
}

local abilityType = {
    ['Hide'] = 0,
    ['Normal'] = 1,
    ['Common'] = 2,
    ['Hero'] = 3,
    ['Item'] = 4,
    ['Magicbook'] = 5,
    ['Build'] = 6,
}

function mt:__tostring()
    return ('%s|%s|%s'):format('unit', self:get_name(), tostring(self._base))
end


function mt:lightning(data)
    return up.lightning(data)
end

function mt:set_name(name)
    self._base:api_set_name(name)
end

function mt:get_name()
    return self._base:api_get_name()
end

function mt:get_type()
    return unitType[self._base:api_get_type()]
end

function mt:get_key()
    return self._base.api_get_key()
end

function mt:get_icon()
    return GameAPI.get_icon_id_by_unit_type(self._base.api_get_key())
end

function mt:get_point()
    local p = self._base:api_get_position()
    return up.actor_point(p)
end

function mt:get_owner()
    return up.player(self._base:api_get_role():api_get_role_id())
end

function mt:get_player()
    return up.player(self._base:api_get_role():api_get_role_id())
end

function mt:add_item(item)
    local item = self._base:api_add_item(item)
    return item
end

function mt:get_skill_point()
    return self._base:api_get_ability_point()
end

function mt:get_attack_speed()
    local attack_skill = self:find_skill('Normal',nil,1)
    if attack_skill then
        if self:get('attack_speed') == 0 then
            return 0
        else
            local as = self:get('attack_speed') / 100
            local cd = 1 / (attack_skill:get('cd')/as)
            return cd
        end
    else
        return false
    end
end

function mt:get_atk_range()
    local attack_skill = self:find_skill('Normal',nil,1)
    if attack_skill then
        return attack_skill:get('range')
    else
        return false
    end
end

--Base 
-- function mt:attack_move(point)
--     api_release_command()
-- end

function mt:move(point)
    self._base:api_release_command(GameAPI.create_unit_command_move_to_pos(point._base))
end

--road move
function mt:move_road(road,patrol_mode,can_attack)
    self._base:api_release_command(GameAPI.create_unit_command_move_along_road(road._base,patrol_mode,can_attack))
end

function mt:follow(unit)
    -- self._base:api_release_command(GameAPI.create_unit_command_follow(unit._base))
    self._base:api_release_command(GameAPI.create_unit_command_follow(unit._base))
end

function mt:hold(point)
    if not point then point = self:get_point() end
    self._base:api_release_command(GameAPI.create_unit_command_stop(point._base))
end

function mt:stop()
    self._base:api_release_command(GameAPI.create_unit_command_stop())
end

function mt:attack(target)
    if target.type == 'point' then
        self._base:api_release_command(GameAPI.create_unit_command_attack_move(target._base))
    elseif target.type == 'unit' then
        self._base:api_release_command(GameAPI.create_unit_command_attack_target(target._base))
    end
end



function mt:kill(killer)
    if not self:is_destroyed() or not self:is_alive() then
        if not killer then
            self._base:api_kill(nil)
        else
            self._base:api_kill(killer._base)
        end
    end
end

function mt:reborn(point)
    self._base:api_revive(point._base)
end

function mt:remove()
    self._base:api_delete()
end

function mt:get_item(type,slot)
    return up.actor_item(self._base:api_get_item_by_slot(SlotType[type],slot))
end


function mt:get_ability(type,id,slot)
    local base
    if id then
        base = self._base:api_get_ability_by_type(abilityType[type],id)
    end
    if slot then
        base = self._base:api_get_ability(abilityType[type],slot)
    end
    if base then
        local data = {}
        for k, v in pairs(up.skill[id]) do
            if data[k] == nil then
                data[k] = v
            end
        end
        local skill = setmetatable(data, mt)
        skill._base = base
        return skill
    else
        return nil
    end
end

function mt:switch_ability(source,target)
    self._base:api_switch_ability(source._base,target._base)
end

function mt:cast(ability,target)
    local type = target.type
    ability = ability._base
    if target then target = target._base end
    if not target then
        self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability))
    elseif type == 'point' then
        self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability,target))
    elseif type == 'unit' then
        self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability,nil,nil,target))
    elseif type == 'item' then
        self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability,nil,nil,nil,target))
    elseif type == 'destructable' then
        self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability,nil,nil,nil,nil,target))
    end
end

function mt:cast_pointToPoint(ability,point1,point2)
    self._base:api_release_command(GameAPI.create_unit_command_use_skill(ability,point1._base,point2._base))
end

--tag
function mt:add_tag(tag)
    self._base:api_add_tag(tag)
end

function mt:remove_tag(tag)
    self._base:api_remove_tag(tag)
end

function mt:has_tag(tag)
    return self._base:has_tag(tag)
end

--state
function mt:add_restriction(state_name)
    self._base:api_add_state(RestrictionId[state_name])
end

function mt:remove_restriction(state_name)
    self._base:api_remove_state(RestrictionId[state_name])
end

function mt:has_restriction(state_name)
    return self._base:api_has_state(RestrictionId[state_name])
end

function mt:make_invisible(switch)
    if switch then
        self._base:api_add_state(512)
    else
        self._base:api_remove_state(512)
    end
    --self._base:api_set_bar_text_visible(not switch)
    --self._base:api_set_hp_bar_visible(not switch)
end



function mt:has_item_type(key)
    return self._base:api_has_item_key(key)
end

function mt:get_level()
    return self._base:api_get_level()
end

function mt:set_level(lv)
    self._base:api_set_level(lv)
end

function mt:add_level(lv)
    self._base:api_add_level(lv)
end


function mt:set_exp(exp)
    self._base:api_set_exp(Fix32(32))
end

function mt:add_exp(exp)
    self._base:api_add_exp(Fix32(32))
end

function mt:get_exp()
    return self._base:api_get_exp()
end


function mt:get_up_need_exp()
    return self._base:api_get_upgrade_exp()
end

function mt:blink(point)
    self._base:api_transmit(point._base)
end


function mt:set_point(point)
    self._base:api_force_transmit(point._base)
end


function mt:set_time_life(time)
    self._base:api_set_life_cycle(Fix32(time))
end

function mt:pause_time_life(bool)
    self._base:api_pause_life_cycle(bool)
end

function mt:get_time_life()
    return self._base:api_get_life_cycle():float()
end

function mt:get_total_time_life()
    return self._base:api_get_total_life_cycle():float()
end

function mt:show_time_bar(time)
    self._base:api_show_health_bar_count_down(Fix32(time))
end

function mt:damage(data)
    if not data.target then return end
    if data.skill then data.skill = data.skill._base end
    if not data.type then data.type = 0 end

    GameAPI.apply_damage(self._base,data.skill,data.target._base,data.type,Fix32(data.damage),true)
end

function mt:add_damage(data)
    --ex: u:add_damage{target=u,type = 1,skill = ,damage = }
    local skill
    local type
    local source 
    if not data.source then
        source = nil
    else
        source = data.source._base
    end

    if not data.skill then
        skill = nil
    else
        skill = data.skill._base
    end
    if not data.type then
        type = 0
    else
        type = data.type
    end
    GameAPI.apply_damage(source,skill,self._base,type,Fix32(data.damage),true)
end


function mt:add_animation(data)
    if not data.init_time then data.init_time = 0 end
    if not data.end_time then data.end_time = -1 end
    if not data.loop then data.loop = false end
    if not data.speed then data.speed = 1 end
    self._base:api_play_animation(data.name,data.speed,data.init_time,data.end_time,data.loop)
    --self._base:api_play_animation(data.name,data.rate,data.init_time,data.end_time,data.loop)
end


function mt:stop_animation(name)
    if name then
        self._base:api_stop_animation(name)
    else
        self._base:api_stop_cur_animation()
    end
end

function mt:change_animation(source,target)
    self._base:api_change_animation(target,source)
end

function mt:cancel_change_animation(source,target)
    self._base:api_cancel_change_animation(target,source)
end

function mt:clear_change_animation(name)
    self._base:api_clear_change_animation(name)
end

-- reset_all_animation


--ghost
function mt:ghost_start(data)
    if not data then data = {} end
    local r,g,b,a = Fix32(data.r or 255),Fix32(data.g or 255.0), Fix32(data.b or 255.0), Fix32(data.a or 255.0)
    local interval = Fix32(data.interval or 0.3)
    local start = Fix32(data.start or 0.1)
    local dura = Fix32(data.dura or 0.1)
    local over = Fix32(data.over or 0.3)
    self._base.api_start_ghost(r,g,b,a,interval,dura,start,over)
end

function mt:ghost_close()
    self._base:api_stop_ghost()
end

function mt:ghost_wait_close(time)
    if self.ghost_wait_close_timer then
        self.ghost_wait_close_timer:remove()
    end
    self.ghost_wait_close_timer = up.wait(time,function()
        self:ghost_close()
        self.ghost_wait_close_timer:remove()
        self.ghost_wait_close_timer = nil
    end)
end

function mt:ghost_set_color(r,g,b,a)
    self._base:api_set_ghost_color(Fix32(r),Fix32(g),Fix32(b),Fix32(a))
end

function mt:ghost_set_time(interval,start,dura,over)
    self._base:api_set_ghost_time(Fix32(interval),Fix32(start),Fix32(dura),Fix32(over))
end

function mt:change_model(name)
    self._base:api_replace_model(name)
end

function mt:cancel_change_model(name)
    self._base:api_cancel_replace_model(name)
end

function mt:get_pkg_size()
    return self._base:api_get_unit_pkg_cnt()
end

function mt:get_bag_size()
    return self._base:api_get_unit_pkg_cnt()
end

function mt:get_model()
    return self._base:api_get_model()
end


function mt:set_scale(scale)
    self._base:api_set_scale(scale)
end


function mt:get_height()
    return self._base:api_get_height()
end

function mt:set_height(height,speed)
    if speed then
        self._base:gradually_raise_api(Fix32(height),speed)
    else
        self._base:api_raise_height(Fix32(height))
    end
end

function mt:get_facing()
    return self._base:get_face_angle():float()
end

function mt:set_facing(angle,time)
    local b = true
    if not time then
        time = 0
    end
    if time == 0 then
        b = false
    end
    if b then
        self._base:api_set_face_angle(Fix32(angle),Fix32(time*1000))
    else
        self._base:api_set_face_angle(Fix32(angle),Fix32(-1))
    end
end

function mt:set_facing_point(point,time)
    local b = true
    if not time then
        time = 0
    end
    if time == 0 then
        b = false
    end
    if b then
        self._base:api_set_face_angle(GameAPI.get_points_angle(self._base:api_get_position(), point._base), Fix32(time * 1000))
    else
        self._base:api_set_face_angle(Fix32(angle),Fix32(-1))
    end
end

function mt:get_turn_speed()
    return self._base:api_get_turn_speed()
end

function mt:set_turn_speed(speed)
    self._base:set_turn_speed(Fix32(speed))
end

--conditions
    function mt:is_alive()
        return self._base:api_is_alive()
    end

    function mt:is_move()
        return self._base:api_is_moving()
    end

    function mt:has_item(item)
        return self._base:api_has_item(item)
    end

    function mt:in_range(target,range)

    end

--shop
    function mt:is_shop()
        return self._base:api_is_shop()
    end

    function mt:add_shop_item(tab,item)
        self._base:api_add_shop_item(tab,item._base)
    end

    function mt:add_shop_unit(tab,unit)
        self._base:api_add_shop_unit(tab,unit._base)
    end

    function mt:remove_shop_item(tab,id)
        self._base:api_remove_shop_item(tab,id)
    end

    function mt:remove_shop_unit(tab,id)
        self._base:api_remove_shop_unit(tab,id)
    end

    function mt:set_shop_item_stock(tab,id,cnt)
        self._base:set_shop_item_stock(tab,id,cnt)
    end

    function mt:set_shop_unit_stock(tab,id,cnt)
        self._base:api_set_shop_unit_stock(tab,id,cnt)
    end

    function mt:buy_item(shop,tab,id)
        if not shop:is_shop() then return end
        self._base:api_buy_item_with_tab_name(shop._base,tab,id)
    end

    function mt:buy_unit(shop,tab,id)
        if not shop:is_shop() then return end
        self._base:api_buy_unit_with_tab_name(shop._base,tab,id)
    end

    function mt:sell_item(shop,item)
        self._base:api_sell_item(shop._base,item._base)
    end

    function mt:get_shop_item_stock(tab,id)
        return self._base:api_get_shop_item_stock(tab,id)
    end

    function mt:get_shop_unit_stock(tab,id)
        return self._base:api_get_shop_unit_stock(tab,id)
    end

    function mt:get_shop_tab_cnt()
        return self._base:api_get_shop_tab_cnt()
    end

    function mt:get_shop_range()
        return self._base:api_get_shop_range():float()
    end

    function mt:get_shop_tab_name(tab_idx)
        return self._base:api_get_shop_tab_name(tab_idx)
    end

    --get shop tab goos count
        -- tab_idx
    function mt:get_tab_good_cnt(tab_idx)
        local a = self._base:api_get_shop_item_list(tab_idx)
        local n = 0
        for index, value in Python.enumerate(a) do
            n = n + 1
        end
        return n
    end

    function up.unit_class.__index:each_goods(tab_idx)
        local a = self._base:api_get_shop_item_list(tab_idx)
        local goods_list = {}
        for _, key in Python.enumerate(a) do
            table.insert(goods_list,key)
        end
        local n = 0
        return function (t, v)
            n = n + 1
            return t[n]
        end, goods_list
    end
    

    function mt:get_shop_tab_goods_key(tab_idx,id)
        local a = self._base:api_get_shop_item_list(tab_idx)
        for index, value in Python.enumerate(a) do
            if index == id - 1 then
                return value
            end
        end
    end
    
    --get sell cd
    function mt:get_shop_item_cd(tab_idx,key)
        local t = self._base:api_get_shop_item_cd(tab_idx,key)
        if t then
            local cd = {}
            for _, value in Python.enumerate(t) do
                table.insert(cd,value:float())
            end
            return cd
        else
            return nil
        end
    end

--Base
function mt:create_unit(name, point, angle)
    local u = up.create_unit(name, point, angle,self:get_player())
    return u
end


local up_event_dispatch = up.event_dispatch
local up_event_notify = up.event_notify
local up_game = up.game

--Register Event
function mt:event(name, f)
	return up.event_register(self, name, f)
end

--Fire Event
function mt:event_dispatch(name, ...)
    local res, arg = up_event_dispatch(self, name, ...)
    if res ~= nil then
        return res, arg
    end
    local player = self:get_owner()
    if player then
        local res, arg = up_event_dispatch(player, name, ...)
        if res ~= nil then
            return res, arg
        end
    end
    local res, arg = up_event_dispatch(up_game, name, ...)
    if res ~= nil then
        return res, arg
    end
    return nil
end

function mt:event_notify(name, ...)
    up_event_notify(self, name, ...)
    local player = self:get_owner()
    if player then
        up_event_notify(player, name, ...)
    end
    up_event_notify(up_game, name, ...)
end

function mt:is_enemy(dest)
    return GameAPI.is_enemy(self._base,dest._base)
end

function mt:is_ally(dest)
    return GameAPI.is_ally(self._base,dest._base)
end

function mt:is_hero()
    return self:get_type() == 'hero'
end

function mt:get_atk_type()
    return self._base:api_get_atk_type()
end

function mt:get_def_type()
    return self._base:api_get_def_type()
end

function mt:get_main_attr()
    --print(self._base:get_main_attr())
    return self._base:api_get_main_attr()
end

function mt:get_select_circle_scale()
    return GameAPI.get_select_circle_scale(self._base):float()
end

function mt:is_building()
    return self:get_type() == 'building'
end

function mt:is_type(flag)
    return self:get_type() == flag
end

function mt:is_illusion()
    return GameAPI.is_unit_illusion(self._base)
end

function mt:is_destroyed()
    if self then
        return self._base:api_is_destroyed()
    end
end

--  can unit see the dest
function mt:is_visible(dest)
    return GameAPI.get_visibility_of_unit(self._base,dest._base)
end

function mt:can_move()
    return true
end

function mt:can_blink(point)
    return self._base.api_can_teleport_to(point._base)
end

function mt:can_attack()

    return true
end

function mt:get(attr,type)
    if attrType[attr] then attr = attrType[attr] end
    if not type then
        return  self._base:api_get_float_attr(attr):float()
    end
    local type_list = {
        ['Base'] = function()
            return self._base:api_get_attr_base(attr):float()
        end,
        ['BaseRatio'] = function()
            return self._base:api_get_attr_base_ratio(attr):float()
        end,
        ['Bonus'] = function()
            return self._base:api_get_attr_bonus(attr):float()
        end,
        ['BonusRatio'] = function()
            return self._base:api_get_attr_bonus_ratio(attr):float()
        end,
        ['AllRatio'] = function()
            return self._base:api_get_attr_all_ratio(attr):float()
        end,
        ['Extra'] = function()
            return self._base:api_get_attr_other(attr):float()
        end,
    }
    return type_list[type]()
end

function mt:set(attr,value,type)
    if not type then
        type = 'Base'
    end
    if attrType[attr] then attr = attrType[attr] end
    if attr == 'hp_cur' or attr == 'mp_cur' then
        self._base:api_set_attr(attr, Fix32(value))
        return
    end
    local type_list = {
        ['Base'] = function()
            self._base:api_set_attr_base(attr, Fix32(value))
        end,
        ['BaseRatio'] = function()
            self._base:api_set_attr_base_ratio(attr, Fix32(value))
        end,
        ['Bonus'] = function()
            self._base:api_set_attr_bonus(attr, Fix32(value))
        end,
        ['BonusRatio'] = function()
            self._base:api_set_attr_bonus_ratio(attr, Fix32(value))
        end,
        ['AllRatio'] = function()
            self._base:api_set_attr_all_ratio(attr, Fix32(value))
        end,
    }
    type_list[type]()
end

function mt:add(attr,value,type)
    if attrType[attr] then attr = attrType[attr] end
    -- self._base:api_add_attr_base(attr, Fix32(value))
    if not type then
        type = 'Base'
    end
    local type_list = {
        ['Base'] = function()
            self._base:api_add_attr_base(attr, Fix32(value))
        end,
        ['BaseRatio'] = function()
            self._base:api_add_attr_base_ratio(attr, Fix32(value))
        end,
        ['Bonus'] = function()
            self._base:api_add_attr_bonus(attr, Fix32(value))
        end,
        ['BonusRatio'] = function()
            self._base:api_add_attr_bonus_ratio(attr, Fix32(value))
        end,
        ['AllRatio'] = function()
            self._base:api_add_attr_all_ratio(attr, Fix32(value))
        end,
    }
    type_list[type]()
end

--custom kv
function mt:setTypeKv(key,value)
end

--todo
function mt:getKv(key,type,isType)
end

function mt:hasTypeKv(key,type)
    return GameAPI['has_unit_key_'..KvType[type]..'_kv'](self:get_key(),key)
end

function mt:getTypeKv(key,type)
    local value = GameAPI['get_unit_key_'..KvType[type]..'_kv'](self:get_key(),key)
    if type == 'real' then
        value = value:float()
    end
    if type == 'int' then
        value = value:int()
    end
    return value
end

local Units = {}
function up.actor_unit(u)
    if u == nil then return nil end
    local id 
    if type(u) == 'number' then
        id = u
        u = GameAPI.get_unit_by_id(u)
    else
        id = u:api_get_id()
    end
    if not Units[id] then
        local unit = {}
        unit._base = u
        setmetatable(unit, mt)
        Units[id] = unit
    end
    return Units[id]
end


function up.create_unit(name, point, angle, player)
    local u = GameAPI.create_unit(name,point._base,Fix32(angle),player._base)
    return up.actor_unit(u)
end

local elevator_entity = {

	initial_properties = {
		collisionbox = {-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375},
		physical = true,
		visual = "mesh",
		mesh = "carts_cart.b3d",
		visual_size = {x=0.875, y=0.875},
		textures = {"elevators_elevator.png"}
	},
	driver = nil,
	velocity = {x=0, y=0, z=0},
	attached_items = {},
	jumped = false,
	sneaked = false,
	on_brakerail = false,
	ejected_player = nil,
	ejected_pos = nil,
	one_tick = 0,
	remove_elevator = false,
	hud_time = 0,
	hud_id = nil,
	hud_player = nil

}






function elevator_entity:on_activate(staticdata, dtime_s)

	self.object:set_armor_groups({immortal=1})

end






function elevator_entity:on_rightclick(clicker)

	-- not a player
	if not clicker or not clicker:is_player() then
		return
	end

	local player_name = clicker:get_player_name()

	-- player clicks on empty elevator
	if not self.driver then
		self.driver = player_name
		manage_attachment(clicker, self.object)
		player_api.set_animation(clicker, "stand")

	-- driver wants to leave
	elseif player_name == self.driver then
		self.object:set_acceleration( vector.new(0,0,0) )
		self.object:set_velocity( vector.new(0,0,0) )
		manage_attachment(clicker, nil)
		self.driver = nil
		self.ejected_player = clicker
		self.ejected_pos = eject_to_pos(clicker)
	end

end






function elevator_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)

	-- not a player
	if not puncher or not puncher:is_player() then
		return
	end

	-- the puncher musst be outside the elevator to remove it
	if self.driver ~= puncher:get_player_name() and puncher:get_player_control().sneak then

		-- if it is allowed to eject others they will be ejected
		if eject_by_others then
			local player = minetest.get_player_by_name(self.driver)
			self.driver = nil
			manage_attachment(player, nil)
			self.ejected_player = player
			self.ejected_pos = eject_to_pos(player)
		end

		-- only remove the elevator if it is empty
		if not self.driver then

			-- give the puncher the item
			local inv = puncher:get_inventory()

			if not (creative and creative.is_enabled_for
						and creative.is_enabled_for(puncher:get_player_name()))
						or not inv:contains_item("main", "elevators:elevator") then
				local leftover = inv:add_item("main", "elevators:elevator")
				-- If no room in inventory add a replacement elevator to the world
				if not leftover:is_empty() then
					minetest.add_item(self.object:get_pos(), leftover)
				end
			end

			-- remove elevator
			self.remove_elevator = true;
		end

	end

end






function elevator_entity:on_step(dtime)
	
	if self.driver then

		-- player left the game
		if not minetest.get_player_by_name(self.driver) then
			self.driver = nil
			return
		end


		-- change velocity if the seated player jumps or sneaks
		if minetest.get_player_by_name(self.driver):get_player_control().jump then
			if self.object:get_velocity().y <= top_speed then
				self.object:set_acceleration(vector.new(0,time_to_accelerate*(top_speed-self.object:get_velocity().y) + dtime*10,0))
			else
				self.object:set_velocity( vector.new(0,top_speed,0) )
				self.hud_time = 10
				self.hud_player = self.driver
			end
		elseif minetest.get_player_by_name(self.driver):get_player_control().sneak then
			if self.object:get_velocity().y >= -top_speed then
				self.object:set_acceleration(vector.new(0,time_to_accelerate*(-(top_speed + self.object:get_velocity().y)) - dtime*10,0))
			else
				self.object:set_velocity( vector.new(0,-top_speed,0) )
				self.hud_time = 10
				self.hud_player = self.driver
			end
			
		else
			self.object:set_acceleration(vector.new(0,0,0))
		end


		-- calculate position of the heading node
		local next_pos = self.object:get_pos()
		local going_down = false
		local going_up = false

		if self.object:get_velocity().y < 0 then
			next_pos = vector.add( next_pos , vector.new(0,-0.5,0) )
			going_down = true
		elseif self.object:get_velocity().y > 0 then
			next_pos = vector.add( next_pos , vector.new(0,0.5,0) )
			going_up = true
		else
			-- Not moving. Could be even out of rails if those got destroyed in the meantime
		end

		local next_node = minetest.get_node(next_pos)

		if next_node.name ~= "elevators:rail" and next_node.name ~= "elevators:brakerail" then -- next node is not an elevators:rail and not an elevators:brakerail
			self.object:set_velocity( vector.new(0,0,0) )
			if going_up == true then -- moving upwards
				self.object:set_pos( vector.new(self.object:get_pos().x, math.floor(self.object:get_pos().y) , self.object:get_pos().z) )
			end
			if going_down == true then -- moving downwards
				self.object:set_pos( vector.new(self.object:get_pos().x, math.ceil(self.object:get_pos().y) , self.object:get_pos().z) )
			end
		elseif minetest.get_node(self.object:get_pos()).name == "elevators:brakerail" then -- next node is an elevators:brakerail
			if self.on_brakerail == false then
				self.on_brakerail = true
				self.object:set_velocity( vector.new(0,0,0) )
				self.object:set_acceleration( vector.new(0,0,0) )
			end
		else
			self.on_brakerail = false
		end


		

	else -- there is no driver in the elevator

		self.object:set_acceleration( vector.new(0,0,0) )
		self.object:set_velocity( vector.new(0,0,0) )

		if self.ejected_player then -- reposition player if he was ejected
			if self.one_tick == 3 then
				self.ejected_player:set_pos(self.ejected_pos)
				self.ejected_player = nil
				self.one_tick = 0
			else
				self.one_tick = self.one_tick + 1
			end
		end

		if self.remove_elevator and self.one_tick == 0 then -- on_punch() has been called
				self.object:remove()
		end


	end


	-- display hud
	if self.hud_player then
		if self.hud_player ~= self.driver then

			-- remove hub from the player
			if minetest.get_player_by_name(self.hud_player) then
				minetest.get_player_by_name(self.hud_player):hud_remove(self.hud_id)
			end

			self.hud_player = nil
			self.hud_time = 0
			self.hud_id = nil
			return
		end

		if self.hud_time ~= 0 then

			if not self.hud_id then -- add hud
				self.hud_id = minetest.get_player_by_name(self.hud_player):hud_add({
					 hud_elem_type = "text",
					 position      = {x = 0.5, y = 0.8},
					 offset        = {x = 0,   y = 0},
					 text          = "max speed reached",
					 alignment     = {x = 0, y = 0},  -- center aligned
					 scale         = {x = 100, y = 100}, -- covered later
					 number        = 0xFFFFFF
				})
			end

			self.hud_time = self.hud_time - 1

		else

			--remove hud
			minetest.get_player_by_name(self.hud_player):hud_remove(self.hud_id)
			self.hud_player = nil
			self.hud_id = nil

		end

	end
	

end






function eject_to_side(pos)

	local node_0_available = not minetest.registered_nodes[minetest.get_node( vector.new(pos.x, pos.y-2, pos.z) ).name].walkable
	local node_1_available = not minetest.registered_nodes[minetest.get_node( vector.new(pos.x, pos.y-1, pos.z) ).name].walkable
	local node_2_available = not minetest.registered_nodes[minetest.get_node( pos ).name].walkable -- hight of the elevator
	local node_3_available = not minetest.registered_nodes[minetest.get_node( vector.new(pos.x, pos.y+1, pos.z) ).name].walkable
	local node_4_available = not minetest.registered_nodes[minetest.get_node( vector.new(pos.x, pos.y+2, pos.z) ).name].walkable

	-- check 1x2x1 nodes to be free
	if not node_0_available and node_1_available and node_2_available then
		return vector.new(pos.x, pos.y-1, pos.z)
	end
	if not node_1_available and node_2_available and node_3_available then
		return pos
	end
	if not node_2_available and node_3_available and node_4_available then
		return vector.new(pos.x, pos.y+1, pos.z)
	end

	-- no spot to eject found
	return nil

end






function eject_to_pos(player)

	local player_yaw = player:get_look_horizontal()
	local eject_pos

	-- convert yaw into 														
	if player_yaw > 5.497787 or player_yaw <= 0.785398 then								
		eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z+1) )
	elseif player_yaw <= 2.356194 then
		eject_pos = eject_to_side( vector.new(player:get_pos().x-1, player:get_pos().y, player:get_pos().z) )
	elseif player_yaw <= 3.926990 then
		eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z-1) )
	else
		eject_pos = eject_to_side( vector.new(player:get_pos().x+1, player:get_pos().y, player:get_pos().z) )
	end


	if eject_pos ~= nil then
		return eject_pos
	end

	-- all 4 other directions
	eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z+1) )
	if eject_pos ~= nil then
		return eject_pos
	end
	eject_pos = eject_to_side( vector.new(player:get_pos().x-1, player:get_pos().y, player:get_pos().z) )
	if eject_pos ~= nil then
		return eject_pos
	end
	eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z-1) )
	if eject_pos ~= nil then
		return eject_pos
	end
	eject_pos = eject_to_side( vector.new(player:get_pos().x+1, player:get_pos().y, player:get_pos().z) )
	if eject_pos ~= nil then
		return eject_pos
	end

	-- eject above
	return vector.new(player:get_pos().x, player:get_pos().y+2, player:get_pos().z)

end	






function manage_attachment(player, obj)

	-- not a player
	if not player then
		return
	end

	local status = obj ~= nil
	local player_name = player:get_player_name()
	if player_api.player_attached[player_name] == status then
		return
	end
	player_api.player_attached[player_name] = status

	if status then
		player:set_attach(obj, "", {x=0, y=-4.5, z=0}, {x=0, y=0, z=0})
		player:set_eye_offset({x=0, y=-4, z=0},{x=0, y=-4, z=0})
	else
		player:set_detach()
		player:set_eye_offset({x=0, y=0, z=0},{x=0, y=0, z=0})
	end

end






minetest.register_entity("elevators:elevator", elevator_entity)






minetest.register_craftitem("elevators:elevator", {
	description = "Elevator",
	inventory_image = minetest.inventorycube("elevators_elevator_top.png", "elevators_elevator_side.png", "elevators_elevator_side.png"),
	wield_image = "elevators_elevator_side.png",
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and not (placer and placer:is_player() and placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return
		end

		if minetest.get_node(pointed_thing.under).name == "elevators:rail" or minetest.get_node(pointed_thing.under).name == "elevators:brakerail" then
			minetest.add_entity(pointed_thing.under, "elevators:elevator")
		elseif minetest.get_node(pointed_thing.under).name == "elevators:rail" or minetest.get_node(pointed_thing.under).name == "elevators:brakerail" then
			minetest.add_entity(pointed_thing.above, "elevators:elevator")
		else
			return
		end

		minetest.sound_play({name = "default_place_node_metal", gain = 0.5},
			{pos = pointed_thing.above}, true)

		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(placer:get_player_name())) then
			itemstack:take_item()
		end
		return itemstack
	end
})






minetest.register_craft({
	output = "elevators:elevator",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})

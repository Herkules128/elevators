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

	-- eject driver
	if self.driver then
		self.object:set_acceleration( vector.new(0,0,0) )
		self.object:set_velocity( vector.new(0,0,0) )
		local player = minetest.get_player_by_name(self.driver)
		self.driver = nil
		manage_attachment(player, nil)
		self.ejected_player = player
		self.ejected_pos = eject_to_pos(player)
	end

	-- give the puncher the item
	local inv = puncher:get_inventory()

	if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(puncher:get_player_name()))
				or not inv:contains_item("main", "elevators:elevator") then
		local leftover = inv:add_item("main", "elevators:elevator")
		-- If no room in inventory add a replacement cart to the world
		if not leftover:is_empty() then
			minetest.add_item(self.object:get_pos(), leftover)
		end
	end


	self.remove_elevator = true;

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
			self.object:set_acceleration(vector.new(0,time_to_accelerate*(top_speed-self.object:get_velocity().y),0))
		elseif minetest.get_player_by_name(self.driver):get_player_control().sneak then
			self.object:set_acceleration(vector.new(0,time_to_accelerate*(-(top_speed + self.object:get_velocity().y)),0))
		else
			self.object:set_acceleration(vector.new(0,0,0))
		end


		-- calculate position of the heading node
		local next_pos = self.object:get_pos()
		local down = false

		if self.object:get_velocity().y < 0 then
			next_pos = vector.add( next_pos , vector.new(0,-0.5,0) )
			down = true
		else
			next_pos = vector.add( next_pos , vector.new(0,0.5,0) )
		end

		local next_node = minetest.get_node(next_pos)

		if next_node.name ~= "elevators:rail" and next_node.name ~= "elevators:brakerail" then -- next node is not an elvators:rail and not an elevators:brakerail
			self.object:set_velocity( { x=0, y=0, z=0} )
			if down == false then
				self.object:set_pos( vector.floor(self.object:get_pos()) )
			else
				self.object:set_pos( vector.floor(vector.add( self.object:get_pos() , vector.new(0,1,0) ) ) )
			end
		elseif minetest.get_node(self.object:get_pos()).name == "elevators:brakerail" then -- next node is an elevators:brakerail
			if self.on_brakerail == false then
				self.on_brakerail = true
				self.object:set_velocity( vector.new(0,0,0) )
				self.object:set_acceleration(vector.new(0,0,0))
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

	

end






function eject_to_side(pos)

	local node_ground_available = minetest.get_node( vector.new(pos.x, pos.y-2, pos.z) ).name == "air"
	local node_0_available = minetest.get_node( vector.new(pos.x, pos.y-1, pos.z) ).name == "air"
	local node_1_available = minetest.get_node(pos).name == "air" -- hight of the elevator
	local node_2_available = minetest.get_node( vector.new(pos.x, pos.y+1, pos.z) ).name == "air"
	local node_3_available = minetest.get_node( vector.new(pos.x, pos.y+2, pos.z) ).name == "air"

	-- check 1x2x1 nodes to be free
	if not node_ground_available and node_0_available and node_1_available then
		return vector.new(pos.x, pos.y-1, pos.z)
	end
	if not node_0_available and node_1_available and node_2_available then
		return pos
	end
	if not node_1_available and node_2_available and node_3_available then
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
	else
			
		-- all 4 other directions
		eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z+1) )
		if eject_pos ~= nil then
			return eject_pos
		else
			eject_pos = eject_to_side( vector.new(player:get_pos().x-1, player:get_pos().y, player:get_pos().z) )
			if eject_pos ~= nil then
				return eject_pos
			else
				eject_pos = eject_to_side( vector.new(player:get_pos().x, player:get_pos().y, player:get_pos().z-1) )
				if eject_pos ~= nil then
					return eject_pos
				else
					eject_pos = eject_to_side( vector.new(player:get_pos().x+1, player:get_pos().y, player:get_pos().z) )
					if eject_pos ~= nil then
						return eject_pos
					end
				end
			end
		end
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

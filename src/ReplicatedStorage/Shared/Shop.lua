--!strict
export type Item = {
	id: string,
	slot: string,
	name: string,
	price: number,
	vip: boolean?,
	color: Color3,
}

local Shop = {}

Shop.Items = {
	{ id = "suit_black", slot = "suit", name = "Black Tie", price = 0, color = Color3.fromRGB(16, 16, 18) },
	{ id = "suit_ivory", slot = "suit", name = "Ivory Dinner", price = 400, color = Color3.fromRGB(228, 220, 206) },
	{ id = "suit_wine", slot = "suit", name = "Wine Velvet", price = 800, color = Color3.fromRGB(78, 22, 32) },
	{ id = "suit_navy", slot = "suit", name = "Midnight Navy", price = 900, color = Color3.fromRGB(18, 28, 48) },
	{ id = "suit_gold", slot = "suit", name = "Gilded", price = 0, vip = true, color = Color3.fromRGB(186, 150, 78) },

	{ id = "knife_steel", slot = "knife", name = "Steel", price = 0, color = Color3.fromRGB(196, 196, 204) },
	{ id = "knife_obsidian", slot = "knife", name = "Obsidian", price = 600, color = Color3.fromRGB(22, 22, 28) },
	{ id = "knife_ivory", slot = "knife", name = "Ivory Edge", price = 1200, color = Color3.fromRGB(232, 224, 210) },

	{ id = "gun_gold", slot = "gun", name = "Gold Revolver", price = 0, color = Color3.fromRGB(212, 175, 110) },
	{ id = "gun_nickel", slot = "gun", name = "Nickel", price = 500, color = Color3.fromRGB(176, 180, 188) },
	{ id = "gun_onyx", slot = "gun", name = "Onyx", price = 1400, color = Color3.fromRGB(24, 24, 28) },
} :: { Item }

function Shop.get(id: string): Item?
	for _, it in ipairs(Shop.Items) do
		if it.id == id then
			return it
		end
	end
	return nil
end

function Shop.defaults(): { [string]: string }
	return {
		suit = "suit_black",
		knife = "knife_steel",
		gun = "gun_gold",
	}
end

return Shop

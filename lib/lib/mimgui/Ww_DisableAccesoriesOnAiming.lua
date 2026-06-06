require 'lib.moonloader'

local object_visible = {}
local iskl = {3131}
local dist_visible = 1

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	while true do
	wait(0)
		if isKeyDown(VK_RBUTTON) then
			for i, objid in pairs(getAllObjects()) do
				for iid = 1, #iskl do
					pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					_, objX, objY, objZ = getObjectCoordinates(objid)
					local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
					if ddist < dist_visible and object_visible[objid] ~= false and tonumber(getObjectModel(objid)) ~= iskl[iid] then
						setObjectVisible(objid, false)
						object_visible[objid] = false
					end
				end
			end
		else
			for i, objid in pairs(getAllObjects()) do
				for iid = 1, #iskl do
					if object_visible[objid] == false then
						pX, pY, pZ = getCharCoordinates(PLAYER_PED)
						_, objX, objY, objZ = getObjectCoordinates(objid)
						local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
						if object_visible[objid] == false and tonumber(getObjectModel(objid)) ~= iskl[iid] then
							setObjectVisible(objid, true)
							object_visible[objid] = true
						end
					end
				end
			end
			repeat wait(0) until isKeyDown(VK_RBUTTON)
		end
	end
end
tb = {}
font = renderCreateFont('Arial', 10, 4)
X, Y = getScreenResolution()
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    repeat wait(0) until isSampAvailable()
	while true do wait(0)
		if isCharSittingInAnyCar(PLAYER_PED) then
			car = storeCarCharIsInNoSave(PLAYER_PED)
			posx, posy, posz = getCarCoordinates(car)
			X, Y = convert3DCoordsToScreen(posx, posy, posz)
			health = getCarHealth(car)
			bool, hpdamage = damag(health)
			if bool == true then
				rendersec(hpdamage)
			end
			for k, pv in pairs(getAllChars()) do
				boolshit = hasCarBeenDamagedByChar(car, pv)
				if boolshit == true then
					_, id = sampGetPlayerIdByCharHandle(pv)
					nickname = sampGetPlayerNickname(id)
					goren(nickname, id)
					clearCarLastDamageEntity(car)
				end
			end
		end
	end
end
a = 0
color = 0xAB00ff00
function rendersec(hpdamage)
t=os.clock() + 1
	while t > os.clock() do 
		a = a + 10
		if hpdamage > 200 then
			color = 0x4Dff0000
			colorpoly = 0x4Dff0000
		elseif	hpdamage > 100 then
			color = 0x4Dffff00
			colorpoly = 0x4Dffff00
		else
			color = 0x4D00ff00
			colorpoly = 0x4D00ff00
		end
		X = X + 1
		renderDrawBox(X, Y,	28, 28, color)
		renderDrawPolygon(X+14, Y+14, 27, 27, 3, a, colorpoly)
		renderFontDrawText(font, '-'..hpdamage, X+4, Y+6, 0xFFffffff)
		wait(0)
	end
end
function goren(nickname, id)
tt=os.clock() + 2

	while tt > os.clock() do
		wait(0)
		renderDrawBoxWithBorder(X-18, Y+4, 20, 20, 0x80ff0000, 2, 0x40ff0000)
		renderFontDrawText(font, 'damaged your car: '..nickname..' ['..id..']', X+4, Y+6, 0xFFffffff)
	end
end
function damag(health)
table.insert(tb, health)
	if #tb >= 3 then
		table.remove(tb, 1, 2)
	end
	if tb[1] ~= tb[2] then
		if tb[1] ~= nil and  tb[2] ~= nil then
			if tb[1] > tb[2] then
				return true, tb[1]-tb[2]
			end
		else
			return false
		end
	else
		return false
	end
end


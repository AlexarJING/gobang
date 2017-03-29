-------------不要修改这部分--------------------------
require "love.math"
local map = {}
for i = 1, 15 do
	local gridChannel = love.thread.getChannel("grid"..i)
	map[i] = gridChannel:pop()
end
local colorChannel = love.thread.getChannel("color")
local result = love.thread.getChannel("result")
local lastPlayedChannel = love.thread.getChannel("lastPlayed")
local playerColor = colorChannel:pop()
local lastPlayed = lastPlayedChannel:pop()
--[[ 案例，已知量 map地图，color你操控的颜色，对方最后落子，lastPlayed,
应返回结果x,y并 result:push()来返回结果同时return]]

--------------下面部分自己修改------------------------
local function getLineValue(target,targetColor,x,y,dx,dy)
	local multiply = 1
	local value = 0
	for i = 0,4 do
		local testColor = target[x+dx*i] and target[x+dx*i][y+dy*i]
		if testColor == targetColor then
			multiply = multiply + 1 
			value = value + 10^(multiply) + 1 - math.abs(x-8)/30 - math.abs(y-8)/30
		elseif testColor == 0 then
			multiply = 1
		else
			return 0
		end
	end
	return value
end

local function tryMap(kx,ky)
	local new = {}
	for x = 1,15 do
		new[x] = {}
		for y = 1,15 do
			new[x][y] = map[x][y]
		end
	end
	new[kx][ky] = playerColor
	return new
end

local function getMapValue(tx,ty)
	local target = tryMap(tx,ty)
	local mapValue = 0
	for x = 1, 15 do
		for y = 1, 15 do
			local proValue = 
				getLineValue(target,playerColor,x,y,1,1) +
				getLineValue(target,playerColor,x,y,1,0) +
				getLineValue(target,playerColor,x,y,0,1) +
				getLineValue(target,playerColor,x,y,-1,1) 
			local negValue = 
				getLineValue(target,-playerColor,x,y,1,1) +
				getLineValue(target,-playerColor,x,y,1,0) +
				getLineValue(target,-playerColor,x,y,0,1) +
				getLineValue(target,-playerColor,x,y,-1,1)

			mapValue = mapValue + proValue - 9*negValue
		end
	end
	return mapValue
end

local function testAll()
	local all = {}
	for x = 1,15 do
		for y = 1,15 do
			if map[x][y] == 0 then
				local try = {
					x = x,
					y = y,
					result = getMapValue(x,y)
				}
				table.insert(all,try)
			end
		end
	end
	table.sort(all,function(a,b) return a.result>b.result end)
	result:push(all[1].x)
	result:push(all[1].y)
end

testAll()
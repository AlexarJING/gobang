require "love.math"
local map = {}
for i = 1, 15 do
	local gridChannel = love.thread.getChannel("grid"..i)
	map[i] = gridChannel:pop()
end
local colorChannel = love.thread.getChannel("color")
local result = love.thread.getChannel("result")
local lastPlayedChannel = love.thread.getChannel("lastPlayed")
local color = colorChannel:pop()
local lastPlayed = lastPlayedChannel:pop()
--[[ 案例，已知量 map地图，color你操控的颜色，对方最后落子，lastPlayed,
应返回结果x,y并 result:push()来返回结果同时return]]
while true do
	local x = love.math.random(1,15)
	local y = love.math.random(1,15)
	if map[x][y] == 0 then
		result:push(x)
		result:push(y)
		return
	end
end

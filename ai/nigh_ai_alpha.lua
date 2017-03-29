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
应返回结果x,y并 result:push()来返回结果同时return
black: -1
white: 1
]]
local debug=false
--------------下面部分自己修改------------------------

local flag = playerColor
local t_map={}

local defenceHotMap={}
local attackHotMap={}
local function initMap()
	-- t_map = table.clone(map)
	t_map = map
	for x = 1,15 do
		defenceHotMap[x]={}
		attackHotMap[x]={}
		for y = 1,15 do
			defenceHotMap[x][y]=0
			attackHotMap[x][y]=0
		end
	end
end

local function isPosValid(x,y)
	if x>0 and y>0 and x<=15 and y<=15 then
		return true
	else
		return false
	end
end
-- local function getLength()
-- flag:	black:-1  white:1
local function getScore( x,y,flag )
	local _x0,_y0,_x1,_y1=x,y,x,y
	local score=0

	-- tlrb
	while isPosValid(_x0-1,_y0-1) and t_map[_x0-1][_y0-1]==flag do _x0,_y0=_x0-1,_y0-1 end
	while isPosValid(_x1+1,_y1+1) and t_map[_x1+1][_y1+1]==flag do _x1,_y1=_x1+1,_y1+1 end
	length = _x1-_x0+1
	if length<5 then
		_=0
		if isPosValid(_x0-1,_y0-1) and t_map[_x0-1][_y0-1]==0 then _=math.pow(length,3) end
		if isPosValid(_x1+1,_y1+1) and t_map[_x1+1][_y1+1]==0 then if _>0 then _=_*4 else _=math.pow(length,3) end end
	else
		_ = 1024
	end
	score = score+_

	-- trbl
	_x0,_y0,_x1,_y1=x,y,x,y
	while isPosValid(_x0-1,_y0+1) and t_map[_x0-1][_y0+1]==flag do _x0,_y0=_x0-1,_y0+1 end
	while isPosValid(_x1+1,_y1-1) and t_map[_x1+1][_y1-1]==flag do _x1,_y1=_x1+1,_y1-1 end
	length = _x1-_x0+1
	if length<5 then
		_=0
		if isPosValid(_x0-1,_y0+1) and t_map[_x0-1][_y0+1]==0 then _=math.pow(length,3) end
		if isPosValid(_x1+1,_y1-1) and t_map[_x1+1][_y1-1]==0 then if _>0 then _=_*4 else _=math.pow(length,3) end end
	else
		_ = 1024
	end
	score = score+_

	-- lr
	_x0,_y0,_x1,_y1=x,y,x,y
	while isPosValid(_x0-1,_y0) and t_map[_x0-1][_y0]==flag do _x0,_y0=_x0-1,_y0 end
	while isPosValid(_x1+1,_y1) and t_map[_x1+1][_y1]==flag do _x1,_y1=_x1+1,_y1 end
	length = _x1-_x0+1
	if length<5 then
		_=0
		if isPosValid(_x0-1,_y0) and t_map[_x0-1][_y0]==0 then _=math.pow(length,3) end 
		if isPosValid(_x1+1,_y1) and t_map[_x1+1][_y1]==0 then if _>0 then _=_*4 else _=math.pow(length,3) end end
	else
		_ = 1024
	end
	score = score+_

	-- tb
	_x0,_y0,_x1,_y1=x,y,x,y
	while isPosValid(_x0,_y0-1) and t_map[_x0][_y0-1]==flag do _x0,_y0=_x0,_y0-1 end
	while isPosValid(_x1,_y1+1) and t_map[_x1][_y1+1]==flag do _x1,_y1=_x1,_y1+1 end
	length = _y1-_y0+1
	if length<5 then
		_=0
		if isPosValid(_x0,_y0-1) and t_map[_x0][_y0-1]==0 then _=math.pow(length,3) end
		if isPosValid(_x1,_y1+1) and t_map[_x1][_y1+1]==0 then if _>0 then _=_*4 else _=math.pow(length,3) end end
	else
		_ = 1024
	end
	score = score+_
	return score
end

local function getHotMap( )
	for x = 1,15 do
		for y = 1,15 do
			if t_map[x][y] == 0 then
				t_map[x][y] = -flag
				defenceHotMap[x][y] = getScore(x,y,-flag)
				t_map[x][y] = flag
				attackHotMap[x][y] = getScore(x,y,flag)
				t_map[x][y] = 0
			end
		end
	end
end


local function getMaxMap(map)
	local max = {score=0}
	for x = 1,15 do
		for y = 1,15 do
			if map[x][y]>max.score then
				max = {x=x,y=y,score=map[x][y]}
			end
		end
	end
	if not max.x then max.x,max.y = love.math.random(4,11),love.math.random(4,11) end
	return max
end

local defenceMax={}
local attackMax={}
local function getMaxScore( )
	defenceMax = getMaxMap(defenceHotMap)
	attackMax = getMaxMap(attackHotMap)
	if debug then
		print("defenceMax=",defenceMax.score,"x=",defenceMax.x,"y=",defenceMax.y)
		print("attackMax=",attackMax.score,"x=",attackMax.x,"y=",attackMax.y)
	end
end

local function step()
	initMap()
	getHotMap()
	getMaxScore()
	if attackMax.score>1000 or
		((attackMax.score>60 or defenceMax.score<60) and attackMax.score>=1.4*defenceMax.score) then
		if debug then print("attack",attackMax.x,attackMax.y) end
		result:push({x=attackMax.x,y=attackMax.y})
	else
		if debug then print("defence",defenceMax.x,defenceMax.y) end
		result:push({x=defenceMax.x,y=defenceMax.y})
	end
end

step()

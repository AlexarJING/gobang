love.window.setMode(600,600)
local game = {}
game.turnLimit = 10
game.boardX = 20
game.boardY = 20
game.gridSize = 40
function game.newPlayer(aiPath,color)
	local player = {
		timer = 0,
		steps = {},
		color = color,
		aiPath = aiPath
	}
	return player
end

function game.initPlayer(p1,p2)
	game.player1 = game.newPlayer(p1)
	game.player2 = game.newPlayer(p2)
end

function game.clearBoard()
	local grid = {}
	for x = 1, 15 do
		grid[x] = {}
		for y = 1, 15 do
			grid[x][y] = 0 -- -1 黑 0 空 1 白
		end
	end
	game.board = grid
end

function game.chooseColor()
	local rnd = love.math.random()
	if rnd<0.5 then
		game.black = game.player1
		game.player1.color = -1
		game.player2.color = 1
	else
		game.black = game.player2
		game.player2.color = -1
		game.player1.color = 1
	end

	game.currentPlayer = game.black
end

function game.set(x,y)
	if game.board[x][y] == 0 then
		game.board[x][y] = game.currentPlayer.color
	else
		error("wrong position")
	end
end



function game.lineCount(x,y,dx,dy)
	local color = game.board[x][y]
	if color == 0 then return end
	local count = 0
	for i = 0, 10 do
		if game.board[x+dx*i] 
			and game.board[x+dx*i][y+dy*i] 
			and color == game.board[x+dx*i][y+dy*i] then
			count = count+1
		else
			return count
		end
	end

	return count>=5
end

function game.checkWin()
	for x = 1, 15 do
		for y = 1, 15 do
			if game.lineCount(x,y,-1,-1) or
				game.lineCount(x,y,-1,0) or
				game.lineCount(x,y,-1,1) or
				game.lineCount(x,y,0,-1) or
				game.lineCount(x,y,0,1) or
				game.lineCount(x,y,1,-1) or
				game.lineCount(x,y,1,0) or
				game.lineCount(x,y,1,1) then
				print("player ".. (game.currentPlayer.color == 1 and "white" or "black") .." wins")
				return true
			end
		end
	end
end

function game.turnEnd()
	game.turnTimer = game.turnLimit
	game.currentPlayer = game.currentPlayer == game.player1 and game.player2 or game.player1
	if game.currentPlayer.aiPath then
		game.currentAI =  love.thread.newThread(game.currentPlayer.aiPath)
		game.currentAI:start()
		for i = 1,15 do
			local gridChannel = love.thread.getChannel("grid"..i)
			gridChannel:supply(game.board[i])
		end
		local colorChannel = love.thread.getChannel("color")
	end
	--game.checkWin()
end

function game.process(dt)
	game.turnTimer = game.turnTimer - dt
	if game.turnTimer<0 then
		game.turnEnd()
	else
		--[[
		local x,y = game.currentPlayer.ai.calculate(game.board)
		if x and game.set(x,y) then	
			game.turnEnd()
		end]]
	end
	game.currentPlayer.timer = game.currentPlayer.timer + dt
end

function game.initGame(p1path,p2path)
	game.turnTimer = game.turnLimit
	game.clearBoard()
	game.initPlayer(p1path,p2path)
	game.chooseColor()
end

function game.draw()
	love.graphics.setColor(0,0,255)
	for i = 1,15 do
		love.graphics.line(game.boardX,game.boardY+game.gridSize*(i-1),
						game.boardX+game.gridSize*14,game.boardY+game.gridSize*(i-1))
		love.graphics.line(game.boardX+game.gridSize*(i-1),game.boardY,
						game.boardX+game.gridSize*(i-1),game.boardY+game.gridSize*14)
	end
	for x = 1,15 do
		for y = 1,15 do
			if game.board[x][y] == -1 then
				love.graphics.setColor(0,0,0)
				love.graphics.circle("fill",game.boardY+game.gridSize*(x-1),game.boardY+game.gridSize*(y-1),game.gridSize/2)
			elseif game.board[x][y] == 1 then
				love.graphics.setColor(255,255,255)
				love.graphics.circle("fill",game.boardY+game.gridSize*(x-1),game.boardY+game.gridSize*(y-1),game.gridSize/2)
			end
		end
	end

	love.graphics.setColor(255,0,0)
	love.graphics.circle("line",game.mx,game.my,game.gridSize/2)
	local c = game.currentPlayer.color == -1 and 0 or 255
	love.graphics.setColor(c,c,c,100)
	love.graphics.circle("fill",game.mx,game.my,game.gridSize/2)
end

function love.load()
	love.graphics.setBackgroundColor(100,100,100)
	game.initGame("player1.lua")
end

function love.update(dt)
	game.process(dt)
	local mx,my = love.mouse.getPosition()
	
	game.gx = math.ceil((mx-game.boardX+ game.gridSize/2)/game.gridSize)
	game.gy = math.ceil((my-game.boardY+ game.gridSize/2)/game.gridSize)

	game.mx = game.gx*game.gridSize - game.gridSize/2
	game.my = game.gy*game.gridSize - game.gridSize/2
end

function love.draw()
	game.draw()
end

function love.mousepressed()
	if game.board[game.gx][game.gy] == 0 then
		game.board[game.gx][game.gy] = game.currentPlayer.color
		game.turnEnd()
	end
end
io.stdout:setvbuf("no")
local suit = require "suit"
love.window.setMode(600,600)
love.window.setTitle("五子棋")
local game = {}
game.turnLimit = 20
game.boardX = 20
game.boardY = 20
game.gridSize = 40
function game.newPlayer(aiPath,color)
	if aiPath == "manual" then aiPath = nil end
	local player = {
		timer = 0,
		steps = {},
		color = color,
		aiPath = aiPath and "ai/"..aiPath,
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
		game.white = game.player2
		game.player1.color = -1
		game.player2.color = 1
	else
		game.black = game.player2
		game.white = game.player1
		game.player2.color = -1
		game.player1.color = 1
	end

	game.currentPlayer = game.black
end

function game.set(x,y)
	if game.board[x][y] == 0 then
		if game.checkForbidden(x,y) then
			love.window.showMessageBox("禁手", "黑方禁止双活三", "error")
			print("forbidden")
			return
		else
			game.board[x][y] = game.currentPlayer.color
			game.lastPlayedX = x
			game.lastPlayedY = y
			table.insert(game.step, {
				x = x,
				y = y,
				color = game.currentPlayer.color
				})
		end		
	else
		print("wrong position")
	end
	
	return true
end



function game.lineCount(x,y,dx,dy)
	local color = game.board[x][y]
	if color == 0 then return 0 end
	local count = 0
	for i = 0, 4 do
		if game.board[x+dx*i] 
			and game.board[x+dx*i][y+dy*i] 
			and color == game.board[x+dx*i][y+dy*i] then
			count = count+1
		else
			return count
		end
	end
	return count
end



function game.checkWin()
	for x = 1, 15 do
		for y = 1, 15 do
			if game.lineCount(x,y,1,1)>=5 or
				game.lineCount(x,y,1,0)>=5 or
				game.lineCount(x,y,0,1)>=5 or 
				game.lineCount(x,y,-1,1)>=5 then
				return true
			end
		end
	end
end

local liveThree = {false,true,true,true,false}

function game.match(x,y,dx,dy,color,pattern)
	if dx == 0 and dy == 0 then
		return game.match(x,y,1,0,color,pattern) 
			or game.match(x,y,1,1,color,pattern) 
			or game.match(x,y,0,1,color,pattern) 
	end
	for i = -2,2 do
		local targetColor = pattern[i+3] and color or 0
		if game.board[x+dx*i] and game.board[x+dx*i][y+dy*i] 
			and game.board[x+dx*i][y+dy*i] == targetColor then
			--match
		else
			return
		end
	end
	return true
end

function game.liveThree(x,y)
	local color = game.currentPlayer.color
	local count = 0
	for dx = -1, 1 do
		for dy = -1,1 do			
			if game.match(x+dx,y+dy,dx,dy,color,liveThree) then
				count = count + 1
			end
			if count == 2 then
				return true
			end
		end
	end
end

function game.checkForbidden(tx,ty)
	if game.currentPlayer == game.black then
		if game.liveThree(tx,ty) then
			return true
		end
	end
end

function game.initAI()
	game.currentPlayer.ai =  love.thread.newThread(game.currentPlayer.aiPath)
	game.currentPlayer.ai:start()
	for i = 1,15 do
		local gridChannel = love.thread.getChannel("grid"..i)
		gridChannel:push(game.board[i])
	end
	local colorChannel = love.thread.getChannel("color")
	colorChannel:push(game.currentPlayer.color)
	game.result = love.thread.getChannel("result")
	local lastPlayed = love.thread.getChannel("lastPlayed")
	lastPlayed:push({game.lastPlayedX,game.lastPlayedY})
end

function game.turnEnd()
	game.turnTimer = game.turnLimit
	game.currentPlayer = game.currentPlayer == game.player1 and game.player2 or game.player1
	if game.currentPlayer.aiPath then	
		game.initAI()
	end
	if game.checkWin() then game.gameover() end
end

function game.process(dt)
	game.turnTimer = game.turnTimer - dt
	if game.turnTimer<0 then
		game.turnEnd()
	else
		if game.currentPlayer.aiPath then
			if game.currentPlayer.ai then
				local x = game.result:peek()
				if x and game.set(game.result:pop(),game.result:pop()) then
					game.turnEnd()
				end
			else
				game.initAI()
			end		
		end
	end
	game.currentPlayer.timer = game.currentPlayer.timer + dt
end

function game.initGame(p1path,p2path)
	love.graphics.setBackgroundColor(100,100,100)
	game.step = {}
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
	if game.lastPlayedX then
		love.graphics.setColor(0,255,0,100)
		love.graphics.rectangle("line",
			game.boardY+game.gridSize*(game.lastPlayedX-1)-game.gridSize/2,
			game.boardY+game.gridSize*(game.lastPlayedY-1)-game.gridSize/2,
			game.gridSize,game.gridSize)
	end

	for i, step in ipairs(game.step) do
		local color = step.color == -1 and 255 or 0
		love.graphics.setColor(color,color,color,255)
		love.graphics.print(i, 
			game.boardY+game.gridSize*(step.x-1)-5,
			game.boardY+game.gridSize*(step.y-1)-5)
	end
end

function game.gameover()
	local title = "游戏结束"
	local message = "player ".. (game.currentPlayer.color == -1 and "white" or "black") .." wins"
	local buttons = {"重新开始", "退出", escapebutton = 2}
	local pressedbutton = love.window.showMessageBox(title, message, buttons)
	if pressedbutton == 1 then
	    game.initGame("player1.lua")
	elseif pressedbutton == 2 then
	    love.event.quit()
	end
end



function love.load()
	game.aiLibrary ={}
	game.aiLibrary[0] = "manual"
	for _,name in ipairs(love.filesystem.getDirectoryItems("ai")) do
        table.insert(game.aiLibrary,name)
    end
    game.p1Ctrl = game.aiLibrary[0]
    game.p2Ctrl = game.aiLibrary[0]
end

function game.ui()
	suit.Label("player1:"..game.p1Ctrl,50,50,200,30)
	for i = 0, #game.aiLibrary do
		local aiFile = suit.Button(game.aiLibrary[i],{id = "p1"..i},100,100+50*i,100,30)
		if aiFile.hit then
			game.p1Ctrl = game.aiLibrary[i]
		end
	end

	suit.Label("player2:"..game.p2Ctrl,350,50,200,30)
	for i = 0, #game.aiLibrary do
		local aiFile = suit.Button(game.aiLibrary[i],{id = "p2"..i},400,100+50*i,100,30)
		if aiFile.hit then
			game.p2Ctrl = game.aiLibrary[i]
		end
	end

	local startButton = suit.Button("start",250,500,100,30)
	if startButton.hit then
		game.initGame(game.p1Ctrl,game.p2Ctrl)
		game.start = true
	end
end


function love.update(dt)
	local mx,my = love.mouse.getPosition()	
	game.gx = math.ceil((mx-game.boardX+ game.gridSize/2)/game.gridSize)
	game.gy = math.ceil((my-game.boardY+ game.gridSize/2)/game.gridSize)

	game.mx = game.gx*game.gridSize - game.gridSize/2
	game.my = game.gy*game.gridSize - game.gridSize/2
	if game.start then
		game.process(dt)
		local title = string.format("五子棋，黑方：%s, 白方：%s, 落子倒计时：%d",
			game.black.aiPath or "玩家", game.white.aiPath or "玩家", game.turnTimer)
		love.window.setTitle(title)
	else
		game.ui()
	end
end

function love.draw()
	if game.start then
		game.draw()
	end
	suit.draw()
end

function love.mousepressed()
	if not game.start then return end
	if game.board[game.gx][game.gy] == 0 and not game.currentPlayer.ai then
		if game.set(game.gx,game.gy) then
			game.turnEnd()
		end
	end
end

function love.textinput(t)
    suit.textinput(t)  
end

function love.keypressed(key)
    suit.keypressed(key)    
end
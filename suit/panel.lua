-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	opt.id = opt.id or text
	opt.font = opt.font or love.graphics.getFont()

	w = w or 100
	h = h or 100
	core:registerDraw(opt.draw or core.theme.Panel, opt, x,y,w,h)

	return {
		id = opt.id,
	}
end

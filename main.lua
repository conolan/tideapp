
display.setStatusBar( display.HiddenStatusBar )

	   
local storyboard = require "storyboard"
--storyboard.isDebug=true

storyboard.options = {
						effect = "fromRight",
						time = 400
					 }

screenLeft=display.screenOriginX
screenRight=display.contentWidth-display.screenOriginX
screenTop=display.screenOriginY
screenBot=display.contentHeight-display.screenOriginY
screenWidth=display.contentWidth-display.screenOriginX*2
screenHeight=display.contentHeight -display.screenOriginY*2
_G.isResume=false

m_position={}
m_position.x=16
m_position.y=208
midTide=2
storyboard.gotoScene( "tide", storyboard.options)

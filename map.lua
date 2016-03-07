local storyboard = require( "storyboard" )
storyboard.purgeOnSceneChange = true
local scene = storyboard.newScene()
local widget = require( "widget" )
local http = require("socket.http")
local ltn12 = require("ltn12")

-- simple screen with buttons to change the tide location
-- also change the scale (30 or 40) which effects the sacle of the tide curve.
-- Writes the resulting data to places.txt which is read when app starts up after suspend
		
function scene:createScene( event )
	local screenGroup = self.view
	local rect = display.newRect(display.screenOriginX, display.screenOriginY, display.contentWidth-display.screenOriginX*2, display.contentHeight -display.screenOriginY*2)
	rect:setFillColor(1,1,1)
	rect.anchorX = 0
	rect.anchorY = 0
	screenGroup:insert(rect)
	
	local myImage = display.newImageRect("images/header.png", 320,96)
	myImage.anchorX = 0
	myImage.anchorY = 0
	myImage.x = 0
	myImage.y =display.screenOriginY/2
	screenGroup:insert(myImage)	
	
	
	local homeButton = widget.newButton{
			top=display.contentHeight-100-display.screenOriginY,
			left = 20,
			width=80,
			height=70,
			defaultFile = "images/tide.png",
			
			onRelease=function(event)
							storyboard.gotoScene( "tide", storyboard.options)
							transition.to(event.target,{time=50,alpha=1})
							return true
			end,
			onPress=function(event)
							
							transition.to(event.target,{time=50,alpha=0.5})
							return true
			end
		}
	screenGroup:insert(homeButton)
	
	local places={"dublin","cobh","galway","belfast"}

	local scales={40,40,30,40}
	for i=1,4 do
	local placeButton = widget.newButton{
			top=display.contentHeight-380-display.screenOriginY+((i-1)*70),
			left = 20,
			width=280,
			height=60,
			label=string.upper(places[i]),
			labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
			fontSize=36,
			defaultFile = "images/blankbutton.png",
			
			onRelease=function(event)
				theCity=places[i]
				placeSave(places[i]..","..scales[i])
				m_scale=scales[i]
				storyboard.gotoScene( "tide", storyboard.options)
				transition.to(event.target,{time=50,alpha=1})
				return true
			end,
			onPress=function(event)
							
							transition.to(event.target,{time=50,alpha=0.5})
							return true
			end
		}
	screenGroup:insert(placeButton)
	end
	
end

function placeSave(thePlace)
   local path = system.pathForFile( "place.txt", system.DocumentsDirectory )
   local file = io.open(path, "w")
   if ( file ) then
      local contents = tostring( thePlace )
      file:write( contents )
      io.close( file )
      return true
   else
      print( "Error: could not read ", place.txt, "." )
      return false
   end
end


function scene:enterScene( event )

end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )

end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
	
end

---------------------------------------------------------------------------------
-- END OF IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

return scene
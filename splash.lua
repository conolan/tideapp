local storyboard = require( "storyboard" )
storyboard.purgeOnSceneChange = true
local scene = storyboard.newScene()

local widget = require( "widget" )
local http = require("socket.http")
local ltn12 = require("ltn12")
local iap = require("plugin.iap_badger")

-- used for advert for another app and inapp purchase
-- Also allows sending of sms and email from app with tide data

local catalogue = {
    products = {    

        fullYear = {
                --A list of product names or identifiers specific to apple's App Store or Google Play.
                productNames = { apple="xxxxxxxxxx", google="xxxxxxxxxxxx"},
                --The product type
                productType = "non-consumable",
                --This function is called when a purchase is complete.
                onPurchase=function() iap.setInventoryValue("unlock", true) end,
        }
    },

    --Information about how to handle the inventory item
    inventoryItems = {
        unlock = { productType="non-consumable" }
    }
}

local iapOptions = {
    --The catalogue generated above
    catalogue=catalogue,
    --The filename in which to save the inventory
    filename="inventory.txt",        
}

--Initialise IAP badger
iap.init(iapOptions)

function sendText()
	local options={}
	local tideSms=""
	if tideWeek[1][5]~=nil then
		for i=2,5 do
			if tonumber(tideWeek[1][i])>midTide then tideSms=tideSms.." High "..timeWeek[1][i] end
			if tonumber(tideWeek[1][i])<midTide then tideSms=tideSms.." Low "..timeWeek[1][i] end
		end
	else
		for i=2,4 do
			if tonumber(tideWeek[1][i])>midTide then tideSms=tideSms.." High "..timeWeek[1][i] end
			if tonumber(tideWeek[1][i])<midTide then tideSms=tideSms.." Low "..timeWeek[1][i] end
		end
	end
	options =
		{	
			body = "I got a great Irish Tide App. Todays tides in "..theCity.. " are: "..tideSms..": Search for Irish Tides 2016' in your app store"
			
		}
	native.showPopup("sms", options)
end

local function onComplete( event )
        if "clicked" == event.action then
                local i = event.index
                if 1 == i then
                        -- Do nothing; dialog will simply dismiss
                elseif 2 == i then
                        sendText()
                end
        end
end
		
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
	
	disText = display.newText("Download FREE DUBCAMS App", 10, 200, 300,100, native.systemFont, 20)

	disText:setTextColor(1,153/254,0)
	disText.anchorX = 0
	disText.anchorY = 0
	screenGroup:insert(disText)
	
	local function doAd(touch)	
		if touch.phase == "ended" then 
			local environment = system.getInfo( "platformName" )
			if environment=="Android" then
				system.openURL( "https://play.google.com/store/apps/details?id=com.apptoonz.conor.dublintrafficcam&hl=en")
			else
				system.openURL( "https://itunes.apple.com/ie/app/dubcams/id950605227?mt=8")
			end
		end
	end
	
	local dubcam = display.newImageRect("images/dubcam.png", 300,85)
	dubcam.anchorX = 0
	dubcam.anchorY = 0
	dubcam.x, dubcam.y = 10,100
	dubcam:addEventListener( "touch", doAd )
	screenGroup:insert(dubcam)
	
	if not(isPaid) then
		local iap = display.newImageRect("images/iap.png", 220,70)
		iap.anchorX = 0
		iap.anchorY = 0
		iap.x, iap.y = 50,230
		iap:addEventListener( "touch", purchaseItem )
		screenGroup:insert(iap)
		
		local options=
		{
			--parent = textGroup,
			text = "Purchase access to the entire years tides",     
			x = 10,
			y = 300,
			width = 300,     --required for multi-line and alignment
			font = native.systemFontBold,   
			fontSize = 24,
			align = "center"  --new alignment parameter
		}
				
		purText = display.newText(options)

		purText:setFillColor(94/256,29/254,180/256)
		purText.anchorX = 0
		purText.anchorY = 0
		screenGroup:insert(purText)
		
		local options=
		{
			--parent = textGroup,
			text = "Restore Purchase",     
			x = 10,
			y = 360,
			width=300,
			font = native.systemFontBold,   
			fontSize = 24,
			align = "center"  --new alignment parameter
		}
				
		resText = display.newText(options)

		resText:setFillColor(.2,.2,.2)
		resText.anchorX = 0
		resText.anchorY = 0
		resText:addEventListener( "touch", restoreItem )
		screenGroup:insert(resText)
	else
		dubcam.y=dubcam.y+60
		disText.y=disText.y+60
	end
		
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
	
	local txtButton = widget.newButton{
		top=display.contentHeight-100-display.screenOriginY,
		left = 120,
		width=80,
		height=70,
		defaultFile = "images/text.png",
		
		onRelease=function(event)
						local alert = native.showAlert( "Send Text", "Text today's tides to a friend", 
                                        { "No", "Yes" }, onComplete )
						transition.to(event.target,{time=50,alpha=1})
						return true
		end,
		onPress=function(event)
						
						transition.to(event.target,{time=50,alpha=0.5})
						return true
		end
	}
	screenGroup:insert(txtButton)
	
	local emailButton = widget.newButton{
			top=display.contentHeight-100-display.screenOriginY,
			left = 220,
			width=80,
			height=70,
			defaultFile = "images/email.png",
			
			onRelease=function(event)
				local options =
				{
					subject = "Irish Tides 2016",
					body = "Found this Irish Tides app"
				}
				native.showPopup("mail", options)	
				transition.to(event.target,{time=50,alpha=1})
				return true
			end,
			onPress=function(event)
							
							transition.to(event.target,{time=50,alpha=0.5})
							return true
			end
		}
	screenGroup:insert(emailButton)	
		
	disText2 = display.newText("       Return        Send text       Send email", 10, display.contentHeight-120-display.screenOriginY, 300,100, native.systemFont, 16)
	disText2:setTextColor(0,0,0)
	disText2.anchorX = 0
	disText2.anchorY = 0
	screenGroup:insert(disText2)
	
end

local function savePurchase()
	local filename = "myPurchase.txt"
	local path = system.pathForFile( filename, system.DocumentsDirectory )
	local file = io.open(path, "a")
	if ( file ) then
		file:write( "isPaid" )
		io.close( file )
		return true
	else
		print( "Error: could not read ", filename, "." )
		return false
	end
end
 

local function purchaseListener(product )
    isPaid=true
	iap.addToInventory("unlock")
	savePurchase()
    native.showAlert("Purchase complete", "Your unlock purchase was successful.")
	storyboard.gotoScene( "tide", storyboard.options)
end

local function restoreListener()
	native.showAlert("Restore", "Your items are being restored", {"Okay"})
end

local function timeoutListener()
	native.showAlert("Restore", "Unable to restore purchase", {"Okay"})
end

function purchaseItem(event)
--Tell IAP badger to initiate a purchase
	iap.purchase("fullYear", purchaseListener)
end

function restoreItem(event)
	iap.restore( false, restoreListener, timeoutListener, 3000 )
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
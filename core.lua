--[[
MIT License

Copyright (c) 2023 Graham Ranson of Glitch Games Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

--- Class creation.
local Device = {}

-- Localised functions.
local getInfo = system.getInfo
local sub = string.sub
local open = io.open
local close = io.close
local pathForFile = system.pathForFile

-- Localised values.

-- Static values.
local Platform = {}
Platform.OSX = "macos"
Platform.Windows = "win32"
Platform.Linux = "linux"
Platform.Android = "android"
Platform.IOS = "ios"
Platform.AppleTV = "tvos"
Platform.WindowsPhone = "winphone"
Platform.Web = "html5"
Platform.Switch = "nx64"

function Device:new( params )
	
	-- Get the params, if any
	self._params = params or {}

	return self

end

--- Gets the simple tag for each platform.
-- @return The name of the platform. Either 'macos', 'win32', 'android', 'ios', 'tvos', 'winphone', 'nx64, or 'html5'.
function Device:getPlatform()
	return getInfo( "platform" )
end

--- Gets the environment name.
-- @return The name of the environment. Either 'device' or 'simulator'.
function Device:getEnvironment()
	return getInfo( "environment" )
end

--- Gets the architecture.
-- @return The architecture.
function Device:getArchitecture()
	return getInfo( "architectureInfo" )
end

--- Gets the model name.
-- @return The name of the model.
function Device:getModel()
	return getInfo( "model" )
end

--- Checks if the game is currently running on a physical device.
-- @return True if it is, false otherwise.
function Device:isReal()
	return self:getEnvironment() == "device"
end

--- Checks if the game is currently running in the simulator.
-- @return True if it is, false otherwise.
function Device:isSimulator()
	return self:getEnvironment() == "simulator"
end

--- Checks if the game is currently running on a TV based console.
-- @return True if it is, false otherwise.
function Device:isTV()
	if self:isAppleTV() or self:isAmazonTV() or self:isAndroidTV() then
		return true
	end
end

--- Checks if the game is currently running on an AppleTV.
-- @return True if it is, false otherwise.
function Device:isAppleTV()
	return self:getPlatform() == Platform.AppleTV
end

--- Checks if the game is currently running on an Amazon FireTV.
-- @return True if it is, false otherwise.
function Device:isAmazonTV()
	return self:getModel() == "AFTB"
end

--- Checks if the game is currently running on an Android TV.
-- @return True if it is, false otherwise.
function Device:isAndroidTV()

	-- Is this the first time we've checked
	if self._isAndroidTV == nil then

		-- Set it to false by default
		self._isAndroidTV = false

		-- Work out of this is an AndroidTV device
		if self._launchArguments then

			local categories = self._launchArguments[ "androidIntent" ][ "categories" ]
			for i = 1, #categories, 1 do
				if categories[ i ] == "android.intent.category.LEANBACK_LAUNCHER" then
					self._isAndroidTV = true
					break
				end
			end

		end

	end

	return self:isReal() and self._isAndroidTV

end

--- Checks if the game is currently running on an iOS device.
-- @return True if it is, false otherwise.
function Device:isIOS()
	return self:getPlatform() == Platform.IOS
end

--- Checks if the game is currently running on an Android device.
-- @return True if it is, false otherwise.
function Device:isAndroid()
	return string.lower( self:getPlatform() ) == Platform.Android
end

--- Checks if the game is currently running on an OSX machine.
-- @return True if it is, false otherwise.
function Device:isOSX()
	return self:getPlatform() == Platform.OSX
end

--- Checks if the game is currently running on a Windows machine.
-- @return True if it is, false otherwise.
function Device:isWindows()
	return self:getPlatform() == Platform.Windows
end

--- Checks if the game is currently running on a Linux machine.
-- @return True if it is, false otherwise.
function Device:isLinux()
	return self:getPlatform() == Platform.Linux
end

--- Checks if the game is currently running on an Amazon Kindle device.
-- @return True if it is, false otherwise.
function Device:isKindle()
	return ( self:getModel() == "Kindle Fire" or self:getModel() == "WFJWI" or sub( self:getModel(), 1, 2 ) == "KF" )
end

--- Checks if the game is currently running on a desktop.
-- @return True if it is, false otherwise.
function Device:isDesktop()
	return self:getModel() == "Desktop" or self:isOSX() or self:isWindows() or self:isLinux()
end

--- Checks if the game is currently running on a mobile device.
-- @return True if it is, false otherwise.
function Device:isMobile()
	return self:isIOS() or self:isAndroid()
end

--- Checks if the game is currently running on an iPad.
-- @return True if it is, false otherwise.
function Device:isIPad()
	return self:getModel() == "iPad"
end

--- Checks if the game is currently running on a Nintendo Switch.
-- @return True if it is, false otherwise.
function Device:isNintendoSwitch()
	return self:getPlatform() == Platform.Switch
end

--- Checks if the game is currently running on a Console.
-- @return True if it is, false otherwise.
function Device:isConsole()
	return self:isNintendoSwitch()
end

--- Checks if the game is currently running from the Steam store.
-- @return True if it is, false otherwise.
function Device:isSteam()

	-- Get the dir separator for this platform
	local dirSeperator = package.config:sub( 1, 1 )

	-- Get the root path
	local path = pathForFile()

	--- Removes the last directory from a path.
	-- @param path The current path.
	-- @return The new path.
	local moveUpOneDir = function( path )

		-- Remove everything after the last forward or back slash so and return the result
		return path:gsub( "(.*)%" .. dirSeperator .. ".*$", "%1" )

	end

	-- Are we on OSX?
	if self:isOSX() then

		-- Remove 'Corona' from the path
		path = moveUpOneDir( path )

		-- Remove 'Resources' from the path
		path = moveUpOneDir( path )

		-- Append the Plugins folder to the path
		path = path .. dirSeperator .. "Plugins"

		-- Append the steam api dylib file to the end of the path
		path = path .. dirSeperator .. "libsteam_api.dylib"

	-- Are we on Windows?
	elseif self:isWindows() then

		-- Remove 'Resources' from the path
		path = moveUpOneDir( path )

		-- Append the steam api dll file to the end of the path
		path = path .. dirSeperator .. "steam_api.dll"

	-- Are we on Linux? Is anybody?
	elseif self:isLinux() then

	-- Otherwise we're on a non-desktop device
	else

		-- So just quit early and return false
		return false

	end

	-- Try to open the file
	local file = open( path, "r" )

	-- Flag to state whether the file exists or not
	local exists = false

	-- Does it exist?
	if file then

		-- Then flag it
		exists = true

		-- And close out the file handler
		close( file )

		-- And nil it
		file = nil

	end

	-- And return the result
	return exists

end
--- Checks if the game is currently in a browser.
-- @return True if it is, false otherwise.
function Device:isWeb()
	return self:getPlatform() == Platform.Web or self:getEnvironment() == "browser"
end

--- Gets the name of the store that the app was built for.
-- @return The name of the store.
function Device:getTargetStore()
	return getInfo( "targetAppStore" )
end

--- Gets the Android API level.
-- @return The api level.
function Device:getAPILevel()
	return getInfo( "androidApiLevel" )
end

--- Checks if the hardware architecture matches OSX.
-- @return True if it does, false otherwise.
function Device:architectureIsOSX()
	local arch = self:getArchitecture()
	return arch == "i386" or arch == "x86_64" or arch == "ppc" or arch == "ppc64"
end

--- Checks if the hardware architecture matches Windows.
-- @return True if it does, false otherwise.
function Device:architectureIsWindows()
	local arch = self:getArchitecture()
	return arch == "x86" or arch == "x64" or arch == "IA64" or arch == "ARM"
end

--- Checks if the current GPU is known to be problematic with display.capture calls.
-- @return True if it is, false otherwise.
function Device:willGPUHaveIssuesWithCaptures()

	-- All the naughty GPUs
	local gpus =
	{
		"Radeon RX560",
		"Intel UHD Graphics 630",
		"Intel(R) UHD Graphics 630",
		"Nvidia GeForce GTX 750 Ti",
		"Nvidia GeForce GTX 965m",
		"Nvidia GeForce GTX 1060",
		"Nvidia GeForce GTX 1650",
		"Nvidia GeForce GTX 1650 with Max-Q Design",
		"Nvidia GeForce GTX 2060",
		"Nvidia GeForce RTX 2070 SUPER",
		"GeForce RTX 2080 Ti/PCIe/SSE2"
	}

	-- Get the renderer name
	local renderer = system.getInfo( "GL_RENDERER" )

	-- Loop through the GPUs
	for i = 1, #gpus, 1 do

		-- Does it match the current renderer?
		if gpus[ i ] == renderer then

			-- Return true as it's a naughty one
			return true

		end
		
	end

end

return Device

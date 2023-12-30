-- Reputation System, made by Wasied on dec2023
-- This file is used to load the reputation system.
-- Do not touch this file unless you know what you are doing.

Reputation = Reputation or {}

-- Some shortcuts
local function Load(f) include("reputation_system/"..f) end
local function Send(f) AddCSLuaFile("reputation_system/"..f) end
local function SendLoad(f) 
    if SERVER then Send(f) end 
    Load(f)
end

-- Load our files
SendLoad("config.lua")
SendLoad("constants.lua")

if SERVER then

    Load("server/sv_api.lua")
    Load("server/sv_functions.lua")
    Load("server/sv_hooks.lua")
    Load("server/sv_network.lua")

    Send("client/cl_functions.lua")
    Send("client/cl_menu.lua")
    Send("client/cl_hooks.lua")
    Send("client/cl_network.lua")

else

    Load("client/cl_functions.lua")
    Load("client/cl_menu.lua")
    Load("client/cl_hooks.lua")
    Load("client/cl_network.lua")

end
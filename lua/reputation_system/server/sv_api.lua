Reputation.API = {}

-- URL-encode a string
-- @param string sURL - The string to encode
function Reputation.API:URLEncode(sURL)

    assert(isstring(sURL), "sURL must be a string")

    return sURL:gsub("\n", "\r\n"):gsub("([^%w ])", function(sChar)
        return ("%%%02X"):format(sChar:byte())
    end):gsub(" ", "+")

end

-- Make a HTTP request to our API
-- @param string sEndpoint - The endpoint to request
-- @param table tData - The data to send
-- @param function fcCallback - The callback function
function Reputation.API:Request(sEndpoint, tData, fcCallback)

    assert(isstring(sEndpoint), "sEndpoint must be a string")
    assert(istable(tData), "tData must be a table")
    assert(isfunction(fcCallback), "fcCallback must be a function")

    local sFullURL = Reputation.Config.APIHost..sEndpoint

    if #tData > 0 then

        sFullURL = sFullURL.."?"

        for sKey, xValue in pairs(tData) do

            if sFullURL:sub(-1) ~= "?" then
                sFullURL = sFullURL.."&"
            end

            local sValue = istable(xValue) and util.TableToJSON(xValue) or tostring(xValue)
            sFullURL = ("%s%s=%s"):format(sFullURL, sKey, self:URLEncode(sValue))

        end

    end

    http.Fetch(sFullURL, function(sBody, iSize, tHeaders, iCode)

        if iCode ~= 200 then
            return fcCallback(false, "HTTP request failed with code "..iCode)
        end

        if sBody == "" then
            return fcCallback(true)
        else

            local tJSON = util.JSONToTable(sBody)

            if not istable(tJSON) then
                return fcCallback(false, "Invalid JSON response")
            end

            if tJSON.error then
                return fcCallback(false, tJSON.error)
            end

            return fcCallback(true, tJSON)

        end

    end, function(sError)

        return fcCallback(false, sError)

    end)

end

-- Get the current server ID from the API
function Reputation.API:FetchServerID(fcCallback)

    if not self.iServerID then

        self:Request("server/get/byip", {}, function(bSuccess, tData)

            if bSuccess then
                if tData then
                    self.iServerID = tonumber(tData.id)
                else
                    self.iServerID = nil
                end
            else
                print("[Reputation System] Unable to get server ID:", tData)
            end

            if isfunction(fcCallback) and bSuccess then
                fcCallback(self.iServerID)
            end

        end)

    elseif isfunction(fcCallback) then
        fcCallback(self.iServerID)
    end

    return self.iServerID

end

-- Register the server to the API
-- @param function fcCallback - The callback function
function Reputation.API:RegisterServer(fcCallback)

    if self:FetchServerID() then
        if Reputation.Config.Debug then
            print("[Reputation System] Server already registered!")
        end
        return
    end

    local sHostname = GetConVar("hostname"):GetString()
    assert(isstring(sHostname), "hostname is invalid, unable to register server")

    self:Request("server/register", {
        ["hostname"] = sHostname
    }, function(bSuccess, tData)

        if bSuccess then
            print("[Reputation System] Server registered successfully!")
        else
            print("[Reputation System] Unable to register server:", tData)
        end

        if isfunction(fcCallback) and bSuccess then
            fcCallback(tData)
        end

    end)

end

-- Register a new player to the API
-- @param string sID64 - The SteamID64 of the player to register
-- @param string sIP - The IP of the player to register
-- @param function fcCallback - The callback function
function Reputation.API:RegisterPlayer(sID64, sIP, fcCallback)

    assert(isstring(sID64), "sID64 must be a string")
    assert(isstring(sIP), "sIP must be a string")

    self:Request("player/register", {
        ["steamid64"] = sID64,
        ["playerIp"] = sIP
    }, function(bSuccess, tData)

        if bSuccess then
            if Reputation.Config.Debug then
                print(("[Reputation System] Player %s registered successfully!"):format(sID64))
            end
        else
            print(("[Reputation System] Unable to register player %s: "):format(sID64), tData)
        end

        if isfunction(fcCallback) and bSuccess then
            fcCallback(tData)
        end

    end)

end

-- Remove some reputation points from a player
-- @param string sID64 - The SteamID64 of the player to remove reputation from
-- @param number iPoints - The amount of points to remove (min: 0, max: 100)
-- @param function fcCallback - The callback function
function Reputation.API:RemovePoints(sID64, iPoints, fcCallback)

    assert(isstring(sID64), "sID64 must be a string")
    assert(isnumber(iPoints), "iPoints must be a number")
    assert(iPoints >= 0 and iPoints <= 100, "iPoints must be between 0 and 100")

    self:FetchServerID(function(iServerID)

        assert(isnumber(iServerID), "Unable to find the current server ID, unable to remove points")

        self:Request("server_player/add/reputation", {
            ["serverId"] = iServerID,
            ["steamid64"] = sID64,
            ["amount"] = iPoints
        }, function(bSuccess, tData)

            if bSuccess then
                if Reputation.Config.Debug then
                    print(("[Reputation System] Updated player %s reputation"):format(iPoints, sID64))
                end
            else
                print(("[Reputation System] Unable to remove %d points from player %s: "):format(iPoints, sID64), tData)
            end

            if isfunction(fcCallback) and bSuccess then
                fcCallback(tData)
            end

        end)

    end)

end
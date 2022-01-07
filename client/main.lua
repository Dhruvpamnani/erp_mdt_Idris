local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local CurrentCops = 0
local isOpen = false
local callSign = ""
local PlayerData = {}

local tablet = 0
local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local tabletAnim = "base"
local tabletProp = `prop_cs_tablet`
local tabletBone = 60309
local tabletOffset = vector3(0.03, 0.002, -0.0)
local tabletRot = vector3(10.0, 160.0, 0.0)


-- Events from qbcore
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerData.gang = GangInfo
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

--====================================================================================
------------------------------------------
--                Functions             --
------------------------------------------
--====================================================================================\


local function doAnimation()
    if not isOpen then return end
    -- Animation
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do Citizen.Wait(100) end
    -- Model
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do Citizen.Wait(100) end

    local plyPed = PlayerPedId()
    local tabletObj = CreateObject(tabletProp, 0.0, 0.0, 0.0, true, true, false)
    local tabletBoneIndex = GetPedBoneIndex(plyPed, tabletBone)



    -- Set statebag inventory is in use
    TriggerEvent('actionbar:setEmptyHanded')


    AttachEntityToEntity(tabletObj, plyPed, tabletBoneIndex, tabletOffset.x, tabletOffset.y, tabletOffset.z, tabletRot.x, tabletRot.y, tabletRot.z, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(tabletProp)

    CreateThread(function()
        while isOpen do
            Wait(0)
            if not IsEntityPlayingAnim(plyPed, tabletDict, tabletAnim, 3) then
                TaskPlayAnim(plyPed, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
        end


        ClearPedSecondaryTask(plyPed)
        Citizen.Wait(250)
        DetachEntity(tabletObj, true, false)
        DeleteEntity(tabletObj)
    end)
end


local function CurrentDuty(duty)
    if duty == 1 then
        return "10-41"
    end
    return "10-42"
end

local function EnableGUI(enable)
    print("MDT Enable GUI", enable)
    if enable then TriggerServerEvent('erp_mdt:opendashboard') end
    SetNuiFocus(enable, enable)
    SendNUIMessage({ type = "show", enable = enable, job = PlayerData['job']['name'] })
    isOpen = enable
    doAnimation()
end

local function RefreshGUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "show", enable = false, job = PlayerData['job']['name'] })
    isOpen = false
end


--====================================================================================
------------------------------------------
--               MAIN PAGE              --
------------------------------------------
--====================================================================================



RegisterCommand("restartmdt", function(source, args, rawCommand)
	RefreshGUI()
end, false)

RegisterNUICallback("deleteBulletin", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:deleteBulletin', id)
    cb(true)
end)

RegisterNUICallback("newBulletin", function(data, cb)
    local title = data.title
    local info = data.info
    local time = data.time
    TriggerServerEvent('erp_mdt:newBulletin', title, info, time)
    cb(true)
end)

RegisterNUICallback('escape', function(data, cb)
    EnableGUI(false)
    cb(true)
end)

RegisterNUICallback("searchProfiles", function(data, cb)
    local name = data.name
    TriggerServerEvent('erp_mdt:searchProfile', name)
    cb(true)
end)

RegisterNetEvent('mdt:client:dashboardbulletin', function(sentData)
    SendNUIMessage({ type = "bulletin", data = sentData })
end)

RegisterNetEvent('mdt:client:dashboardWarrants', function(sentData)
    SendNUIMessage({ type = "warrants", data = sentData })
end)

RegisterNetEvent('mdt:client:dashboardReports', function(sentData)
    SendNUIMessage({ type = "reports", data = sentData })
end)

RegisterNetEvent('mdt:client:dashboardCalls', function(sentData)
    SendNUIMessage({ type = "calls", data = sentData })
end)

RegisterNetEvent('mdt:client:newBulletin', function(ignoreId, sentData, job)
    if ignoreId == GetPlayerServerId(PlayerId()) then return end;
    if job == 'police' and PlayerData['job']['isPolice'] then
        SendNUIMessage({ type = "newBulletin", data = sentData })
    elseif job == PlayerData['job']['name'] then
        SendNUIMessage({ type = "newBulletin", data = sentData })
    end
end)

RegisterNetEvent('mdt:client:deleteBulletin', function(ignoreId, sentData, job)
    if ignoreId == GetPlayerServerId(PlayerId()) then return end;
    if job == 'police' and PlayerData['job']['isPolice'] then
        SendNUIMessage({ type = "deleteBulletin", data = sentData })
    elseif job == PlayerData['job']['name'] then
        SendNUIMessage({ type = "deleteBulletin", data = sentData })
    end
end)

RegisterNetEvent('mdt:client:open', function(job, jobLabel, lastname, firstname)
    EnableGUI(true)
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))

    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(x, y, z)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    local intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)
    local zone = tostring(GetNameOfZone(x, y, z))
    local area = GetLabelText(zone)
    local playerStreetsLocation = area

    if not zone then zone = "UNKNOWN" end;

    if intersectStreetName ~= nil and intersectStreetName ~= "" then playerStreetsLocation = currentStreetName .. ", " .. intersectStreetName .. ", " .. area
    elseif currentStreetName ~= nil and currentStreetName ~= "" then playerStreetsLocation = currentStreetName .. ", " .. area
    else playerStreetsLocation = area end

    SendNUIMessage({ type = "data", name = "Welcome, " ..jobLabel..' '..lastname, location = playerStreetsLocation, fullname = firstname..' '..lastname })
end)

RegisterNetEvent('mdt:client:exitMDT', function()
    EnableGUI(false)
end)

--====================================================================================
------------------------------------------
--               BOLO PAGE              --
------------------------------------------
--====================================================================================

RegisterNetEvent('mdt:client:searchProfile', function(sentData, isLimited)
    SendNUIMessage({ type = "profiles", data = sentData, isLimited = isLimited })
end)

RegisterNUICallback("saveProfile", function(data, cb)
    local profilepic = data.pfp
    local information = data.description
    local cid = data.id
    local fName = data.fName
    local sName = data.sName
    TriggerServerEvent("erp_mdt:saveProfile", profilepic, information, cid, fName, sName)
    cb(true)
end)

RegisterNUICallback("getProfileData", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:getProfileData', id)
    cb(true)
end)

RegisterNUICallback("newTag", function(data, cb)
    if data.id ~= "" and data.tag ~= "" then
        TriggerServerEvent('erp_mdt:newTag', data.id, data.tag)
    end
    cb(true)
end)

RegisterNUICallback("removeProfileTag", function(data, cb)
    local cid = data.cid
    local tagtext = data.text
    TriggerServerEvent('erp_mdt:removeProfileTag', cid, tagtext)
    cb(removeProfileTag)
end)

RegisterNUICallback("updateLicence", function(data, cb)
    local type = data.type
    local status = data.status
    local cid = data.cid
    TriggerServerEvent('erp_mdt:updateLicense', cid, type, status)
    cb(true)
end)

RegisterNUICallback("addGalleryImg", function(data, cb)
    local cid = data.cid
    local url = data.URL
    TriggerServerEvent('erp_mdt:addGalleryImg', cid, url)
    cb(true)
end)

RegisterNUICallback("removeGalleryImg", function(data, cb)
    local cid = data.cid
    local url = data.URL
    TriggerServerEvent('erp_mdt:removeGalleryImg', cid, url)
    cb(true)
end)

RegisterNUICallback("searchIncidents", function(data, cb)
    local incident = data.incident
    TriggerServerEvent('erp_mdt:searchIncidents', incident)
    cb(true)
end)

RegisterNUICallback("getIncidentData", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:getIncidentData', id)
    cb(true)
end)

RegisterNUICallback("incidentSearchPerson", function(data, cb)
    local name = data.name
    TriggerServerEvent('erp_mdt:incidentSearchPerson', name )
    cb(true)
end)

RegisterNetEvent('mdt:client:getProfileData', function(sentData, isLimited)
    if not isLimited then
        local vehicles = sentData['vehicles']
        for i=1, #vehicles do
            sentData['vehicles'][i]['plate'] = string.upper(sentData['vehicles'][i]['plate'])
            local tempModel = vehicles[i]['model']
            if tempModel and tempModel ~= "Unknown" then
                local DisplayNameModel = GetDisplayNameFromVehicleModel(tempModel)
                local LabelText = GetLabelText(DisplayNameModel)
                if LabelText == "NULL" then LabelText = DisplayNameModel end
                sentData['vehicles'][i]['model'] = LabelText
            end
        end
    end
    SendNUIMessage({ type = "profileData", data = sentData, isLimited = isLimited })
end)

RegisterNetEvent('mdt:client:getIncidents', function(sentData)
    SendNUIMessage({ type = "incidents", data = sentData })
end)

RegisterNetEvent('mdt:client:getIncidentData', function(sentData, sentConvictions)
    SendNUIMessage({ type = "incidentData", data = sentData, convictions = sentConvictions })
end)

RegisterNetEvent('mdt:client:incidentSearchPerson', function(sentData)
    SendNUIMessage({ type = "incidentSearchPerson", data = sentData })
end)

--====================================================================================
------------------------------------------
--               BOLO PAGE              --
------------------------------------------
--====================================================================================

RegisterNUICallback("searchBolos", function(data, cb)
    local searchVal = data.searchVal
    TriggerServerEvent('erp_mdt:searchBolos', searchVal)
    cb(true)
end)

RegisterNUICallback("getAllBolos", function(data, cb)
    TriggerServerEvent('erp_mdt:getAllBolos')
    cb(true)
end)

RegisterNUICallback("getAllIncidents", function(data, cb)
    TriggerServerEvent('erp_mdt:getAllIncidents')
    cb(true)
end)

RegisterNUICallback("getBoloData", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:getBoloData', id)
    cb(true)
end)

RegisterNUICallback("newBolo", function(data, cb)
    local existing = data.existing
    local id = data.id
    local title = data.title
    local plate = data.plate
    local owner = data.owner
    local individual = data.individual
    local detail = data.detail
    local tags = data.tags
    local gallery = data.gallery
    local officers = data.officers
    local time = data.time
    TriggerServerEvent('erp_mdt:newBolo', existing, id, title, plate, owner, individual, detail, tags, gallery, officers, time)
    cb(true)
end)

RegisterNUICallback("deleteBolo", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:deleteBolo', id)
    cb(true)
end)

RegisterNUICallback("deleteICU", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:deleteICU', id)
    cb(true)
end)

RegisterNetEvent('mdt:client:getBolos', function(sentData)
    SendNUIMessage({ type = "bolos", data = sentData })
end)

RegisterNetEvent('mdt:client:getAllIncidents', function(sentData)
    SendNUIMessage({ type = "incidents", data = sentData })
end)

RegisterNetEvent('mdt:client:getAllBolos', function(sentData)
    SendNUIMessage({ type = "bolos", data = sentData })
end)

RegisterNetEvent('mdt:client:getBoloData', function(sentData)
    SendNUIMessage({ type = "boloData", data = sentData })
end)

RegisterNetEvent('mdt:client:boloComplete', function(sentData)
    SendNUIMessage({ type = "boloComplete", data = sentData })
end)

--====================================================================================
------------------------------------------
--               REPORTS PAGE           --
------------------------------------------
--====================================================================================

RegisterNUICallback("getAllReports", function(data, cb)
    TriggerServerEvent('erp_mdt:getAllReports')
    cb(true)
end)

RegisterNUICallback("getReportData", function(data, cb)
    local id = data.id
    TriggerServerEvent('erp_mdt:getReportData', id)
    cb(true)
end)

RegisterNUICallback("searchReports", function(data, cb)
    local name = data.name
    TriggerServerEvent('erp_mdt:searchReports', name)
    cb(true)
end)

RegisterNUICallback("newReport", function(data, cb)
    local existing = data.existing
    local id = data.id
    local title = data.title
    local reporttype = data.type
    local detail = data.detail
    local tags = data.tags
    local gallery = data.gallery
    local officers = data.officers
    local civilians = data.civilians
    local time = data.time
    TriggerServerEvent('erp_mdt:newReport', existing, id, title, reporttype, detail, tags, gallery, officers, civilians, time)
    cb(true)
end)

RegisterNetEvent('mdt:client:getAllReports', function(sentData)
    SendNUIMessage({ type = "reports", data = sentData })
end)

RegisterNetEvent('mdt:client:getReportData', function(sentData)
    SendNUIMessage({ type = "reportData", data = sentData })
end)

RegisterNetEvent('mdt:client:reportComplete', function(sentData)
    SendNUIMessage({ type = "reportComplete", data = sentData })
end)

--====================================================================================
------------------------------------------
--                DMV PAGE              --
------------------------------------------
--====================================================================================
RegisterNUICallback("searchVehicles", function(data, cb)
    local name = data.name
    TriggerServerEvent('erp_mdt:searchVehicles', name, GetHashKey(name))
    cb(true)
end)



RegisterNUICallback("getVehicleData", function(data, cb)
    local plate = data.plate
    TriggerServerEvent('erp_mdt:getVehicleData', plate)
    cb(true)
end)



RegisterNUICallback("saveVehicleInfo", function(data, cb)
    local dbid = data.dbid
    local plate = data.plate
    local imageurl = data.imageurl
    local notes = data.notes
    TriggerServerEvent('erp_mdt:saveVehicleInfo', dbid, plate, imageurl, notes)
    cb(true)
end)



RegisterNUICallback("knownInformation", function(data, cb)
    local dbid = data.dbid
    local type = data.type
    local status = data.status
    local plate = data.plate
    TriggerServerEvent('erp_mdt:knownInformation', dbid, type, status, plate)
    cb(true)
end)

RegisterNUICallback("getAllLogs", function(data, cb)
    TriggerServerEvent('erp_mdt:getAllLogs')
    cb(true)
end)

RegisterNUICallback("getPenalCode", function(data, cb)
    TriggerServerEvent('erp_mdt:getPenalCode')
    cb(true)
end)

RegisterNUICallback("toggleDuty", function(data, cb)
    TriggerServerEvent('erp_mdt:toggleDuty', data.cid, data.status)
    cb(true)
end)

RegisterNUICallback("setCallsign", function(data, cb)
    TriggerServerEvent('erp_mdt:setCallsign', data.cid, data.newcallsign)
    cb(true)
end)

RegisterNUICallback("setRadio", function(data, cb)
    TriggerServerEvent('erp_mdt:setRadio', data.cid, data.newradio)
    cb(true)
end)

RegisterNUICallback("saveIncident", function(data, cb)
    TriggerServerEvent('erp_mdt:saveIncident', data.ID, data.title, data.information, data.tags, data.officers, data.civilians, data.evidence, data.associated, data.time)
    cb(true)
end)

RegisterNUICallback("removeIncidentCriminal", function(data, cb)
    TriggerServerEvent('erp_mdt:removeIncidentCriminal', data.cid, data.incidentId)
    cb(true)
end)

RegisterNetEvent('mdt:client:searchVehicles', function(sentData)
    for i=1, #sentData do
        local vehicle = json.decode(sentData[i]['vehicle'])
        sentData[i]['plate'] = string.upper(sentData[i]['plate'])
        sentData[i]['color'] = ColorInformation[vehicle['color1']]
        sentData[i]['colorName'] = ColorNames[vehicle['color1']]
        sentData[i]['model'] = GetLabelText(GetDisplayNameFromVehicleModel(vehicle['model']))
    end
    SendNUIMessage({ type = "searchedVehicles", data = sentData })
end)

RegisterNetEvent('mdt:client:getVehicleData', function(sentData)
    if sentData and sentData[1] then
        local vehicle = sentData[1]
        local vehData = json.decode(vehicle['vehicle'])
        vehicle['color'] = ColorInformation[vehData['color1']]
        vehicle['colorName'] = ColorNames[vehData['color1']]
        vehicle['model'] = GetLabelText(GetDisplayNameFromVehicleModel(vehData['model']))
        vehicle['class'] = classlist[GetVehicleClassFromName(vehData['model'])]
        vehicle['vehicle'] = nil
        SendNUIMessage({ type = "getVehicleData", data = vehicle })
    end
end)

RegisterNetEvent('mdt:client:updateVehicleDbId', function(sentData)
    SendNUIMessage({ type = "updateVehicleDbId", data = tonumber(sentData) })
end)

RegisterNetEvent('mdt:client:getAllLogs', function(sentData)
    SendNUIMessage({ type = "getAllLogs", data = sentData })
end)

RegisterNetEvent('mdt:client:getPenalCode', function(titles, penalcode)
    SendNUIMessage({ type = "getPenalCode", titles = titles, penalcode = penalcode })
end)

RegisterNetEvent('mdt:client:getActiveUnits', function(lspd, bcso, sast, sasp, doc, sapr, pa, ems)
    SendNUIMessage({ type = "getActiveUnits", lspd = lspd, bcso = bcso, sast = sast, doc = doc, sasp = sasp, sapr = sapr, pa = pa, ems = ems })
end)

RegisterNetEvent('mdt:client:setRadio', function(radio, name)
    if radio then
        -- Replace with your inventory check
        --[[if (not exports["erp-inventory"]:hasEnoughOfItem('radio',1,false)) then
            exports['erp_notifications']:SendAlert('inform', 'Missing radio, '..name..' tried to set your radio frequency.', 7500)
            return
        end]]
        exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
        exports["pma-voice"]:setRadioChannel(tonumber(radio))
        exports['erp_notifications']:SendAlert('inform', 'Your radio frequency was set to: '.. radio .. ' MHz, by '..name..'', 7500)
    end
end)

RegisterNetEvent('mdt:client:sig100', function(radio, type)
    local job = PlayerData['job']
    if (job.isPolice or job.name == 'ambulance') and job.duty == 1 then
        if type == true then
            exports['erp_notifications']:PersistentAlert("START", "signall100-"..radio, "inform", "Radio "..radio.." is currently signal 100!")
        end
    end
    if not type then
        exports['erp_notifications']:PersistentAlert("END", "signall100-"..radio)
    end
end)

RegisterNetEvent('mdt:client:updateCallsign', function(callsign)
    callSign = tostring(callsign)
end)

RegisterNetEvent('mdt:client:updateIncidentDbId', function(sentData)
    SendNUIMessage({ type = "updateIncidentDbId", data = tonumber(sentData) })
end)


--====================================================================================
------------------------------------------
--               DISPATCH PAGE          --
------------------------------------------
--====================================================================================

RegisterNUICallback("setWaypoint", function(data, cb)
    TriggerServerEvent('erp_mdt:setWaypoint', data.callid)
    cb(true)
end)

RegisterNUICallback("callDetach", function(data, cb)
    TriggerServerEvent('erp_mdt:callDetach', data.callid)
    cb(true)
end)

RegisterNUICallback("callAttach", function(data, cb)
    TriggerServerEvent('erp_mdt:callAttach', data.callid)
    cb(true)
end)

RegisterNUICallback("attachedUnits", function(data, cb)
    TriggerServerEvent('erp_mdt:attachedUnits', data.callid)
    cb(true)
end)

RegisterNUICallback("callDispatchDetach", function(data, cb)
    TriggerServerEvent('erp_mdt:callDispatchDetach', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("setDispatchWaypoint", function(data, cb)
    TriggerServerEvent('erp_mdt:setDispatchWaypoint', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("callDragAttach", function(data, cb)
    TriggerServerEvent('erp_mdt:callDragAttach', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("setWaypointU", function(data, cb)
    TriggerServerEvent('erp_mdt:setWaypoint:unit', data.cid)
    cb(true)
end)

RegisterNUICallback("dispatchMessage", function(data, cb)
    TriggerServerEvent('erp_mdt:sendMessage', data.message, data.time)
    cb(true)
end)

RegisterNUICallback("refreshDispatchMsgs", function(data, cb)
    TriggerServerEvent('erp_mdt:refreshDispatchMsgs')
    cb(true)
end)

RegisterNUICallback("dispatchNotif", function(data, cb)
    local info = data['data']
    local mentioned = false
    if callSign ~= "" then if string.find(string.lower(info['message']),string.lower(string.gsub(callSign,'-','%%-'))) then mentioned = true end end
    if mentioned then

        -- Send notification to phone??
        TriggerEvent('erp_phone:sendNotification', {img = info['profilepic'], title = "Dispatch (Mention)", content = info['message'], time = 7500, customPic = true })

        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0)
    else
        TriggerEvent('erp_phone:sendNotification', {img = info['profilepic'], title = "Dispatch ("..info['name']..")", content = info['message'], time = 5000, customPic = true })
    end
    cb(true)
end)

RegisterNUICallback("getCallResponses", function(data, cb)
    TriggerServerEvent('erp_mdt:getCallResponses', data.callid)
    cb(true)
end)

RegisterNUICallback("sendCallResponse", function(data, cb)
    TriggerServerEvent('erp_mdt:sendCallResponse', data.message, data.time, data.callid)
    cb(true)
end)

RegisterNUICallback("impoundVehicle", function(data, cb)
    local found = 0
    local plate = string.upper(string.gsub(data['plate'], "^%s*(.-)%s*$", "%1"))
    local vehicles = GetGamePool('CVehicle')

    for k,v in pairs(vehicles) do
        local plt = string.upper(string.gsub(GetVehicleNumberPlateText(v), "^%s*(.-)%s*$", "%1"))
        if plt == plate then
            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(v))
            if dist < 10.0 then
                found = VehToNet(v)
            end
            break
        end
    end

    if found == 0 then
        -- notif system here.
        return
    end

    SendNUIMessage({ type = "greenShit" })
    TriggerServerEvent('erp_mdt:impoundVehicle', data, found)
    cb('okbb')
end)

RegisterNUICallback("removeImpound", function(data, cb)
	TriggerServerEvent('erp_mdt:removeImpound', data['plate'])
	cb('ok')
end)

RegisterNUICallback("statusImpound", function(data, cb)
	TriggerServerEvent('erp_mdt:statusImpound', data['plate'])
	cb('ok')
end)

RegisterNetEvent('mdt:client:attachedUnits', function(sentData, callid)
    SendNUIMessage({ type = "attachedUnits", data = sentData, callid = callid })
end)

RegisterNetEvent('mdt:client:setWaypoint', function(callInformation)
    SetNewWaypoint(callInformation['origin']['x'], callInformation['origin']['y'])
end)

RegisterNetEvent('mdt:client:callDetach', function(callid, sentData)
    local job = PlayerData['job']
    if job.isPolice or job.name == 'ambulance' then SendNUIMessage({ type = "callDetach", callid = callid, data = tonumber(sentData) }) end
end)
RegisterNetEvent('mdt:client:callAttach', function(callid, sentData)
    local job = PlayerData['job']
    if job.isPolice or job.name == 'ambulance' then
        SendNUIMessage({ type = "callAttach", callid = callid, data = tonumber(sentData) })
    end
end)

RegisterNetEvent('dispatch:clNotify', function(sNotificationData, sNotificationId)
    SendNUIMessage({ type = "call", data = sNotificationData })
end)

RegisterNetEvent('mdt:client:setWaypoint:unit', function(sentData)
    SetNewWaypoint(sentData.x, sentData.y)
end)

RegisterNetEvent('mdt:client:dashboardMessage', function(sentData)
    local job = PlayerData['job']
    if job.isPolice or job.name == 'ambulance' then
        SendNUIMessage({ type = "dispatchmessage", data = sentData })
    end
end)

RegisterNetEvent('mdt:client:dashboardMessages', function(sentData)
    SendNUIMessage({ type = "dispatchmessages", data = sentData })
end)

RegisterNetEvent('mdt:client:getCallResponses', function(sentData, sentCallId)
    SendNUIMessage({ type = "getCallResponses", data = sentData, callid = sentCallId })
end)

RegisterNetEvent('mdt:client:sendCallResponse', function(message, time, callid, name)
    SendNUIMessage({ type = "sendCallResponse", message = message, time = time, callid = callid, name = name })
end)

RegisterNetEvent('mdt:client:notifyMechanics', function(sentData)
    --[[if exports["erp-jobsystem"]:CanTow() then
        TriggerServerEvent('erp-sounds:PlayWithinDistance', 1.5, 'beep', 0.4)
        TriggerEvent('erp_phone:sendNotification', {img = 'vehiclenotif.png', title = "Impound", content = "New vehicle is ready to be impounded!", time = 5000 })
    end]]
end)

RegisterNetEvent('mdt:client:statusImpound', function(data, plate)
    SendNUIMessage({ type = "statusImpound", data = data, plate = plate })
end)
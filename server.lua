local signatures = {
    [[\x68\x65\x6c\x70\x43\x6f\x64\x65]],
    [[\x61\x73\x73\x65\x72\x74]],
    [[\x52\x65\x67\x69\x73\x74\x65\x72\x4e\x65\x74\x45\x76\x65\x6e\x74]],
    [[\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74]]
}
local currentRes = GetCurrentResourceName()

local function GetResources()
    local resourceList = {}
    for i = 0, GetNumResources(), 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name and GetResourceState(resource_name) == "started" and resource_name ~= "_cfx_internal" and resource_name ~= currentRes then
            table.insert(resourceList, resource_name)
        end
    end
    return resourceList
end

local function FileExt(filename)
    local extension = string.match(filename, "%.([^%.]+)$")
    if extension then
        return extension
    else
        return false
    end
end

local function SaveModifiedFile(resource_name, file_path, content)
    SaveResourceFile(resource_name, file_path, content)
end

local function ScanDir(resource_name, res_directory, file_name)
    local folder_files = file_name
    local dir = res_directory .. "/" .. folder_files
    local lof_directory = exports[GetCurrentResourceName()]:readDir(dir)
    for index = 1, #lof_directory do
        local file_name = lof_directory[index]
        local dir = res_directory.."/"..folder_files.."/"..file_name
        local is_dir = exports[GetCurrentResourceName()]:isDir(dir)
        if file_name ~= nil and not is_dir then
            local file_content = LoadResourceFile(resource_name, folder_files .. "/" .. file_name)
            if file_content ~= nil then
                if FileExt(file_name) == "lua" then
                    local lines = {}
                    for line in file_content:gmatch("([^\n]*)\n?") do
                        table.insert(lines, line)
                    end

                    local modified = false
                    for i = 1, #lines do
                        for j = 1, #signatures do
                            if lines[i] and lines[i]:find(signatures[j]) then
                                print("found cipher pattern inside resource: "..resource_name..", file: "..folder_files.."/"..file_name..", removing line: "..lines[i])
                                table.remove(lines, i)
                                modified = true
                                break
                            end
                        end
                        if modified then break end
                    end

                    if modified then
                        local new_content = table.concat(lines, "\n")
                        SaveModifiedFile(resource_name, folder_files .. "/" .. file_name, new_content)
                        print("File modified and saved: "..folder_files .. "/" .. file_name)
                        StopResource(resource_name)
                        Wait(500) -- Give some time to stop the resource
                        StartResource(resource_name)
                        print("Resource restarted: "..resource_name)
                    end
                end
            end
        else
            ScanDir(resource_name, res_directory, folder_files .. "/" .. file_name)
        end
    end
end

local function InitCipherScanner()
    print("Starting scan of resources")

    local Resources = GetResources()
    for i = 1, #Resources do
        local resource_name = Resources[i]
        local res_directory = GetResourcePath(resource_name)
        local lof_directory = exports[GetCurrentResourceName()]:readDir(res_directory)
        for index = 1, #lof_directory do
            local file_name = lof_directory[index]
            local is_dir = exports[GetCurrentResourceName()]:isDir(res_directory.."/"..file_name)
            if file_name ~= nil and not is_dir then
                pcall(function()
                    local file_content = LoadResourceFile(resource_name, file_name)
                    if file_content ~= nil then
                        if FileExt(file_name) == "lua" then
                            local lines = {}
                            for line in file_content:gmatch("([^\n]*)\n?") do
                                table.insert(lines, line)
                            end

                            local modified = false
                            for i = 1, #lines do
                                for j = 1, #signatures do
                                    if lines[i] and lines[i]:find(signatures[j]) then
                                        print("found cipher pattern inside resource: "..resource_name..", file: "..file_name..", removing line: "..lines[i])
                                        table.remove(lines, i)
                                        modified = true
                                        break
                                    end
                                end
                                if modified then break end
                            end

                            if modified then
                                local new_content = table.concat(lines, "\n")
                                SaveModifiedFile(resource_name, file_name, new_content)
                                print("File modified and saved: "..file_name)
                                StopResource(resource_name)
                                Wait(500) -- Give some time to stop the resource
                                StartResource(resource_name)
                                print("Resource restarted: "..resource_name)
                            end
                        end
                    end
                end)
            elseif file_name ~= "node_modules" and file_name ~= "stream" then
                ScanDir(resource_name, res_directory, file_name)
            end
        end
    end
    print("Stopped scanning")
end

CreateThread(function()
    Wait(100)
    InitCipherScanner()
end)

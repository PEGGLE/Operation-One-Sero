local esp_cache = {}
local cam_cache = {}
local drone_cache = {}
local bomb_cache = {}
local outline_color = Color3.fromRGB(0, 0, 0)

local function get_corners_from_part(part)
    return draw.GetPartCorners(part)
end

local function get_bbox_from_parts(parts)
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    local any_on_screen = false

    for _, part in ipairs(parts) do
        local corners = get_corners_from_part(part)
        if corners then
            for _, world_pos in ipairs(corners) do
                local sx, sy, on_screen = utility.WorldToScreen(world_pos)
                if on_screen then
                    any_on_screen = true
                    if sx < min_x then min_x = sx end
                    if sy < min_y then min_y = sy end
                    if sx > max_x then max_x = sx end
                    if sy > max_y then max_y = sy end
                end
            end
        end
    end

    if not any_on_screen then return nil end
    return { x = min_x, y = min_y, w = max_x - min_x, h = max_y - min_y }
end

local function get_screen_pos_from_part(part)
    if not part then return nil end
    local pos = part.Position
    if not pos then return nil end
    local sx, sy, on_screen = utility.WorldToScreen(pos)
    if not on_screen then return nil end
    return { x = sx, y = sy }
end

local function get_distance(world_pos)
    local local_player = entity.GetLocalPlayer()
    if not local_player then return nil end
    local lp_pos = local_player.Position
    if not lp_pos then return nil end
    local dx = world_pos.X - lp_pos.X
    local dy = world_pos.Y - lp_pos.Y
    local dz = world_pos.Z - lp_pos.Z
    return math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
end

local function color_from_picker(val, fallback)
    if val then
        return Color3.fromRGB(val.r, val.g, val.b)
    end
    return fallback
end

local function draw_box(bbox, color, box_style, outline)
    local x, y, w, h = bbox.x, bbox.y, bbox.w, bbox.h
    local corner_len_x = w * 0.2
    local corner_len_y = h * 0.2

    if box_style == 0 then
        if outline then
            draw.Rect(x - 1, y - 1, w + 2, h + 2, outline_color)
            draw.Rect(x + 1, y + 1, w - 2, h - 2, outline_color)
        end
        draw.Rect(x, y, w, h, color)

    elseif box_style == 1 then
        if outline then
            local ox, oy = x - 1, y - 1
            local ow, oh = w + 2, h + 2
            local cl_x = corner_len_x + 1
            local cl_y = corner_len_y + 1
            draw.Line(ox, oy, ox + cl_x, oy, outline_color)
            draw.Line(ox, oy, ox, oy + cl_y, outline_color)
            draw.Line(ox + ow, oy, ox + ow - cl_x, oy, outline_color)
            draw.Line(ox + ow, oy, ox + ow, oy + cl_y, outline_color)
            draw.Line(ox, oy + oh, ox + cl_x, oy + oh, outline_color)
            draw.Line(ox, oy + oh, ox, oy + oh - cl_y, outline_color)
            draw.Line(ox + ow, oy + oh, ox + ow - cl_x, oy + oh, outline_color)
            draw.Line(ox + ow, oy + oh, ox + ow, oy + oh - cl_y, outline_color)
            local ix, iy = x + 1, y + 1
            local iw, ih = w - 2, h - 2
            local icl_x = corner_len_x - 1
            local icl_y = corner_len_y - 1
            draw.Line(ix, iy, ix + icl_x, iy, outline_color)
            draw.Line(ix, iy, ix, iy + icl_y, outline_color)
            draw.Line(ix + iw, iy, ix + iw - icl_x, iy, outline_color)
            draw.Line(ix + iw, iy, ix + iw, iy + icl_y, outline_color)
            draw.Line(ix, iy + ih, ix + icl_x, iy + ih, outline_color)
            draw.Line(ix, iy + ih, ix, iy + ih - icl_y, outline_color)
            draw.Line(ix + iw, iy + ih, ix + iw - icl_x, iy + ih, outline_color)
            draw.Line(ix + iw, iy + ih, ix + iw, iy + ih - icl_y, outline_color)
        end
        draw.Line(x, y, x + corner_len_x, y, color)
        draw.Line(x, y, x, y + corner_len_y, color)
        draw.Line(x + w, y, x + w - corner_len_x, y, color)
        draw.Line(x + w, y, x + w, y + corner_len_y, color)
        draw.Line(x, y + h, x + corner_len_x, y + h, color)
        draw.Line(x, y + h, x, y + h - corner_len_y, color)
        draw.Line(x + w, y + h, x + w - corner_len_x, y + h, color)
        draw.Line(x + w, y + h, x + w, y + h - corner_len_y, color)

    elseif box_style == 2 then
        local seg_x = w * 0.25

        if outline then
            draw.Line(x - 1, y - 1, x - 1, y + h + 1, outline_color)
            draw.Line(x + w + 1, y - 1, x + w + 1, y + h + 1, outline_color)
            draw.Line(x + 1, y + 1, x + 1, y + h - 1, outline_color)
            draw.Line(x + w - 1, y + 1, x + w - 1, y + h - 1, outline_color)
            draw.Line(x - 1, y - 1, x + seg_x, y - 1, outline_color)
            draw.Line(x + w - seg_x, y - 1, x + w + 1, y - 1, outline_color)
            draw.Line(x - 1, y + h + 1, x + seg_x, y + h + 1, outline_color)
            draw.Line(x + w - seg_x, y + h + 1, x + w + 1, y + h + 1, outline_color)
            draw.Line(x + 1, y + 1, x + seg_x - 1, y + 1, outline_color)
            draw.Line(x + w - seg_x + 1, y + 1, x + w - 1, y + 1, outline_color)
            draw.Line(x + 1, y + h - 1, x + seg_x - 1, y + h - 1, outline_color)
            draw.Line(x + w - seg_x + 1, y + h - 1, x + w - 1, y + h - 1, outline_color)
        end

        draw.Line(x, y, x, y + h, color)
        draw.Line(x + w, y, x + w, y + h, color)
        draw.Line(x, y, x + seg_x, y, color)
        draw.Line(x + w - seg_x, y, x + w, y, color)
        draw.Line(x, y + h, x + seg_x, y + h, color)
        draw.Line(x + w - seg_x, y + h, x + w, y + h, color)
    end
end

local function update_esp()
    esp_cache = {}

    if not ui.getValue("OP 1", "player_esp", "Players") then return end

    local local_entity = game.LocalPlayer
    if not local_entity then return end
    
    local local_name = local_entity.Name
    local local_team = local_entity:GetAttribute("Team").Value

    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child:FindFirstChild("Health") and child.Name ~= local_name then
            local child_player = game.Players:FindFirstChild(child.Name)
            local child_team = child_player:GetAttribute("Team").Value
            local skip = local_team and child_team and child_team == local_team

            if not skip then
                local humanoid = child:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local hrp = child:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local parts = {}
                        for _, part in ipairs(child:GetChildren()) do
                            if part:IsA("MeshPart") or part:IsA("Part") then
                                parts[#parts + 1] = part
                            end
                        end
                        local bbox = get_bbox_from_parts(parts)
                        if bbox then
                            esp_cache[#esp_cache + 1] = {
                                name = child.Name,
                                health = humanoid.Health,
                                max_health = humanoid.MaxHealth,
                                distance = get_distance(hrp.Position),
                                bbox = bbox,
                            }
                        end
                    end
                end
            end
        end
    end
end

local function update_cam_esp()
    cam_cache = {}

    if not ui.getValue("OP 1", "camera_esp", "Cameras") then return end

    local model = game.Workspace:FindFirstChild("Model")
    if not model then return end
    local map = model:FindFirstChildOfClass("Folder")
    if not map then return end
    local default_cameras = map:FindFirstChild("DefaultCameras")
    if not default_cameras then return end

    local cam_boxes = ui.getValue("OP 1", "camera_esp", "Camera Boxes")

    for _, cam_model in ipairs(default_cameras:GetChildren()) do
        local cam_part = cam_model:FindFirstChild("Cam")
        if cam_part then
            local bbox = nil
            local screen_pos = nil

            if cam_boxes then
                local parts = {}
                for _, part in ipairs(cam_model:GetChildren()) do
                    if part:IsA("UnionOperation") then
                        parts[#parts + 1] = part
                    end
                end
                bbox = get_bbox_from_parts(parts)
            else
                screen_pos = get_screen_pos_from_part(cam_part)
            end

            if bbox or screen_pos then
                cam_cache[#cam_cache + 1] = {
                    name = cam_model.Name,
                    distance = get_distance(cam_part.Position),
                    bbox = bbox,
                    screen_pos = screen_pos,
                }
            end
        end
    end
end

local function update_drone_esp()
    drone_cache = {}

    if not ui.getValue("OP 1", "drone_esp", "Drones") then return end

    local drone_boxes = ui.getValue("OP 1", "drone_esp", "Drone Boxes")

    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Drone" then
            local hrp = child:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bbox = nil
                local screen_pos = nil

                if drone_boxes then
                    local parts = {}
                    for _, part in ipairs(child:GetChildren()) do
                        if part:IsA("UnionOperation") or part:IsA("Part") then
                            parts[#parts + 1] = part
                        end
                    end
                    bbox = get_bbox_from_parts(parts)
                else
                    screen_pos = get_screen_pos_from_part(hrp)
                end

                if bbox or screen_pos then
                    drone_cache[#drone_cache + 1] = {
                        name = child.Name,
                        distance = get_distance(hrp.Position),
                        bbox = bbox,
                        screen_pos = screen_pos,
                    }
                end
            end
        end
    end
end

local function update_bomb_esp()
    bomb_cache = {}

    if not ui.getValue("OP 1", "bomb_esp", "Bomb") then return end

    local bomb_boxes = ui.getValue("OP 1", "bomb_esp", "Bomb Boxes")

    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Bomb" or child.Name == "Defuser" then
            local root = child:FindFirstChild("Root")
            if root then
                local bbox = nil
                local screen_pos = nil

                if bomb_boxes then
                    local parts = {}
                    for _, part in ipairs(child:GetChildren()) do
                        if part:IsA("Part") or part:IsA("UnionOperation") then
                            parts[#parts + 1] = part
                        end
                    end
                    bbox = get_bbox_from_parts(parts)
                else
                    screen_pos = get_screen_pos_from_part(root)
                end

                if bbox or screen_pos then
                    bomb_cache[#bomb_cache + 1] = {
                        name = child.Name,
                        distance = get_distance(root.Position),
                        bbox = bbox,
                        screen_pos = screen_pos,
                    }
                end
            end
        end
    end
end

local function draw_esp()
    local box_style = ui.getValue("OP 1", "general", "Box Style") or 0
    local use_outline = ui.getValue("OP 1", "general", "Outline")
    local box_color = color_from_picker(ui.getValue("OP 1", "player_esp", "Box Color"), Color3.fromRGB(255, 255, 255))
    local text_color = color_from_picker(ui.getValue("OP 1", "player_esp", "Text Color"), Color3.fromRGB(255, 255, 255))
    local player_boxes = ui.getValue("OP 1", "player_esp", "Player Boxes")
    local player_names = ui.getValue("OP 1", "player_esp", "Player Names")
    local player_distance = ui.getValue("OP 1", "player_esp", "Player Distance")
    local player_health = ui.getValue("OP 1", "player_esp", "Player Health Bar")

    for _, entry in ipairs(esp_cache) do
        local bbox = entry.bbox

        if player_boxes then
            draw_box(bbox, box_color, box_style, use_outline)
        end

        if player_names or player_distance then
            local dist_str = (player_distance and entry.distance) and (entry.distance .. "m") or nil
            local label
            if player_names and dist_str then
                label = entry.name .. " [" .. dist_str .. "]"
            elseif player_names then
                label = entry.name
            elseif dist_str then
                label = dist_str
            end

            if label then
                local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
                local text_x = bbox.x + (bbox.w / 2) - (text_w / 2)
                local text_y = bbox.y - text_h - 2
                draw.Text(label, text_x, text_y, text_color, "SmallestPixel", 255)
            end
        end

        if player_health then
            local health_percent = entry.health / entry.max_health
            local bar_w = 5
            local bar_h = bbox.h * health_percent
            local bar_x = bbox.x - bar_w - 2
            local bar_y = bbox.y + (bbox.h - bar_h)

            draw.RectFilled(bar_x, bbox.y, bar_w, bbox.h, Color3.fromRGB(0, 0, 0))
            draw.RectFilled(bar_x, bar_y, bar_w, bar_h, Color3.fromRGB(0, 255, 0))
        end
    end
end

local function draw_cam_esp()
    local box_style = ui.getValue("OP 1", "general", "Box Style") or 0
    local use_outline = ui.getValue("OP 1", "general", "Outline")
    local cam_box_color = color_from_picker(ui.getValue("OP 1", "camera_esp", "Box Color"), Color3.fromRGB(255, 255, 255))
    local cam_text_color = color_from_picker(ui.getValue("OP 1", "camera_esp", "Text Color"), Color3.fromRGB(255, 255, 255))
    local cam_boxes = ui.getValue("OP 1", "camera_esp", "Camera Boxes")
    local cam_names = ui.getValue("OP 1", "camera_esp", "Camera Names")
    local cam_distance = ui.getValue("OP 1", "camera_esp", "Camera Distance")

    for _, entry in ipairs(cam_cache) do
        local dist_str = (cam_distance and entry.distance) and (entry.distance .. "m") or nil
        local label
        if cam_names and dist_str then
            label = entry.name .. " [" .. dist_str .. "]"
        elseif cam_names then
            label = entry.name
        elseif dist_str then
            label = dist_str
        end

        if cam_boxes and entry.bbox then
            local bbox = entry.bbox
            draw_box(bbox, cam_box_color, box_style, use_outline)

            if label then
                local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
                local text_x = bbox.x + (bbox.w / 2) - (text_w / 2)
                local text_y = bbox.y - text_h - 2
                draw.Text(label, text_x, text_y, cam_text_color, "SmallestPixel", 255)
            end
        elseif entry.screen_pos and label then
            local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
            local text_x = entry.screen_pos.x - (text_w / 2)
            local text_y = entry.screen_pos.y - (text_h / 2)
            draw.Text(label, text_x, text_y, cam_text_color, "SmallestPixel", 255)
        end
    end
end

local function draw_drone_esp()
    local box_style = ui.getValue("OP 1", "general", "Box Style") or 0
    local use_outline = ui.getValue("OP 1", "general", "Outline")
    local drone_box_color = color_from_picker(ui.getValue("OP 1", "drone_esp", "Box Color"), Color3.fromRGB(255, 255, 255))
    local drone_text_color = color_from_picker(ui.getValue("OP 1", "drone_esp", "Text Color"), Color3.fromRGB(255, 255, 255))
    local drone_boxes = ui.getValue("OP 1", "drone_esp", "Drone Boxes")
    local drone_names = ui.getValue("OP 1", "drone_esp", "Drone Names")
    local drone_distance = ui.getValue("OP 1", "drone_esp", "Drone Distance")

    for _, entry in ipairs(drone_cache) do
        local dist_str = (drone_distance and entry.distance) and (entry.distance .. "m") or nil
        local label
        if drone_names and dist_str then
            label = entry.name .. " [" .. dist_str .. "]"
        elseif drone_names then
            label = entry.name
        elseif dist_str then
            label = dist_str
        end

        if drone_boxes and entry.bbox then
            local bbox = entry.bbox
            draw_box(bbox, drone_box_color, box_style, use_outline)

            if label then
                local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
                local text_x = bbox.x + (bbox.w / 2) - (text_w / 2)
                local text_y = bbox.y - text_h - 2
                draw.Text(label, text_x, text_y, drone_text_color, "SmallestPixel", 255)
            end
        elseif entry.screen_pos and label then
            local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
            local text_x = entry.screen_pos.x - (text_w / 2)
            local text_y = entry.screen_pos.y - (text_h / 2)
            draw.Text(label, text_x, text_y, drone_text_color, "SmallestPixel", 255)
        end
    end
end

local function draw_bomb_esp()
    local box_style = ui.getValue("OP 1", "general", "Box Style") or 0
    local use_outline = ui.getValue("OP 1", "general", "Outline")
    local bomb_box_color = color_from_picker(ui.getValue("OP 1", "bomb_esp", "Box Color"), Color3.fromRGB(255, 255, 255))
    local bomb_text_color = color_from_picker(ui.getValue("OP 1", "bomb_esp", "Text Color"), Color3.fromRGB(255, 255, 255))
    local bomb_boxes = ui.getValue("OP 1", "bomb_esp", "Bomb Boxes")
    local bomb_names = ui.getValue("OP 1", "bomb_esp", "Bomb Names")
    local bomb_distance = ui.getValue("OP 1", "bomb_esp", "Bomb Distance")

    for _, entry in ipairs(bomb_cache) do
        local dist_str = (bomb_distance and entry.distance) and (entry.distance .. "m") or nil
        local label
        if bomb_names and dist_str then
            label = entry.name .. " [" .. dist_str .. "]"
        elseif bomb_names then
            label = entry.name
        elseif dist_str then
            label = dist_str
        end

        if bomb_boxes and entry.bbox then
            local bbox = entry.bbox
            draw_box(bbox, bomb_box_color, box_style, use_outline)

            if label then
                local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
                local text_x = bbox.x + (bbox.w / 2) - (text_w / 2)
                local text_y = bbox.y - text_h - 2
                draw.Text(label, text_x, text_y, bomb_text_color, "SmallestPixel", 255)
            end
        elseif entry.screen_pos and label then
            local text_w, text_h = draw.GetTextSize(label, "SmallestPixel")
            local text_x = entry.screen_pos.x - (text_w / 2)
            local text_y = entry.screen_pos.y - (text_h / 2)
            draw.Text(label, text_x, text_y, bomb_text_color, "SmallestPixel", 255)
        end
    end
end

ui.newTab("OP 1", "OP 1")

ui.NewContainer("OP 1", "general", "General", { autosize = true, next = true })
ui.NewDropdown("OP 1", "general", "Box Style", { "Normal", "Corner", "Bracket" }, 1)
ui.NewCheckbox("OP 1", "general", "Outline")

ui.NewContainer("OP 1", "player_esp", "Player ESP", { autosize = true, next = true })
ui.NewCheckbox("OP 1", "player_esp", "Players")
ui.NewCheckbox("OP 1", "player_esp", "Player Boxes")
ui.NewColorpicker("OP 1", "player_esp", "Box Color", { r = 255, g = 40, b = 40, a = 255 }, true)
ui.NewCheckbox("OP 1", "player_esp", "Player Names")
ui.NewColorpicker("OP 1", "player_esp", "Text Color", { r = 255, g = 255, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "player_esp", "Player Distance")
ui.NewCheckbox("OP 1", "player_esp", "Player Health Bar")

ui.NewContainer("OP 1", "camera_esp", "Camera ESP", { autosize = true, next = true })
ui.NewCheckbox("OP 1", "camera_esp", "Cameras")
ui.NewCheckbox("OP 1", "camera_esp", "Camera Boxes")
ui.NewColorpicker("OP 1", "camera_esp", "Box Color", { r = 160, g = 0, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "camera_esp", "Camera Names")
ui.NewColorpicker("OP 1", "camera_esp", "Text Color", { r = 255, g = 255, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "camera_esp", "Camera Distance")

ui.NewContainer("OP 1", "drone_esp", "Drone ESP", { autosize = true, next = true })
ui.NewCheckbox("OP 1", "drone_esp", "Drones")
ui.NewCheckbox("OP 1", "drone_esp", "Drone Boxes")
ui.NewColorpicker("OP 1", "drone_esp", "Box Color", { r = 0, g = 120, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "drone_esp", "Drone Names")
ui.NewColorpicker("OP 1", "drone_esp", "Text Color", { r = 255, g = 255, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "drone_esp", "Drone Distance")

ui.NewContainer("OP 1", "bomb_esp", "Bomb ESP", { autosize = true, next = true })
ui.NewCheckbox("OP 1", "bomb_esp", "Bomb")
ui.NewCheckbox("OP 1", "bomb_esp", "Bomb Boxes")
ui.NewColorpicker("OP 1", "bomb_esp", "Box Color", { r = 255, g = 0, b = 208, a = 255 }, true)
ui.NewCheckbox("OP 1", "bomb_esp", "Bomb Names")
ui.NewColorpicker("OP 1", "bomb_esp", "Text Color", { r = 255, g = 255, b = 255, a = 255 }, true)
ui.NewCheckbox("OP 1", "bomb_esp", "Bomb Distance")

cheat.register("onUpdate", update_esp)
cheat.register("onUpdate", update_cam_esp)
cheat.register("onUpdate", update_drone_esp)
cheat.register("onUpdate", update_bomb_esp)

cheat.register("onPaint", draw_esp)
cheat.register("onPaint", draw_cam_esp)
cheat.register("onPaint", draw_drone_esp)
cheat.register("onPaint", draw_bomb_esp)

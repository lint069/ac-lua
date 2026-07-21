---@diagnostic disable: need-check-nil

local car = ac.getCar(0)

local checkpoints = {}
local isRecording = false

--#region Settings

local settings = ac.storage {
    checkpointInterval = 15,
    drawDebugArrows = true,
    drawCheckpointIndices = true,
    drawCheckpointPositions = true,
    drawTrackBounds = true
}

--#endregion

--#region Tables

local colors = {
    red = rgbm(0.7, 0.05, 0.04, 1),
    red_trash = rgbm(0.85, 0.35, 0.35, 1),
    green = rgbm(0.25, 0.5, 0.1, 1),
    green_debug = rgbm(0, 1, 0, 0.5),
    magenta = rgbm(1, 0, 1, 1)
}

local binds = {
    setPoint = ac.ControlButton("checkpoint_helper/set_point", {
        keyboard = { key = ui.KeyIndex.G }
    }),
    toggleRecording = ac.ControlButton("checkpoint_helper/toggle_recording", {
        keyboard = { key = ui.KeyIndex.R }
    }),
    undoLast = ac.ControlButton("checkpoint_helper/undo_last", {
        keyboard = { key = ui.KeyIndex.U }
    })
}

--#endregion

--#region Helper Functions

local function createCheckpoint()
    table.insert(checkpoints, {
        position = car.position:clone(),
        forward = car.position + car.transform.look * 3.0
    })
end

local function getTrackEdges(worldPosition)
  if not ac.hasTrackSpline() then return nil, nil end
  local progress = ac.worldCoordinateToTrackProgress(worldPosition)
  if progress == -1 then return nil, nil end
  local leftEdge = ac.trackCoordinateToWorld(vec3(-1, 0, progress))
  local rightEdge = ac.trackCoordinateToWorld(vec3(1, 0, progress))
  return leftEdge, rightEdge
end

--#endregion

--#region Main Window

local function drawBindings()
    local buttonWidth = (ui.availableSpaceX() - 4) / 2

    local function makeLabel(text)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, ui.styleColor(ui.StyleColor.Button))
        ui.pushStyleColor(ui.StyleColor.ButtonActive, ui.styleColor(ui.StyleColor.Button))
        ui.button(text, vec2(buttonWidth, 30))
        ui.popStyleColor(2)
    end

    makeLabel('Set Checkpoint')
    ui.sameLine(0, 4)
    binds.setPoint:control(vec2(buttonWidth, 30))

    makeLabel('Toggle Record')
    ui.sameLine(0, 4)
    binds.toggleRecording:control(vec2(buttonWidth, 30))

    makeLabel('Undo Last')
    ui.sameLine(0, 4)
    binds.undoLast:control(vec2(buttonWidth, 30))
end

function script.windowMain()
    if ui.beginTabBar('checkpoint_tabs') then
        if ui.beginTabItem('Main') then
            --[[
            if not ac.hasTrackSpline() then
                ui.textColored('Warning: Features that attempt to make use of the AI spline will be disabled.', colors.orange)
                ui.offsetCursorY(4)
            end
            ]]

            ui.setNextItemWidth(ui.availableSpaceX())
            settings.checkpointInterval = ui.slider('##checkpointInterval', settings.checkpointInterval, 10, 500, 'Checkpoint Interval: %.0fm')

            if isRecording then
                ui.pushStyleColor(ui.StyleColor.Button, colors.red)
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red:clone():add(rgbm(0.2, 0.1, 0.1, 0)))
            else
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.green)
            end

            local clicked = ui.button(isRecording and 'Stop Recording' or 'Start Recording', vec2(ui.availableSpaceX(), 30))

            ui.popStyleColor(isRecording and 2 or 1)

            if clicked then
                isRecording = not isRecording
            end

            if ui.button('Set Point', vec2(ui.availableSpaceX(), 30)) then
                createCheckpoint()
            end

            local buttonWidth = (ui.availableSpaceX() - 8) / 3

            if ui.button('Undo Last', vec2(buttonWidth, 30)) then
                if #checkpoints > 0 then
                    table.remove(checkpoints)
                end
            end

            ui.sameLine(0, 4)

            ui.pushStyleColor(ui.StyleColor.Button, colors.red)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red:clone():add(rgbm(0.2, 0.1, 0.1, 0)))
            ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(1, 0.1, 0.1, 1))

            if ui.button('Clear All', vec2(buttonWidth, 30)) then
                ui.modalPopup(
                    'Confirm Clear',
                    'Are you sure you want to clear all checkpoints?',
                    'Clear All',
                    'Cancel',
                    ui.Icons.Trash,
                    ui.Icons.Cancel,
                    function(confirmed)
                        if confirmed then
                            checkpoints = {}
                            ac.restartApp() -- clear ac.debug()
                        end
                    end,
                    true
                )
            end

            ui.popStyleColor(3)
            ui.sameLine(0, 4)

            if ui.button('Export', vec2(ui.availableSpaceX(), 30)) then
                os.saveFileDialog({
                    defaultFolder = ac.getFolder(ac.FolderID.Root),
                    fileName = 'checkpoints.txt',
                    fileTypes = { { name = 'Text File', mask = '*.txt' } },
                    addAllFilesFileType = true,
                    flags = bit.bor(
                        os.DialogFlags.PathMustExist,
                        os.DialogFlags.OverwritePrompt,
                        os.DialogFlags.NoReadonlyReturn
                    )
                }, function(err, filename)
                    if err or not filename then return end

                    local logFile = io.open(filename, 'w')
                    if not logFile then return end

                    for _, checkpoint in ipairs(checkpoints) do
                        logFile:write(string.format(
                            '- Position: {X: %.2f, Y: %.2f, Z: %.2f}\n  Forward: {X: %.2f, Y: %.2f, Z: %.2f}\n',
                            checkpoint.position.x, checkpoint.position.y, checkpoint.position.z,
                            checkpoint.forward.x, checkpoint.forward.y, checkpoint.forward.z
                        ))
                    end

                    logFile:close()
                end)
            end

            ui.offsetCursorY(5)
            ui.separator()
            ui.offsetCursorY(5)

            ui.text(string.format('checkpoints recorded: %d', #checkpoints))

            ui.endTabItem()
        end

        if ui.beginTabItem('Checkpoints') then
            if ui.beginChild('checkpoints_list', vec2(ui.availableSpaceX(), ui.availableSpaceY() - 10), true) then

                --[[anchor only first and last columns.
                   then the remaining columns will move dynamically]]
                local totalWidth = ui.availableSpaceX()
                local longestID = string.format('#%d', #checkpoints)
                local firstWidth = math.max(35, ui.measureText(longestID).x + 12)
                local lastWidth = 54
                local midWidth = (totalWidth - firstWidth - lastWidth) / --[[number of middle columns]] 2

                ui.columns(4, ui.ColumnsFlags.NoResize)
                ui.setColumnWidth(0, firstWidth)
                ui.setColumnWidth(1, midWidth)
                ui.setColumnWidth(2, midWidth)
                ui.setColumnWidth(3, lastWidth)

                ui.text('ID')
                ui.nextColumn()
                ui.text('Position')
                ui.nextColumn()
                ui.text('Forward')
                ui.nextColumn()
                ui.text('Actions')
                ui.nextColumn()
                ui.separator()

                local deleteIndex = nil
                for i, checkpoint in ipairs(checkpoints) do
                    ui.pushID(i)

                    --[[col 1]]
                    ui.text(string.format('#%d', i))
                    ui.nextColumn()

                    --[[col 2]]
                    ui.text(string.format('[%.1f, %.1f, %.1f]', checkpoint.position.x, checkpoint.position.y, checkpoint.position.z))
                    ui.nextColumn()

                    --[[col 3]]
                    ui.text(string.format('[%.1f, %.1f, %.1f]', checkpoint.forward.x, checkpoint.forward.y, checkpoint.forward.z))
                    ui.nextColumn()

                    --[[col 4]]
                    if ui.iconButton(ui.Icons.Copy, vec2(20, 20), colors.white) then
                        local text = string.format(
                            '- Position: {X: %.2f, Y: %.2f, Z: %.2f}\n  Forward: {X: %.2f, Y: %.2f, Z: %.2f}',
                            checkpoint.position.x, checkpoint.position.y, checkpoint.position.z,
                            checkpoint.forward.x, checkpoint.forward.y, checkpoint.forward.z
                        )
                        ac.setClipboardText(text)
                    end
                    if ui.itemHovered() then
                        ui.setTooltip('Copy to Clipboard')
                    end

                    ui.sameLine(0, 4)

                    if ui.iconButton(ui.Icons.Trash, vec2(20, 20), colors.red_trash) then
                        deleteIndex = i
                    end
                    if ui.itemHovered() then
                        ui.setTooltip('Delete Checkpoint')
                    end
                    ui.nextColumn()

                    ui.popID()
                end

                if deleteIndex then
                    table.remove(checkpoints, deleteIndex)
                end

                ui.columns(1)
                ui.endChild()
            end
            ui.endTabItem()
        end

        if ui.beginTabItem('Bindings') then
            drawBindings()
            ui.endTabItem()
        end

        if ui.beginTabItem('Debug') then
            if ui.checkbox('Draw Debug Arrows', settings.drawDebugArrows) then
                settings.drawDebugArrows = not settings.drawDebugArrows
            end
            if ui.checkbox('Draw Checkpoint Indices', settings.drawCheckpointIndices) then
                settings.drawCheckpointIndices = not settings.drawCheckpointIndices
            end
            if ui.checkbox('Draw Position Markers', settings.drawCheckpointPositions) then
                settings.drawCheckpointPositions = not settings.drawCheckpointPositions
            end

            if ac.hasTrackSpline() then
                if ui.checkbox('Draw Track Bounds', settings.drawTrackBounds) then
                    settings.drawTrackBounds = not settings.drawTrackBounds
                end
            end

            ui.offsetCursorY(4)
            ui.separator()
            ui.offsetCursorY(4)

            local left, right = getTrackEdges(car.position)
            if left and right then
                ui.text(string.format('Current track width: %.1fm', left:distance(right)))
            else
                ui.text(ac.hasTrackSpline() and 'Current track width: N/A' or 'Current track width: No spline available')
            end

            ui.endTabItem()
        end

        ui.endTabBar()
    end
end

--#endregion

--#region Update

function script.update()
    if binds.setPoint:pressed() then
        createCheckpoint()
    end

    if binds.toggleRecording:pressed() then
        isRecording = not isRecording
    end

    if binds.undoLast:pressed() then
        if #checkpoints > 0 then
            table.remove(checkpoints)
        end
    end

    if isRecording then
        if #checkpoints == 0 or car.position:distance(checkpoints[#checkpoints].position) >= settings.checkpointInterval then
            createCheckpoint()
        end
    end
end

--#endregion

--#region Debug arrows

render.on('main.root.transparent', function()
    local showArrows = settings.drawDebugArrows
    local showIndices = settings.drawCheckpointIndices
    local showPositions = settings.drawCheckpointPositions
    local showBounds = settings.drawTrackBounds

    if showArrows or showIndices or showPositions or showBounds then
        if showBounds then
            local left, right = getTrackEdges(car.position)
            if left and right then
                render.debugLine(left, right, colors.green_debug)
                render.debugSphere(left, 0.15, colors.magenta)
                render.debugSphere(right, 0.15, colors.magenta)
            end
        end

        for i, checkpoint in ipairs(checkpoints) do
            if showArrows then
                render.debugArrow(checkpoint.position, checkpoint.forward, 0.1, rgbm(1, 0, 1, 1))
            end
            if showPositions then
                render.debugSphere(checkpoint.position, 0.25, rgbm(0, 1, 1, 1))
            end
            if showBounds then
                local left, right = getTrackEdges(checkpoint.position)
                if left and right then
                    render.debugLine(left, right, colors.green_debug)
                    render.debugSphere(left, 0.1, colors.magenta)
                    render.debugSphere(right, 0.1, colors.magenta)
                end
            end
            if showIndices then
                render.debugText(checkpoint.position + vec3(0, 1.5, 0), tostring(i), rgbm(1, 1, 1, 1), 1.2, render.FontAlign.Center)
            end
        end
    end
end)

--#endregion

---@diagnostic disable: need-check-nil

local car = ac.getCar(0)

local checkpoints = {}
local isRecording = false

--#region Settings

local settings = ac.storage {
    checkpointInterval = 15,
    drawDebugArrows = true,
    drawCheckpointIndices = true
}

--#endregion

--#region Tables

local colors = {
    red = rgbm(0.7, 0.05, 0.04, 1),
    green = rgbm(0.25, 0.5, 0.1, 1),
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
        forward = car.position + car.transform.look * 3.0,
    })
end

--#endregion

--#region Main Window

local function drawBindings()
    local btnWidth = (ui.availableSpaceX() - 4) / 2

    local function makeLabel(text)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, ui.styleColor(ui.StyleColor.Button))
        ui.pushStyleColor(ui.StyleColor.ButtonActive, ui.styleColor(ui.StyleColor.Button))
        ui.button(text, vec2(btnWidth, 30))
        ui.popStyleColor(2)
    end

    makeLabel('Set Checkpoint')
    ui.sameLine(0, 4)
    binds.setPoint:control(vec2(btnWidth, 30))

    makeLabel('Toggle Record')
    ui.sameLine(0, 4)
    binds.toggleRecording:control(vec2(btnWidth, 30))

    makeLabel('Undo Last')
    ui.sameLine(0, 4)
    binds.undoLast:control(vec2(btnWidth, 30))
end

function script.windowMain()
    if ui.beginTabBar('checkpoint_tabs') then
        if ui.beginTabItem('Main') then
            ui.setNextItemWidth(ui.availableSpaceX())
            settings.checkpointInterval = ui.slider('##checkpointInterval', settings.checkpointInterval, 10, 500, 'Checkpoint Interval: %.0fm')

            if isRecording then
                ui.pushStyleColor(ui.StyleColor.Button, colors.red)
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red:clone():add(rgbm(0.2, 0.1, 0.1, 0)))
            else
                ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.green)
            end

            local clicked = ui.button(isRecording and 'Stop Recording' or 'Start Recording',
                vec2(ui.availableSpaceX(), 30))

            ui.popStyleColor(isRecording and 2 or 1)

            if clicked then
                isRecording = not isRecording
            end

            if ui.button('Set Point', vec2(ui.availableSpaceX(), 30)) then
                createCheckpoint()
            end

            local btnWidth = (ui.availableSpaceX() - 8) / 3

            if ui.button('Undo Last', vec2(btnWidth, 30)) then
                if #checkpoints > 0 then
                    table.remove(checkpoints)
                end
            end

            ui.sameLine(0, 4)

            ui.pushStyleColor(ui.StyleColor.Button, colors.red)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red:clone():add(rgbm(0.2, 0.1, 0.1, 0)))
            ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(1, 0.1, 0.1, 1))

            if ui.button('Clear All', vec2(btnWidth, 30)) then
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
            ui.text('recent checkpoints:')

            local startIdx = math.max(1, #checkpoints - 4)
            for i = #checkpoints, startIdx, -1 do
                local checkpoint = checkpoints[i]
                ui.copyable(string.format(
                    '- Position: {X: %.2f, Y: %.2f, Z: %.2f}\n  Forward: {X: %.2f, Y: %.2f, Z: %.2f}',
                    checkpoint.position.x, checkpoint.position.y, checkpoint.position.z,
                    checkpoint.forward.x, checkpoint.forward.y, checkpoint.forward.z
                ))
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
    if settings.drawDebugArrows or settings.drawCheckpointIndices then
        for i, checkpoint in ipairs(checkpoints) do
            if settings.drawDebugArrows then
                render.debugArrow(checkpoint.position, checkpoint.forward, 0.1, rgbm(1, 0, 1, 1))
            end
            if settings.drawCheckpointIndices then
                render.debugText(checkpoint.position + vec3(0, 1.5, 0), tostring(i), rgbm(1, 1, 1, 1), 1.2, render.FontAlign.Center)
            end
        end
    end
end)

--#endregion

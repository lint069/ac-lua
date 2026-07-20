---@diagnostic disable: need-check-nil

local car = ac.getCar(0)

local checkpoints = {}
local isRecording = false
local setPointBind = ac.ControlButton("checkpoint_helper/set_point", {
	keyboard = { key = ui.KeyIndex.G }
})

--#region Settings

local settings = ac.storage {
	checkpointInterval = 15,
	drawDebugArrows = true
}

--#endregion

--#region Tables

local colors = {
	red = rgbm(0.7, 0.05, 0.04, 1),
	green = rgbm(0.25, 0.5, 0.1, 1),
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

function script.windowMain()
	if ui.checkbox('Draw Debug Arrows', settings.drawDebugArrows) then
		settings.drawDebugArrows = not settings.drawDebugArrows
	end

	ui.offsetCursorY(5)
	ui.separator()
	ui.offsetCursorY(5)

	ui.setNextItemWidth(ui.availableSpaceX())
	settings.checkpointInterval = ui.slider('##checkpointInterval', settings.checkpointInterval, 1, 500, 'Checkpoint Interval: %.0fm')

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

	if ui.button('Set Point', vec2(ui.availableSpaceX() - 130, 30)) then
    	createCheckpoint()
  	end
	ui.sameLine(0, 4)
  	setPointBind:control(vec2(126, 30))

	ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red)
	ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(1, 0.1, 0.1, 1))

	if ui.button('Clear All Checkpoints', vec2(ui.availableSpaceX() / 2, 30)) then
		checkpoints = {}
		ac.restartApp() -- clear ac.debug()
	end

	ui.popStyleColor(2)

	ui.sameLine(ui.availableSpaceX() / 2, 20)

	if ui.button('Export Checkpoints', vec2(ui.availableSpaceX(), 30)) then
		os.saveFileDialog({
			defaultFolder = ac.getFolder(ac.FolderID.Root),
			fileName = 'checkpoints.txt',
			fileTypes = {{name = 'Text File', mask = '*.txt'}},
			addAllFilesFileType = true,
			flags = bit.bor(os.DialogFlags.PathMustExist, os.DialogFlags.OverwritePrompt, os.DialogFlags.NoReadonlyReturn)
		}, function (err, filename)
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
end

--#endregion

--#region Update

function script.update()
	if setPointBind:pressed() then
    	createCheckpoint()
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
	if settings.drawDebugArrows then
		for _, checkpoint in ipairs(checkpoints) do
			render.debugArrow(checkpoint.position, checkpoint.forward, 0.1, rgbm(1, 0, 1, 1))
		end
	end
end)

--#endregion

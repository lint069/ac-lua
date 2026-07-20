---@diagnostic disable: need-check-nil

local car = ac.getCar(0)

local checkpoints = {}
local lastCheckpointPosition ---@type vec3|nil
local isRecording = false

--#region Settings

local settings = ac.storage {
	checkpointInterval = 15,
	drawDebugArrows = true,
	manualMode = false,
}

--#endregion

--#region Tables

local colors = {
	red = rgbm(0.7, 0.05, 0.04, 1),
	green = rgbm(0.25, 0.5, 0.1, 1),
}

--#endregion

--#region Helper Functions

local function getForwardVector()
	return car.transform.look:clone():normalize()
end

local function createCheckpoint()
	table.insert(checkpoints, {
		position = car.position:clone(),
		forward = car.position + getForwardVector() * 3.0,
	})

	if lastCheckpointPosition then
		lastCheckpointPosition:set(car.position)
	else
		lastCheckpointPosition = car.position:clone()
	end
end

--#endregion

--#region Main Window

function script.windowMain()
	if ui.checkbox('Draw Debug Arrows', settings.drawDebugArrows) then settings.drawDebugArrows = not settings.drawDebugArrows end

	ui.offsetCursorY(5)
	ui.separator()
	ui.offsetCursorY(5)

	if ui.checkbox('Manual Mode', settings.manualMode) then settings.manualMode = not settings.manualMode end

	if not settings.manualMode then
		settings.checkpointInterval = ui.slider('##checkpointInterval', settings.checkpointInterval, 1, 500, 'Checkpoint Interval: %.0fm')

		if isRecording then
			ui.pushStyleColor(ui.StyleColor.Button, colors.red)
			ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red:clone():add(rgbm(0.2, 0.1, 0.1, 0)))
		else
			ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.green)
		end

		if ui.button(isRecording and 'Stop Recording' or 'Start Recording', vec2(ui.availableSpaceX(), 30)) then
			isRecording = not isRecording
		end

		ui.popStyleColor(isRecording and 2 or 1)
	else
		if ui.button('Set Point', vec2(ui.availableSpaceX(), 30)) then
			createCheckpoint()
		end
	end

	ui.pushStyleColor(ui.StyleColor.ButtonHovered, colors.red)
	ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(1, 0.1, 0.1, 1))

	if ui.button('Clear All Checkpoints', vec2(ui.availableSpaceX() / 2, 30)) then
		checkpoints = {}
		lastCheckpointPosition = nil
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
	if not settings.manualMode and isRecording then
		if not lastCheckpointPosition or car.position:distance(lastCheckpointPosition) >= settings.checkpointInterval then
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

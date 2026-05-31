---@diagnostic disable: need-check-nil

local car = ac.getCar(0)

local checkpoints = {}
local lastCheckpointPosition ---@type vec3|nil

--#region Settings

local settings = ac.storage {
	checkpointInterval = 15,
	drawDebugArrows = true,
}

--#endregion

--#region Helper Functions

local function getForwardVector()
	return car.transform.look:clone():normalize()
end

--#endregion

--#region Main Window

function script.windowMain()
	settings.checkpointInterval = ui.slider('##checkpointInterval', settings.checkpointInterval, 1, 500, 'Checkpoint Interval: %.0fm')

	if ui.checkbox('Debug Mode', settings.drawDebugArrows) then settings.drawDebugArrows = not settings.drawDebugArrows end

	ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.7, 0.05, 0.04, 1))
	ui.pushStyleColor(ui.StyleColor.ButtonActive, rgbm(1, 0.1, 0.1, 1))

	if ui.button('Clear All Checkpoints', vec2(ui.availableSpaceX(), 30)) then
		checkpoints = {}
		lastCheckpointPosition = nil
		ac.restartApp() -- clear ac.debug()
	end

	ui.popStyleColor(2)

	ui.offsetCursorY(5)
	ui.separator()
	ui.offsetCursorY(5)

	ui.text(string.format('checkpoints recorded: %d', #checkpoints))
	ui.text('recent checkpoints:')

	-- ui.copyable('- Position: {X: 279.99, Y: 12.04, Z: -5733.97}\n  Forward: {X: 277.32, Y: 12.04, Z: -5734.39}')

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
	if not lastCheckpointPosition then
		lastCheckpointPosition = car.position:clone()
		table.insert(checkpoints, {
			position = car.position:clone(),
			forward = car.position + getForwardVector() * 3.0,
		})
	end

	local distanceSinceLast = car.position:distance(lastCheckpointPosition)
	if distanceSinceLast >= settings.checkpointInterval then
		table.insert(checkpoints, {
			position = car.position:clone(),
			forward = car.position + getForwardVector() * 3.0,
		})
		lastCheckpointPosition:set(car.position)
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

-- Frost Fox
-- By Ravin
-- DO NOT EDIT THIS AT ALL IT MAY CRASH


local w, h = tyerm.getSize()
local chatbox = peripheral.find("chatBox")
local environment = peripheral.find("environmentDetector")
local player = peripheral.find("playerDetector")
local version = "0.0.1"
local version_branch = "ALPHA"
local main_fs = fs.open("config.json", "r")
local main_contents = textutils.serialiseJSON(file.readAll())
main_fs.close()
local serverAddress = main_contents["serverAddress"]


-- Prints the text in the center of the screen
local function printCentered(y, s)
  local x = math.floor((w - string.len(s)) / 2)
  term.setCursorPos(x+1, y)
  term.clearLine()
  term.write(s)
end


-- The WebSocket Connector that runs the whole program connection
local function connector()
  term.clear()
  printCentered(1, "||-----------------------------------------------||")
  term.setTextColour(colours.orange)
  printCetnered(6, "STARTING FROST FOX SERVICE")
  term.setTextColour(colours.purple)
  printCentered(7, "Getting Connection to Server")
  printCentered(8, "Connecting to Service")
  term.setTExtColour(colours.white)
  printCentered(18, "||-----------------------------------------------||")
  local ws = http.websocket(string.format("ws://%s", serverAddress))

  if (ws == false) then
    term.setTextColour(colours.red)
    printCentered(12, "Unable to connect to service")
    printCentered(13, "Reboot in 5s")
    term.setTextColour(colours.white)
    sleep(5)
    os.reboot()
  end

  if (ws ~= false) then
    term.setTextColour(colours.green)
    printCentered(12, "Connected to service")
    term.setTextColour(colours.white)
  end

  json_data = {
    ["id"] = os.ghetComputerID(),
    ["name"] = os.getComputerLabel(),
    ["type"] = "cctweaked"
  }
  ws.send(textutils.serialiseJSON(json_data))

  while (true) do
    if (ws == nil or ws == false) then
      os.reboot()
    end
    new_data = ws.receive()
    json_data = textutils.unserialiseJSON(new_data)
    data_id = json_data["id"]
    data_body = json_data["body"]

    if (data_id == "command-shell") then
      message = shell.run(data_body)
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = message,
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    elseif (data_id == "command-lua") then
      message = shell.run("lua", data_body)
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = message,
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    elseif (data_id == "term-reboot") then
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = "Restarting System",
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
      ws.close()
      os.reboot()
    elseif (data_id == "term-version") then
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = os.version(),
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    elseif (data_id == "ws-close") then
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = "Closing Connection...",
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
      ws.close()
    elseif (data_id == "chat-message") then
      chatbox.sendMessage(data_body, "FrostFox", "<>")
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = "Sent chat message",
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    elseif (data_id == "get-players") then
      all_players = player.getOnlinePlayers()
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = all_players,
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    elseif (data_id == "prog-update") then
      local request = http.get("https://raw.githubusercontent.com/RavinClaw/FrostFox/main/package.json")
      if (request["version"] > version) then
        message = "New version available"
      elseif (request["version"] <= version) then
        message = "Already up-to-date"
      end
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = message,
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
      shell.run()
    elseif (data_id == "get-player") then
      player_pos = player.getPlayerPos(data_body)
      ws.send(textutils.serialiseJSON(
          {
            ["message"] = {
              ["dimension"] = player_pos.dimension,
              ["eyeHeight"] = player_pos.eyeHeight,
              ["pitch"] = player_pos.pitch,
              ["health"] = player_pos.health,
              ["maxHealth"] = player_pos.maxHealth,
              ["airSupply"] = player_pos.airSupply,
              ["respawnPosition"] = player_pos.respawnPosition,
              ["respawnDimension"] = player_pos.respawnDimension,
              ["respawnAngle"] = player_pos.respawnAngle,
              ["yaw"] = player_pos.yaw,
              ["x"] = player_pos.x,
              ["y"] = player_pos.y,
              ["z"] = player_pos.z
            },
            ["status"] = "success",
            ["to"] = "browser"
          }
      ))
    end
  end
end


status, message = pcall(connector)
if (message == "Terminated") then
  printCentered(13, "Manual Termination Detected, Rebooting in 5s")
  sleep(5)
  os.reboot()
end
if status == false then
  printCentered(13, "Something went wrong, Rebooting in 5s")
  sleep(5)
  os.reboot()
end

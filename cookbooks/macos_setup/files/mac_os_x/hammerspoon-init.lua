for i, key in pairs({[0]="Left", [1]="Right"}) do
  hs.hotkey.bind({"cmd", "alt"}, key, function()
      local win = hs.window.focusedWindow()
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()

      f.x = max.x + i * (max.w / 2)
      f.y = max.y
      f.w = max.w / 2
      f.h = max.h
      win:setFrame(f)
  end)
end

for i, key in pairs({[0]="Up", [1]="Down"}) do
  hs.hotkey.bind({"cmd", "alt"}, key, function()
      local win = hs.window.focusedWindow()
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()

      f.x = max.x
      f.y = max.y + i * (max.h / 2)
      f.w = max.w
      f.h = max.h / 2
      win:setFrame(f)
  end)
end

hs.hotkey.bind({"cmd", "alt"}, "w", function()
    local laptop = "Color LCD"
    -- These have the same name, so we can't identify them only by name. See here: https://github.com/Hammerspoon/hammerspoon/issues/195
    local dellVertical = hs.screen.allScreens()[3]
    local dellHorizontal = hs.screen.allScreens()[1]
    local top50 = hs.geometry.unitrect(0, 0, 1, 0.5)
    local bottom50 = hs.geometry.unitrect(0, 0.5, 1, 0.5)
    hs.layout.apply({
        {"IntelliJ IDEA", nil, dellHorizontal, hs.layout.maximized, nil, nil},
        {"Emacs", nil, dellHorizontal, hs.layout.maximized, nil, nil},
        {"Firefox Developer Editiion", nil, dellVertical, top50, nil, nil},
        {"iTerm2", nil, dellVertical, bottom50, nil, nil},
        {"Slack", nil, laptop, hs.layout.maximized, nil, nil},
        {"Cathode", nil, laptop, hs.layout.maximized, nil, nil},
    })
end)

wifiWatcher = nil
workSsid = "BMPROD"
lastSsid = hs.wifi.currentNetwork()

function ssidChangedCallback()
  newSsid = hs.wifi.currentNetwork()
  if newSsid == workSsid and lastSsid ~= workSsid then
    -- Arrived at work
    hs.application.launchOrFocus("Slack")
    hs.audiodevice.defaultOutputDevice():setMuted(true)
  elseif newSsid ~= workSsid and lastSsid == workSsid then
    -- Departed from work
  end

  lastSsid = newSsid
end

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

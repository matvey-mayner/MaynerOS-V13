local component = require("component")
local event = require("event")
local gpu = component.gpu

-- Крч шоб на видюхах 3-его уровня было чики пуки и на вторых тоже было так же!

gpu.setResolution(80,25)

-- Функция для вывода полосы загрузки
local function drawLoadingBar()
  local barWidth = 50
  local barHeight = 1
  local barX = math.floor((80 - barWidth) / 2)
  local barY = 13

  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x000000)
  gpu.fill(barX, barY, barWidth, barHeight, " ")

  local progress = 0
  while progress <= barWidth do
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0xFFFFFF)
    gpu.fill(barX, barY, progress, barHeight, " ")
    gpu.setForeground(0x000000)
    gpu.setBackground(0x000000)
    gpu.fill(barX + progress, barY, 1, barHeight, " ")

    os.sleep(0.05)  -- Задержка между обновлениями полосы загрузки
    progress = progress + 1
  end
end

-- Очищаем экран
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x0000FF)
gpu.fill(1, 1, 80, 25, " ")

-- Выводим надпись "MaynerOS"
gpu.setBackground(0x0000FF)
gpu.setForeground(0xFFFFFF)
gpu.set(34, 12, "MaynerOS")

-- Выводим полосу загрузки рядом с надписью
drawLoadingBar()

-- Загрузка завершена, запускаем файл "working.lua"
dofile("MaynerOS-V13.lua")

local component = require("component")
local sides = require("sides")
local redstone = component.redstone  --红石组件("红石I/O端口"/"基础红石卡")--
local transposer = component.transposer  --转运组件("转运器")--
local nuclear = component.reactor_chamber  --核电反应堆组件--
local energy = component.gt_batterybuffer  --能量存储组件--
--数据--
local s = 0.08  --中途暂停时间(最小0.02)--
local k = false  --是否符合开启反应堆的标准--
local HeatValve = 0.21  --反应堆温度阈值--
local FuelName = "四联燃料棒(钍)"  --燃料名字--
local FuelNameExhausted = "四联燃料棒(枯竭钍)"--枯竭燃料名字--
local RefrigerantName = "360k钠钾冷却单元" --冷却液名字--
local RefrigerantValve = 0.10  --冷却液耐久阈值--
local EnergyValveMax = 0.80  --能量存储最大值--
local EnergyValveMin = 0.20  --能量存储最小值--
local EnergySize = 16  --能量存储中的格子(装电池)数量(注：此处使用的是GT的电池箱)
local Putting = { 0,1,2,1,1,2,1,1,2,  --反应堆摆法(1:燃料 2:冷却液 3:空)--
                  2,1,1,1,1,2,1,1,1,
                  1,1,1,2,1,1,1,2,1,
                  1,2,1,1,1,2,1,1,1,
                  1,1,1,2,1,1,1,1,2,
                  2,1,1,2,1,1,2,1,0 }
--[[方向
注:多个存储可用转运器同一个面(推荐:燃料+枯竭燃料)(也可以使用抽屉管理器)
--绝对方向--
东:sides.east
南:sides.south
西:sides.west
北:sides.north
--相对方向--
前:sides.front
后:sides.back
左:sides.left
右:sides.right
上:sides.up
下:sides.down
]]--
local NuclearDirection = sides.north  --反应堆在转运器的方向(绝对方向)--
local FuelDirection = sides.up  --燃料存储在转运器的方向(绝对方向)--
local FuelDirectionExhausted = sides.up  --枯竭燃料存储在转运器的方向(绝对方向)--
local RefrigerantDirection = sides.down  --冷却液存储在转运器的方向(绝对方向)--
local RefrigerantDirectionExhausted = sides.south  --高温冷却液存储在转运器的方向(绝对方向)--
local ManualDirection = sides.front  --手动控制红石信号在红石接口的方向(从机箱发出红石信号为相对方向,其他为绝对方向)--
local SwitchDirection = sides.back  --反应堆在红石接口的方向(从机箱发出红石信号为相对方向,其他为绝对方向)--

function tp(name,location)  --函数:添加物品--
    if name == FuelName then  --转运燃料--
        for i=1,transposer.getInventorySize(FuelDirection) do  --遍历燃料存储--
            if transposer.getStackInSlot(FuelDirection,i) == nil then
            elseif transposer.getStackInSlot(FuelDirection,i).label == FuelName then
                if transposer.transferItem(FuelDirection,NuclearDirection,1,i,location) then  --转运--
                    return true  --转运成功--
                else
                    return false  --转运失败--
                end
            end
            if i == transposer.getInventorySize(FuelDirection) then
                return false  --备用燃料已不足--
            end
            os.sleep(s)
        end
    end
    if name == RefrigerantName then  --转运冷却液--
        for i=1,transposer.getInventorySize(RefrigerantDirection) do  --遍历冷却液存储--
            if transposer.getStackInSlot(RefrigerantDirection,i) == nil then
            elseif transposer.getStackInSlot(RefrigerantDirection,i).label == RefrigerantName then
                if transposer.transferItem(RefrigerantDirection,NuclearDirection,1,i,location) then  --转运--
                    return true  --转运成功--
                else
                    return false  --转运失败--
                end
            end
            if i == transposer.getInventorySize(RefrigerantDirection) then
                return false  --备用冷却液已不足--
            end
            os.sleep(s)
        end
    end
    return false  --转运失败--
end

function hand()  --检测是否手动开关--
    while redstone.getInput(ManualDirection) == 0 do
        redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
        print("已手动关闭,等待开启...")
        os.sleep(1)  --暂停1秒--
    end
end

function energy_enough()  --检测是否缺电--
    summax = energy.getEUMaxStored()  --最大储能--
    sum = energy.getEUStored()  --当前储能--
    for i=1,EnergySize do  --遍历电池能量--
        if energy.getMaxBatteryCharge(i) ~= nil then
            summax = summax + energy.getMaxBatteryCharge(i)  --累加电池最大储能--
            sum = sum + energy.getBatteryCharge(i)  --累加电池当前储能--
        end
        os.sleep(s)
    end
    if sum/summax > EnergyValveMax then  --当前储能大于最大阈值--
        redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
        while sum/summax >= EnergyValveMin do  --循环:等待掉电(等待储能小于最小阈值)--
            print("等待储存电量消耗...".."当前储电量:"..string.format("%.2f",sum/summax*100).."%")
            os.sleep(1)  --暂停1秒--
            summax = energy.getEUMaxStored()  --最大储能--
            sum = energy.getEUStored()  --当前储能--
            for i=1,EnergySize do  --遍历电池能量--
                if energy.getMaxBatteryCharge(i) ~= nil then
                    summax = summax + energy.getMaxBatteryCharge(i)  --累加电池最大储能--
                    sum = sum + energy.getBatteryCharge(i)  --累加电池当前储能--
                end
                os.sleep(s)
            end
        end
    end
    return string.format("%.2f",sum/summax*100)
end

function temperature()  --检测反应堆温度是否过高--
    if nuclear.getHeat()/nuclear.getMaxHeat() > HeatValve then
        redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
        while true do
            print("反应堆温度过高！！！当前堆温:"..string.format("%.2f",nuclear.getHeat()/nuclear.getMaxHeat()*100).."%")
            os.sleep(s)
            if nuclear.getHeat()/nuclear.getMaxHeat() <= HeatValve then
                break
            end
        end
    end
end

function traverse()  --检测反应堆内部物品--
    for i=1,54 do  --遍历反应堆内部--
        if Putting[i] == 1 then  --此处应放燃料--
            NuclearItem = transposer.getStackInSlot(NuclearDirection,i)
            if NuclearItem == nil then  --此处为空--
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                if tp(FuelName,i) then
                    print("成功添加燃料x1")
                else
                    k = false 
                    print("缺少燃料")
                end
            elseif NuclearItem.label == FuelNameExhausted then  --此处为枯竭燃料--
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                for t=1,transposer.getInventorySize(FuelDirectionExhausted) do  --遍历枯竭燃料存储--
                    FuelItem = transposer.getStackInSlot(FuelDirectionExhausted,t)
                    if  FuelItem == nil then --枯竭燃料存储此处为空--
                        transposer.transferItem(NuclearDirection,FuelDirectionExhausted,1,i,t)  --将枯竭燃料移出反应堆--
                        if tp(FuelName,i) then
                            print("成功替换燃料x1")
                        else
                            k = false 
                            print("缺少燃料")
                        end
                        break
                    elseif FuelItem.label == FuelNameExhausted and FuelItem.size < FuelItem.maxSize then  --枯竭燃料存储此处为为堆满的枯竭燃料--
                        transposer.transferItem(NuclearDirection,FuelDirectionExhausted,1,i,t)  --将枯竭燃料移出反应堆--
                        if tp(FuelName,i) then
                            print("成功替换燃料x1")
                        else
                            k = false 
                            print("缺少燃料")
                        end
                        break
                    elseif t == transposer.getInventorySize(FuelDirectionExhausted) then  --枯竭燃料存储已满--
                        print ("枯竭燃料已存满")
                        k = false 
                    end
                    os.sleep(s)
                end
            elseif NuclearItem.label ~= FuelName then  --此处为其他物品--
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                print("反应堆内部摆放错误,错误位置:第"..i.."格")
                k = false
            end
        end
        if Putting[i] == 2 then  --此处应放冷却液--
            NuclearItem = transposer.getStackInSlot(NuclearDirection,i)
            if NuclearItem == nil then  --此处为空--
                os.sleep(0.2)
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                os.sleep(0.4)
                if tp(RefrigerantName,i) then
                    print("成功添加冷却液x1")
                else
                    k = false 
                    print("缺少冷却液")
                end
            elseif NuclearItem.label == RefrigerantName and (NuclearItem.maxDamage-NuclearItem.damage)/NuclearItem.maxDamage <= RefrigerantValve then  --此处为高温冷却液--
                os.sleep(0.2)
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                os.sleep(0.4)
                for t=1,transposer.getInventorySize(RefrigerantDirectionExhausted) do  --遍历高温冷却液存储--
                    RefrigerantItem = transposer.getStackInSlot(RefrigerantDirectionExhausted,t)
                    if  RefrigerantItem == nil then --高温冷却液存储此处为空--
                        transposer.transferItem(NuclearDirection,RefrigerantDirectionExhausted,1,i,t)  --将高温冷却液移出反应堆--
                        if tp(RefrigerantName,i) then
                            print("成功替换冷却液x1")
                        else
                            k = false 
                            print("缺少冷却液")
                        end
                        break
                    elseif t == transposer.getInventorySize(RefrigerantDirectionExhausted) then  --高温冷却液存储已满--
                        print ("高温冷却液已存满")
                        k = false 
                    end
                    os.sleep(s)
                end
            elseif NuclearItem.label ~= RefrigerantName then  --此处为其他物品--
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                print("反应堆内部摆放错误,错误位置:第"..i.."格")
                k = false
            end
        end
        if Putting[i] == 0 then  --此处应为空--
            
        end
        os.sleep(s)
    end
end

function main()  --主函数--
    while true do
        k = true
        hand()  --检测是否手动开关--
        EnergyReserve = energy_enough()  --检测是否缺电--
        temperature()  --检测反应堆温度是否过高--
        traverse()  --检测反应堆内部物品--
        if k then
            redstone.setOutput(SwitchDirection,1)
            print("运行中...输出功率:"..string.format("%.2f",nuclear.getReactorEUOutput()).."EU/t".."  当前储电量:"..EnergyReserve.."%")
        end
        os.sleep(s)
    end
end



main()  --程序在此处运行--
--[[
IC2强冷核电OC自动化程序
繁星Stars出品
作者博客：https://www.stars22.xyz
此项目Github（使用方法请移至此处）：
https://github.com/Stars-22/GTNH-PowerfulCoolingNuclearReactor
]]--
local component = require("component")
local sides = require("sides")

--以下配置需要根据需求修改--
local redstone = component.redstone  --红石组件("红石I/O端口"/"基础红石卡")--
local transposer = component.transposer  --转运组件("转运器")--
local nuclear = component.reactor_chamber  --核电反应堆组件--
local energy = component.gt_batterybuffer  --能量存储组件--
--数据--
local s = 0.05  --指令中途暂停时间--
local HeatValve = 0.21  --反应堆温度阈值--
local FuelName = "四联燃料棒(钍)"  --燃料名字--
local FuelNameExhausted = "四联燃料棒(枯竭钍)"--枯竭燃料名字--
local RefrigerantName = "360k氦冷却单元" --冷却液名字--
local RefrigerantValve = 0.10  --冷却液耐久阈值--
local EnergyValveMax = 0.98  --能量存储最大值--
local EnergyValveMin = 0.80  --能量存储最小值--
local EnergySize = 16  --能量存储中的格子(装电池)数量(注：此处使用的是GT的电池箱)--
local Putting = { 3,1,2,1,1,2,1,1,2,
                  2,1,1,1,1,2,1,1,1,
                  1,1,1,2,1,1,1,2,1,
                  1,2,1,1,1,2,1,1,1,
                  1,1,1,2,1,1,1,1,2,
                  2,1,1,2,1,1,2,1,3 }  --反应堆摆法(0:空 1:燃料 2:冷却液 3:生产燃料棒(例:GTNH生产阳光化合物))--
--[[方向
注:多个存储可用转运器同一个面(推荐:燃料+枯竭燃料)(也可以使用抽屉管理器)
--绝对方向--
东:sides.east
南:sides.south
西:sides.west
北:sides.north
上:sides.up
下:sides.down
--相对方向--
前:sides.front
后:sides.back
左:sides.left
右:sides.right
上:sides.up
下:sides.down
]]--
--默认参数--
local NuclearDirection = sides.west  --反应堆在转运器的方向(绝对方向)--
local FuelDirection = sides.south  --燃料存储在转运器的方向(绝对方向)--
local FuelDirectionExhausted = sides.south  --枯竭燃料存储在转运器的方向(绝对方向)--
local RefrigerantDirection = sides.down  --冷却液存储在转运器的方向(绝对方向)--
local RefrigerantDirectionExhausted = sides.north  --高温冷却液存储在转运器的方向(绝对方向)--
local ManualDirection = sides.front  --手动控制红石信号在红石接口的方向(从机箱发出红石信号为相对方向,其他为绝对方向)--
local SwitchDirection = sides.back  --反应堆在红石接口的方向(从机箱发出红石信号为相对方向,其他为绝对方向)--
--生产燃料棒参数(例:GTNH生产阳光化合物)--
local switchContinue = false  --原料燃料棒不足、产物燃料棒输出满、此处为其他物品时,是否需要关闭反应堆--
local switchChange = false  --更换或添加生产燃料棒时,是否需要关闭反应堆--
local inFuelDirection = sides.south  --原料燃料棒存储在转运器的方向(绝对方向)--
local outFuelDirection = sides.south  --产物燃料棒存储在转运器的方向(绝对方向)--
local inFuelName = "萤石燃料棒"  --原料燃料棒名字--
local outFuelName = "阳光化合物燃料棒"--产物燃料棒名字--
--以上配置需要根据需求修改--

function tp(inName, location, inDirection)  --函数:添加物品--
    for i=1,transposer.getInventorySize(inDirection) do  --遍历输入存储--
        if transposer.getStackInSlot(inDirection,i) == nil then
        elseif transposer.getStackInSlot(inDirection,i).label == inName then
            if transposer.transferItem(inDirection,NuclearDirection,1,i,location) then  --转运--
                return true  --转运成功--
            else
                return false  --转运失败--
            end
        end
        if i == transposer.getInventorySize(inDirection) then
            return false  --输入不足--
        end
        os.sleep(s)
    end
    return false  --转运失败--
end

function hand()  --检测是否手动开关--
    while redstone.getInput(ManualDirection) == 0 do
        redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
        print("已手动关闭,等待开启...")
        os.sleep(0.5)  --暂停0.5秒--
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
                if tp(FuelName,i,FuelDirection) then
                    print("成功添加燃料x1")
                else
                    print("缺少燃料")
                    return false
                end
            elseif NuclearItem.label == FuelNameExhausted then  --此处为枯竭燃料--
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                for t=1,transposer.getInventorySize(FuelDirectionExhausted) do  --遍历枯竭燃料存储--
                    FuelItem = transposer.getStackInSlot(FuelDirectionExhausted,t)
                    if  FuelItem == nil then --枯竭燃料存储此处为空--
                        transposer.transferItem(NuclearDirection,FuelDirectionExhausted,1,i,t)  --将枯竭燃料移出反应堆--
                        if tp(FuelName,i,FuelDirection) then
                            print("成功替换燃料x1")
                        else
                            print("缺少燃料")
                            return false
                        end
                        break
                    elseif FuelItem.label == FuelNameExhausted and FuelItem.size < FuelItem.maxSize then  --此处为未堆满的枯竭燃料--
                        transposer.transferItem(NuclearDirection,FuelDirectionExhausted,1,i,t)  --将枯竭燃料移出反应堆--
                        if tp(FuelName,i,FuelDirection) then
                            print("成功替换燃料x1")
                        else
                            print("缺少燃料")
                            return false
                        end
                        break
                    elseif t == transposer.getInventorySize(FuelDirectionExhausted) then  --枯竭燃料存储已满--
                        print ("枯竭燃料已存满")
                        return false
                    end
                    os.sleep(s)
                end
            elseif NuclearItem.label ~= FuelName then  --此处为其他物品--
                print("反应堆内部摆放错误,错误位置:第"..i.."格")
                return false
            end
        end
        if Putting[i] == 2 then  --此处应放冷却液--
            NuclearItem = transposer.getStackInSlot(NuclearDirection,i)
            if NuclearItem == nil then  --此处为空--
                os.sleep(s)
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                os.sleep(0.4)
                if tp(RefrigerantName,i,RefrigerantDirection) then
                    print("成功添加冷却液x1")
                else
                    print("缺少冷却液")
                    return false
                end
            elseif NuclearItem.label == RefrigerantName and (NuclearItem.maxDamage-NuclearItem.damage)/NuclearItem.maxDamage <= RefrigerantValve then  --此处为高温冷却液--
                os.sleep(s)
                redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                os.sleep(0.4)
                for t=1,transposer.getInventorySize(RefrigerantDirectionExhausted) do  --遍历高温冷却液存储--
                    RefrigerantItem = transposer.getStackInSlot(RefrigerantDirectionExhausted,t)
                    if  RefrigerantItem == nil then --高温冷却液存储此处为空--
                        transposer.transferItem(NuclearDirection,RefrigerantDirectionExhausted,1,i,t)  --将高温冷却液移出反应堆--
                        if tp(RefrigerantName,i,RefrigerantDirection) then
                            print("成功替换冷却液x1")
                        else
                            print("缺少冷却液")
                            return false
                        end
                        break
                    elseif t == transposer.getInventorySize(RefrigerantDirectionExhausted) then  --高温冷却液存储已满--
                        print ("高温冷却液已存满")
                        return false
                    end
                    os.sleep(s)
                end
            elseif NuclearItem.label ~= RefrigerantName then  --此处为其他物品--
                print("反应堆内部摆放错误,错误位置:第"..i.."格")
                return false
            end
        end
        if Putting[i] == 3 then  --此处应为生产燃料棒--
            NuclearItem = transposer.getStackInSlot(NuclearDirection,i)
            if NuclearItem == nil then  --此处为空--
                if switchChange then
                    redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                end
                if tp(inFuelName,i,inFuelDirection) then
                    print("成功添加原料燃料棒x1")
                elseif switchContinue then
                    if switchContinue then
                        print("缺少原料燃料棒")
                        return false
                    end
                end
            elseif NuclearItem.label == outFuelName then  --此处为产物燃料棒--
                if switchChange then
                    redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
                end
                for t=1,transposer.getInventorySize(outFuelDirection) do  --遍历产物燃料棒存储--
                    FuelItem = transposer.getStackInSlot(outFuelDirection,t)
                    if  FuelItem == nil then --产物燃料棒存储此处为空--
                        transposer.transferItem(NuclearDirection,outFuelDirection,1,i,t)  --将产物燃料棒移出反应堆--
                        if tp(inFuelName,i,inFuelDirection) then
                            print("成功替换原料燃料棒x1")
                        else
                            if switchContinue then
                                print("缺少原料燃料棒")
                                return false
                            end
                        end
                        break
                    elseif FuelItem.label == outFuelName and FuelItem.size < FuelItem.maxSize then  --此处为未堆满的产物燃料棒--
                        transposer.transferItem(NuclearDirection,outFuelDirection,1,i,t)  --将枯竭燃料移出反应堆--
                        if tp(inFuelName,i,inFuelDirection) then
                            print("成功替换原料燃料棒x1")
                        else
                            if switchContinue then
                                print("缺少原料燃料棒")
                                return false
                            end
                        end
                        break
                    elseif t == transposer.getInventorySize(FuelDirectionExhausted) then  --枯竭燃料存储已满--
                        print ("产物燃料棒已存满")
                        if switchContinue then
                            return false
                        end
                    end
                    os.sleep(s)
                end
            elseif NuclearItem.label ~= inFuelName then  --此处为其他物品--
                print("反应堆内部摆放错误,错误位置:第"..i.."格")
                if switchContinue then
                    return false
                end
            end
        end
        if Putting[i] == 0 then  --此处应为空--

        end
        os.sleep(s)
    end
    return true
end

function main()  --主函数--
    while true do
        hand()  --检测是否手动开关--
        EnergyReserve = energy_enough()  --检测是否缺电--
        temperature()  --检测反应堆温度是否过高--
        --检测反应堆内部物品--
        if traverse() then
            redstone.setOutput(SwitchDirection,1)
            print("运行中...输出功率:"..string.format("%.2f",nuclear.getReactorEUOutput()).."EU/t".."  当前储电量:"..EnergyReserve.."%")
        
        else
            redstone.setOutput(SwitchDirection,0)  --关闭反应堆--
        end
        os.sleep(s)
    end
end

main()  --程序在此处运行--
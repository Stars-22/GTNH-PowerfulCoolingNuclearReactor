# GTNH强冷核电OC自动化-2.0.0

本程序由繁星制作，本程序将使用OpenComputer(开放式电脑)模组实现GTNH IC2强冷核电自动化<br>
注：请保证核电以及OC设备保持区块加载，否则核电将为核弹！！！

## 索引
- [GTNH强冷核电OC自动化-2.0.0](#gtnh强冷核电oc自动化-200)
    - [索引](#索引)
    - [材料](#材料)
    - [用法](#用法)
        - [使用因特网卡](#使用因特网卡)
        - [使用复制粘贴](#使用复制粘贴)
    - [样例](#样例)
    - [Release Notes](#release-notes)
        - [1.0.0](#100)
        - [2.0.0](#200)
    - [贡献](#贡献)

## 材料

1. 核电一套<br>
2. OC电脑一套（最低T1配置即可）<br>
3. 红石I/O端口/基础红石卡 x1 （样例为基础红石卡）<br>
4. 转运器 x1<br>
5. 适配器 x1 （用扳手关闭不需要的面，只需一面连接反应堆即可，否则可能会显示组件过多）<br>
6. 箱子（建议x3）<br>
7. 拉杆 x1<br>
8. 能量转换器（可选）

## 用法

### 使用因特网卡

1. ```wget https://github.com/Stars-22/GTNH-PowerfulCoolingNuclearReactor/raw/main/IC2_FuckCoolingNuclear.lua```<br>
2. ```edit IC2_FuckCoolingNuclear.lua```<br>
3. 修改配置

### 使用复制粘贴

1. ```edit IC2_FuckCoolingNuclear.lua```<br>
2. 在GitHub中复制 IC2_FuckCoolingNuclear.lua （每次复制，复制200行）
3. 在编辑器中进行粘贴<br>
4. 修改配置

## 样例
![](https://github.com/Stars-22/GTNH-PowerfulCoolingNuclearReactor/blob/main/picture/1.png)
![](https://github.com/Stars-22/GTNH-PowerfulCoolingNuclearReactor/blob/main/picture/2.png)
![](https://github.com/Stars-22/GTNH-PowerfulCoolingNuclearReactor/blob/main/picture/3.png)

## Release Notes

#### 1.0.0
1. GTNH强冷核电OC自动化基本完工

#### 2.0.0
1. 修复了反应堆开启时，冷却单元不足时与产物存储存满时，无法及时关闭反应堆而导致堆温上升的问题
2. 修复了一些注释错误的问题
3. 优化了一些逻辑上问题
4. 添加了对GTNH萤石燃料棒自动化的支持

## 贡献
0. 本说明最后一次修改于2024-01-06<br>
1. [繁星Stars](https://github.com/Stars-22 "https://github.com/Stars-22")


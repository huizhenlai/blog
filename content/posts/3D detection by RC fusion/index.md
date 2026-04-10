---
title: "3D detection by RC fusion"
summary: A survey about 3D detction.
date: 2025-03-25
draft: false
weight: 1
tags: [Camera ,Mmware Radar, Fusion]  # 标签，可以是多个
author: "lhz"  # 作者
math: true
series: ["传感器融合"]
featured: true
hideTitle: true
---

# 3D detection by RC fusion

开宗明义，我需要实现**基于毫米波雷达和视觉的3D目标检测**，其中主要是需要获取目标的**类别、位置、尺寸、速度**，在此基础上，结合车道线检测和自测速，形成一个较为完备的自动驾驶环境感知系统。

其中主要的难题在于，雷达的点云过于稀疏，雷达和摄像头的位置较准，和边缘计算部署的算力压力。

主要的数据集还是nuScenes



几篇综述：

1. 3D Object Detection for Autonomous Driving: A Comprehensive Survey （比较新，全面）
2. A Survey on 3D Object Detection Methods for Autonomous Driving Applications （TITS）
3. Multi-Modal 3D Object Detection in Autonomous Driving: a Survey （TIV，专注多模态融合）
4. [[radar-camera-fusion.github.io](https://radar-camera-fusion.github.io/)](https://github.com/Radar-Camera-Fusion/Awesome-Radar-Camera-Fusion)
5. [Charles R. Qi](https://charlesrqi.com/) 的工作


|          Methods          |                       works                       |
| :-----------------------: | :-----------------------------------------------: |
|       Image -Driven       | Monocular view detectors, Frustum-based detectors |
|    Dimension reduction    |             Bird’s eye view detectors             |
| Leveraging Sparsity in 3D |     Point set deep net, Sparse 3D conv, GNNs      |



毫米波雷达的优势在于距离远，能测速，在全天时全天候场景中拥有鲁棒性，但是分辨率低。

视觉能够获取外观信息，但无法直接获得场景的3D结构信息，对天气和环境敏感。



几个方案：

1. 借鉴Lidar的方案
2. 看nuScenes中camera + radar的方案（不多）



# Radar and Camera Fusion for Object Detection and Tracking: A Comprehensive Survey
## Where  to fusion

1. 前视图融合 (Front View, FV)

   1. 雷达投影附近的FV图像上生成ROI，只在ROI中进行特征提取和后处理。
   2. 雷达数据投影到相机的透视平面，创建雷达伪图像，然后再和图像一起进行特征提取和处理。

2. 鸟瞰图融合 (Bird's-Eye View, BEV) -> 有效解决遮挡，保留雷达信息（天然适合BEV）

   1. 雷达 -> BEV : 离散化，形成voxel或者grid

   2. 视觉 -> BEV : 比较麻烦，单目转深度图

      * 反向投影映射 (Iverse Projection Mapping，IPM)
      * Lift-Solat-Shoot (LSS) 方法

      

## When to fusion

|                       分类                       |            对象            |                优势                |            劣势            |
| :----------------------------------------------: | :------------------------: | :--------------------------------: | :------------------------: |
|          data-level (**early fusion**)           |  原始数据或预处理数据融合  |              信息全面              |     数据量大，时空开销     |
|        feature-level (**middle fusion**)         |     单独提取的特征融合     | 数据压缩，适合深度学习方案，鲁棒性 |     正在探索，资料不多     |
| decision-level (object-level or **late fusion**) | 独立处理特征输出决策再融合 |      灵活的模块化结构和低开销      | 异构数据融合困难，难以纠错 |



###  Late fusion

1. 基于相似性评估，采用卡尔曼/贝叶斯/匈牙利进行匹配 -> 各自输出目标信息，再通过相似性匹配算法判断和融合 -> 适合MOT
2. 通过坐标转换矩阵协调位置关系



RODNet: Radar Object Detection using Cross-Modal Supervision : RA heatmap + Image detection heatmap







### 关键问题

1. Sensor Calibration
2. Modal Fusion Representation
3. Data Alignment
4. Fusion Operation





## Image-driven

Key idea: 

* Leveraging mature 2D detectors for region proposal. greatly reducing 3D search space. 

* 3D deep learning for accurate object localization in frustum point clouds.



## nuScenes 

[Object detection task - nuScenes](https://www.nuscenes.org/object-detection?externalData=all&mapData=all&modalities=Camera%2C Radar) 

Camera +  Radar methods

文件组织：

```bash
mini/
   ├── maps/				# 地图
   │   └── xxx.png
   ├── samples/             #采样数据
   │   ├── 6个相机
   │   ├── 5个毫米波雷达
   │   └── 1个激光雷达
   ├── sweeps/              #未被采样数据
   │   └── ...
   ├── v1.0-mini/              # 
   │   └── ...
   └── requirements.txt

```





## MV3D

Multi-View 3D Object Detection Network for Autonomous Driving



应该做成BEV的情况

融合时需要处理特征图之间的空间错位



**Point-based 3D perception**

尽管雷达点云[2，50]与激光雷达相似的数据表示，但基于雷达点的3D感知的研究较少。几项作品[56，69，81]检查了自由空间检测的雷达点，但只有少数研究[71，75]尝试在自主驾驶中进行3D对象检测。基于雷达点的检测方法将Pointpillars [29]与图神经网络[66]或KPCONV [72]相适应，重点是提取更好的局部特征。



**Camera-Point 3D Perception**

两个传感器之间的视图差异被认为是多模式融合的瓶颈。通过将3D信息投影到2D图像（例如，点[6，77，82]，提案[1，26，28]或预测结果[52]）并收集周围预测区域的信息来处理差异。一些摄像机雷达融合方法[38，46]试图通过将雷达点投影到图像来提高深度估计。

多亏了单眼BEV方法的进步，最近的融合方法提取了统一BEV空间中的图像和点特征图，然后通过元素串联串联[45]或Sumpation [34]融合特征图，假设多模式特征映射在空间上很好地排列。

之后，Fused BEV特征图用于各种感知任务，例如3D检测[12,34,37,85]，BEV分割[45，88]或HD MAP生成[11，32]。然而，尽管相机具有独特的特征（例如，不准确的BEV转换）和雷达（例如稀疏和歧义），但以前的摄像机雷达融合却较少考虑它们。我们提出的CRN专注于融合多模式特征图，考虑到每个传感器的特征，以彻底拥有两全其美的特征。



Depth Estimation from Monocular Images and Sparse Radar Data 

用雷达和视觉融合生成类似于深度图。

[brade31919/radar_depth: Source code of the IROS 2020 paper "Depth Estimation from Monocular Images and Sparse Radar Data"](https://github.com/brade31919/radar_depth)



BEVFormer 南大&上海AI实验室 ： 纯视觉生成BEV

VPN：Cross-view Semantic Segmentation for Sensing Surroundings  https://github.com/pbw-Berwin/View-Parsing-Network


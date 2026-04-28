---
title: "Object detection data format"
summary: Describe the object detection data fomrat such as YOLO, COCO and VOC
date: 2025-03-17
draft: false 
weight: 10
tags: ["Object Detetion"]  # 标签，可以是多个
categories: ["Tutorials"]  # 分类
series: ["传感器融合"]
author: "lhz"  # 作者
hideTitle: true
---

# Object Detection Data Format

三个类型: YOLO、COCO、VOC

## 数据解释

### YOLO

数据格式：

```.
.
└── yolo_dataset            #根目录
    └── train
    │   ├── images
    │   └── labels
    └── val
    │   ├── images  
 	│ 	└── labels 
    └── test
        ├── images
        └── labels         
```

预先划分训练集、验证集和测试集

以训练集为例

```
.
└── yolo_dataset            #根目录
    └── train
        ├── images
        │	├─ 0000001.jpg
      	│	├─ 0000002.jpg
      	│	├─ 0000003.jpg
     	│	├─ 0000004.jpg
     	│	└─ ...
        └── labels
        	├─ 0000001.txt
      		├─ 0000002.txt
      		├─ 0000003.txt
     		├─ 0000004.txt
     		└─ ...

```

图片名字与标签名字一一对应，标签使用txt文本保存。


#### 检测任务

yolo标注格式如下所示：

```json
<object-class> <x> <y> <width> <height>
```

例如：

```
0 0.412500 0.318981 0.358333 0.636111
1 0.325002 0.123981 0.323113 0.231231
...
```

多行代表多个目标

\<object-class> ：对象的标签索引，整数
x, y:  目标的 **中心坐标**，相对于图片的W和H做归一化，即 x/W，y/H。
width, height : 目标（bbox）的宽和高，相对于图像的 W 和 H 做归一化。

(x,y,w,h) 数据均 $[0.0,1.0]$ 区间



#### 分割任务

```
<class-index> <x1> <y1> <x2> <y2> ... <xn> <yn>
```

其中`<x1> <y1> <x2> <y2> ... <xn> <yn>` 为对象分割掩码的边界坐标，坐标由空格分隔。

对于分割任务而言，最少也需要三个坐标对 \<xn> \<yn>，则分割实际上就是由多边形进行标注，同样的多行代表多个实例。

```
0 0.681 0.485 0.670 0.487 0.676 0.487
1 0.504 0.000 0.501 0.004 0.498 0.004 0.493 0.010 0.492 0.0104
```

#### 外部配置

YAML文件用于定义数据集配置，

```yaml
path: ../datasets # dataset root dir
train: train/images # 只需要指定图片即可，labels不指定，（待进一步了解）
val: val/images 
test: test/images 

# Classes
names:
  0: person
  1: bicycle
  2: car
  3: motorcycle
  4: airplane
  5: bus
  6: train
  7: truck
```

### VOC

```f
VOC
├─Annotations
│      ├─img0001.xml
│      ├─img0002.xml
│      ├─img0003.xml
│      └─ ...
├─ImageSets
│  └─Main
│      ├─train.txt
│      ├─test.txt
│      └─val.txt
│
└─JPEGImages
        ├─img0001.jpg
        ├─img0002.jpg
        ├─img0003.jpg
        └─ ...
```

在 train.txt , test.txt 和 val.txt 中指定image的路径和名字。

```xml
<annotation>
  <folder>17</folder> # 图片所处文件夹
  <filename>77258.bmp</filename> # 图片名
  <path>~/frcnn-image/61/ADAS/image/frcnn-image/17/77258.bmp</path>
  <source>  #图片来源相关信息
    <database>Unknown</database>  
  </source>
  <size> #图片尺寸
    <width>640</width>
    <height>480</height>
    <depth>3</depth>
  </size>
  <segmented>0</segmented>  #是否有分割label
  <object> 包含的物体
    <name>car</name>  #物体类别
    <pose>Unspecified</pose>  #物体的姿态
    <truncated>0</truncated>  #物体是否被部分遮挡（>15%）
    <difficult>0</difficult>  #是否为难以辨识的物体， 主要指要结体背景才能判断出类别的物体。虽有标注， 但一般忽略这类物体
    <bndbox>  #物体的bound box
      <xmin>2</xmin>     #左
      <ymin>156</ymin>   #上
      <xmax>111</xmax>   #右
      <ymax>259</ymax>   #下
    </bndbox>
  </object>
</annotation>
```

bndbox中的数据 (xmin,ymin, xmax, ymax)，分别为bbox的左上角和右下角坐标。

### COCO

与其他两个格式的一个图片一个标注文件不同，COCO所有的目标边界框标注都在一个 json文件中，实质上是一个字典。

```json
{
  "info": info, 
  "images": [image], 
  "annotations": [annotation], 
  "categories": [categories],
  "licenses": [license],
}
```

其中 lincenses 和 info 可以不需要，主要为协议和描述信息

`categories`表示所有的类别，格式如下：

```json
"categories": 
 [
     {"id": 1, "name": "grader", "color": "#94563B", "supercategory": "none"}, 
     {"id": 2, "name": "cement_truck", "color": "#0B8372", "supercategory": "none"}, 
     {"id": 3, "name": "mobile_crane", "color": "#7DE7CC", "supercategory": "none"},
     {"id": 5, "name": "dump_truck", "color": "#7539F5", "supercategory": "none"}, 
     {"id": 6, "name": "concrete_mixer_truck", "color": "#DD6108", "supercategory": "none"}, 
     {"id": 7, "name": "wheel_loader", "color": "#EE0641", "supercategory": "none"}, 
     {"id": 8, "name": "compactor", "color": "#44013F", "supercategory": "none"}, 
     {"id": 9, "name": "dozer", "color": "#ADCCE8", "supercategory": "none"},
     {"id": 10, "name": "excavator", "color": "#54D31E", "supercategory": "none"},
     {"id": 11, "name": "backhoe_loader", "color": "#8D90CF", "supercategory": "none"},
     {"id": 12, "name": "tower_crane", "color": "#E43A74", "supercategory": "none"}
 ]
```

其中 supercategory 为大类，例如划分机动车、非机动车，再细分轿车、SUV之类。



`annotations` 为标注信息 

```json
"annotations":
[
    {'segmentation': [[0, 0, 60, 0, 60, 40, 0, 40]],
     'area': 240.000,
     'iscrowd': 0,
     'image_id': 289343,
     'bbox': [0., 0., 60., 40.],
     'category_id': 18,
     'id': 1768
     }
 ...
]
```

`segmentation` 为分割的多边形，



`image` 为图片信息，主要存放图片路径和ID，还包括图片尺寸

```json
"images":
[
    {
      'license': 4,
      'file_name': '000000397133.jpg',
      'coco_url': 'http://images.cocodataset.org/val2017/000000397133.jpg',
      'height': 427,
      'width': 640,
      'date_captured': '2013-11-14 17:02:52',
      'flickr_url': 'http://farm7.staticflickr.com/6116/6255196340_da26cf2c9e_z.jpg',
      'id': 397133
      }
   ...
]
```



## 类型转换

### COCO 2 YOLO

ultralytics自带函数进行JSON2YOLO

```python
from ultralytics.data.converter import convert_coco
convert_coco(labels_dir = "path/COCO_labels",use_segments = True, cls91to80 = False)
```

该函数

```python
convert_coco(
    labels_dir="../coco/annotations/",
    save_dir="coco_converted/",
    use_segments=False,
    use_keypoints=False,
    cls91to80=True,
    lvis=False,
)
```

cls91to80参数的默认打开的，对于其他的数据集要关掉？

不关似乎会报错（未验证）



### VOC 2 YOLO

```python
import xml.etree.ElementTree as ET
import os

def convert_voc_to_yolo(voc_path, yolo_path, classes):
    if not os.path.exists(yolo_path):
        os.makedirs(yolo_path)

    for xml_file in os.listdir(voc_path):
        if xml_file.endswith('.xml'):
            tree = ET.parse(os.path.join(voc_path, xml_file))
            root = tree.getroot()

            img_width = int(root.find('size/width').text)
            img_height = int(root.find('size/height').text)

            yolo_file = os.path.join(yolo_path, xml_file.replace('.xml', '.txt'))
            with open(yolo_file, 'w') as f:
                for obj in root.findall('object'):
                    class_name = obj.find('name').text
                    if class_name in classes:
                        class_id = classes.index(class_name)

                        bbox = obj.find('bndbox')
                        x_min = int(bbox.find('xmin').text)
                        y_min = int(bbox.find('ymin').text)
                        x_max = int(bbox.find('xmax').text)
                        y_max = int(bbox.find('ymax').text)

                        x_center = (x_min + x_max) / 2 / img_width
                        y_center = (y_min + y_max) / 2 / img_height
                        width = (x_max - x_min) / img_width
                        height = (y_max - y_min) / img_height

                        f.write(f"{class_id} {x_center} {y_center} {width} {height}\n")

# 使用示例
voc_path = 'path/to/voc/annotations'
yolo_path = 'path/to/yolo/annotations'
classes = ['class1', 'class2', 'class3']  # 自定义类别

convert_voc_to_yolo(voc_path, yolo_path, classes)
```

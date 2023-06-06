#导入功能模块
import numpy as np #是Python数值计算的扩展，专门用来处理矩阵
import pandas as pd #pandas是基于numpy的数据分析工具，能方便的操作大型数据集
import matplotlib.pyplot as plt

#rand 生成均匀分布的伪随机数。分布在（0~1）之间
#主要语法：rand(m,n)生成m行n列的均匀分布的伪随机数，
# rand(m,n,'double')生成指定精度的均匀分布的伪随机数，
# 参数还可以是'single'， 
#  rand(RandStream,m,n)利用指定的RandStream(我理解为随机种子)生成伪随机数。

#randn 生成标准正态分布的伪随机数（均值为0，方差为1）

#显示图表窗口
# plt.plot(np.random.rand(10))
# plt.show()

# #图表窗口2  魔法函数，嵌入图表

# x = np.random.randn(1000)  #生成标准正态分布伪随机数
# y = np.random.randn(1000)
# plt.scatter(x,y)

# s = pd.Series(np.random.randn(100))
# s.plot(style = 'k--o',figsize=(10,5))

# plt.show()

df = pd.DataFrame(np.random.randn(1000,2),columns=['A','B'])
df.hist(figsize=(12,5),color = 'g',alpha = 0.8)

plt.show()
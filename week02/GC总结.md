# 理论总结
## 串行GC (Serial GC)
-XX:+UseSerialGC\
年轻代-标记复制算法，老年代-标记清除整理算法\
单线程，会触发STW \
无法充分利用多核CPU，只是用单核，利用率高，暂停时间长，适合1G以内单核CPU的JVM，不适合多核、高并发场景\
## 并行GC (Parallel GC)
-XX:+UseParallelGC\
年轻代-标记复制算法，老年代-标记清除整理算法\
多线程，会触发STW\
GC线程数由-XX：ParallelGCThreads指定，默认为CPU核数\
适用于多核CPU，主要目标使增加吞吐量\
## CMS GC（Mostly Concurrent Mark and Sweep Garbage Collector）
-XX:+UseConcMarkSweepGC\
年轻代-并行标记复制算法，老年代-并发标记清除算法\
目标是避免在老年代垃圾收集时出现长时间的卡顿，主要通过两种手段来达成此目标：\
1.不对老年代进行整理，而是使用空闲列表（free-lists）来管理内存空间的回收。\
2.在 mark-and-sweep （标记-清除）阶段的大部分工作和应用线程一起并发执行。\
默认GC线程数为CPU核数的1/4 \
CMS的六个阶段：
1. Initial Mark（初始标记）
   标记所有的根对象，包括根对象直接引用的对象，以及被年轻代中所有存活对象所引用的对象（老年代单独回收）。会触发STW。
2. Concurrent Mark（并发标记）
   遍历老年代，标记所有的存活对象，从前一阶段 “Initial Mark”找到的根对象开始算起。与业务程序并发运行。
3. Concurrent Preclean（并发预清理）
   因为前一阶段与程序并发运行，可能有一些引用关系已经发生了改变。如果在并发标记过程中引用关系发生了变化，JVM会通过“Card（卡片）”的方式将发生了改变的区域标记为“脏”区，即卡片标记（Card Marking）。与业务线程并发运行。
4. 完成老年代中所有存活对象的标记。会触发STW。
5. Concurrent Sweep（并发清除）
   删除不再使用的对象，并回收内存空间。与业务线程并发运行。
6. Concurrent Reset（并发重置）
   重置 CMS 算法相关的内部数据，为下一次 GC 循环做准备。与业务线程并发运行。

## G1 GC (Garbage First)
设计目标是：将 STW 停顿的时间和分布，变成可预期且可配置的\
堆不再分成年轻代和老年代，而是划分为多个（通常是2048个）可以存放对象的小块堆区域(smaller heap regions)。每个小块，可能一会被定义成 Eden区，一会被指定为 Survivor区或者Old 区。在逻辑上，所有的 Eden 区和 Survivor 区合起来就是年轻代，所有的 Old 区拼在一起那就是老年代。\
每次 GC 暂停都会收集所有年轻代的内存块，但一般只包含部分老年代的内存块 \
在并发阶段估算每个小堆块存活对象的总数。构建回收集的原则是：垃圾最多的小块会被优先收集。这也是 G1 名称的由来。\




# 代码执行分析
代码使用老师的GCLogAnalysis 

首先指定堆内存1g 
```
java -Xmx1g -Xms1g -XX:+PrintGCDetails GCLogAnalysis
``` 

输出结果
```
正在执行...
[GC (Allocation Failure) [DefNew: 279568K->34944K(314560K), 0.0555188 secs] 279568K->89925K(1013632K), 0.0557432 secs] [Times: user=0.03 sys=0.03, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 314527K->34943K(314560K), 0.0659599 secs] 369509K->163247K(1013632K), 0.0661614 secs] [Times: user=0.02 sys=0.05, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 314559K->34941K(314560K), 0.0571115 secs] 442863K->238207K(1013632K), 0.0573845 secs] [Times: user=0.03 sys=0.03, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 314557K->34943K(314560K), 0.0562188 secs] 517823K->312730K(1013632K), 0.0564536 secs] [Times: user=0.03 sys=0.03, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 314559K->34943K(314560K), 0.0573447 secs] 592346K->389305K(1013632K), 0.0575581 secs] [Times: user=0.05 sys=0.01, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 314219K->34944K(314560K), 0.0625807 secs] 668581K->474992K(1013632K), 0.0628087 secs] [Times: user=0.02 sys=0.03, real=0.06 secs]
执行结束!共生成对象次数:6273
Heap
 def new generation   total 314560K, used 46525K [0x05000000, 0x1a550000, 0x1a550000)
  eden space 279616K,   4% used [0x05000000, 0x05b4f508, 0x16110000)
  from space 34944K, 100% used [0x16110000, 0x18330000, 0x18330000)
  to   space 34944K,   0% used [0x18330000, 0x18330000, 0x1a550000)
 tenured generation   total 699072K, used 440048K [0x1a550000, 0x45000000, 0x45000000)
   the space 699072K,  62% used [0x1a550000, 0x3530c0c0, 0x3530c200, 0x45000000)
 Metaspace       used 1715K, capacity 2244K, committed 2368K, reserved 4480K
 ```
 
 根据第一行输出\
 ```[GC (Allocation Failure) [DefNew: 279568K->34944K(314560K), 0.0555188 secs] 279568K->89925K(1013632K), 0.0557432 secs] [Times: user=0.03 sys=0.03, real=0.06 secs]```\
 可知young区共有307m，使用量由273m减到了34m，减少了239m；\
 堆内存整体共有989m，使用量由273m减到了87m，减少了186m。\
 这说明初始状态下old区使用量为0，young区减少量大于堆内存总体减少量，相差的53m去了old区。\
 共执行了6次young gc。
 

 再次运行程序，指定堆内存256m\
 ```java -Xmx256m -Xms256m -XX:+PrintGCDetails GCLogAnalysis```\
 输出结果
 ```
 正在执行...
[GC (Allocation Failure) [DefNew: 69924K->8704K(78656K), 0.0147974 secs] 69924K->22426K(253440K), 0.0150289 secs] [Times: user=0.00 sys=0.01, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78656K->8701K(78656K), 0.0191552 secs] 92378K->43289K(253440K), 0.0194649 secs] [Times: user=0.01 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78020K->8702K(78656K), 0.0172039 secs] 112608K->64734K(253440K), 0.0174571 secs] [Times: user=0.00 sys=0.02, real=0.01 secs]
[GC (Allocation Failure) [DefNew: 78654K->8703K(78656K), 0.0190505 secs] 134686K->88347K(253440K), 0.0192653 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78655K->8703K(78656K), 0.0230459 secs] 158299K->115352K(253440K), 0.0232957 secs] [Times: user=0.02 sys=0.01, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78655K->8703K(78656K), 0.0227337 secs] 185304K->140735K(253440K), 0.0229556 secs] [Times: user=0.02 sys=0.02, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78435K->8701K(78656K), 0.0192787 secs] 210466K->164141K(253440K), 0.0194872 secs] [Times: user=0.02 sys=0.02, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78653K->78653K(78656K), 0.0003891 secs][Tenured: 155440K->169644K(174784K), 0.0517020 secs] 234093K->169644K(253440K), [Metaspace: 99K->99K(4480K)], 0.0536462 secs] [Times: user=0.05 sys=0.02, real=0.05 secs]
[GC (Allocation Failure) [DefNew: 69952K->69952K(78656K), 0.0001155 secs][Tenured: 169644K->174780K(174784K), 0.0541242 secs] 239596K->182262K(253440K), [Metaspace: 99K->99K(4480K)], 0.0553921 secs] [Times: user=0.05 sys=0.02, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174780K->174773K(174784K), 0.0560811 secs] 253419K->196948K(253440K), [Metaspace: 99K->99K(4480K)], 0.0570735 secs] [Times: user=0.05 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174773K->174497K(174784K), 0.0646572 secs] 253379K->201336K(253440K), [Metaspace: 99K->99K(4480K)], 0.0658986 secs] [Times: user=0.06 sys=0.00, real=0.07 secs]
[Full GC (Allocation Failure) [Tenured: 174540K->174540K(174784K), 0.0130168 secs] 253173K->214992K(253440K), [Metaspace: 99K->99K(4480K)], 0.0140750 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 174756K->174563K(174784K), 0.0282210 secs] 253384K->225011K(253440K), [Metaspace: 99K->99K(4480K)], 0.0296969 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
[Full GC (Allocation Failure) [Tenured: 174563K->174656K(174784K), 0.0392122 secs] 252475K->226813K(253440K), [Metaspace: 99K->99K(4480K)], 0.0405595 secs] [Times: user=0.03 sys=0.00, real=0.04 secs]
[Full GC (Allocation Failure) [Tenured: 174656K->174687K(174784K), 0.0585773 secs] 253110K->224055K(253440K), [Metaspace: 99K->99K(4480K)], 0.0595144 secs] [Times: user=0.06 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174687K->174687K(174784K), 0.0109159 secs] 253262K->236083K(253440K), [Metaspace: 99K->99K(4480K)], 0.0119322 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 174687K->174704K(174784K), 0.0173439 secs] 252870K->239362K(253440K), [Metaspace: 99K->99K(4480K)], 0.0185242 secs] [Times: user=0.03 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 174704K->174714K(174784K), 0.0220015 secs] 253338K->240895K(253440K), [Metaspace: 99K->99K(4480K)], 0.0230438 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 174714K->174558K(174784K), 0.0416018 secs] 253239K->235570K(253440K), [Metaspace: 99K->99K(4480K)], 0.0424743 secs] [Times: user=0.03 sys=0.00, real=0.04 secs]
[Full GC (Allocation Failure) [Tenured: 174558K->174558K(174784K), 0.0107442 secs] 253051K->240479K(253440K), [Metaspace: 99K->99K(4480K)], 0.0111652 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
执行结束!共生成对象次数:3684
Heap
 def new generation   total 78656K, used 68225K [0x04c00000, 0x0a150000, 0x0a150000)
  eden space 69952K,  97% used [0x04c00000, 0x08ea0528, 0x09050000)
  from space 8704K,   0% used [0x098d0000, 0x098d0000, 0x0a150000)
  to   space 8704K,   0% used [0x09050000, 0x09050000, 0x098d0000)
 tenured generation   total 174784K, used 174558K [0x0a150000, 0x14c00000, 0x14c00000)
   the space 174784K,  99% used [0x0a150000, 0x14bc7a80, 0x14bc7c00, 0x14c00000)
 Metaspace       used 99K, capacity 2244K, committed 2368K, reserved 4480K
 ``` 
 
 在发生了9次young gc后，发生了11次full gc。
 
 
 再次运行程序，指定堆内存128m\
 ```java -Xmx128m -Xms128m -XX:+PrintGCDetails GCLogAnalysis```\
 输出结果
```
正在执行...
[GC (Allocation Failure) [DefNew: 34935K->4352K(39296K), 0.0103308 secs] 34935K->12235K(126720K), 0.0105831 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [DefNew: 39167K->4349K(39296K), 0.0161916 secs] 47051K->26107K(126720K), 0.0163268 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [DefNew: 39293K->4346K(39296K), 0.0161594 secs] 61051K->42854K(126720K), 0.0163431 secs] [Times: user=0.00 sys=0.02, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 39098K->4350K(39296K), 0.0113078 secs] 77606K->53294K(126720K), 0.0115117 secs] [Times: user=0.00 sys=0.02, real=0.01 secs]
[GC (Allocation Failure) [DefNew: 39294K->4351K(39296K), 0.0101838 secs] 88238K->63333K(126720K), 0.0107149 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [DefNew: 39295K->4348K(39296K), 0.0106279 secs] 98277K->74558K(126720K), 0.0108018 secs] [Times: user=0.00 sys=0.01, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 39292K->4338K(39296K), 0.0124098 secs] 109502K->89870K(126720K), 0.0126642 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 39268K->39268K(39296K), 0.0000875 secs][Tenured: 85532K->86945K(87424K), 0.0247121 secs] 124800K->93229K(126720K), [Metaspace: 99K->99K(4480K)], 0.0250990 secs] [Times: user=0.01 sys=0.02, real=0.03 secs]
[Full GC (Allocation Failure) [Tenured: 87418K->87129K(87424K), 0.0165460 secs] 126711K->101721K(126720K), [Metaspace: 99K->99K(4480K)], 0.0169678 secs] [Times: user=0.01 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87129K->87140K(87424K), 0.0244423 secs] 126282K->109186K(126720K), [Metaspace: 99K->99K(4480K)], 0.0247434 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
[Full GC (Allocation Failure) [Tenured: 87140K->87372K(87424K), 0.0320460 secs] 125853K->108071K(126720K), [Metaspace: 99K->99K(4480K)], 0.0324338 secs] [Times: user=0.03 sys=0.00, real=0.04 secs]
[Full GC (Allocation Failure) [Tenured: 87372K->87372K(87424K), 0.0111509 secs] 126564K->113512K(126720K), [Metaspace: 99K->99K(4480K)], 0.0114351 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87372K->87372K(87424K), 0.0070985 secs] 126594K->117606K(126720K), [Metaspace: 99K->99K(4480K)], 0.0073754 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87372K->87372K(87424K), 0.0064107 secs] 126512K->121531K(126720K), [Metaspace: 99K->99K(4480K)], 0.0073788 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87372K->87401K(87424K), 0.0407867 secs] 126623K->118855K(126720K), [Metaspace: 99K->99K(4480K)], 0.0410064 secs] [Times: user=0.03 sys=0.00, real=0.04 secs]
[Full GC (Allocation Failure) [Tenured: 87415K->87415K(87424K), 0.0025924 secs] 126705K->121507K(126720K), [Metaspace: 99K->99K(4480K)], 0.0027823 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87415K->87415K(87424K), 0.0014438 secs] 126573K->123202K(126720K), [Metaspace: 99K->99K(4480K)], 0.0027839 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87415K->87415K(87424K), 0.0039557 secs] 126203K->124787K(126720K), [Metaspace: 99K->99K(4480K)], 0.0041619 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87415K->87375K(87424K), 0.0448436 secs] 126525K->123080K(126720K), [Metaspace: 99K->99K(4480K)], 0.0458651 secs] [Times: user=0.05 sys=0.00, real=0.05 secs]
[Full GC (Allocation Failure) [Tenured: 87375K->87375K(87424K), 0.0077542 secs] 126576K->123162K(126720K), [Metaspace: 99K->99K(4480K)], 0.0089463 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[Full GC (Allocation Failure) [Tenured: 87375K->87375K(87424K), 0.0015245 secs] 126625K->124035K(126720K), [Metaspace: 99K->99K(4480K)], 0.0016866 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87375K->87375K(87424K), 0.0117862 secs] 126458K->125042K(126720K), [Metaspace: 99K->99K(4480K)], 0.0148694 secs] [Times: user=0.00 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 87375K->87333K(87424K), 0.0349640 secs] 126613K->124378K(126720K), [Metaspace: 99K->99K(4480K)], 0.0351946 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
[Full GC (Allocation Failure) [Tenured: 87333K->87333K(87424K), 0.0022491 secs] 126608K->126039K(126720K), [Metaspace: 99K->99K(4480K)], 0.0024749 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87333K->87333K(87424K), 0.0011898 secs] 126522K->126255K(126720K), [Metaspace: 99K->99K(4480K)], 0.0018012 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87333K->87333K(87424K), 0.0010073 secs] 126607K->126124K(126720K), [Metaspace: 99K->99K(4480K)], 0.0016791 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Allocation Failure) [Tenured: 87333K->86898K(87424K), 0.0370980 secs] 126124K->125688K(126720K), [Metaspace: 99K->99K(4480K)], 0.0382321 secs] [Times: user=0.03 sys=0.00, real=0.04 secs]
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
        at GCLogAnalysis.generateGarbage(GCLogAnalysis.java:46)
        at GCLogAnalysis.main(GCLogAnalysis.java:23)
Heap
 def new generation   total 39296K, used 38842K [0x05400000, 0x07ea0000, 0x07ea0000)
  eden space 34944K, 100% used [0x05400000, 0x07620000, 0x07620000)
  from space 4352K,  89% used [0x07a60000, 0x07e2e9b8, 0x07ea0000)
  to   space 4352K,   0% used [0x07620000, 0x07620000, 0x07a60000)
 tenured generation   total 87424K, used 86898K [0x07ea0000, 0x0d400000, 0x0d400000)
   the space 87424K,  99% used [0x07ea0000, 0x0d37c878, 0x0d37ca00, 0x0d400000)
 Metaspace       used 100K, capacity 2244K, committed 2368K, reserved 4480K
 ```
 此时经历了多次young gc与full gc后，产生了oom，堆内存溢出。
 
 
 指定使用Serial串行化\
 ```java -Xmx256m -Xms256m -XX:+PrintGCDetails -XX:+UseSerialGC GCLogAnalysis``` \
 输出结果
 ```
 正在执行...
[GC (Allocation Failure) [DefNew: 69952K->8704K(78656K), 0.0199246 secs] 69952K->24535K(253440K), 0.0201206 secs] [Times: user=0.00 sys=0.01, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78656K->8703K(78656K), 0.0258184 secs] 94487K->47469K(253440K), 0.0260244 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
[GC (Allocation Failure) [DefNew: 78655K->8700K(78656K), 0.0264664 secs] 117421K->75979K(253440K), 0.0266400 secs] [Times: user=0.02 sys=0.02, real=0.03 secs]
[GC (Allocation Failure) [DefNew: 78414K->8702K(78656K), 0.0273997 secs] 145694K->102250K(253440K), 0.0276086 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78414K->8701K(78656K), 0.0237070 secs] 171962K->123200K(253440K), 0.0240166 secs] [Times: user=0.00 sys=0.01, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78653K->8697K(78656K), 0.0250502 secs] 193152K->147686K(253440K), 0.0252527 secs] [Times: user=0.03 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [DefNew: 78120K->8701K(78656K), 0.0278653 secs] 217109K->171579K(253440K), 0.0280877 secs] [Times: user=0.00 sys=0.03, real=0.03 secs]
[GC (Allocation Failure) [DefNew: 78500K->78500K(78656K), 0.0000903 secs][Tenured: 162877K->165309K(174784K), 0.0513436 secs] 241378K->165309K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0526168 secs] [Times: user=0.06 sys=0.00, real=0.06 secs]
[GC (Allocation Failure) [DefNew: 69375K->69375K(78656K), 0.0000890 secs][Tenured: 165309K->174772K(174784K), 0.0580869 secs] 234684K->181966K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0598554 secs] [Times: user=0.06 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174772K->174232K(174784K), 0.0569763 secs] 253093K->195202K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0581382 secs] [Times: user=0.06 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174525K->174783K(174784K), 0.0654103 secs] 253180K->199712K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0677528 secs] [Times: user=0.06 sys=0.00, real=0.07 secs]
[Full GC (Allocation Failure) [Tenured: 174783K->174783K(174784K), 0.0160730 secs] 253347K->215184K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0173324 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 174783K->174441K(174784K), 0.0417503 secs] 253349K->221798K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0422820 secs] [Times: user=0.05 sys=0.00, real=0.05 secs]
[Full GC (Allocation Failure) [Tenured: 174621K->174740K(174784K), 0.0524577 secs] 253226K->226668K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0527835 secs] [Times: user=0.05 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174740K->174220K(174784K), 0.0587732 secs] 253346K->222486K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0597012 secs] [Times: user=0.06 sys=0.00, real=0.06 secs]
[Full GC (Allocation Failure) [Tenured: 174220K->174220K(174784K), 0.0131860 secs] 252782K->232007K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0141523 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 174652K->174657K(174784K), 0.0202237 secs] 253258K->236208K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0212473 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
[Full GC (Allocation Failure) [Tenured: 174657K->174347K(174784K), 0.0236252 secs] 253275K->236908K(253440K), [Metaspace: 1711K->1711K(4480K)], 0.0244913 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
执行结束!共生成对象次数:3620
Heap
 def new generation   total 78656K, used 64814K [0x05400000, 0x0a950000, 0x0a950000)
  eden space 69952K,  92% used [0x05400000, 0x0934b820, 0x09850000)
  from space 8704K,   0% used [0x0a0d0000, 0x0a0d0000, 0x0a950000)
  to   space 8704K,   0% used [0x09850000, 0x09850000, 0x0a0d0000)
 tenured generation   total 174784K, used 174347K [0x0a950000, 0x15400000, 0x15400000)
   the space 174784K,  99% used [0x0a950000, 0x15392fb0, 0x15393000, 0x15400000)
 Metaspace       used 1715K, capacity 2244K, committed 2368K, reserved 4480K
 ```
 
 指定使用Parallel并行
 ```
 java -Xmx256m -Xms256m -XX:+PrintGCDetails -XX:+UseParallelGC GCLogAnalysis
 ```
 输出结果
 ```
 正在执行...
[GC (Allocation Failure) [PSYoungGen: 65752K->10750K(76544K)] 65752K->23352K(251392K), 0.0083739 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 76542K->10747K(76544K)] 89144K->44949K(251392K), 0.0127486 secs] [Times: user=0.00 sys=0.16, real=0.02 secs]
[GC (Allocation Failure) [PSYoungGen: 76539K->10745K(76544K)] 110741K->67477K(251392K), 0.0114850 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 76537K->10749K(76544K)] 133269K->88197K(251392K), 0.0119037 secs] [Times: user=0.06 sys=0.14, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 76530K->10751K(76544K)] 153978K->111730K(251392K), 0.0134969 secs] [Times: user=0.08 sys=0.13, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 75828K->10747K(40192K)] 176807K->131138K(215040K), 0.0116646 secs] [Times: user=0.06 sys=0.14, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 40187K->16512K(58368K)] 160578K->139354K(233216K), 0.0075202 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 45381K->22652K(58368K)] 168223K->148390K(233216K), 0.0102692 secs] [Times: user=0.16 sys=0.05, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 51571K->25652K(58368K)] 177309K->156153K(233216K), 0.0133186 secs] [Times: user=0.20 sys=0.00, real=0.02 secs]
[GC (Allocation Failure) [PSYoungGen: 55092K->16698K(58368K)] 185593K->163000K(233216K), 0.0145528 secs] [Times: user=0.09 sys=0.11, real=0.02 secs]
[Full GC (Ergonomics) [PSYoungGen: 16698K->0K(58368K)] [ParOldGen: 146302K->134674K(174848K)] 163000K->134674K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0641165 secs] [Times: user=0.38 sys=0.02, real=0.06 secs]
[GC (Allocation Failure) [PSYoungGen: 28928K->11757K(58368K)] 163602K->146431K(233216K), 0.0056805 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 41156K->10998K(58368K)] 175831K->157313K(233216K), 0.0087887 secs] [Times: user=0.00 sys=0.00, real=0.01 secs]
[GC (Allocation Failure) [PSYoungGen: 40438K->10020K(58368K)] 186753K->166209K(233216K), 0.0069745 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[Full GC (Ergonomics) [PSYoungGen: 10020K->0K(58368K)] [ParOldGen: 156188K->156138K(174848K)] 166209K->156138K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0470958 secs] [Times: user=0.58 sys=0.02, real=0.05 secs]
[Full GC (Ergonomics) [PSYoungGen: 28905K->0K(58368K)] [ParOldGen: 156138K->164030K(174848K)] 185043K->164030K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0543524 secs] [Times: user=0.56 sys=0.00, real=0.05 secs]
[Full GC (Ergonomics) [PSYoungGen: 29277K->0K(58368K)] [ParOldGen: 164030K->170922K(174848K)] 193307K->170922K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0552346 secs] [Times: user=0.61 sys=0.00, real=0.06 secs]
[Full GC (Ergonomics) [PSYoungGen: 29234K->0K(58368K)] [ParOldGen: 170922K->173351K(174848K)] 200157K->173351K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0524389 secs] [Times: user=0.61 sys=0.00, real=0.06 secs]
[Full GC (Ergonomics) [PSYoungGen: 29018K->5683K(58368K)] [ParOldGen: 173351K->174391K(174848K)] 202369K->180074K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0504780 secs] [Times: user=0.59 sys=0.00, real=0.05 secs]
[Full GC (Ergonomics) [PSYoungGen: 29158K->10907K(58368K)] [ParOldGen: 174391K->174817K(174848K)] 203549K->185724K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0503083 secs] [Times: user=0.59 sys=0.02, real=0.05 secs]
[Full GC (Ergonomics) [PSYoungGen: 29253K->15965K(58368K)] [ParOldGen: 174817K->174817K(174848K)] 204071K->190782K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0363484 secs] [Times: user=0.41 sys=0.00, real=0.03 secs]
[Full GC (Ergonomics) [PSYoungGen: 29440K->18113K(58368K)] [ParOldGen: 174817K->174611K(174848K)] 204257K->192724K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0332764 secs] [Times: user=0.41 sys=0.00, real=0.03 secs]
[Full GC (Ergonomics) [PSYoungGen: 29302K->17385K(58368K)] [ParOldGen: 174611K->174570K(174848K)] 203913K->191956K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0323265 secs] [Times: user=0.39 sys=0.01, real=0.03 secs]
[Full GC (Ergonomics) [PSYoungGen: 29440K->19480K(58368K)] [ParOldGen: 174570K->174667K(174848K)] 204010K->194147K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0326349 secs] [Times: user=0.61 sys=0.00, real=0.03 secs]
[Full GC (Ergonomics) [PSYoungGen: 29377K->19678K(58368K)] [ParOldGen: 174667K->174776K(174848K)] 204044K->194455K(233216K), [Metaspace: 1711K->1711K(4480K)], 0.0352598 secs] [Times: user=0.39 sys=0.00, real=0.04 secs]
执行结束!共生成对象次数:2956
Heap
 PSYoungGen      total 58368K, used 21052K [0x0fac0000, 0x15000000, 0x15000000)
  eden space 29440K, 71% used [0x0fac0000,0x10f4f030,0x11780000)
  from space 28928K, 0% used [0x11780000,0x11780000,0x133c0000)
  to   space 28928K, 0% used [0x133c0000,0x133c0000,0x15000000)
 ParOldGen       total 174848K, used 174776K [0x05000000, 0x0fac0000, 0x0fac0000)
  object space 174848K, 99% used [0x05000000,0x0faae278,0x0fac0000)
 Metaspace       used 1715K, capacity 2244K, committed 2368K, reserved 4480K
 ```
 
 这里产生一个疑问，本地环境java8，未指定GC策略时，显示的年轻代为DefNew，与Serial相同，而不是Parallel的PSYoungGen。使用-XX:+PrintCommandLineFlags参数打印默认GC策略，但没有显示
 ```
 java -XX:+PrintCommandLineFlags GCLogAnalysis
 ```
 输出结果
 ```
-XX:InitialHeapSize=16777216 -XX:MaxHeapSize=268435456 -XX:+PrintCommandLineFlags -XX:-UseLargePagesIndividualAllocation
正在执行...
执行结束!共生成对象次数:4072
```

指定CMS
```
java -Xmx1g -Xms1g -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC GCLogAnalysis
```
输出结果
```
正在执行...
[GC (Allocation Failure) [ParNew: 279616K->34944K(314560K), 0.0311176 secs] 279616K->87564K(1013632K), 0.0314860 secs] [Times: user=0.05 sys=0.16, real=0.03 secs]
[GC (Allocation Failure) [ParNew: 314560K->34942K(314560K), 0.0377401 secs] 367180K->167711K(1013632K), 0.0379853 secs] [Times: user=0.11 sys=0.11, real=0.03 secs]
[GC (Allocation Failure) [ParNew: 314558K->34943K(314560K), 0.0562500 secs] 447327K->244151K(1013632K), 0.0567126 secs] [Times: user=0.78 sys=0.06, real=0.07 secs]
[GC (Allocation Failure) [ParNew: 314559K->34943K(314560K), 0.0551427 secs] 523767K->319362K(1013632K), 0.0553579 secs] [Times: user=0.56 sys=0.01, real=0.06 secs]
[GC (Allocation Failure) [ParNew: 314559K->34943K(314560K), 0.0555822 secs] 598978K->397776K(1013632K), 0.0557824 secs] [Times: user=0.59 sys=0.02, real=0.05 secs]
[GC (CMS Initial Mark) [1 CMS-initial-mark: 362833K(699072K)] 398473K(1013632K), 0.0012366 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[CMS-concurrent-mark-start]
[CMS-concurrent-mark: 0.004/0.004 secs] [Times: user=0.03 sys=0.05, real=0.02 secs]
[CMS-concurrent-preclean-start]
[CMS-concurrent-preclean: 0.001/0.001 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[CMS-concurrent-abortable-preclean-start]
[GC (Allocation Failure) [ParNew[CMS-concurrent-abortable-preclean: 0.001/0.104 secs] [Times: user=0.30 sys=0.00, real=0.11 secs]
: 314559K->34943K(314560K), 0.0661413 secs] 677392K->473592K(1013632K), 0.0663822 secs] [Times: user=0.77 sys=0.05, real=0.06 secs]
[GC (CMS Final Remark) [YG occupancy: 35194 K (314560 K)][Rescan (parallel) , 0.0005195 secs][weak refs processing, 0.0000302 secs][class unloading, 0.0002990 secs][scrub symbol table, 0.0007525 secs][scrub string table, 0.0009030 secs][1 CMS-remark: 438648K(699072K)] 473842K(1013632K), 0.0036137 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[CMS-concurrent-sweep-start]
[CMS-concurrent-sweep: 0.002/0.002 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
[CMS-concurrent-reset-start]
执行结束!共生成对象次数:6385[CMS-concurrent-reset: 0.013/0.013 secs] [Times: user=0.03 sys=0.00, real=0.02 secs]

Heap
 par new generation   total 314560K, used 64953K [0x05600000, 0x1ab50000, 0x1ab50000)
  eden space 279616K,  10% used [0x05600000, 0x0734e830, 0x16710000)
  from space 34944K,  99% used [0x16710000, 0x1892ff38, 0x18930000)
  to   space 34944K,   0% used [0x18930000, 0x18930000, 0x1ab50000)
 concurrent mark-sweep generation total 699072K, used 313021K [0x1ab50000, 0x45600000, 0x45600000)
 ```
 可以看出首先对年轻代的回收采用了并行版本的Serial，之后进入了老年代回收的“六阶段”\
 
 指定使用G1
 ```
 java -Xmx1g -Xms1g -XX:+PrintGC -XX:+UseG1GC GCLogAnalysis
 ```
 输出结果
 ```
 正在执行...
[GC pause (G1 Evacuation Pause) (young) 64M->24M(1024M), 0.0071793 secs]
[GC pause (G1 Evacuation Pause) (young) 78M->44M(1024M), 0.0146469 secs]
[GC pause (G1 Evacuation Pause) (young) 103M->68M(1024M), 0.0120257 secs]
[GC pause (G1 Evacuation Pause) (young) 134M->85M(1024M), 0.0113964 secs]
[GC pause (G1 Evacuation Pause) (young) 191M->121M(1024M), 0.0116935 secs]
[GC pause (G1 Evacuation Pause) (young) 272M->172M(1024M), 0.0149760 secs]
[GC pause (G1 Evacuation Pause) (young) 331M->221M(1024M), 0.0165512 secs]
[GC pause (G1 Evacuation Pause) (young) 413M->277M(1024M), 0.0178439 secs]
[GC pause (G1 Evacuation Pause) (young)-- 809M->438M(1024M), 0.0430961 secs]
[GC pause (G1 Humongous Allocation) (young) (initial-mark) 550M->462M(1024M), 0.0238472 secs]
[GC concurrent-root-region-scan-start]
[GC concurrent-root-region-scan-end, 0.0014413 secs]
[GC concurrent-mark-start]
[GC concurrent-mark-end, 0.0038279 secs]
[GC remark, 0.0037892 secs]
[GC cleanup 484M->467M(1024M), 0.0026030 secs]
[GC concurrent-cleanup-start]
[GC concurrent-cleanup-end, 0.0010609 secs]
执行结束!共生成对象次数:5875
```
可以看出G1的并发标记过程与CMS类似。
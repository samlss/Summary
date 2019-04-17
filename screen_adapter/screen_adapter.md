# 屏幕适配的几种方案以及优缺点总结



## 1.基础概念

屏幕尺寸：一般称之为手机大小，例如5寸，5.5寸、6寸、6.5寸等等，手机屏幕对角线的长度，单位为inch(英尺)；



屏幕分辨率：一般形容为横向像素点x竖向像素点，常见的屏幕分辨率有320x480、480x800、720x1280、1080x1920等等。



屏幕像素密度dpi(density per inch)：每英寸的像素点数，



三者关系：

![snap_dpi_calculate](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_dpi_calculate.png)



![snap_dip_details](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_dip_details.png)



Android中的相关参数(以下源码均为android-28中的源码)：

```java
DisplayMetrics dm = getResources().getDisplayMetrics();

dm.density -> 屏幕密度

dm.densityDpi -> 手机屏幕像素密度(固定值，出厂时已指定，Android手机中可能是120，160，240)

//公式转换
dm.density = dm.densityDpi / 160;

px = density * dp;
px = dp * (dpi / 160);

dp/dip: dp和dip是一样的，密度无关像素，Density Independent Pixels的缩写

```



为什么是density = dpi / 160而不是120和240？

在回答这个问题之前，我们先看看安卓中的相关源码：

![snap_density_dpi](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_density_dpi.png)

density大概意思为：

屏幕的逻辑密度，是密度独立像素单元(即dp)的缩放因子，其中1dp大约是160dpi屏幕上的1px(例如在分辨率为240*320，尺寸为(宽x高 = 1.5x2英寸)屏幕下，dpi = 160，可自己手动算一下)，提供Android系统显示的基值，例如dpi=160时，density=1，dpi = 120时，density=0.75。

density值不取决于屏幕的真实屏幕大小，而是根据dpi的总体变化逐步调整整个UI的大小。例如在一个分辨为240x320，density=1的屏幕下，无论它的宽是1.8英寸还是1.3英寸，dpi不改变的前提下，density就还是1。但是如果屏幕分辨率增加到320x480，且屏幕尺寸还是(宽x高)1.5x2英寸的话，这样的话density值会变大(因为dpi变大了)，可能是1.5。



我们去找一下真正赋值的地方：

```java
//类：ResourcesImpl
if (mConfiguration.densityDpi != Configuration.DENSITY_DPI_UNDEFINED) {
    mMetrics.densityDpi = mConfiguration.densityDpi;
    mMetrics.density = mConfiguration.densityDpi * DisplayMetrics.DENSITY_DEFAULT_SCALE;
}

//----------------------------------------------------------------
//下面两个接口在DisplayMetrics类中
//将dp单位的密度转换为密度标度的缩放因子
public static final float DENSITY_DEFAULT_SCALE = 1.0f / DENSITY_DEFAULT;

//整个系统使用的参考密度
public static final int DENSITY_DEFAULT = DENSITY_MEDIUM;

 public static final int DENSITY_MEDIUM = 160;
//----------------------------------------------------------------

//由上面接口我们知道
mMetrics.density = mConfiguration.densityDpi / 160;

```

接着我们继续找mConfiguration.densityDpi赋值的地方

```java
//在ResourcesImpl中，创建了一个Configuration类
private final Configuration mConfiguration = new Configuration();

//并在下面函数中对mConfiguration.densityDpi赋了值
public final void startPreloading() {
    synchronized (sSync) {
        //others calling...
        mConfiguration.densityDpi = DisplayMetrics.DENSITY_DEVICE;
        //others calling...
    }
}

//我们再回到DisplayMetrics类看
//虽是个标注废弃的方法，但是在api28中，其内部仍然有调用
//隐藏接口，但是可通过调用DisplayMetrics.DENSITY_DEVICE_STABLE获取
@Hide
@Deprecated
public static int DENSITY_DEVICE = getDeviceDensity();

public static final int DENSITY_DEVICE_STABLE = getDeviceDensity();

//通过获取系统属性获取手机dpi
private static int getDeviceDensity() {
    return SystemProperties.getInt("qemu.sf.lcd_density",
                                   SystemProperties.getInt("ro.sf.lcd_density", DENSITY_DEFAULT));
}
```



好了，回到问题，之所以调用是因为安卓中使用了独立像素单元(dp)作为屏幕基本单位，且公式为：

```java
dm.density = dm.densityDpi / 160;
px = density * dp;
```



在这样条件下，当屏幕dpi为160时，1px=1dp，因此取160。



## 2.屏幕分辨率限定符

由于安卓屏幕碎片化严重，这种方案就是尽可能多地在res目录下面创建各种分辨率对应的values-xxx文件夹，然后选定一种基准分辨率，其他分辨率以该分辨为基准，生成对应的dimens文件。

![snap_resolution_res](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_resolution_res.png)

然后根据一个基准分辨率，例如基准分辨率为 1280x720，将宽度分成 720 份，取值为 1px~720px，将高度分成 1280 份，取值为 1px~1280px，生成各种分辨率对应的 dimens.xml 文件。如下分别为分辨率 1280x720 与 1920x1080 所对应的横向dimens.xml 文件

![snap_resolution_res_details](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_resolution_res_details.png)

假设设计图上的一个控件的宽度为 720px，那么布局中就写 android:layout_width="@dimen/x720" ，当运行程序的时候，系统会根据设备的分辨率去寻找对应的 dimens.xml 文件。例如运行在分辨率为 1280x720 的设备上，系统会自动找到对应的 values-1280x720 文件夹下的 lay_x.xml 文件，由上图可知 x720 对应的值为720.px，可铺满该屏幕宽度。运行在分辨率为 1920x1080 的设备上，系统会自动找到对应的 values-1920x1080 文件夹下的 lay_x.xml 文件，由上图可知 x720 对应的值为 1080.0px，可铺满该屏幕宽度。这样就达到了屏幕适配的要求。



这种方法的优点是：基本解决适配问题，且UI设计稿一般是以像素为基本单位，如果UI设计界面使用的就是基准分辨率的话，就直接可以在layout上使用对应的dimens了，极大提升了我们的开发效率。



这种方法的缺点是：要精准匹配分辨率，例如1920x1080的手机一定要找到values-1920x1080的dimens文件。否则就会使用默认的尺寸，而使用默认的尺寸的话，就有可能造成UI不对齐，变形等现象。



## 3.最小宽度限定符

smallestWidth 限定符适配原理与屏幕分辨率限定符适配原理一样，系统都是根据限定符去寻找对应的 dimens.xml 文件。

Android 在 Android 3.2 中引入了“最小宽度”限定符，其原理是取屏幕最小宽度(dp)，与屏幕分辨率限定符不同的是，最小宽度以dp为单位，我们可以通过以下方式获取最小宽度:

```java
DisplayMetrics dm = getResources().getDisplayMetrics();
int widthPixels  = dm.widthPixels;
int heightPixels = dm.heightPixels;

float widthInDp  = widthPixels / dm.density;
float heightInDp = heightPixels / dm.density;

float smallestWidthInDp = widthInDp <= heightInDp ? widthInDp : heightInDp;

Log.e("TAG", "widthInDp: "+widthInDp);
Log.e("TAG", "heightInDp: "+heightInDp);
Log.e("TAG", "smallestWidthInDp: "+smallestWidthInDp);

//测试机打印分别为:
//widthInDp: 360.0
//heightInDp: 640.0
//smallestWidthInDp: 360.0
```

最小宽度是不区分宽和高的，哪一边小就认为哪一边是最小宽度。

我们在开发者选项中也可以看到手机的最小宽度：

![snap_developer_option](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_developer_option.png)



我们看下面一张图，下面定义了6中最小宽度，但是其中已经囊括了36中不同分辨率的情况，如果要用屏幕分辨率限定符的话，要定义36个values-宽x高的文件，想想都头疼。因此，这也是谷歌提出最小宽度限定符的原因之一。以最少的限定符适配更多的屏幕，以减少工作量和包体积。

![snap_resolution_and_dp](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_resolution_and_dp.png)

这里有谷歌提供的更准确的设备列表：https://material.io/tools/devices
这里囊括了各种分辨率的屏幕，也注明了对应的最小宽度。当然，因为安卓的开源性，可能这里的统计也会有遗漏，因此，如果你需要适配更精准的最小宽度，你可以手动添加对应的values-swXXXdp。当然，你如果不匹配的话，也会找到对应的最小宽度的目录，然后拿到对应的dimens。
例如当前程序运行在最小宽度为360的手机上，系统会自动去获取values-sw360dp目录下的dimens.xml文件下相应的值，如果当前程序没有values-sw360dp目录，但是有values-sw320dp目录，那么系统就会去找到values-sw320dp目录取对应的值。

向下取最小宽度的好处是，哪怕没有百分之百匹配，也有很高的契合率，不会导致遮挡问题。例如现在手机最小宽度是360dp，但是程序资源上只有values-sw320dp，那么取320dp，320/360≈0.8889，在保证不会导致遮挡的问题下，误差在0.12左右，即values-sw360dp下的1dp大概等于values-sw320dp下的0.88dp，在这个误差范围之内，显示效果还是相当不错的。

------

具体做法：

在Android Studio中安装插件：ScreenMatch

![snap_plugin_screen_match](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_plugin_screen_match.png)

我们可以通过项目目录下的screenMatch.properties文件配置该插件支持的属性

```java
//基准，该插件默认值为360，建议以实际的设计图最小宽度作为参考标准
base_dp=360

//指定要匹配的最小宽度
//默认为384,392,400,410,411,480,533,592,600,640,662,720,768,800,811,820,960,961,1024,1280,1365
//如果需要其他的，则在这里手动添加
match_dp=384,392,400,410,411,480,533,592,600,640,662,720,768,800,811,820,960,961,1024,1280,1365

//指定不匹配的最小宽度
ignore_dp=

//这里设置在弹出选择module的dialog时，要过滤的module，即不能选择该module
ignore_module_name=

//要在哪个module下生成
match_module=app

//是否显示选择module的dialog，true为不显示，会默认使用上一次选中的module，
//或者默认的module->app
not_show_dialog=false

//是否在项目目录下创建一个dimens示例文件screenMatch_example_dimens.xml
//该文件可供参考，false为创建，true为不创建，默认为false
not_create_default_dimens=false
    
//是否适配sp
//默认为true, 为true的话，sp=dp，否则sp与基准即values的dimens目录下的sp一致
is_match_font_sp=true

//设置要创建values-wXXXdp目录还是values-swXXXdp目录
//默认为true，true为创建values-swXXXdp目录
//false为创建values-wXXXdp目录
create_values_sw_folder=true

```


这里的基准dimens文件(res/values/dimens.xml)如下(当然也可以使用上面的screenMatch_example_dimens.xml文件)：

[dimens.xml](https://github.com/samlss/Summary/blob/master/screen_adapter/dimens.xml)

然后在目录下面点击右键：

![snap_sm_plugin_use](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_sm_plugin_use.png)

然后选择module

![snap_sm_plugin_select_module](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_sm_plugin_select_module.png)

确认后生成：

![snap_sm_generation_finish](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_sm_generation_finish.png)

------

关于自定义的最小宽度，首先要和UI确定设计图的宽高，例如当前UI设计图宽高为720x1280px，在Android Studio layout.xml的preview中，我们并没有找到对应的分辨率设备：

![snap_as_layout_preview](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_as_layout_preview.png)

因此我们需要创建一个自定义的设备

![snap_new_device](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_new_device.png)

可以看到其density为xhdpi，在安卓，有以下的对应关系：

![snap_density_define](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_density_define.png)

那么计算可得最小宽度为：

```java
float smallestWidth = 720 * 160 / 320 = 360；
```



和ScreenMatch默认的最小宽度一致，可直接生成对应的values-swxxxdp文件夹。这里有个需要注意的地方是，当ScreenMatch最小宽度设置为360的时候，那么会生成以下这些文件夹：

```java
384,392,400,410,411,480,533,592,600,640,662,720,768,800,811,820,960,961,1024,1280,1365
```

如果我们要适配360dp以下的最小宽度的时候，例如我指定：

```java
match_dp=320,384,392,400,410,411,480,533,592,600,640,662,720,768,800,811,820,960,961,1024,1280,1365
```

那么会生成以下这些values-swxxxdp目录：

![snap_sm_plugin_base_dp_note](https://github.com/samlss/Summary/blob/master/screen_adapter/snap_sm_plugin_base_dp_note.png)

我们可以看到，缺少了360dp目录，这时就会去找320dp目录，因此当我们要适配比基准最小宽度(即base_dp)小的时候，需要再手动重新创建一个base_dp的目录，并把res/values/dimens.xml文件拷贝过去。

该适配方法的优点有：使用方便，适配率高。

缺点：导致包体积变大，生成上面所有最小宽度的文件大概增加368kb左右。


## 4.百分比布局

早期的percent-layout库，现在google的constraintlayout库都是百分比布局。内部实现原理是，在layout.xml中使用，指定view对应宽高的百分比，该百分比数值基于屏幕分辨率。

优点：使用方便，适配率高

缺点：就是每次都要将UI设计稿的对应大小换算成百分比，例如设计稿设计的ImageView尺寸是180x180，但是在我们编写layout文件的时候，不能直接128dp*128dp或者128px*128px。在把设计稿向UI代码转换的过程中，我们需要耗费相当的精力去转换尺寸，这会极大的降低我们的生产力，拉低开发效率。并且UI可能随时会增加一个Button、一个ImageView，这个时候又要重新计算对应的百分比，着实耗费相当多的精力。



## 5.鸿洋大神的AndroidAutoLayout库

使用方法，在你的项目的AndroidManifest中注明你的设计稿的尺寸:

```java
<meta-data android:name="design_width" android:value="768"></meta-data>

<meta-data android:name="design_height" android:value="1280"></meta-data>

```

然后继承库中的AutoLayoutActivity，或者layout文件中使用AutioLinearLayout、AutoRelativeLayout、AutoFrameLayout。

原理：运行时在最外层套上自定义的LinearLayout、RelativeLayout，AutoFrameLayout，然后在onMeasure的时候根据设计稿的尺寸和屏幕实际宽高的比例对子view进行调整。

优点：开发高效，适配率精准。

缺点：在onMeasure中重新测量设置，对性能有一定影响；可能会对某些自定义控件产生影响；只能使用上面三种自定义layout，不能灵活使用其他的Layout组件；加深布局层次。

## 6.修改density和scaledDensity

[今日头条方案](https://mp.weixin.qq.com/s/d9QCoBP6kV9VSWvVldVVwA)

原理：通过动态修改density的值以达到适配效果，可以通过下面例子了解：

```java
//我们知道公式：
px = density * dp;
//即
dp = px / density


//我们假设屏幕宽度为1080x1920，当前density = 3，那么
px = 3 * dp;
dp = px / 3;

//再假设UI设计图的宽度为720
//那我们可以通过对比，获取对应的density值，为
dp = 1080 / 3 = 720 / newDensity

//可以得到
newDensity = 720 / 360 = 2;

//以下为设置适配activity屏幕的代码
DisplayMetrics dm = activity.getResources().getDisplayMetrics();
dm.density = newDensity;
dm.densityDpi = newDensity * 160;

//关于scaledDensity为系统字体的缩放密度，因此其设置代码为：
DisplayMetrics systemDm = Resources.getSystem().getDisplayMetrics(); //获取系统显示度量

//即在原本系统的密度比上乘以新的density值
dm.scaledDensity = newDensity * (systemDm.scaledDensity / systemDm.density)
```



该适配方法的优点：代码比较简单，也没有涉及到系统非公开api的调用，因此理论上不会影响app稳定性。



缺点：会影响系统级别的UI大小，例如Dialog，Toast等。另外，可能会对老项目产生影响，因为修改了系统的density值之后，整个布局的实际尺寸都会发生改变。



参考：

https://www.jianshu.com/p/1302ad5a4b04

https://mp.weixin.qq.com/s/d9QCoBP6kV9VSWvVldVVwA

https://www.jianshu.com/p/a4b8e4c5d9b0

https://www.jianshu.com/p/2aded8bb6ede

https://developer.android.com/training/multiscreen/screensizes

https://theground.jimdo.com/android/android-screen-size-ldpi-mdpi-hdpi

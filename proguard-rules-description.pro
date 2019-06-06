#运行混淆器之后输出的文件有：
#Android Studio项目混淆后输出的文件所在位置为:
#module's directory/build/outputs/proguard/release/mapping.txt
#
#         dump.txt
#
#                   描述.apk包中所有class文件的内部结构。
#
#         mapping.txt
#
#                   列出了源代码与混淆后的类，方法和属性名字之间的映射。这个文件对于在构建之后得到的bug报告是有用的，因为它把混淆的堆栈跟踪信息反翻译为源代码中的类，方法和成员名字。
#
#         seeds.txt
#
#                   列出那些未混淆的类和成员。
#
#         usage.txt
#
#                   列出从.apk中剥离的代码。
#
#         这些文件放在以下目录中：
#
#l <project_root>/bin/proguard 当你使用Ant时
#
#l <project_root>/proguard 当你使用Eclipse时


#Proguard通配符(可参考https://segmentfault.com/a/1190000004461614)
#
#通配符      描述
#<field>     匹配类中的所有字段
#<method>    匹配类中所有的方法
#<init>      匹配类中所有的构造函数
#*           匹配任意长度字符，不包含包名分隔符(.)
#**          匹配任意长度字符，包含包名分隔符(.)
#***         匹配任意参数类型
#{ *;}       表示一个类中的所有的东西

#关键字                       描述
#keep                        保留类和类中的成员，防止被混淆或移除
#keepnames                   保留类和类中的成员，防止被混淆，成员没有被引用会被移除
#keepclassmembers            只保留类中的成员，防止被混淆或移除
#keepclassmembernames        只保留类中的成员，防止被混淆，成员没有引用会被移除
#keepclasseswithmembers      保留类和类中的成员，防止被混淆或移除，保留指明的成员
#keepclasseswithmembernames  保留类和类中的成员，防止被混淆，保留指明的成员，成员没有引用会被移除


#-dontwarn
#
#dontwarn是一个和keep可以说是形影不离,尤其是处理引入的library时.
#
#引入的library可能存在一些无法找到的引用和其他问题,在build时可能会发出警告,如果我们不进行处理,通常会导致build中止.
#因此为了保证build继续,我们需要使用dontwarn处理这些我们无法解决的library的警告.
#
#比如关闭Twitter sdk的警告,我们可以这样做
#
#-dontwarn com.twitter.sdk.**

#表达式中的 class 关键字表示任何接口类、抽象类和普通类； interface 关键字表示只能是接口类；
#enum 关键字表示只能是枚举类。如果在 interface 和 enum 关键字前面加上感叹号（“ ! ”）分别表示不是接口类的类和不是枚举类的类。
# class 关键字前面是不能加感叹号的。

#---------------------------------默认保留区---------------------------------

# 代码混淆压缩比，在0~7之间，默认为5,一般不下需要修改
-optimizationpasses 5

# 混淆时不使用大小写混合，混淆后的类名为小写
# windows下的同学还是加入这个选项吧(windows大小写不敏感)
#-dontusemixedcaseclassnames

# 指定不去忽略非公共的库的类
# 默认跳过，有些情况下编写的代码与类库中的类在同一个包下，并且持有包中内容的引用，此时就需要加入此条声明
#-dontskipnonpubliclibraryclasses

#指定不去忽略非公共的库的类的成员(例如jar包中的非public classes的members)
-dontskipnonpubliclibraryclassmembers

# 不做预检验，preverify是proguard的四个步骤之一
# Android不需要preverify，去掉这一步可以加快混淆速度
-dontpreverify

# Optimization is turned off by default. Dex does not like code run
# through the ProGuard optimize and preverify steps (and performs some
# of these optimizations on its own).
# 不进行优化，建议使用此选项，理由见上
-dontoptimize

#有了verbose这句话，混淆后就会生成映射文件
#生成原类名和混淆后的类名的映射文件
-verbose
#apk 包内所有 class 的内部结构
-dump dump.txt
#未混淆的类和成员
-printseeds seeds.txt
#列出从 apk 中删除的代码
-printusage unused.txt
#混淆前后的映射
-printmapping mapping.txt

# 指定混淆时采用的算法，后面的参数是一个过滤器
# 这个过滤器是谷歌推荐的算法，一般不改变
-optimizations !code/simplification/cast,!field/*,!class/merging/*

#这条规则配置特别强大，它可以把你的代码以及所使用到的各种第三方库代码统统移动到同一个包下，
#可能有人知道这条配置，但仅仅知道它还不能发挥它最大的作用，默认情况下，
#你只要在 rules 文件中写上 -repackageclasses 这一行代码就可以了，它会把上述的代码文件都移动到根包目录下，
#即在 / 包之下，这样当有人反编译了你的 APK，将会在根包之下看到 成千上万 的类文件并列着
-repackageclasses

# 保护代码中的Annotation不被混淆
# 保护内部类不被混淆
# 这在JSON实体映射时非常重要，比如fastJson
-keepattributes *Annotation*,InnerClasses

#不混淆泛型
-keepattributes Signature

#抛出异常时保留代码行号
-keepattributes SourceFile,LineNumberTable

#忽略警告
-ignorewarning

#使用混淆字典
-obfuscationdictionary dictionary-drakeet1.txt
-classobfuscationdictionary dictionary-drakeet1.txt
-packageobfuscationdictionary dictionary-drakeet1.txt

# 使用 -assumenosideeffects 这个配置项可以帮我们在编译成 APK 之前把日志代码全部删掉，
# 这么做不仅有助于提升性能，而且日志代码往往会保留很多我们的意图和许多可被反编译的字符串：
# 注：assumenosideeffects 需要启用代码优化才能生效即不使用-dontoptimize
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int d(...);
    public static int w(...);
    public static int v(...);
    public static int i(...);
    public static int e(...);
}

# 保留了继承自Activity、Application这些类的子类
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class com.google.vending.licensing.ILicensingService
-keep public class com.android.vending.licensing.ILicensingService

-keep class android.support.** {*;}
# The support library contains references to newer platform versions.
# Don't warn about those in case this app is linking against an older
# platform version.  We know about them, and they are safe.
-dontwarn android.support.**

# 保留所有的本地native方法不被混淆
-keepclasseswithmembernames class * {
    native <methods>;
}


# 保留Activity中的方法参数是view的方法，
# 从而我们在layout里面编写onClick就不会影响
-keepclassmembers class * extends android.app.Activity{
    public void *(android.view.View);
}

# 枚举类不能被混淆
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留自定义控件(继承自View)不能被混淆
-keep public class * extends android.view.View{
    *** get*();
    void set*(***);
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# 保留Parcelable序列化的类不能被混淆
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}

# 保留Serializable 序列化的类不被混淆
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 对R文件下的所有类及其方法，都不能被混淆
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 对于带有回调函数onXXEvent的，不能混淆
-keepclassmembers class * {
    void *(**On*Event);
}

# Understand the @Keep support annotation.
-keep class android.support.annotation.Keep

-keep @android.support.annotation.Keep class * {*;}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <methods>;
}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <fields>;
}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <init>(...);
}
#----------------------------------------------------------------------------

#---------------------------------webview------------------------------------
-keepclassmembers class fqcn.of.javascript.interface.for.Webview {
   public *;
}

-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}

-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, jav.lang.String);
}


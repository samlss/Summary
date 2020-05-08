### LocalBroadcastManager源码分析
- 版本：**++androidx.localbroadcastmanager:1.0.0++**
- 代码行数（连注释）：++**319**++

#### 官方注释
```
/**
 * Helper to register for and send broadcasts of Intents to local objects
 * within your process.  This has a number of advantages over sending
 * global broadcasts with {@link android.content.Context#sendBroadcast}:
 * 
 * - You know that the data you are broadcasting won't leave your app, so
 * don't need to worry about leaking private data.
 * - It is not possible for other applications to send these broadcasts to
 * your app, so you don't need to worry about having security holes they can
 * exploit.
 * - It is more efficient than sending a global broadcast through the
 * system.
 * </ul>
 */
```

1. 帮助在你的应用程序中（仅限单进程）注册意图广播并将其发送到本地监听器。
2. 与全局广播相比，具有以下优势：
    - [x] 仅进程内部使用，更安全
    - [x] 它比通过系统发送全局广播更有效



#### 主要方法

Method | 说明
---|---
getInstance | 获取单例
registerReceiver | 注册接收器
unregisterReceiver | 注销接收器
sendBroadcast | 异步发送广播，将在主线程Handler中调度处理
sendBroadcastSync | 同步发送广播，在调用线程处理

#### 内部类
Class | 说明
---|---
ReceiverRecord | 用于记录接收器
BroadcastRecord | 用于记录广播器

```
private static final class ReceiverRecord {
    final IntentFilter filter;
    final BroadcastReceiver receiver;
    boolean broadcasting;
    boolean dead;

    ReceiverRecord(IntentFilter _filter, BroadcastReceiver _receiver) {
        filter = _filter;
        receiver = _receiver;
    }

    @Override
    public String toString() {
        //...
    }
}

private static final class BroadcastRecord {
    final Intent intent;
    final ArrayList<ReceiverRecord> receivers;

    BroadcastRecord(Intent _intent, ArrayList<ReceiverRecord> _receivers) {
        intent = _intent;
        receivers = _receivers;
    }
}
```


#### 源码分析
##### 主要变量：

```
//用于记录每个receiver对应的注册集合
private final HashMap<BroadcastReceiver, ArrayList<ReceiverRecord>> mReceivers = new HashMap<>();

//用于记录每个不同的action对应的注册集合
private final HashMap<String, ArrayList<ReceiverRecord>> mActions = new HashMap<>();

//等待发送的广播集合
private final ArrayList<BroadcastRecord> mPendingBroadcasts = new ArrayList<>();

//Handler处理发送广播的消息类型
static final int MSG_EXEC_PENDING_BROADCASTS = 1;

//Looper为主线程的Handler
private final Handler mHandler;

//单例锁对象
private static final Object mLock = new Object();

//单例对象
private static LocalBroadcastManager mInstance;

```

##### 注册广播
```
public void registerReceiver(BroadcastReceiver receiver, IntentFilter filter) {
    synchronized (mReceivers) {
        ReceiverRecord entry = new ReceiverRecord(filter, receiver);
        ArrayList<ReceiverRecord> filters = mReceivers.get(receiver);
        if (filters == null) {
            filters = new ArrayList<>(1);
            mReceivers.put(receiver, filters);
        }
        filters.add(entry);
        for (int i=0; i<filter.countActions(); i++) {
            String action = filter.getAction(i);
            ArrayList<ReceiverRecord> entries = mActions.get(action);
            if (entries == null) {
                entries = new ArrayList<ReceiverRecord>(1);
                mActions.put(action, entries);
            }
            entries.add(entry);
        }
    }
}
```

- 给mReceivers加锁
- 根据receiver和filter创建一个ReceiverRecord并且将其加入到mReceivers对应的接收器记录集合中
- 遍历filter的所有action，并将创建的ReceiverRecord加入到mActions对应的接收器记录集合中
- 注册代码较为简单，主要是将注册的信息放到ReceiverRecord中，然后插入到本地的hashmap中

##### 注销广播
```
public void unregisterReceiver(@NonNull BroadcastReceiver receiver) {
    synchronized (mReceivers) {
        final ArrayList<ReceiverRecord> filters = mReceivers.remove(receiver);
        if (filters == null) {
            return;
        }
        for (int i=filters.size()-1; i>=0; i--) {
            final ReceiverRecord filter = filters.get(i);
            filter.dead = true;
            for (int j=0; j<filter.filter.countActions(); j++) {
                final String action = filter.filter.getAction(j);
                final ArrayList<ReceiverRecord> receivers = mActions.get(action);
                if (receivers != null) {
                    for (int k=receivers.size()-1; k>=0; k--) {
                        final ReceiverRecord rec = receivers.get(k);
                        if (rec.receiver == receiver) {
                            rec.dead = true;
                            receivers.remove(k);
                        }
                    }
                    if (receivers.size() <= 0) {
                        mActions.remove(action);
                    }
                }
            }
        }
    }
}
```
- 给mReceivers加锁
- mReceivers移除对应接收器记录
- mActions移除对应接收器记录

#### sendBroadcast
异步发送广播，如果调度成功即加入异步处理的话，则返回true，否则返回false
```
public boolean sendBroadcast(Intent intent) {
        synchronized (mReceivers) {
            final String action = intent.getAction();
            final String type = intent.resolveTypeIfNeeded(
                    mAppContext.getContentResolver());
            final Uri data = intent.getData();
            final String scheme = intent.getScheme();
            final Set<String> categories = intent.getCategories();

            //...debug 忽略...

            ArrayList<ReceiverRecord> entries = mActions.get(intent.getAction());
            if (entries != null) {
                //...debug 忽略...

                ArrayList<ReceiverRecord> receivers = null;
                for (int i=0; i<entries.size(); i++) {
                    ReceiverRecord receiver = entries.get(i);
                    //...debug 忽略...

                    if (receiver.broadcasting) {
                        //...debug 忽略...
                        continue;
                    }

                    int match = receiver.filter.match(action, type, scheme, data,
                            categories, "LocalBroadcastManager");
                    if (match >= 0) {
                        //...debug 忽略...
                        if (receivers == null) {
                            receivers = new ArrayList<ReceiverRecord>();
                        }
                        receivers.add(receiver);
                        receiver.broadcasting = true;
                    } else {
                        //...debug 忽略...
                    }
                }

                if (receivers != null) {
                    for (int i=0; i<receivers.size(); i++) {
                        receivers.get(i).broadcasting = false;
                    }
                    mPendingBroadcasts.add(new BroadcastRecord(intent, receivers));
                    if (!mHandler.hasMessages(MSG_EXEC_PENDING_BROADCASTS)) {
                        mHandler.sendEmptyMessage(MSG_EXEC_PENDING_BROADCASTS);
                    }
                    return true;
                }
            }
        }
        return false;
    }
```
- 给mReceivers加锁
- 获取intent的action、data、scheme、categories，用于intentfilter的匹配处理
- 如果接收器已经加入到通知列表即broadcasting为true的话，则无需处理
- 通过mActions获取接收器集合，并开始遍历，若receiver.filter.match即匹配为true的话，代表需要发送广播到该接收器中
- ，通过intent和匹配的接收器记录集合创建BroadcastRecord广播记录并添加到mPendingBroadcasts集合中
- 最后通过handler发送处理广播接收的调度消息，等待handle调度处理

#### sendBroadcastSync
同步处理广播发送，当发送广播调度成功后，马上执行广播发送处理
```
public void sendBroadcastSync(Intent intent) {
    if (sendBroadcast(intent)) {
        executePendingBroadcasts();
    }
}
```

#### executePendingBroadcasts
发送广播
```
void executePendingBroadcasts() {
    while (true) {
        final BroadcastRecord[] brs;
        synchronized (mReceivers) {
            final int N = mPendingBroadcasts.size();
            if (N <= 0) {
                return;
            }
            brs = new BroadcastRecord[N];
            mPendingBroadcasts.toArray(brs);
            mPendingBroadcasts.clear();
        }
        for (int i=0; i<brs.length; i++) {
            final BroadcastRecord br = brs[i];
            final int nbr = br.receivers.size();
            for (int j=0; j<nbr; j++) {
                final ReceiverRecord rec = br.receivers.get(j);
                if (!rec.dead) {
                    rec.receiver.onReceive(mAppContext, br.intent);
                }
            }
        }
    }
}
```
- 获取待发送广播列表，若为空，则退出本次处理，若不为空，则将mPendingBroadcasts转为数组，这样做是为了避免多线程同时操作mPendingBroadcasts集合
- 遍历，若接收器记录尚未死亡，则调用接收器记录中的receiver的onReceive接口，完成广播接收通知


#### 注意
1. getInstance的时候不要传activity对象，否则有可能导致内存泄漏，因为在构建单例对象的时候，会直接引用参数context
```
private LocalBroadcastManager(Context context) {
    mAppContext = context;
    //...
}
```

2. 调用sendBroadcast之后有可能有一定延时，因为调用该方法会将发送广播逻辑放到Handler中调度执行
3. 不要在onReceive中处理耗时的逻辑，否则会导致LocalBroadcastManager广播发送延迟


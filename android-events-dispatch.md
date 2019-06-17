在Android手机中，从手指点击屏幕到传递事件到Activity或者View，中间的过程是什么？

***++下面所有源码都是API28版本++***

首先触摸事件肯定要先捕获才能传给对应的窗口，例如**一个Activity就是一个窗口，统一由WMS管理**。那么应该会有一个线程一直在监听屏幕按键事件，在Linux中，内核会把触摸事件封装好并且写入到/dev/input/目录对应的文件中，该目录保存了所有输入事件的对应文件：
```
event0 event1 event2 event3 event4 event5 event6 event7 event8
```

输入事件可能有按钮、触摸屏、USB等等。

#### WindowManagerService和InputManagerService
在SystemServer进程启动的时候会启动一些系统服务，其中包括了WMS和IMS(缩写)。可以看到两者是先后添加的，证明他们两个应该是有联系的，并且在创建WindowManagerService的时候，其中一个需要的参数就是InputManagerService，创建服务并且将服务添加到ServiceManager后启动InputManagerService。

```
//SystemServer
private void startOtherServices() {
    //...
    inputManager = new InputManagerService(context);
    wm = WindowManagerService.main(context, inputManager,
            mFactoryTestMode != FactoryTest.FACTORY_TEST_LOW_LEVEL,
            !mFirstBoot, mOnlyCore);
    ServiceManager.addService(Context.WINDOW_SERVICE, wm);
    ServiceManager.addService(Context.INPUT_SERVICE, inputManager);
    
    //启动
    inputManager.start();
   ...
   }
```



##### InputManagerService

先看看InputManagerService实例化过程，可以看到调用了nativeInit接口
```
//InputManagerService
public InputManagerService(Context context) {
    ...
    mPtr = nativeInit(this, mContext, mHandler.getLooper().getQueue());
    ...
}

//启动
public void start() {
    ...
    nativeStart(mPtr);
    ...
}

private static native long nativeInit(InputManagerService service,
            Context context, MessageQueue messageQueue);
            
private static native void nativeStart(long ptr);            
```

接着我们找到对应的cpp文件：
```
//com_android_server_input_InputManagerService.cpp
static jlong nativeInit(JNIEnv* env, jclass /* clazz */,
        jobject serviceObj, jobject contextObj, jobject messageQueueObj) {
    sp<MessageQueue> messageQueue = android_os_MessageQueue_getMessageQueue(env, messageQueueObj);
    if (messageQueue == NULL) {
        jniThrowRuntimeException(env, "MessageQueue is not initialized.");
        return 0;
    }

    NativeInputManager* im = new NativeInputManager(contextObj, serviceObj,
            messageQueue->getLooper());
            
    im->incStrong(0);
    return reinterpret_cast<jlong>(im);
}

//启动
static void nativeStart(JNIEnv* env, jclass /* clazz */, jlong ptr) {
    NativeInputManager* im = reinterpret_cast<NativeInputManager*>(ptr);
    status_t result = im->getInputManager()->start();
    ...
}
```

可以看到创建了NativeInputManager对象，与此同时，创建了EventHub和InputManager对象：
```
//com_android_server_input_InputManagerService.cpp
NativeInputManager::NativeInputManager(jobject contextObj,
        jobject serviceObj, const sp<Looper>& looper) :
        mLooper(looper), mInteractive(true) {
    JNIEnv* env = jniEnv();

    ...
    sp<EventHub> eventHub = new EventHub();
    mInputManager = new InputManager(eventHub, this, this);
}
```

接着看InputManage，可以看到创建了两个对象，一个叫**InputDispatcher**，一个叫**InputReader**，从字面意思，可以理解为输入分发器和输入读取器，即一个负责事件分发，一个负责事件读取。初始化的时候创建了两条线程，即通过线程去处理事件分发和事件读取，并且在start方法中启动线程。
```
//Inputmanager.cpp
InputManager::InputManager(...) {
    mDispatcher = new InputDispatcher(dispatcherPolicy);
    mReader = new InputReader(eventHub, readerPolicy, mDispatcher);
    initialize();
}

void InputManager::initialize() {
    mReaderThread = new InputReaderThread(mReader);
    mDispatcherThread = new InputDispatcherThread(mDispatcher);
}

status_t InputManager::start() {
    status_t result = mDispatcherThread->run("InputDispatcher", PRIORITY_URGENT_DISPLAY);
    ...

    result = mReaderThread->run("InputReader", PRIORITY_URGENT_DISPLAY);
    ...

    return OK;
}
```

对应的InputManager头文件：
```
//InputManager.h
private:
    sp<InputReaderInterface> mReader;
    sp<InputReaderThread> mReaderThread;

    sp<InputDispatcherInterface> mDispatcher;
    sp<InputDispatcherThread> mDispatcherThread;

    void initialize();
};
```

##### 事件读取

找到InputReaderInterface：
```
//InputReader.h
RawEvent mEventBuffer[EVENT_BUFFER_SIZE];

sp<QueuedInputListener> mQueuedListener;

/* Processes raw input events and sends cooked event data to an input listener. */
/* 预处理原始输入事件后发送事件数据到事件监听器 */
class InputReaderInterface : public virtual RefBase {
...
 /* Runs a single iteration of the processing loop.
     * Nominally reads and processes one incoming message from the EventHub.
     * 从EventHub中读取并处理事件
     * 
     * This method should be called on the input reader thread.
     * 该方法在ReaderThread中被调用
     */
    virtual void loopOnce() = 0;
}
```

```
//InputReader.cpp

//这里的listener传递的其实就是mDispatcher
InputReader::InputReader(... {
        mQueuedListener = new QueuedInputListener(listener);
    ...
}

bool InputReaderThread::threadLoop() {
    mReader->loopOnce();
    return true;
}

//从EventHub中获取事件
void InputReader::loopOnce() {
    ...
    size_t count = mEventHub->getEvents(timeoutMillis, mEventBuffer, EVENT_BUFFER_SIZE);

    { 
        ...
        
        if (count) {
            processEventsLocked(mEventBuffer, count);
        }

        ...
    } 

    ...

    mQueuedListener->flush();
}

//处理RawEvent
//通过processEventsForDeviceLocked处理对应设备事件
//处理设备增加、删除和修改事件
void InputReader::processEventsLocked(const RawEvent* rawEvents, size_t count) {
    for (const RawEvent* rawEvent = rawEvents; count;) {
        int32_t type = rawEvent->type;
        size_t batchSize = 1;
        if (type < EventHubInterface::FIRST_SYNTHETIC_EVENT) {
            ...
            #if DEBUG_RAW_EVENTS
                ALOGD("BatchSize: %zu Count: %zu", batchSize, count);
            #endif
                processEventsForDeviceLocked(deviceId, rawEvent, batchSize);
        } else {
            switch (rawEvent->type) {
            case EventHubInterface::DEVICE_ADDED:
                addDeviceLocked(rawEvent->when, rawEvent->deviceId);
                break;
            case EventHubInterface::DEVICE_REMOVED:
                removeDeviceLocked(rawEvent->when, rawEvent->deviceId);
                break;
            case EventHubInterface::FINISHED_DEVICE_SCAN:
                handleConfigurationChangedLocked(rawEvent->when);
                break;
            default:
                ALOG_ASSERT(false); // can't happen
                break;
            }
        }
        ...
    }
}

void InputReader::processEventsForDeviceLocked(int32_t deviceId,
        const RawEvent* rawEvents, size_t count) {
    ssize_t deviceIndex = mDevices.indexOfKey(deviceId);
    if (deviceIndex < 0) {
        ALOGW("Discarding event for unknown deviceId %d.", deviceId);
        return;
    }

    InputDevice* device = mDevices.valueAt(deviceIndex);
    if (device->isIgnored()) {
        //ALOGD("Discarding event for ignored deviceId %d.", deviceId);
        return;
    }

    device->process(rawEvents, count);
}
```

- threadLoop()方法中返回true的话，线程会继续循环执行，这里会循环执行mReader->loopOnce()。
- loopOnce()方法会从EventHub中取出事件，保存到mEventBuffer中。再通过processEventsLocked方法对读取到的事件进行预先处理。
- mQueuedListener->flush()方法会将事件发送到mDispatcher事件分发器中


##### EventHub
EventHub利用Linux的inotify和epoll机制，通过inotify监听/dev/input/目录，epoll监听获取事件，并且将对应事件封装成RawEvent：

```
//EventHub.cpp
static const char *DEVICE_PATH = "/dev/input";

//构造函数中创建inotify监听DEVICE_PATH目录包括目录下的文件的删除和创建，且通过epoll监听mINotifyFd描述符，当DEVICE_PATH发生变化的时候，会通知当前线程。
EventHub::EventHub(void) : ...{
    ...

    mEpollFd = epoll_create(EPOLL_SIZE_HINT);
    mINotifyFd = inotify_init();
    int result = inotify_add_watch(mINotifyFd, DEVICE_PATH, IN_DELETE | IN_CREATE);

    struct epoll_event eventItem;
    memset(&eventItem, 0, sizeof(eventItem));
    //监听的描述符有内容可读，这时可通过mINotifyFd读取对应的事件
    eventItem.events = EPOLLIN; 
    eventItem.data.u32 = EPOLL_ID_INOTIFY;
    result = epoll_ctl(mEpollFd, EPOLL_CTL_ADD, mINotifyFd, &eventItem);

    ...

    eventItem.data.u32 = EPOLL_ID_WAKE;
    result = epoll_ctl(mEpollFd, EPOLL_CTL_ADD, mWakeReadPipeFd, &eventItem);
    ...
}
```

```
struct RawEvent {
    nsecs_t when; //时间
    int32_t deviceId; //设备id
    int32_t type; //表示输入事件类型
    int32_t code; //表示数据类型
    int32_t value; //表示数据的值
};
```

#### 事件分发
```
//InputDispatcher.h
sp<Looper> mLooper;
Queue<EventEntry> mInboundQueue;
```

```
//InputDispatcher.cpp
//初始化C++层Looper对象
InputDispatcher::InputDispatcher(const sp<InputDispatcherPolicyInterface>& policy) :
    ...
    mLooper = new Looper(false);
    ...
}

bool InputDispatcherThread::threadLoop() {
    mDispatcher->dispatchOnce();
    return true;
}

//接收和分发事件
void InputDispatcher::dispatchOnce() {
    ...
    
    if (!haveCommandsLocked()) {
        dispatchOnceInnerLocked(&nextWakeupTime);
    }

    ...
    mLooper->pollOnce(timeoutMillis);
}

//开始实现分发逻辑
void InputDispatcher::dispatchOnceInnerLocked(nsecs_t* nextWakeupTime) {
    ...

    // 如果事件分发被冻结，不执行超时和分发任何新事件
    if (mDispatchFrozen) {
#if DEBUG_FOCUS
        ALOGD("Dispatch frozen.  Waiting some more.");
#endif
        return;
    }

    ...

    //开始处理新事件
    //若mPendingEvent为null则从队列中取一个出来
    if (! mPendingEvent) {
        if (mInboundQueue.isEmpty()) {
            
            ...

            // 若没有待处理事件，直接返回
            if (!mPendingEvent) {
                return;
            }
        } else {
            // Inbound queue 至少有一个事件.
            mPendingEvent = mInboundQueue.dequeueAtHead();
            traceInboundQueueLengthLocked();
        }

        ...
    }

    ...
    
    //开始分发事件
    switch (mPendingEvent->type) {
    case EventEntry::TYPE_CONFIGURATION_CHANGED: {
        ConfigurationChangedEntry* typedEntry =
                static_cast<ConfigurationChangedEntry*>(mPendingEvent);
        done = dispatchConfigurationChangedLocked(currentTime, typedEntry);
        dropReason = DROP_REASON_NOT_DROPPED; // configuration changes are never dropped
        break;
    }

    case EventEntry::TYPE_DEVICE_RESET: {
        DeviceResetEntry* typedEntry =
                static_cast<DeviceResetEntry*>(mPendingEvent);
        done = dispatchDeviceResetLocked(currentTime, typedEntry);
        dropReason = DROP_REASON_NOT_DROPPED; // device resets are never dropped
        break;
    }

    case EventEntry::TYPE_KEY: {
        KeyEntry* typedEntry = static_cast<KeyEntry*>(mPendingEvent);
        ...
        done = dispatchKeyLocked(currentTime, typedEntry, &dropReason, nextWakeupTime);
        break;
    }

    case EventEntry::TYPE_MOTION: {
        MotionEntry* typedEntry = static_cast<MotionEntry*>(mPendingEvent);
        ...
        done = dispatchMotionLocked(currentTime, typedEntry,
                &dropReason, nextWakeupTime);
        break;
    }

    default:
        ALOG_ASSERT(false);
        break;
    }

   ...
}

bool InputDispatcher::dispatchMotionLocked(
        nsecs_t currentTime, MotionEntry* entry, DropReason* dropReason, nsecs_t* nextWakeupTime) {
        
    //确定窗口目标
    Vector<InputTarget> inputTargets;
        
    ...
    
    if (isPointerEvent) {
        // Pointer event.  (eg. touchscreen)
        injectionResult = findTouchedWindowTargetsLocked(currentTime,
                entry, inputTargets, nextWakeupTime, &conflictingPointerActions);
    } else {
        // Non touch event.  (eg. trackball)
        injectionResult = findFocusedWindowTargetsLocked(currentTime,
                entry, inputTargets, nextWakeupTime);
    }

    ...
   
    dispatchEventLocked(currentTime, entry, inputTargets);
    return true;
}

void InputDispatcher::dispatchEventLocked(nsecs_t currentTime,
        EventEntry* eventEntry, const Vector<InputTarget>& inputTargets) {
    ...

    for (size_t i = 0; i < inputTargets.size(); i++) {
        const InputTarget& inputTarget = inputTargets.itemAt(i);

        ssize_t connectionIndex = getConnectionIndexLocked(inputTarget.inputChannel);
        if (connectionIndex >= 0) {
            sp<Connection> connection = mConnectionsByFd.valueAt(connectionIndex);
            prepareDispatchCycleLocked(currentTime, connection, eventEntry, &inputTarget);
        } else {
            ...
        }
    }
}


```
- threadLoop()方法中返回true的话，线程会继续循环执行，这里会循环执行mDispatcher->dispatchOnce()。
- 调用mLooper->pollOnce(timeoutMillis)后会等待超时或者被唤醒，这里会被InputReader线程唤醒。
- dispatchOnceInnerLocked()被唤醒后开始处理Input消息。
- 在dispatchOnceInnerLocked()中实现具体的事件分发逻辑，通过mInboundQueue取出待分发事件，可以看到有**TYPE_KEY**事件，**TYPE_MOTION**等事件，这里我们分析TYPE_MOTION事件。
- dispatchMotionLocked处理触摸事件分发，首先通过findFocusedWindowTargetsLocked找到目标窗口，再通过dispatchEventLocked将触摸事件发送到目标窗口。

后续上传到Java层解析可参考：https://www.jianshu.com/p/f05d6b05ba17

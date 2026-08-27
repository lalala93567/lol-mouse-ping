#Requires AutoHotkey v2.0
#SingleInstance Force

; --- 初始化 ---
CoordMode "Mouse", "Screen"
IniFile := "Config.ini"

; 释放资源
GifPath := A_Temp "\ping.gif"
SoundPath := A_Temp "\ping.mp3"
FileInstall "ping.gif", GifPath, 1 
FileInstall "ping.mp3", SoundPath, 1 

; 读取配置
if !FileExist(IniFile) {
    IniWrite "XButton1", IniFile, "Settings", "Hotkey"
    IniWrite "150", IniFile, "Settings", "Width"
    IniWrite "150", IniFile, "Settings", "Height"
    IniWrite "1200", IniFile, "Settings", "Duration"
}
MyHotkey := IniRead(IniFile, "Settings", "Hotkey")
MyW := IniRead(IniFile, "Settings", "Width"), MyH := IniRead(IniFile, "Settings", "Height")
MyDuration := IniRead(IniFile, "Settings", "Duration")

; --- 队列管理变量 ---
ClickQueue := []
IsPlaying := false

; 动态绑定
Hotkey MyHotkey, EnqueueClick

; --- 1. 入队函数 ---
EnqueueClick(ThisHotkey) {
    MouseGetPos(&mX, &mY)
    ClickQueue.Push({x: mX, y: mY}) ; 把坐标存入队列
    if !IsPlaying
        ProcessQueue() ; 如果当前没在放，开始处理
}

; --- 2. 队列处理器 ---
ProcessQueue() {
    global IsPlaying
    if ClickQueue.Length = 0 {
        IsPlaying := false
        return
    }

    IsPlaying := true
    Pos := ClickQueue.RemoveAt(1) ; 取出队列第一个坐标
    
    ShowPingAnimation(Pos.x, Pos.y)
}

; --- 3. 核心显示逻辑 ---
ShowPingAnimation(x, y) {
    ; 播放音效
    SoundPlay SoundPath
    
    ; 创建动画窗口
    MyGui := Gui("+AlwaysOnTop -Caption +Owner +E0x20 +ToolWindow")
    MyGui.BackColor := "123456"
    WinSetTransColor("123456", MyGui)
    
    HTML := '<html><head><meta http-equiv="X-UA-Compatible" content="IE=Edge"></head>'
          . '<body style="margin:0;overflow:hidden;background-color:#123456;">'
          . '<img src="' GifPath '?' A_TickCount '" width="' MyW '" height="' MyH '"></body></html>'
    
    wb := MyGui.Add("ActiveX", "w" MyW " h" MyH, "HTMLFile")
    wb.Value.Write(HTML)
    
    MyGui.Show("x" (x - MyW/2) " y" (y - MyH/2) " NoActivate")
    
    ; 动画结束后，销毁并触发下一个
    SetTimer(() => (
        MyGui.Destroy(),
        ProcessQueue() ; 递归调用，处理下一个
    ), -MyDuration)
}

OnExit (*) => (
    FileExist(GifPath) ? FileDelete(GifPath) : "",
    FileExist(SoundPath) ? FileDelete(SoundPath) : ""
)
RunAsTask(SingleInstance := 0, Shortcut := "") ; RunAsTask() v0.23 - Auto-elevates script without UAC prompt
{                                              ;    By SKAN for ah2 on D67M/D683 @ autohotkey.com/r?t=119710
    Global A_Args

    Local  TaskSchd,  TaskRoot,  TaskName,  RunAsTask,  TaskExists
        ,  CmdLine,  PathCrc,  Args,  XML,  AhkPath,  Description
        ,  STMM  :=  A_TitleMatchMode
        ,  DHW   :=  A_DetectHiddenWindows
        ,  SWD   :=  A_WinDelay
        ,  QUO   :=  '"'

    A_TitleMatchMode      :=  1
    A_DetectHiddenWindows :=  1
    A_WinDelay            :=  0

    Try    TaskSchd  :=  ComObject("Schedule.Service")
      ,    TaskSchd.Connect()
      ,    TaskRoot  :=  TaskSchd.GetFolder("\")
    Catch
           Return

    Loop Files A_AhkPath
         AhkPath  :=  A_LoopFileFullPath

    CmdLine  :=  A_IsCompiled ? QUO A_ScriptFullpath QUO :  QUO AhkPath QUO A_Space QUO A_ScriptFullpath QUO
    PathCrc  :=  DllCall("ntdll\RtlComputeCrc32", "int",0, "wstr",CmdLine, "uint",StrLen(CmdLine)*2, "uint")
    TaskName :=  Format("RunAsTask\{1:}_{2:}@{3:08X}", A_ScriptName, A_PtrSize=8 ? "64" : "32", PathCrc)

      Try  RunAsTask  :=  TaskRoot.GetTask(TaskName)
        ,  TaskExists :=  1
    Catch
           TaskExists :=  0


    If ( A_IsAdmin = False )
    {
         If ( A_Args.Length > 0 )
              Args := Format(StrReplace(Format("{:" A_Args.Length "}",""), "`s", "`n{}"), A_Args*)  ; Join()
          ,   WinSetTitle(TaskName Args , A_ScriptHwnd)

         If ( TaskExists = True )
              Try    RunAsTask.Run(0)
              Catch
                     MsgBox("Task launch failed (disabled?):`n" TaskName, "RunAsTask", " 0x40000 Iconx")
                  ,  ExitApp()

         If ( TaskExists = False )
              Try    Run("*RunAs " CmdLine, A_ScriptDir)
              Catch
                     MsgBox("Task not created..`nChoose 'Yes' in UAC",    "RunAsTask", " 0x40000 Iconx T4")
                  ,  ExitApp()

         If ( A_Args.Length > 0 )
              WinWait("Exit_" TaskName " ahk_class AutoHotkey",, 5)

         ExitApp()
    }


    If ( A_IsAdmin = True )
    {
        If ( TaskExists = False )
             XML :=  Format('
                           ( LTrim
                             <?xml version="1.0" ?>
                             <Task xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
                                 <Principals>
                                     <Principal>
                                         <LogonType>InteractiveToken</LogonType>
                                         <RunLevel>HighestAvailable</RunLevel>
                                     </Principal>
                                 </Principals>
                                 <Settings>
                                     <MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
                                     <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
                                     <AllowHardTerminate>true</AllowHardTerminate>
                                     <AllowStartOnDemand>true</AllowStartOnDemand>
                                     <Enabled>true</Enabled>
                                     <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
                                 </Settings>
                                 <Actions>
                                     <Exec>
                                         <Command>{1:}</Command>
                                         <Arguments>{2:}</Arguments>
                                         <WorkingDirectory>{3:}</WorkingDirectory>
                                     </Exec>
                                 </Actions>
                             </Task>
                          )'
                          ,  A_IsCompiled = 1  ?  QUO A_ScriptFullpath QUO  :  QUO AhkPath QUO
                          ,  A_IsCompiled = 0  ?  QUO A_ScriptFullpath QUO  :  ""
                          ,  A_ScriptDir
                          )
         ,   TaskRoot.RegisterTask( TaskName
                                  , XML
                                  , 0x2  ; TASK_CREATE
                                  , ""
                                  , ""
                                  , 3    ; TASK_LOGON_INTERACTIVE_TOKEN
                                  )

        If ( StrLen(Shortcut) )
             Try   FileGetShortcut(Shortcut,,,, &Description)
             Catch
                   Description := ""
             Finally
              If ( Description != Taskname )
                   FileCreateShortcut("schtasks.exe", Shortcut, A_WorkingDir
                                    , "/run /tn " QUO TaskName QUO, TaskName,,,,7)

        If ( SingleInstance )
             DllCall( "User32\ChangeWindowMessageFilterEx"
                    , "ptr",  A_ScriptHwnd
                    , "uint", 0x44       ;  WM_COMMNOTIFY
                    , "uint", 1          ;  MSGFLT_ALLOW
                    , "ptr",  0
                    )

        If ( WinExist(TaskName " ahk_class AutoHotkey") )
             Args   :=  WinGetTitle()
         ,   WinSetTitle("Exit_" TaskName)
         ,   Args   :=  SubStr(Args, InStr(Args, "`n") + 1)
         ,   A_Args :=  StrSplit(Args, "`n")
    }

    A_WinDelay            :=  SWD
    A_DetectHiddenWindows :=  DHW
    A_TitleMatchMode      :=  STMM

    Return TaskName
} ; ________________________________________________________________________________________________________

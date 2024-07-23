// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Management.Automation.Internal;
using System.Management.Automation.Interpreter;
using System.Management.Automation.Language;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;
using Microsoft.PowerShell.Commands;

namespace System.Management.Automation.Deobfuscation
{
    internal static class DeobfuscationGlobalVariables
    {
        public static bool EnableDeobfuscation = false;

        public static bool EnableRecord = false;

        public static bool EnableInstructionsRecord = false;

        public static Expression currentExpr;
        //Expression-related expr in compiling
        public static Stack whileAst = new Stack();
        public static Instruction currentInstruction;
        //current instruction
        public static Dictionary<Expression, Ast> astMap = new Dictionary<Expression, Ast>();
        public static string scriptBlock;
        public static Stack blocks = new Stack();

        //unti-compiler optimization
        public static Dictionary<string, Dictionary<string, object>> dotNetInfo = new Dictionary<string, Dictionary<string, object>>();

        //public static Stack loops = new Stack();
        //public static Stack ifs = new Stack();

        public static IScriptExtent currentIexScriptExtent;

        public static bool isTimeOut = true;

        public static Dictionary<Ast, int> endLoopMap = new Dictionary<Ast, int>();

        //Assignment of object properties(RandomCase Deobfuscation)
        public static Dictionary<string, string> setMembers = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

        //Store the variable judgment of the loop, where the key is the offset of the variable
        public static Stack loopVariables = new Stack();
        public static int MaxLoopTimes = 10;

        public static string[] nativeBlacklist = { "cmd.exe", "shutdown.exe", "restart.exe", "certutil.exe", "bitsadmin.exe", "curl.exe", "wget.exe", "powershell.exe", "pwsh.exe"};
        public static string[] cmdletBlacklist = { "start-sleep", "restart-computer", "invoke-webrequest", "invoke-restmethod", "test-connection"};
        public static string[] dotnetBlacklist = { "sleep", "shellexecute", "createthread", "showdialog" }; 
        //downloadxxx,New-Object Net.Sockets.TCPClient('39.156.66.10',80)

        public static string[] iexObfuscations = { "((Get-Variable'*mdr*').Name[3,11,2]-Join'')", "((GV'*mdr*').Name[3,11,2]-Join'')", "((Variable'*mdr*').Name[3,11,2]-Join'')", "(([STring]''.indEXof)[149,399,62]-joIn'')" };

    }
}

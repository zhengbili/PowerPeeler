// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.Dynamic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using Newtonsoft.Json;
using System.Security.Cryptography;
using System.Linq;
using System.Collections;
using System.Management.Automation.Language;
using System.Threading;

namespace System.Management.Automation.Deobfuscation
{
    internal static class DeobfuscationUtils
    {
        public static string logFilename = "log.txt";

        public static string recordFilename = "sinkFunctionRecord.txt";

        public static List<Dictionary<string, object>> log = new List<Dictionary<string, object>>();

        public static List<Dictionary<string, object>> sinkFunctionRecord = new List<Dictionary<string, object>>();

        public static string scriptBlockInstruction;

        public static int instructions;

        public static bool enableAmsi;

        public static string amsiInputPath;
        public static string amsiResultPath;

        public static HashSet<string> amsiLogs = new HashSet<string>();

#pragma warning disable SYSLIB0011
        public static BinaryFormatter formatter = new BinaryFormatter();

        public static void WriteLog(object message)
        {
            if (message.GetType() == typeof(Dictionary<string, object>))
            {
                WriteLogObject((Dictionary<string, object>)message);
            }
            else
            {
                using (StreamWriter sw = new StreamWriter(DeobfuscationUtils.logFilename, true))
                {
                    sw.WriteLine(DeobfuscationUtils.ConvertToJson(message).Replace("\n", string.Empty).Replace("\r", string.Empty));
                }
            }
        }

        public static void WriteLogObject(Dictionary<string, object> message)
        {
            log.Add(new Dictionary<string, object>(message));
            if (DeobfuscationUtils.enableAmsi)
            {
                string input = string.Empty;
                try
                {
                    input = DeobfuscationUtils.ConvertToJson(message);
                }
                catch
                {

                }
                string key = string.Empty;
                if (message.ContainsKey("iexOffset"))
                {
                    key += "iex:" + (int[][])message["iexOffset"];
                }
                key += "basic:" + message["startOffset"] + "," + message["endOffset"];

                if (!amsiLogs.Contains(key))
                {
                    amsiLogs.Add(key);
                    if (AmsiUtils.ScanContent(input, "detect") == AmsiUtils.AmsiNativeMethods.AMSI_RESULT.AMSI_RESULT_DETECTED)
                    {
                        throw new Exception("Malicious code detected in deobfuscation.");
                    }
                }

            }
        }

        public static string ConvertToJson(object obj)
        {
            return JsonConvert.SerializeObject(obj, Formatting.Indented);
            //return PSSerializer.Serialize(obj);
        }

        public static object DeepCopy(object obj)
        {
            try
            {
                MemoryStream stream = new MemoryStream();
                formatter.Serialize(stream, obj);
                stream.Seek(0, SeekOrigin.Begin);
                return formatter.Deserialize(stream);
            }
            catch
            {
                return obj;
            }

        }

        public static string ObjectSerialize(object obj)
        {
            try
            {
                #pragma warning disable SYSLIB0011
                MemoryStream stream = new MemoryStream();
                formatter.Serialize(stream, obj);
                string result = System.Convert.ToBase64String(stream.ToArray());
                stream.Flush();
                return result;
            }
            catch
            {
                return PSSerializer.Serialize(obj);
            }
            //return PSSerializer.Serialize(obj);
        }

        public static object CalculateHash(object obj)
        {
            try
            {
                if (obj.GetType() == typeof(NaNObject))
                {
                    return "NaNObject";
                }
                MemoryStream stream = new MemoryStream();
                formatter.Serialize(stream, obj);
                byte[] result = stream.ToArray();
                stream.Flush();
                #pragma warning disable SYSLIB0021
                return new MD5CryptoServiceProvider().ComputeHash(result);
            }
            catch
            {
                return obj;
            }
        }

        public static bool CompareHash(object preHash, object curHash)
        {
            try
            {
                if (preHash.GetType() != typeof(byte[]) || curHash.GetType() != typeof(byte[]))
                {
                    return preHash == curHash;
                }
                byte[] pre = (byte[])preHash;
                byte[] cur = (byte[])curHash;
                return pre.SequenceEqual(cur);
            }
            catch
            {
                return false;
            }
        }

        public static bool CompareObjects(object obj1, object obj2)
        {
            try
            {
                bool result = false;
                using (MemoryStream stream1 = new MemoryStream())
                using (MemoryStream stream2 = new MemoryStream())
                {
                    formatter.Serialize(stream1, obj1);
                    formatter.Serialize(stream2, obj2);
                    result = stream1.ToArray().SequenceEqual(stream2.ToArray());
                    stream1.Flush();
                    stream2.Flush();
                }
                return result;
            }
            catch
            {
                return obj1 == obj2;
            }
        }

        public static void RecordLoopVariable(object value, int startOffset, int endOffset)
        {
            Stack currentIex = (Stack)DeobfuscationGlobalVariables.loopVariables.Peek();
            if (currentIex.Count > 0)
            {
                Dictionary<(int, int), object[]> currenVariable = (Dictionary<(int, int), object[]>)(currentIex.Peek());
                if (currenVariable.ContainsKey((startOffset, endOffset)))
                {
                    object[] values = (object[])currenVariable[(startOffset, endOffset)];
                    object curHash = DeobfuscationUtils.CalculateHash(value);
                    if (DeobfuscationUtils.CompareHash(values[0], curHash))
                    {
                        values[1] = (int)values[1] + 1; //times++
                    }
                    else
                    {
                        values[1] = 0;
                    }
                    values[0] = curHash;
                }
                else
                {
                    object[] values = new object[2];
                    values[0] = DeobfuscationUtils.CalculateHash(value);
                    values[1] = 0;
                    currenVariable[(startOffset, endOffset)] = values;
                }
            }
        }

        public static void RecordSinkFunction(string message)
        {
            using (StreamWriter sw = new StreamWriter(recordFilename, true))
            {
                sw.WriteLine(message);
            }
        }

        public static void RecordSinkFunctionObject(Dictionary<string, object> message)
        {
            sinkFunctionRecord.Add(new Dictionary<string, object>(message));
        }

    }

    [Serializable]
    internal class NaNObject : DynamicObject
    {
        // The inner dictionary to store field names and values.
        public Dictionary<string, object> _dictionary = new Dictionary<string, object>();

        // Get the property value.
        public override bool TryGetMember(
            GetMemberBinder binder, out object result)
        {
            if (_dictionary.ContainsKey(binder.Name))
            {
                _dictionary.TryGetValue(binder.Name, out result);
            }
            else
            {
                result = new NaNObject();
            }
            return true;
        }

        // Set the property value.
        public override bool TrySetMember(
            SetMemberBinder binder, object value)
        {
            _dictionary[binder.Name] = value;
            return true;
        }

        public override bool TryBinaryOperation(
        BinaryOperationBinder binder, object arg, out object result)
        {
            result = this;
            return true;
        }

        public override bool TryUnaryOperation(
        UnaryOperationBinder binder, out object result)
        {
            result = this;
            return true;
        }

        // Converting an object to a specified type.
        public override bool TryConvert(
            ConvertBinder binder, out object result)
        {
            if (binder.Type == typeof(bool))
            {
                result = false;
            }
            else
            {
                result = this;
            }
            return true;
        }

        // Set the property value by index.
        public override bool TrySetIndex(
            SetIndexBinder binder, object[] indexes, object value)
        {
            int index = (int)indexes[0];

            // If a corresponding property already exists, set the value.
            if (_dictionary.ContainsKey("Property" + index))
                _dictionary["Property" + index] = value;
            else
                // If a corresponding property does not exist, create it.
                _dictionary.Add("Property" + index, value);
            return true;
        }

        // Get the property value by index.
        public override bool TryGetIndex(
            GetIndexBinder binder, object[] indexes, out object result)
        {

            int index = (int)indexes[0];
            return _dictionary.TryGetValue("Property" + index, out result);
        }

        public override bool TryInvokeMember(InvokeMemberBinder binder, object[] args, out object result)
        {
            result = new NaNObject();
            return true;
        }

    }
}

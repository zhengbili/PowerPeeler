using System;
using System.Text;
using System.Collections;

public class CmdParser
{
    static int index = 0;
    static ArrayList split(string line, int k = 0)
    {
        ArrayList info = new ArrayList();
        bool f = true;
        int w1, w2 = -1, i = 0;
        while (i < line.Length && " \t".Contains(line[i])) { i += 1; }
        w1 = i;
        while (i < line.Length)
        {
            if (f)
            {
                if (w1 < w2 && !" \t".Contains(line[i]))
                {
                    w1 = i;
                    if (k > 0 && info.Count >= k - 1)
                    {
                        info.Add(line.Substring(w1));
                        return info;
                    }
                }
                else if (w2 < w1 && " \t".Contains(line[i]))
                {
                    w2 = i;
                    info.Add(line.Substring(w1, w2 - w1));
                }
            }
            else
            {
                if (line[i] == '\\') { i += 2; continue; }
            }
            if (line[i] == '"') { f = !f; }
            i += 1;
        }
        if (w2 < w1 && w1 < line.Length) { info.Add(line.Substring(w1)); }
        return info;
    }
    static void write(string s)
    {
        index += 1;
        try
        {
            StreamWriter sw = new StreamWriter("out/" + index.ToString() + ".txt");
            sw.Write(s);
            sw.Close();
        }
        catch (Exception e)
        {
            Console.WriteLine("Exception: " + e.Message);
        }
    }
    static bool between(string s, string[] shorts, string[] longs)
    {
        bool f1 = false, f2 = false;
        foreach (string c in shorts)
        {
            if (s.StartsWith(c)) f1 = true;
        }
        foreach (string c in longs)
        {
            if (c.StartsWith(s)) f2 = true;
        }
        return (f1 && f2);
    }
    public static ArrayList[] parse(string filename)
    {
        ArrayList errors = new ArrayList();
        ArrayList results = new ArrayList();
        string[] short_argvs = { "-nol", "-noe", "-st", "-mta", "-nop", "-noni" };
        string[] long_argvs = { "-nologo", "-noexit", "-sta", "-mta", "-noprofile", "-noninteractive" };
        try
        {
            StreamReader file = new StreamReader(filename);
            string line;
            while ((line = file.ReadLine()) != null)
            {
                ArrayList info = split(line);
                if (info.Count == 0) continue;
                if (((string)info[0]).Contains("powershell") || ((string)info[0]).Contains("pwsh"))
                {
                    if (info.Count < 2) errors.Add("Few args: " + line);
                    int i = 1;
                    while (i < info.Count)
                    {
                        string argv = ((string)info[i]).ToLower();
                        if (argv[0] == '/') argv = "-" + argv.Substring(1);
                        if (argv == "-ec" || (argv.StartsWith("-e") && "-encodedcommand".StartsWith(argv)))
                        {
                            string script;
                            try
                            {
                                string enc = ((string)info[i + 1]).Trim('"');
                                while (enc.Length % 4 > 0) enc += "=";
                                script = Encoding.GetEncoding("UTF-16").GetString(Convert.FromBase64String(enc));
                                results.Add(script);
                            }
                            catch
                            {
                                errors.Add("Bad Base64: " + line);
                            }
                            break;
                        }
                        if (argv.StartsWith("-c") && "-command".StartsWith(argv))
                        {
                            string next_argv = (string)info[i + 1];
                            if (next_argv[0] == '"' && next_argv[next_argv.Length - 1] == '"')
                            {
                                try
                                {
                                    string script = System.Text.RegularExpressions.Regex.Unescape(next_argv.Substring(1, next_argv.Length - 2));
                                    results.Add(script);
                                }
                                catch
                                {
                                    errors.Add("Wrong string: " + line);
                                }
                            }
                            else
                            {
                                ArrayList t = split(line, i + 2);
                                string script = (string)t[t.Count - 1];
                                if (script[0] == '"') script = script.Substring(1);
                                results.Add(script);
                            }
                            break;
                        }
                        if (between(argv, short_argvs, long_argvs)) { i += 1; continue; }
                        if (argv[0] == '-') { i += 2; continue; }
                        if (argv[0] == '"' && argv[argv.Length - 1] == '"')
                        {
                            try
                            {
                                string t = (string)info[i];
                                string script = System.Text.RegularExpressions.Regex.Unescape(t.Substring(1, t.Length - 2));
                                results.Add(script);
                            }
                            catch
                            {
                                errors.Add("Wrong string: " + line);
                            }
                        }
                        else
                        {
                            ArrayList t = split(line, i + 1);
                            string script = (string)t[t.Count - 1];
                            if (script[0] == '"') script = script.Substring(1);
                            results.Add(script);
                        }
                        break;

                    }
                    if (i == info.Count) errors.Add("No argv found: " + line);
                }

            }
            file.Close();
        }
        catch (Exception e)
        {
            Console.WriteLine("Exception: " + e.Message);
        }
        return new ArrayList[] { results, errors };
    }
    static void Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.WriteLine("Usage: ./CmdParser [oneline_command_path]");
            return;
        }
        ArrayList[] info = parse(args[0]);
        ArrayList results = info[0], errors = info[1];
        foreach (string s in results) write(s);
        foreach (string s in errors) Console.WriteLine(s);
    }
}
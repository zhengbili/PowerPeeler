using System;
using System.Text;

namespace DeobfuscationHelper
{
    public class Stringify
    {
        public Stringify()
        {
        }
        public static string QuoteChar(char[] str)
        {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < str.Length; i++)
            {
                char c = str[i];

                if(c=='"'||c=='$'||c=='`')sb.Append("`"+c);
                else if (Char.IsLetterOrDigit(c) || "!#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r".Contains(c))sb.Append(c);
                else sb.Append("`u{"+String.Format("{0:x2}",(int)c)+"}");
            }
            return sb.ToString();
        }
        public static double PrintableRate(byte[] str)
        {
            double s=0;
            for (int i = 0; i < str.Length; i++)
            {
                char c =  System.Convert.ToChar(str[i]);
                if ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\"$`!#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r".Contains(c))s+=1;
            }
            return s/str.Length;
        }
    }
}
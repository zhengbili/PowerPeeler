using System.Text.Json;

public class Echo
{
    static void Main(string[] args)
    {
        Console.WriteLine(JsonSerializer.Serialize(args));
    }
}
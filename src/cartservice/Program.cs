// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using CommandLine;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using cartservice.cartstore;
using Microsoft.Extensions.DependencyInjection;
using System.Runtime.CompilerServices;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using System.Net;
using Microsoft.Extensions.Configuration;

[assembly: InternalsVisibleTo("cartservice.tests")]
namespace cartservice
{
    public class Program
    {
        const string CART_SERVICE_ADDRESS = "LISTEN_ADDR";
        const string REDIS_ADDRESS = "REDIS_ADDR";
        const string CART_SERVICE_PORT = "PORT";

        [Verb("start", HelpText = "Starts the server listening on provided port")]
        public sealed class ServerOptions
        {
            [Option('h', "hostname", HelpText = "The ip on which the server is running. If not provided, LISTEN_ADDR environment variable value will be used. If not defined, localhost is used")]
            public string Host { get; set; }

            [Option('p', "port", HelpText = "The port on for running the server")]
            public int Port { get; set; }

            [Option('r', "redis", HelpText = "The ip of redis cache")]
            public string Redis { get; set; }
        }

        public static async Task Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Invalid number of arguments supplied");
                Environment.Exit(-1);
            }

            switch (args[0])
            {
                case "start":
                    await Parser.Default.ParseArguments<ServerOptions>(args).MapResult<ServerOptions, Task<int>>(
                        async (ServerOptions options) =>
                        {
                            Console.WriteLine($"Started as process with id {System.Diagnostics.Process.GetCurrentProcess().Id}");

                            // Set hostname/ip address
                            string hostname = ReadParameter("host address", options.Host, CART_SERVICE_ADDRESS, p => p, "0.0.0.0");

                            // Set the port
                            int port = ReadParameter("cart service port", options.Port, CART_SERVICE_PORT, int.Parse, 8080);

                            // Set redis cache host (hostname+port)
                            string redis = ReadParameter("redis cache address", options.Redis, REDIS_ADDRESS, p => p, null);

                            // Start ASP.NET Core Engine with GRPC
                            IHost hostBuilder = CreateHostBuilder(redis).Build();
                            await hostBuilder.RunAsync();
                            return 0;
                        },
                        errs => Task.FromResult(1));
                    break;
                default:
                    Console.WriteLine("Invalid command");
                    break;
            }

            await Task.FromResult(0);
        }

        /// <summary>
        /// Reads parameter in the right order
        /// </summary>
        /// <param name="description">Parameter description</param>
        /// <param name="commandLineValue">Value provided from the command line</param>
        /// <param name="environmentVariableName">The name of environment variable where it could have been set</param>
        /// <param name="environmentParser">The method that parses environment variable and returns typed parameter value</param>
        /// <param name="defaultValue">Parameter's default value - in case other method failed to assign a value</param>
        /// <typeparam name="T">The type of the parameter</typeparam>
        /// <returns>Parameter value read from all the sources in the right order(priorities)</returns>
        private static T ReadParameter<T>(
            string description,
            T commandLineValue, 
            string environmentVariableName, 
            Func<string, T> environmentParser, 
            T defaultValue)
        {
            // Command line argument
            if(!EqualityComparer<T>.Default.Equals(commandLineValue, default(T))) 
            {
                Console.WriteLine($"Reading {description} from command line argument. Value: {commandLineValue}. Done!");
                return commandLineValue;
            }

            // Environment variable
            Console.Write($"Reading {description} from environment variable {environmentVariableName}. ");
            string envValue = Environment.GetEnvironmentVariable(environmentVariableName);
            if (!string.IsNullOrEmpty(envValue))
            {
                try
                {
                    var envTyped = environmentParser(envValue);
                    Console.Write($" Value: {envTyped} ");
                    Console.WriteLine("Done!");
                    return envTyped;
                }
                catch (Exception)
                {
                    // We assign the default value later on
                }
            }

            Console.WriteLine($"Environment variable {environmentVariableName} was not set. Setting {description} to {defaultValue}");
            return defaultValue;
        }

        // Additional configuration is required to successfully run gRPC on macOS.
        // For instructions on how to configure Kestrel and gRPC clients on macOS, visit https://go.microsoft.com/fwlink/?linkid=2099682
        static IHostBuilder CreateHostBuilder(string redisAddr) =>
            Host.CreateDefaultBuilder()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureKestrel(options =>
                    {
                        options.Listen(IPAddress.Any, 7070, listenOptions =>
                        {
                            listenOptions.Protocols = HttpProtocols.Http2;
                        });
                    });

                    webBuilder.UseStartup<Startup>();
                    webBuilder.UseSetting("RedisAddress", redisAddr);
                });
    }
}

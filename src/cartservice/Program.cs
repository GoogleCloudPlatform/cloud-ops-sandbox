// Copyright 2020 Google LLC
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

using cartservice;
using cartservice.cartstore;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
string redisAddress = builder.Configuration["REDIS_ADDR"];
ICartStore cartStore = null;
if (!string.IsNullOrEmpty(redisAddress))
{

    cartStore = new RedisCartStore(redisAddress);
}
else
{
    Console.WriteLine("Redis cache host(hostname+port) was not specified. Starting a cart service using local store");
    Console.WriteLine("If you wanted to use Redis Cache as a backup store, you should provide its address via command line or REDIS_ADDR environment variable.");
    cartStore = new LocalCartStore();
}

// Initialize the redis store
cartStore.InitializeAsync().GetAwaiter().GetResult();
Console.WriteLine("Initialization completed");

builder.Services.AddSingleton<ICartStore>(cartStore);
builder.Services.AddGrpc();

// Adding the OtlpExporter creates a GrpcChannel.
// This switch must be set before creating a GrpcChannel/HttpClient when calling an insecure gRPC service.
// See: https://docs.microsoft.com/aspnet/core/grpc/troubleshoot#call-insecure-grpc-services-with-net-core-client
AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

builder.Services.AddOpenTelemetryTracing(tracing =>
{
    tracing.AddAspNetCoreInstrumentation()
        .AddOtlpExporter(options =>
            options.Endpoint = new Uri(builder.Configuration["OTEL_COLLECTOR_ADDR"]));
    if (cartStore is RedisCartStore redisCartStore)
    {
        tracing.AddRedisInstrumentation(redisCartStore.RedisConnectionMultiplexer);
    }
}
);

var app = builder.Build();

// Configure the HTTP request pipeline.

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseAuthorization();

app.MapControllers();
app.MapGrpcService<CartServiceController>();
app.MapGrpcService<HealthCheckService>();

app.MapGet("/", async context =>
    {
        await context.Response.WriteAsync("Communication with gRPC endpoints must be made through a gRPC client. To learn how to create a client, visit: https://go.microsoft.com/fwlink/?linkid=2086909");
    });

app.Run();
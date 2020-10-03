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

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using cartservice.interfaces;
using Grpc.Core;
using Microsoft.Extensions.Logging;

namespace cart_grpc
{
    public class CartServiceImpl : Hipstershop.CartService.CartServiceBase
    {
        private readonly ILogger<CartServiceImpl> _logger;
        private readonly ICartStore _cartStore;

        internal CartServiceImpl(
            ICartStore cartService,
            ILogger<CartServiceImpl> logger)
        {
            _logger = logger;
            _cartStore = cartService;
        }

        public async void Start()
        {
            Console.WriteLine("Starting cart service...");
            await _cartStore.InitializeAsync();
        }
    }
}

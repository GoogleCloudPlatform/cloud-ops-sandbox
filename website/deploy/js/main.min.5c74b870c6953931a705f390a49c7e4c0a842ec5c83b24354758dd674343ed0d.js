/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function(a){'use strict';a(function(){a('[data-toggle="tooltip"]').tooltip(),a('[data-toggle="popover"]').popover(),a('.popover-dismiss').popover({trigger:'focus'})});function b(a){return a.offset().top+a.outerHeight()}a(function(){var c=a(".js-td-cover"),e,f,d;if(!c.length)return;e=b(c),f=a('.js-navbar-scroll').offset().top,d=Math.ceil(a('.js-navbar-scroll').outerHeight()),e-f<d&&a('.js-navbar-scroll').addClass('navbar-bg-onscroll'),a(window).on('scroll',function(){var f=a('.js-navbar-scroll').offset().top-a(window).scrollTop(),c=b(a('.js-td-cover')),e=a('.js-navbar-scroll').offset().top;c-e<d?a('.js-navbar-scroll').addClass('navbar-bg-onscroll'):(a('.js-navbar-scroll').removeClass('navbar-bg-onscroll'),a('.js-navbar-scroll').addClass('navbar-bg-onscroll--fade'))})})})(jQuery),function(a){'use strict';a(function(){var a=document.getElementsByTagName('main')[0],b;if(!a)return;b=a.querySelectorAll('h1, h2, h3, h4, h5, h6'),b.forEach(function(b){if(b.id){var a=document.createElement('a');a.style.visibility='hidden',a.setAttribute('aria-hidden','true'),a.innerHTML=' <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" width="24" height="24" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none"/><path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/></svg>',a.href='#'+b.id,b.insertAdjacentElement('beforeend',a),b.addEventListener('mouseenter',function(){a.style.visibility='initial'}),b.addEventListener('mouseleave',function(){a.style.visibility='hidden'})}})})}(jQuery),function(a){'use strict';var b={init:function(){a(document).ready(function(){a(document).on('keypress','.td-search-input',function(d){var b,c;if(d.keyCode!==13)return;return b=a(this).val(),c="/search/?q="+b,document.location=c,!1})})}};b.init()}(jQuery)
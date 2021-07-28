#!/bin/bash
set -e
set -x

HTTP_ADDR=$(sandboxctl describe | grep "Hipstershop web app address" | awk '{ print $NF  }')

# page should load and show a typewriter
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter
sandboxctl sre-recipes break recipe3
sleep 5
# page should now return a 500 server error
curl -I --no-fail $HTTP_ADDR/product/OLJCESPC7Z | grep "500 Internal Server Error" 
sandboxctl sre-recipes restore recipe3
sleep 5
# check for expected log in recommendationservice
kubectl logs deploy/recommendationservice server | grep "invalid literal for int() with base 10: '5.0'"
# after restoring, site should load properly again
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter

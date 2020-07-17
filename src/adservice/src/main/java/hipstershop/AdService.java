/*
 * Copyright 2018, Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package hipstershop;

import com.google.common.collect.ImmutableListMultimap;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Iterables;
import hipstershop.Demo.Ad;
import hipstershop.Demo.AdRequest;
import hipstershop.Demo.AdResponse;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.StatusRuntimeException;
import io.grpc.health.v1.HealthCheckResponse.ServingStatus;
import io.grpc.services.*;
import io.grpc.stub.StreamObserver;
import io.opencensus.common.Duration;
import io.opencensus.contrib.grpc.metrics.RpcViews;
import io.opencensus.exporter.stats.stackdriver.StackdriverStatsConfiguration;
import io.opencensus.exporter.stats.stackdriver.StackdriverStatsExporter;
import io.opencensus.exporter.trace.stackdriver.StackdriverTraceConfiguration;
import io.opencensus.exporter.trace.stackdriver.StackdriverTraceExporter;
import io.opencensus.trace.AttributeValue;
import io.opencensus.trace.Span;
import io.opencensus.trace.Tracer;
import io.opencensus.trace.Tracing;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public final class AdService {

  private static final Logger logger = LogManager.getLogger(AdService.class);
  private static final Tracer tracer = Tracing.getTracer();

  private static int MAX_ADS_TO_SERVE = 2;
  private Server server;
  private HealthStatusManager healthMgr;

  private static final AdService service = new AdService();

  private void start() throws IOException {
    int port = Integer.parseInt(System.getenv("PORT"));
    healthMgr = new HealthStatusManager();

    server =
        ServerBuilder.forPort(port)
            .addService(new AdServiceImpl())
            .addService(healthMgr.getHealthService())
            .build()
            .start();
    logger.info("Ad Service started, listening on " + port);
    Runtime.getRuntime()
        .addShutdownHook(
            new Thread() {
              @Override
              public void run() {
                // Use stderr here since the logger may have been reset by its JVM shutdown hook.
                System.err.println("*** shutting down gRPC ads server since JVM is shutting down");
                AdService.this.stop();
                System.err.println("*** server shut down");
              }
            });
    healthMgr.setStatus("", ServingStatus.SERVING);
  }

  private void stop() {
    if (server != null) {
      healthMgr.clearStatus("");
      server.shutdown();
    }
  }

  private static class AdServiceImpl extends hipstershop.AdServiceGrpc.AdServiceImplBase {

    /**
     * Retrieves ads based on context provided in the request {@code AdRequest}.
     *
     * @param req the request containing context.
     * @param responseObserver the stream observer which gets notified with the value of {@code
     *     AdResponse}
     */
    @Override
    public void getAds(AdRequest req, StreamObserver<AdResponse> responseObserver) {
      AdService service = AdService.getInstance();
      Span span = tracer.getCurrentSpan();
      try {
        span.putAttribute("method", AttributeValue.stringAttributeValue("getAds"));
        List<Ad> allAds = new ArrayList<>();
        logger.info("received ad request (context_words=" + req.getContextKeysList() + ")");
        if (req.getContextKeysCount() > 0) {
          span.addAnnotation(
              "Constructing Ads using context",
              ImmutableMap.of(
                  "Context Keys",
                  AttributeValue.stringAttributeValue(req.getContextKeysList().toString()),
                  "Context Keys length",
                  AttributeValue.longAttributeValue(req.getContextKeysCount())));
          for (int i = 0; i < req.getContextKeysCount(); i++) {
            Collection<Ad> ads = service.getAdsByCategory(req.getContextKeys(i));
            allAds.addAll(ads);
          }
        } else {
          span.addAnnotation("No Context provided. Constructing random Ads.");
          allAds = service.getRandomAds();
        }
        if (allAds.isEmpty()) {
          // Serve random ads.
          span.addAnnotation("No Ads found based on context. Constructing random Ads.");
          allAds = service.getRandomAds();
        }
        AdResponse reply = AdResponse.newBuilder().addAllAds(allAds).build();
        responseObserver.onNext(reply);
        responseObserver.onCompleted();
      } catch (StatusRuntimeException e) {
        logger.log(Level.WARN, "GetAds Failed", e.getStatus());
        responseObserver.onError(e);
      }
    }
  }

  private static final ImmutableListMultimap<String, Ad> adsMap = createAdsMap();

  private Collection<Ad> getAdsByCategory(String category) {
    return adsMap.get(category);
  }

  private static final Random random = new Random();

  private List<Ad> getRandomAds() {
    List<Ad> ads = new ArrayList<>(MAX_ADS_TO_SERVE);
    Collection<Ad> allAds = adsMap.values();
    for (int i = 0; i < MAX_ADS_TO_SERVE; i++) {
      ads.add(Iterables.get(allAds, random.nextInt(allAds.size())));
    }
    return ads;
  }

  private static AdService getInstance() {
    return service;
  }

  /** Await termination on the main thread since the grpc library uses daemon threads. */
  private void blockUntilShutdown() throws InterruptedException {
    if (server != null) {
      server.awaitTermination();
    }
  }

  private static ImmutableListMultimap<String, Ad> createAdsMap() {
    Ad camera =
        Ad.newBuilder()
            .setRedirectUrl("/product/2ZYFJ3GM2N")
            .setText("Film camera for sale. 50% off.")
            .build();
    Ad lens =
        Ad.newBuilder()
            .setRedirectUrl("/product/66VCHSJNUP")
            .setText("Vintage camera lens for sale. 20% off.")
            .build();
    Ad recordPlayer =
        Ad.newBuilder()
            .setRedirectUrl("/product/0PUK6V6EV0")
            .setText("Vintage record player for sale. 30% off.")
            .build();
    Ad bike =
        Ad.newBuilder()
            .setRedirectUrl("/product/9SIQT8TOJO")
            .setText("City Bike for sale. 10% off.")
            .build();
    Ad baristaKit =
        Ad.newBuilder()
            .setRedirectUrl("/product/1YMWWN1N4O")
            .setText("Home Barista kitchen kit for sale. Buy one, get second kit for free")
            .build();
    Ad airPlant =
        Ad.newBuilder()
            .setRedirectUrl("/product/6E92ZMYYFZ")
            .setText("Air plants for sale. Buy two, get third one for free")
            .build();
    Ad terrarium =
        Ad.newBuilder()
            .setRedirectUrl("/product/L9ECAV7KIM")
            .setText("Terrarium for sale. Buy one, get second one for free")
            .build();
    return ImmutableListMultimap.<String, Ad>builder()
        .putAll("photography", camera, lens)
        .putAll("vintage", camera, lens, recordPlayer)
        .put("cycling", bike)
        .put("cookware", baristaKit)
        .putAll("gardening", airPlant, terrarium)
        .build();
  }

  private static void initStackdriver() {
    logger.info("Initialize StackDriver");

    long sleepTime = 10; /* seconds */
    int maxAttempts = 5;
    boolean statsExporterRegistered = false;
    boolean traceExporterRegistered = false;

    for (int i = 0; i < maxAttempts; i++) {
      try {
        if (!traceExporterRegistered) {
          StackdriverTraceExporter.createAndRegister(
              StackdriverTraceConfiguration.builder().build());
          traceExporterRegistered = true;
        }
        if (!statsExporterRegistered) {
          StackdriverStatsExporter.createAndRegister(
              StackdriverStatsConfiguration.builder()
                  .setExportInterval(Duration.create(60, 0))
                  .build());
          statsExporterRegistered = true;
        }
      } catch (Exception e) {
        if (i == (maxAttempts - 1)) {
          logger.log(
              Level.WARN,
              "Failed to register Stackdriver Exporter."
                  + " Tracing and Stats data will not reported to Stackdriver. Error message: "
                  + e.toString());
        } else {
          logger.info("Attempt to register Stackdriver Exporter in " + sleepTime + " seconds ");
          try {
            Thread.sleep(TimeUnit.SECONDS.toMillis(sleepTime));
          } catch (Exception se) {
            logger.log(Level.WARN, "Exception while sleeping" + se.toString());
          }
        }
      }
    }
    logger.info("StackDriver initialization complete.");
  }

  /** Main launches the server from the command line. */
  public static void main(String[] args) throws IOException, InterruptedException {
    // Registers all RPC views.
    RpcViews.registerAllGrpcViews();

    new Thread(
            new Runnable() {
              public void run() {
                initStackdriver();
              }
            })
        .start();

    // Start the RPC server. You shouldn't see any output from gRPC before this.
    logger.info("AdService starting.");
    final AdService service = AdService.getInstance();
    service.start();
    service.blockUntilShutdown();
  }
}

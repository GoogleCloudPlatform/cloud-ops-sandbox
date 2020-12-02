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

package main

import (
	"context"
	"fmt"
	"html/template"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"

	pb "github.com/GoogleCloudPlatform/microservices-demo/src/frontend/genproto"
	"github.com/GoogleCloudPlatform/microservices-demo/src/frontend/money"
)

var (
	templates = template.Must(template.New("").
		Funcs(template.FuncMap{
			"renderMoney": renderMoney,
		}).ParseGlob("templates/*.html"))
)

func (fe *frontendServer) homeHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	log.WithField("currency", currentCurrency(r)).Info("home")
	currencies, err := fe.getCurrencies(r.Context())
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve currencies"), http.StatusInternalServerError)
		return
	}
	products, err := fe.getProducts(r.Context())
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve products"), http.StatusInternalServerError)
		return
	}
	ratings, err := fe.getAllRatings(r.Context())
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve ratings"), http.StatusInternalServerError)
		return
	}

	cart, err := fe.getCart(r.Context(), sessionID(r))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	type productView struct {
		Item   *pb.Product
		Price  *pb.Money
		Rating float64
	}
	ps := make([]productView, len(products))
	for i, p := range products {
		price, err := fe.convertCurrency(r.Context(), p.GetPriceUsd(), currentCurrency(r))
		if err != nil {
			renderHTTPError(log, r, w, errors.Wrapf(err, "failed to do currency conversion for product %s", p.GetId()), http.StatusInternalServerError)
			return
		}
		rating, found := ratings[p.Id]
		if !found {
			log.WithField("product", p.Id).Error("Product rating is missing")
			rating = 0.0
		}
		ps[i] = productView{p, price, rating}
	}

	// Feature: convert currency for product to all currencies
	if strings.ToLower(os.Getenv("CONVERT_CURRENCIES")) == "true" {
		for i := 0; i < 10*len(currencies); i++ {
			fe.convertAllCurrencies(r, products, currencies)
		}
	}

	if err := templates.ExecuteTemplate(w, "home", map[string]interface{}{
		"session_id":    sessionID(r),
		"request_id":    r.Context().Value(ctxKeyRequestID{}),
		"user_currency": currentCurrency(r),
		"currencies":    currencies,
		"products":      ps,
		"cart_size":     len(cart),
		"banner_color":  os.Getenv("BANNER_COLOR"), // illustrates canary deployments
		"ad":            fe.chooseAd(r.Context(), []string{}, log),
	}); err != nil {
		log.Error(err)
	}
}

func (fe *frontendServer) productHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	id := mux.Vars(r)["id"]
	if id == "" {
		renderHTTPError(log, r, w, errors.New("product id not specified"), http.StatusBadRequest)
		return
	}
	log.WithField("id", id).WithField("currency", currentCurrency(r)).
		Debug("serving product page")

	p, err := fe.getProduct(r.Context(), id)
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve product"), http.StatusInternalServerError)
		return
	}
	currencies, err := fe.getCurrencies(r.Context())
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve currencies"), http.StatusInternalServerError)
		return
	}

	cart, err := fe.getCart(r.Context(), sessionID(r))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	price, err := fe.convertCurrency(r.Context(), p.GetPriceUsd(), currentCurrency(r))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to convert currency"), http.StatusInternalServerError)
		return
	}

	recommendations, err := fe.getRecommendations(r.Context(), sessionID(r), []string{id})
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to get product recommendations"), http.StatusInternalServerError)
		return
	}

	rating, _, err := fe.getRating(r.Context(), id)
	if err != nil {
		log.WithField("product", id).Error("Product rating is missing")
		rating = 0.0
	}

	product := struct {
		Item   *pb.Product
		Price  *pb.Money
		Rating float64
	}{p, price, rating}

	if err := templates.ExecuteTemplate(w, "product", map[string]interface{}{
		"session_id":      sessionID(r),
		"request_id":      r.Context().Value(ctxKeyRequestID{}),
		"ad":              fe.chooseAd(r.Context(), p.Categories, log),
		"user_currency":   currentCurrency(r),
		"currencies":      currencies,
		"product":         product,
		"recommendations": recommendations,
		"cart_size":       len(cart),
	}); err != nil {
		log.Println(err)
	}
}

func (fe *frontendServer) addToCartHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	quantity, _ := strconv.ParseUint(r.FormValue("quantity"), 10, 32)
	productID := r.FormValue("product_id")
	if productID == "" || quantity == 0 {
		renderHTTPError(log, r, w, errors.New("invalid form input"), http.StatusBadRequest)
		return
	}
	log.WithField("product", productID).WithField("quantity", quantity).Debug("adding to cart")

	p, err := fe.getProduct(r.Context(), productID)
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve product"), http.StatusInternalServerError)
		return
	}

	if err := fe.insertCart(r.Context(), sessionID(r), p.GetId(), int32(quantity)); err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to add to cart"), http.StatusInternalServerError)
		return
	}
	w.Header().Set("location", "/cart")
	w.WriteHeader(http.StatusFound)
}

func (fe *frontendServer) emptyCartHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	log.Debug("emptying cart")

	if err := fe.emptyCart(r.Context(), sessionID(r)); err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to empty cart"), http.StatusInternalServerError)
		return
	}
	w.Header().Set("location", "/")
	w.WriteHeader(http.StatusFound)
}

func (fe *frontendServer) viewCartHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	log.Debug("view user cart")
	currencies, err := fe.getCurrencies(r.Context())
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve currencies"), http.StatusInternalServerError)
		return
	}
	cart, err := fe.getCart(r.Context(), sessionID(r))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	recommendations, err := fe.getRecommendations(r.Context(), sessionID(r), cartIDs(cart))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to get product recommendations"), http.StatusInternalServerError)
		return
	}

	shippingCost, err := fe.getShippingQuote(r.Context(), cart, currentCurrency(r))
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to get shipping quote"), http.StatusInternalServerError)
		return
	}

	type cartItemView struct {
		Item     *pb.Product
		Quantity int32
		Price    *pb.Money
	}
	items := make([]cartItemView, len(cart))
	totalPrice := pb.Money{CurrencyCode: currentCurrency(r)}
	for i, item := range cart {
		p, err := fe.getProduct(r.Context(), item.GetProductId())
		if err != nil {
			renderHTTPError(log, r, w, errors.Wrapf(err, "could not retrieve product #%s", item.GetProductId()), http.StatusInternalServerError)
			return
		}
		price, err := fe.convertCurrency(r.Context(), p.GetPriceUsd(), currentCurrency(r))
		if err != nil {
			renderHTTPError(log, r, w, errors.Wrapf(err, "could not convert currency for product #%s", item.GetProductId()), http.StatusInternalServerError)
			return
		}

		multPrice := money.MultiplySlow(*price, uint32(item.GetQuantity()))
		items[i] = cartItemView{
			Item:     p,
			Quantity: item.GetQuantity(),
			Price:    &multPrice}
		totalPrice = money.Must(money.Sum(totalPrice, multPrice))
	}
	totalPrice = money.Must(money.Sum(totalPrice, *shippingCost))

	year := time.Now().Year()
	if err := templates.ExecuteTemplate(w, "cart", map[string]interface{}{
		"session_id":       sessionID(r),
		"request_id":       r.Context().Value(ctxKeyRequestID{}),
		"user_currency":    currentCurrency(r),
		"currencies":       currencies,
		"recommendations":  recommendations,
		"cart_size":        len(cart),
		"shipping_cost":    shippingCost,
		"total_cost":       totalPrice,
		"items":            items,
		"expiration_years": []int{year, year + 1, year + 2, year + 3, year + 4},
	}); err != nil {
		log.Println(err)
	}
}

func (fe *frontendServer) placeOrderHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	log.Debug("placing order")

	var (
		email         = r.FormValue("email")
		streetAddress = r.FormValue("street_address")
		zipCode, _    = strconv.ParseInt(r.FormValue("zip_code"), 10, 32)
		city          = r.FormValue("city")
		state         = r.FormValue("state")
		country       = r.FormValue("country")
		ccNumber      = r.FormValue("credit_card_number")
		ccMonth, _    = strconv.ParseInt(r.FormValue("credit_card_expiration_month"), 10, 32)
		ccYear, _     = strconv.ParseInt(r.FormValue("credit_card_expiration_year"), 10, 32)
		ccCVV, _      = strconv.ParseInt(r.FormValue("credit_card_cvv"), 10, 32)
	)

	order, err := pb.NewCheckoutServiceClient(fe.checkoutSvcConn).
		PlaceOrder(r.Context(), &pb.PlaceOrderRequest{
			Email: email,
			CreditCard: &pb.CreditCardInfo{
				CreditCardNumber:          ccNumber,
				CreditCardExpirationMonth: int32(ccMonth),
				CreditCardExpirationYear:  int32(ccYear),
				CreditCardCvv:             int32(ccCVV)},
			UserId:       sessionID(r),
			UserCurrency: currentCurrency(r),
			Address: &pb.Address{
				StreetAddress: streetAddress,
				City:          city,
				State:         state,
				ZipCode:       int32(zipCode),
				Country:       country},
		})
	if err != nil {
		renderHTTPError(log, r, w, errors.Wrap(err, "failed to complete the order"), http.StatusInternalServerError)
		return
	}
	log.WithField("order", order.GetOrder().GetOrderId()).Info("order placed")

	order.GetOrder().GetItems()
	recommendations, _ := fe.getRecommendations(r.Context(), sessionID(r), nil)

	totalPaid := *order.GetOrder().GetShippingCost()
	for _, v := range order.GetOrder().GetItems() {
		totalPaid = money.Must(money.Sum(totalPaid, *v.GetCost()))
	}

	if err := templates.ExecuteTemplate(w, "order", map[string]interface{}{
		"session_id":      sessionID(r),
		"request_id":      r.Context().Value(ctxKeyRequestID{}),
		"user_currency":   currentCurrency(r),
		"order":           order.GetOrder(),
		"total_paid":      &totalPaid,
		"recommendations": recommendations,
	}); err != nil {
		log.Println(err)
	}
}

// postNewRatingHandler posts new rating vote for product.
// It ignores the error responses on the vote request since it is not critical.
func (fe *frontendServer) submitRatingHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	productID := mux.Vars(r)["id"]
	if productID == "" {
		renderHTTPError(log, r, w, errors.New("product id not specified"), http.StatusBadRequest)
		return
	}
	rating, _ := strconv.ParseInt(r.FormValue("rating"), 10, 32)
	log.WithField("product", productID).WithField("rating", rating).Debug("vote new rating")

	err := fe.postNewRating(r.Context(), productID, int32(rating))
	if err != nil {
		log.WithField("error", err).Warn("failed to post new rating")
	}
	w.WriteHeader(http.StatusOK)
}

func (fe *frontendServer) logoutHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	log.Debug("logging out")
	for _, c := range r.Cookies() {
		c.Expires = time.Now().Add(-time.Hour * 24 * 365)
		c.MaxAge = -1
		http.SetCookie(w, c)
	}
	w.Header().Set("Location", "/")
	w.WriteHeader(http.StatusFound)
}

func (fe *frontendServer) setCurrencyHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	cur := r.FormValue("currency_code")
	log.WithField("curr.new", cur).WithField("curr.old", currentCurrency(r)).
		Debug("setting currency")

	if cur != "" {
		http.SetCookie(w, &http.Cookie{
			Name:   cookieCurrency,
			Value:  cur,
			MaxAge: cookieMaxAge,
		})
	}
	referer := r.Header.Get("referer")
	if referer == "" {
		referer = "/"
	}
	w.Header().Set("Location", referer)
	w.WriteHeader(http.StatusFound)
}

// chooseAd queries for advertisements available and randomly chooses one, if
// available. It ignores the error retrieving the ad since it is not critical.
func (fe *frontendServer) chooseAd(ctx context.Context, ctxKeys []string, log logrus.FieldLogger) *pb.Ad {
	ads, err := fe.getAd(ctx, ctxKeys)
	if err != nil {
		log.WithField("error", err).Warn("failed to retrieve ads")
		return nil
	}
	return ads[rand.Intn(len(ads))]
}

// Converts a product's currency to every other currency
// The error is logged as a warning since it is not critical.
func (fe *frontendServer) convertCurrenciesForProduct(r *http.Request, product *pb.Product, currencies []string) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	for _, c := range currencies {
		_, err := fe.convertCurrency(r.Context(), product.GetPriceUsd(), c)
		if err != nil {
			log.WithField("error", err).Warn("Failed converting currencies for products.")
			return
		}
	}
}

// Converts the currency for all products into every other currency
func (fe *frontendServer) convertAllCurrencies(r *http.Request, products []*pb.Product, currencies []string) {
	for _, p := range products {
		fe.convertCurrenciesForProduct(r, p, currencies)
	}
}

func renderHTTPError(log logrus.FieldLogger, r *http.Request, w http.ResponseWriter, err error, code int) {
	log.WithField("error", err).Error("request error")
	errMsg := fmt.Sprintf("%+v", err)

	w.WriteHeader(code)
	templates.ExecuteTemplate(w, "error", map[string]interface{}{
		"session_id":  sessionID(r),
		"request_id":  r.Context().Value(ctxKeyRequestID{}),
		"error":       errMsg,
		"status_code": code,
		"status":      http.StatusText(code)})
}

func currentCurrency(r *http.Request) string {
	c, _ := r.Cookie(cookieCurrency)
	if c != nil {
		return c.Value
	}
	return defaultCurrency
}

func sessionID(r *http.Request) string {
	v := r.Context().Value(ctxKeySessionID{})
	if v != nil {
		return v.(string)
	}
	return ""
}

func cartIDs(c []*pb.CartItem) []string {
	out := make([]string, len(c))
	for i, v := range c {
		out[i] = v.GetProductId()
	}
	return out
}

func renderMoney(money pb.Money) string {
	return fmt.Sprintf("%s %d.%02d", money.GetCurrencyCode(), money.GetUnits(), money.GetNanos()/10000000)
}

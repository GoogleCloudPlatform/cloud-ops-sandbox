// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"path"
	"time"

	"github.com/pkg/errors"
)

// ErrorResponse describes error response for API call
type ErrorResponse struct {
	Error string `json:"error"`
}

// AllRatingsResponse describes response for GET /ratings
type AllRatingsResponse struct {
	Ratings []struct {
		ID     string  `json:"id"`
		Rating float64 `json:"rating"`
	} `json:"ratings"`
}

// RatingResponse describes response for GET /rating/<id>
type RatingResponse struct {
	ID     string  `json:"id"`
	Rating float64 `json:"rating"`
	Votes  int     `json:"votes"`
}

// RatingRequest describes request for POST /rating
type RatingRequest struct {
	ID     string `json:"id"`
	Rating int32  `json:"rating"`
}

func buildURL(host, resource, id string) (string, error) {
	uri, err := url.ParseRequestURI(host)
	if err != nil {
		return "", errors.Errorf("%q is invalid URL", host)
	}
	uri.Path = path.Join(uri.Path, resource, id)
	return uri.String(), nil
}

// sendRestRequest abstracts sending GET and POST requests with a timeout, parsing response and error handling.
// It parses the returned Json into response. Any response with code that is not 200 or 4xx results in error.
func sendRestRequest(ctx context.Context, method, url string, payload io.Reader, response interface{}) error {
	ctx, cancel := context.WithTimeout(ctx, time.Millisecond*500)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, method, url, payload)
	if err != nil {
		return errors.Wrapf(err, "failed to create %s request to %s", method, url)
	}
	if payload != nil {
		req.Header.Set("Content-type", "application/json")
	}
	result, err := http.DefaultClient.Do(req)
	if result != nil {
		defer result.Body.Close()
	}
	if err != nil {
		return errors.Wrapf(err, "failed to send %s request to %s", method, url)
	}

	body, err := ioutil.ReadAll(result.Body)
	if err != nil {
		return errors.Wrap(err, "failed to read response")
	}

	if result.StatusCode >= 400 {
		errData := new(ErrorResponse)
		err := json.Unmarshal(body, errData)
		if err != nil {
			return errors.Wrap(err, "json unmarshal failed for : "+string(body))
		}
		return errors.Errorf("status: %d, message: %s", result.StatusCode, errData.Error)
	} else if result.StatusCode == 200 {
		err := json.Unmarshal(body, response)
		if err != nil {
			return errors.Wrap(err, "json unmarshal failed for : "+string(body))
		}
		return nil
	} else {
		return errors.Errorf("unhandled response code %q", result.StatusCode)
	}
}

// getAllRatings sends GET /ratings request to rating service.
// It returns a map of product ids to ratings.
func (fe *frontendServer) getAllRatings(ctx context.Context) (map[string]float64, error) {
	result := make(map[string]float64)

	url, err := buildURL(fe.ratingSvcAddr, "ratings", "")
	if err != nil {
		return result, err
	}

	data := new(AllRatingsResponse)
	err = sendRestRequest(ctx, "GET", url, nil, data)
	if err != nil {
		return result, errors.Wrapf(err, "getAllRatings failed")
	}

	for _, r := range data.Ratings {
		result[r.ID] = r.Rating
	}
	return result, nil
}

// getRating sends GET /rating/<id> request to rating service where <id> is a product id.
// It returns the rating of the product and the current number of votes.
func (fe *frontendServer) getRating(ctx context.Context, id string) (float64, int, error) {
	url, err := buildURL(fe.ratingSvcAddr, "rating", id)
	if err != nil {
		return 0, 0, err
	}

	data := new(RatingResponse)
	err = sendRestRequest(ctx, "GET", url, nil, data)
	if err != nil {
		return 0, 0, errors.Wrapf(err, "getRating for %q failed", id)
	}
	return data.Rating, data.Votes, nil
}

// postNewRating sends POST /rating request to rating service to submit a new rating of the product.
// It returns no data because the rating is not updated immediately.
func (fe *frontendServer) postNewRating(ctx context.Context, id string, rating int32) error {
	url, err := buildURL(fe.ratingSvcAddr, "rating", "")
	if err != nil {
		return err
	}

	request, err := json.Marshal(RatingRequest{ID: id, Rating: rating})
	if err != nil {
		return errors.Wrap(err, "failed serialize request data")
	}
	data := new(struct{})
	err = sendRestRequest(ctx, "POST", url, bytes.NewBuffer(request), data)
	if err != nil {
		return errors.Wrapf(err, "post rating %d for %q failed", rating, id)
	}
	return nil
}

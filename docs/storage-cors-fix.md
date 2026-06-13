# Firebase Storage CORS Fix (Web)

If profile photo upload fails in Flutter web with a CORS error, add a CORS rule to your Firebase Storage bucket.

## Symptoms
- Upload fails with a browser CORS error.
- Network error on a request to firebasestorage.googleapis.com.

## Fix
1. Create a file named cors.json with the following content:

```
[
  {
    "origin": [
      "http://localhost:10720",
      "http://localhost:5000",
      "http://localhost:8080"
    ],
    "method": ["GET", "POST", "PUT", "HEAD"],
    "responseHeader": [
      "Content-Type",
      "Authorization",
      "x-goog-resumable"
    ],
    "maxAgeSeconds": 3600
  }
]
```

2. Apply the rule to your Storage bucket:

```
gsutil cors set cors.json gs://uniswap-utm-38aea.firebasestorage.app
```

3. Retry the upload in the web app.

## Notes
- Replace origins if your local port changes.
- If you do not have gsutil, install the Google Cloud SDK.
- Ensure Storage rules allow authenticated uploads.

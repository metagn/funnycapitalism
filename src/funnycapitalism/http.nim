import httpclient, asyncdispatch, lib/jsonwrapper, uri, common, net

proc newHttp*(headers: HttpHeaders): AsyncHttpClient =
  result = newAsyncHttpClient(discordUserAgent, sslContext = newContext(verifyMode = CVerifyNone))
  result.headers = headers

proc parseResponse*(resp: AsyncResponse): JsonNode =
  result = parseJson(waitFor resp.body)

proc get*(http: AsyncHttpClient, uri: Uri): JsonNode =
  parseJson(waitFor http.getContent($uri))

template postHeaders*: HttpHeaders = newHttpHeaders({"Content-Type": "application/json"})

proc post*(http: AsyncHttpClient, uri: Uri, data: JsonNode): Future[AsyncResponse] =
  http.request($uri, HttpPost, $data, postHeaders)

proc patch*(http: AsyncHttpClient, uri: Uri, data: JsonNode): Future[AsyncResponse] =
  http.request($uri, HttpPatch, $data, postHeaders)

proc delete*(http: AsyncHttpClient, uri: Uri): Future[AsyncResponse] =
  http.request($uri, HttpDelete, "", postHeaders)

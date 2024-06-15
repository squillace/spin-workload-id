import { HandleRequest, HttpRequest, HttpResponse, Kv } from "@fermyon/spin-sdk"

const encoder = new TextEncoder()

export const handleRequest: HandleRequest = async function (request: HttpRequest): Promise<HttpResponse> {
  let store = Kv.openDefault()
  store.set("mykey", "myvalue")
  return {
    status: 200,
    headers: {"content-type":"text/plain"},
    body: store.get("mykey") ?? encoder.encode("Key not found")
  }
}

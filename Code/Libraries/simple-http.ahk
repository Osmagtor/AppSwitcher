#SingleInstance Force

; https://github.com/joshuacc/simple-http?tab=readme-ov-file

class SimpleHTTP {
	__New() {
		this.o := ComObject("WinHttp.WinHttpRequest.5.1")
	}

	get(url, headers := "") {
		return this._request("GET", url, "", headers)
	}

	post(url, data := "", headers := "") {
		return this._request("POST", url, data, headers)
	}

	put(url, data := "", headers := "") {
		return this._request("PUT", url, data, headers)
	}

	delete(url, headers := "") {
		return this._request("DELETE", url, "", headers)
	}

	patch(url, data := "", headers := "") {
		return this._request("PATCH", url, data, headers)
	}

	head(url, headers := "") {
		return this._request("HEAD", url, "", headers)
	}

	options(url, headers := "") {
		return this._request("OPTIONS", url, "", headers)
	}

	_request(method, url, data := "", headers := "") {
		this.o.Open(method, url, true)
		this._setHeaders(headers, method)
		this.o.Send(data)
		this.o.WaitForResponse()
		return this.o.ResponseText
	}

	_setHeaders(headers, method) {
		if IsObject(headers) {
			for k, v in headers.OwnProps() {
				this.o.SetRequestHeader(k, v)
			}
		}
		if (method = "POST") && (!IsObject(headers) || !headers.HasOwnProp("Content-Type")) {
			this.o.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		}
	}
}
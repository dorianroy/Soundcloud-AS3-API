package com.dasflash.soundcloud.as3api
{
	import com.adobe.serialization.json.JSON;
	import com.dasflash.soundcloud.as3api.events.SoundcloudEvent;
	import com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent;

	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	import org.iotashan.oauth.IOAuthSignatureMethod;
	import org.iotashan.oauth.OAuthConsumer;
	import org.iotashan.oauth.OAuthRequest;
	import org.iotashan.oauth.OAuthSignatureMethod_HMAC_SHA1;
	import org.iotashan.oauth.OAuthToken;

	/**
	 * Dispatched after the response has been downloaded and parsed successfully.
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudEvent.REQUEST_COMPLETE
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudEvent", name="requestComplete")]

	/**
	 * Dispatched when a call has failed.
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent.FAULT
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent", name="fault")]

	/**
	 * Progress event of file upload.
	 *
	 * @eventType flash.events.ProgressEvent.PROGRESS
	 */
	[Event(type="flash.events.ProgressEvent", name="progress")]


	/**
	 * SoundcloudDelegate represents a single call to the API.
	 *
	 * <p>Usually you don't create instances of this class directly; they get returned by
	 * <code>SoundcloudClient.sendRequest</code>.</p>
	 *
	 * @see SoundcloudClient#sendRequest
	 *
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	public class SoundcloudDelegate extends EventDispatcher
	{
		protected const signatureMethod:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();

		protected var urlRequest:URLRequest;

		protected var urlLoader:URLLoader;

		protected var responseFormat:String;

		protected var fileReference:FileReference;

		protected var fileParameterName:String;


		/**
		 * <p>The constructor only builds the request object and adds response listeners.
		 * The method <code>execute</code> must be called subsequently to send the actual request.</p>
		 *
		 * @param url				The full URL, e.g. "http://api.soundcloud.com/user/userid/tracks"
		 *
		 * @param method			GET, POST, PUT or DELETE. Note that FlashPlayer
		 * 							only supports GET and POST as of this writing.
		 * 							AIR supports all four methods.
		 *
		 * @param consumer			The OAuth consumer. This parameter is not optional, but the token can
		 * 							be empty if you only want to access public resources.
		 *
		 * @param token				(optional) The OAuth token. If this parameter is omitted you can only
		 * 							access public resources.
		 *
		 * @param data				(optional) the data to be sent. This can be a generic object
		 * 							containing request parameters as key/value pairs or a XML object
		 *
		 * @param responseFormat	(optional) tells Soundcloud whether to render response as JSON or XML.
		 * 							Value must be SoundcloudResponseFormat.JSON, .XML or an empty String
		 * 							(default) which will also return XML
		 *
		 * @param dataFormat		(optional) tells the URLLoader how to handle the returned data. Must
		 * 							be URLLoaderDataFormat.TEXT, .VARIABLES or .BINARY. If responseFormat
		 * 							is JSON or XML this parameter will be overriden with .TEXT
		 */
		public function SoundcloudDelegate(url:String,
			method:String,
			consumer:OAuthConsumer,
			token:OAuthToken=null,
			data:Object=null,
			responseFormat:String="",
			dataFormat:String=""
			)
		{
			// save response format. this will be needed to interpret the response data
			this.responseFormat = responseFormat;

			// if responseFormat is set
			if (responseFormat) {

				// add url extension
				url += "." + responseFormat;
			}

			// create a copy of the parameters object which will be populated with the oauth
			// parameters and signed by the OAuthRequest object
			var oauthParams:URLVariables = new URLVariables();

			// create an object with the actual request parameters
			var requestParams:URLVariables = new URLVariables();

			// if data contains a hashmap of parameters
			if (!(data is XML)) {

				for (var p:String in data) {

					// look for a parameter containing a file reference
					if (data[p] is FileReference) {

						// save parameters for upload
						fileReference = data[p] as FileReference;
						fileParameterName = p;

							// else if this is an oauth parameters
					} else if (p.indexOf("oauth_") != -1) {

						// add it to signable parameters
						oauthParams[p] = data[p];

					} else {

						// otherwise add it to the actual request parameters
						requestParams[p] = data[p];
					}
				}

				// if there was no FileReference (i.e. this is going to be a form-urlencoded request)
				// and method is POST 
				if (!fileReference && method == URLRequestMethod.POST) {

					// ensure ALL parameters get signed (OAuth special rule)
					for (var n:String in data) {
						oauthParams[n] = data[n];
					}
				}

			}

			// create OAuthRequest object and pass oauthParams
			var oAuthRequest:OAuthRequest = new OAuthRequest(method, url, oauthParams, consumer, token);

			// build url with oauth parameters
			// this will also add the oauth parameters and signature to the 
			// oauthParams object so we do this even if we don't need the signedURL later on
			var signedURL:String = oAuthRequest.buildRequest(signatureMethod,
				OAuthRequest.RESULT_TYPE_URL_STRING, "");

			// copy added oauth params to requestparams
			for (var o:String in oauthParams) {

				requestParams[o] = oauthParams[o];
			}

			// create request object
			urlRequest = new URLRequest();

			// set content type
			if (data is XML) {

				// send XML with application/xml header
				urlRequest.contentType = "application/xml";

					// else treat data as a map of key/value pairs and send it as url-encoded variables
			} else {

				// set header
				urlRequest.contentType = fileReference ? "multipart/form-data" : "application/x-www-form-urlencoded";
			}

			// set http method
			urlRequest.method = method;

			// set url and parameters depending on the type of request
			if (method == "DELETE") {
				urlRequest.url = signedURL;

					// if this is going to be a file upload we also need the parameters in the query string
			} else if (fileReference) {
				urlRequest.url = signedURL;
				urlRequest.data = requestParams;

					// for an XML request we need to add the XML as the data
			} else if (data is XML) {
				urlRequest.url = signedURL;
				urlRequest.data = data;

					// otherwise we use the plain resource URI and all parameters go
					// into the data object. In case of GET they'll become query params
					// in case of POST they'll end up in the body of the request
			} else {
				urlRequest.url = url;
				urlRequest.data = requestParams;
			}

			// if there is a file reference and method is POST this will be
			// handled with FileReference.upload()
			if (fileReference && method == URLRequestMethod.POST) {

				fileReference.addEventListener(ProgressEvent.PROGRESS, uploadProgressHandler);
				fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, uploadCompleteDataHandler);
				fileReference.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);

					// otherwise this will be handled with URLLoader.load()
			} else {

				// create url loader
				urlLoader = new URLLoader();

				// make sure dataFormat is in line with responseFormat
				if (responseFormat == SoundcloudResponseFormat.JSON || responseFormat == SoundcloudResponseFormat.XML) {
					dataFormat = URLLoaderDataFormat.TEXT;
				}

				// set data format
				urlLoader.dataFormat = dataFormat;

				urlLoader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			}
		}

		/**
		 * Sends the actual request.
		 */
		public function execute():void
		{
			if (fileReference) {

				// upload file
				fileReference.upload(urlRequest, fileParameterName);

			} else {

				// try to send request
				try {
					urlLoader.load(urlRequest);

				} catch (error:Error) {
					throw new Error("Error sending request " + urlRequest.url);
				}
			}
		}

		/**
		 * Returns the signed URLRequest of this delegate
		 *
		 * @return URLRequest
		 */
		public function getUrlRequest():URLRequest
		{
			return urlRequest;
		}

		/**
		 * @private
		 */
		protected function uploadProgressHandler(event:ProgressEvent):void
		{
			dispatchEvent(event);
		}

		/**
		 * @private
		 */
		protected function uploadCompleteDataHandler(event:DataEvent):void
		{
			dispatchCompleteEvent(event.data);
		}

		/**
		 * @private
		 */
		protected function urlLoaderCompleteHandler(event:Event):void
		{
			dispatchCompleteEvent(event.target.data);
		}

		/**
		 * @private
		 */
		protected function dispatchCompleteEvent(rawData:Object):void
		{
			var data:Object;

			switch (responseFormat) {

				case SoundcloudResponseFormat.XML:

					try {
						data = new XML(rawData as String);

					} catch (error:Error) {
						dispatchFaultEvent("couldn't parse XML: " + error.message);
					}
					break;

				case SoundcloudResponseFormat.JSON:

					try {
						data = JSON.decode(rawData as String);

					} catch (error:Error) {
						dispatchFaultEvent("couldn't parse JSON String: " + error.message);
					}
					break;

				default:
					data = rawData;
			}

			dispatchEvent(new SoundcloudEvent(SoundcloudEvent.REQUEST_COMPLETE, data, rawData));
		}

		/**
		 * @private
		 */
		protected function dispatchFaultEvent(message:String, code:int=0):void
		{
			dispatchEvent(new SoundcloudFaultEvent(SoundcloudFaultEvent.FAULT, message, code));
		}

		/**
		 * @private
		 */
		protected function httpStatusHandler(event:HTTPStatusEvent):void
		{
			// do nothing if this is not an error status
			if (event.status != 0 && event.status < 400)
				return;

			// remove complete handler
			if (event.target is FileReference) {
				fileReference.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, uploadCompleteDataHandler);
			} else {
//				urlLoader.removeEventListener(Event.COMPLETE, urlLoaderCompleteHandler);

				// avoid RTE caused by unparsable URLVariables through switching expected response format
				// to simple text
				urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			}

			var msg:String;

			switch (event.status) {
				case 400:
					msg = "Bad Request";
					break;
				case 401:
					msg = "Unauthorized";
					break;
				case 403:
					msg = "Forbidden";
					break;
				case 404:
					msg = "Not Found";
					break;
				case 405:
					msg = "Method Not Allowed";
					break;
				case 406:
					msg = "Not Acceptable";
					break;
				case 407:
					msg = "Proxy Authentication Required";
					break;
				case 408:
					msg = "Request Timeout";
					break;
				case 409:
					msg = "Conflict";
					break;
				case 410:
					msg = "Gone";
					break;
				case 411:
					msg = "Length Required";
					break;
				case 412:
					msg = "Precondition Failed";
					break;
				case 413:
					msg = "Request Entity Too Large";
					break;
				case 414:
					msg = "Request-URI Too Long";
					break;
				case 415:
					msg = "Unsupported Media Type";
					break;
				case 416:
					msg = "Requested Range Not Satisfiable";
					break;
				case 417:
					msg = "Expectation Failed";
					break;
				case 500:
					msg = "Internal Server Error";
					break;
				case 501:
					msg = "Not Implemented";
					break;
				case 502:
					msg = "Bad Gateway";
					break;
				case 503:
					msg = "Service Unavailable";
					break;
				case 504:
					msg = "Gateway Timeout";
					break;
				case 505:
					msg = "HTTP Version Not Supported";
					break;
				default:
					msg = "Unhandled HTTP status";
			}

			dispatchFaultEvent(msg, event.status);
		}

		/**
		 * @private
		 */
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchFaultEvent(event.text);
		}

	}
}

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
	

	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudEvent", name="requestComplete")]
	
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudFault", name="fault")]
	
	[Event(type="flash.events.ProgressEvent", name="progress")]
	

	public class SoundcloudDelegate extends EventDispatcher
	{
		protected const signatureMethod:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();
		
		protected var urlRequest:URLRequest;
		
		protected var urlLoader:URLLoader;
		
		protected var responseFormat:String;
		
		protected var fileReference:FileReference;
		
		protected var fileParameterName:String;
		
		
		/**
		 * SoundcloudDelegate represents a single call to the Soundcloud API
		 * 
		 * @param url				the full URL e.g. http://api.soundcloud.com/user/userid/tracks
		 * 
		 * @param method			GET, POST, PUT or DELETE. Note that FlashPlayer
		 * 							only supports GET and POST as of this writing.
		 * 							AIR supports all four methods.
		 * 
		 * @param consumer			The OAuth consumer
		 * 
		 * @param token				The OAuth token
		 * 
		 * @param params			(optional) a generic object containing the request parameters
		 * 
		 * @param responseFormat	(optional) tells Soundcloud whether to render response as JSON or XML.
		 * 							Value must be SoundcloudResponseFormat.JSON or .XML (default)
		 * 
		 * @param dataFormat		(optional) tells the URLLoader how to handler the returned data. Must
		 * 							be URLLoaderDataFormat.TEXT, .VARIABLES or .BINARY. If responseFormat
		 * 							is JSON or XML this parameter will be overriden with .TEXT
		 * 
		 * @author Dorian Roy
		 * http://www.dasflash.com
		 */
		public function SoundcloudDelegate(	url:String,
											method:String,
											consumer:OAuthConsumer,
											token:OAuthToken,
											params:Object=null,
											responseFormat:String="",
											dataFormat:String=""
											)
		{
			this.responseFormat = responseFormat;
			
			// copy params to URLVariables object
			var urlVars:URLVariables = new URLVariables();
			
			for (var n:String in params) {
				
				// look for a parameter containing a file reference
				if (params[n] is FileReference) {
					
					// save parameters for upload
					fileReference = params[n] as FileReference;
					fileParameterName = n;
					
					// don't copy this to urlVar
					continue;
				}
				
				// copy parameter to urlVar
				urlVars[n] = params[n];
			}
			
			// if responseFormat is set
			if (responseFormat) {
				
				// add url extension
				url += "." + responseFormat;
			}
			
			// create request object
			var oAuthRequest:OAuthRequest = new OAuthRequest(method, url, null, consumer, token);
			
			// build url with oauth parameters
			var signedURL:String = oAuthRequest.buildRequest(	signatureMethod,
																OAuthRequest.RESULT_TYPE_URL_STRING, "");

			// create request object
			urlRequest = new URLRequest(signedURL);
			
			// set http method
			urlRequest.method = method;
			
			// add parameters
			urlRequest.data = urlVars;
			
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
				if (responseFormat==SoundcloudResponseFormat.JSON || responseFormat==SoundcloudResponseFormat.XML) {
					dataFormat = URLLoaderDataFormat.TEXT;
				}
				
				// set data format
				urlLoader.dataFormat = dataFormat;
				
				urlLoader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	//			urlLoader.addEventListener(HTTPStatusEvent["HTTP_RESPONSE_STATUS"], httpStatusHandler);
			}
		}
		
		/**
		 * Send the request 
		 */
		public function execute():void
		{
			if (fileReference) {
				
				trace("starting upload");
				
				// upload file
				fileReference.upload(urlRequest, fileParameterName);
				
			} else {
				// try to send request
				try{
					urlLoader.load(urlRequest);
					
				} catch (error:Error){
					throw new Error("Error sending request " + urlRequest.url);
				}
			}
		}
		
		protected function uploadProgressHandler(event:ProgressEvent):void
		{
			dispatchEvent(event);
		}
		
		protected function uploadCompleteDataHandler(event:DataEvent):void
		{
			dispatchCompleteEvent(event.data);
		}
		
		protected function urlLoaderCompleteHandler(event:Event):void
		{
			dispatchCompleteEvent(event.target.data);
		}
		
		protected function dispatchCompleteEvent(rawData:Object):void
		{
			var data:Object;
			
			switch (responseFormat) {
						
				case SoundcloudResponseFormat.XML:
					data = new XML(rawData as String);
					break;
							
				case SoundcloudResponseFormat.JSON:
					data = JSON.decode(rawData as String);
					break;
					
				default:
					data = rawData;
			}
			
			dispatchEvent( new SoundcloudEvent(SoundcloudEvent.REQUEST_COMPLETE, data, rawData) );
		}
		
		protected function httpStatusHandler(event:HTTPStatusEvent):void
		{
			trace("httpStatusHandler "+event.status);
			
			if (event.status < 400) return;
			
			var msg:String;
			
			switch (event.status) {
				case 400: msg = "Bad Request"; break;
				case 401: msg = "Unauthorized"; break;
				case 403: msg = "Forbidden"; break;
				case 404: msg = "Not Found"; break;
				case 405: msg = "Method Not Allowed"; break;
				case 406: msg = "Not Acceptable"; break;
				case 407: msg = "Proxy Authentication Required"; break;
				case 408: msg = "Request Timeout"; break;
				case 409: msg = "Conflict"; break;
				case 410: msg = "Gone"; break;
				case 411: msg = "Length Required"; break;
				case 412: msg = "Precondition Failed"; break;
				case 413: msg = "Request Entity Too Large"; break;
				case 414: msg = "Request-URI Too Long"; break;
				case 415: msg = "Unsupported Media Type"; break;
				case 416: msg = "Requested Range Not Satisfiable"; break;
				case 417: msg = "Expectation Failed"; break;
				case 500: msg = "Internal Server Error"; break;
				case 501: msg = "Not Implemented"; break;
				case 502: msg = "Bad Gateway"; break;
				case 503: msg = "Service Unavailable"; break;
				case 504: msg = "Gateway Timeout"; break;
				case 505: msg = "HTTP Version Not Supported"; break;
				default: msg = "Unhandled HTTP status";
			}
			
			dispatchEvent( new SoundcloudFaultEvent(SoundcloudFaultEvent.FAULT, msg, event.status) );
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			dispatchEvent( new SoundcloudFaultEvent(SoundcloudFaultEvent.FAULT, event.text) );
		}
		
	}
}

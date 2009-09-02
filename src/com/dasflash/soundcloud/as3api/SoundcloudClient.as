package com.dasflash.soundcloud.as3api
{
	import com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent;
	import com.dasflash.soundcloud.as3api.events.SoundcloudEvent;
	
	import flash.events.EventDispatcher;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import org.iotashan.oauth.OAuthConsumer;
	import org.iotashan.oauth.OAuthToken;

	/**
	 * Base class of the Soundcloud API wrapper for AS3
	 * 
	 * Create an instance of this class and call its authentication methods to
	 * connect your app with the Soundcloud REST API. Once you're authenticated you
	 * can call any resource through the sendRequest() method.
	 * 
	 * @see http://github.com/dasflash/Soundcloud-AS3-API
	 * @see http://api.soundcloud.com/api
	 * 
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	 
	 [Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent", name="requestToken")]
	 
	 [Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent", name="accessToken")]
	 
	 
	public class SoundcloudClient extends EventDispatcher
	{
		// SC resource locations
		protected const requestTokenResource:String		= "oauth/request_token";
		protected const accessTokenResource:String		= "oauth/access_token";
		
		protected var consumerKey:String;
		protected var consumerSecret:String;
		protected var _useSandBox:Boolean;	
		protected var _responseFormat:String;
		
		protected var consumer:OAuthConsumer;
		protected var requestToken:OAuthToken;
		protected var accessToken:OAuthToken;
		
		protected var _verificationRequired:Boolean;
		protected var callbackURL:String;
		
		
		/**
		 * create a Soundcloud API client
		 * 
		 * @param consumerKey		the consumer key you receive when registering your app with Soundcloud
		 * 
		 * @param consumerSecret	the consumer secret you receive when registering your app with Soundcloud
		 * 
		 * @param accessToken		a previously retrieved access token for the current user (optional)
		 * 
		 * @param useSandbox		switch between the Soundcloud live system (false) and the developer
		 * 							sandbox system (true, default)
		 * 
		 * @param responseFormat	"json" or "xml" (default)
		 */
		public function SoundcloudClient(	consumerKey:String,
											consumerSecret:String,
											accessToken:OAuthToken=null,
											useSandbox:Boolean=true,
											responseFormat:String="xml" )
		{
			this.consumerKey = consumerKey;
			this.consumerSecret = consumerSecret;
			this.accessToken = accessToken;
			this.useSandBox = useSandbox;
			this.responseFormat = responseFormat;
			
			consumer = new OAuthConsumer(consumerKey, consumerSecret);
		}
		
		/**
		 * get a request token
		 * 
		 * this token must be traded for an access token by calling
		 * getAccessToken() after user authentication
		 * 
		 * @param callbackURL (optional)
		 * 			the user will be redirected to this page after authentication.
		 * 			this url will be extended with parameters that you can use
		 * 			on the page:
		 * 			oauth_token: the request token the user authorized or denied
		 * 			oauth_verifier: the verification code (only for OAuth 1.0a)
		 * 
		 * @return 	a SoundcloudDelegate instance you can attach a listener to for
		 * 			the SoundcloudEvent and SoundcloudFault events
		 */
		public function getRequestToken(callbackURL:String=null):SoundcloudDelegate
		{
			// store callback URL
			this.callbackURL = callbackURL;
			
			// create parameter object
			var requestParams:Object = {};
			
			// add OAuth version
			requestParams.oauth_version = "1.0";
			
			// add oauth_callback parameter for OAuth 1.0a authentication
			// if no callback is passed, this parameter is set to "oob" (out-of-band)
			// @see http://oauth.googlecode.com/svn/spec/core/1.0a/drafts/3/oauth-core-1_0a.html#auth_step1
			// remove parameter oauth_callback in order to use the API in the old-fashioned
			// 1.0-style (which may not be supported anymore when you read this)
			requestParams.oauth_callback = callbackURL || "oob";
			
			// create request
			var delegate:SoundcloudDelegate = createDelegate(requestTokenResource,
															URLRequestMethod.POST,
															requestParams,
															"",
															URLLoaderDataFormat.VARIABLES);
			
			// send request
			delegate.execute();
			
			// listen for response
			delegate.addEventListener(SoundcloudEvent.REQUEST_COMPLETE, getRequestTokenCompleteHandler);
			
			return delegate;
		}
		
		protected function getRequestTokenCompleteHandler(event:SoundcloudEvent):void	
		{
			var responseVariables:URLVariables = URLVariables(event.data);
			
			requestToken = createTokenFromURLVariables(responseVariables);
			
			// check if OAuth 1.0a parameter oauth_callback_confirmed is returned
			if (responseVariables["oauth_callback_confirmed"] == "true") {
				
				// we need to submit a verification code
				_verificationRequired = true;
			}
			
			dispatchEvent( new SoundcloudAuthEvent(SoundcloudAuthEvent.REQUEST_TOKEN, requestToken) );
		}
		
		/**
		 * open authorization page to grant data access for your app
		 * 
		 * @param targetWindow (optional)
		 * 		target window name, defaults to "_self". use "_blank" to open the
		 * 		authentication page in a new window
		 */
		public function authorizeUser(targetWindow:String="_self"):void
		{
			// create url request
			var userAuthReq:URLRequest = new URLRequest(authURL);
			
			// add request parameters
			var params:URLVariables = new URLVariables();
			params["oauth_token"] = requestToken.key;
			
			// TODO delete this when Soundcloud implements OAuth 1.0a
			// if (callbackURL) params["oauth_callback"] = callbackURL;
			
			userAuthReq.data = params;
			
			// open url in browser
			navigateToURL(userAuthReq, targetWindow);
		}
		
		/**
		 * get access token
		 * 
		 * this token will be used for all subsequent api calls. you can store it 
		 * and reuse it the next time the current user uses your app
		 * 
		 * @return 	a SoundcloudDelegate instance you can attach a listener to for
		 * 			the SoundcloudEvent and SoundcloudFault events
		 */		
		public function getAccessToken(verificationCode:String=null):SoundcloudDelegate
		{
			// create parameter object
			var requestParams:Object = {};
			
			// add verification code if we're using OAuth 1.0a
			if (_verificationRequired) requestParams.oauth_verifier = verificationCode;
			
			// create request
			var delegate:SoundcloudDelegate = createDelegate(	accessTokenResource,
																URLRequestMethod.GET,
																requestParams,
																"",
																URLLoaderDataFormat.VARIABLES,
																requestToken);
			
			// send request
			delegate.execute();
			
			// listen for response
			delegate.addEventListener(SoundcloudEvent.REQUEST_COMPLETE, getAccessTokenCompleteHandler);
			
			return delegate;
		}
		
		protected function getAccessTokenCompleteHandler(event:SoundcloudEvent):void
		{
			accessToken = createTokenFromURLVariables( URLVariables(event.data) );
			
			dispatchEvent( new SoundcloudAuthEvent(SoundcloudAuthEvent.ACCESS_TOKEN, accessToken) ); 
		}
		
		/**
		 * Make a request to the API
		 * 
		 * @param resource	the resource locator, e.g. user/userid/tracks
		 * 
		 * @param method	GET, POST, PUT or DELETE. Note that FlashPlayer	only supports GET
		 * 					and POST as of this writing. AIR supports all four methods.
		 * 
		 * @param params	(optional) a generic object containing the request parameters
		 * 
		 * @return 			a SoundcloudDelegate instance you can attach a listener to for
		 * 					the SoundcloudEvent and SoundcloudFault events
		 */
		public function sendRequest(	resource:String,
										method:String,
										data:Object=null):SoundcloudDelegate
		{
			var delegate:SoundcloudDelegate = createDelegate(	resource,
																method,
																data,
																responseFormat,
																URLLoaderDataFormat.TEXT,
																accessToken);
			
			// send request
			delegate.execute();
			
			// return delegate so you can add a listener to it
			return delegate;
		}
		
		/**
		 * Sends the actual API call
		 * 
		 * @param resource			the resource locator, e.g. user/userid/tracks
		 * 
		 * @param method			GET, POST, PUT or DELETE. Note that FlashPlayer
		 * 							only supports GET and POST as of this writing.
		 * 							AIR supports all four methods.
		 * 
		 * @param data				(optional) the data to be sent. This can be a generic object
		 * 							containing request parameters as key/value pairs or a XML object
		 * 
		 * @param responseFormat	(optional) "binary", "text" (default) or "variables"
		 * 
		 * @param requestToken		(optional) overwrites the access token. Used to pass the 
		 * 							request token when requesting an access token.
		 * 
		 * @return 					a SoundcloudDelegate instance you can attach a listener to
		 * 							for the SoundcloudEvent and SoundcloudFault events
		 */
		protected function createDelegate(	resource:String,
											method:String,
											data:Object=null,
											responseFormat:String="",
											dataFormat:String="",
											requestToken:OAuthToken=null):SoundcloudDelegate
		{
			// use request token if one is passed (to get an access token)
			var token:OAuthToken = requestToken || accessToken;
			
			// create delegate
			var delegate:SoundcloudDelegate = new SoundcloudDelegate(	apiURL+resource,
																		method,
																		consumer,
																		token,
																		data,
																		responseFormat,
																		dataFormat);

			// return delegate so you can add a listener to it
			return delegate;
		}
		
		
		// GETTER / SETTER
		
		public function get useSandBox():Boolean
		{
			return _useSandBox;
		}

		public function set useSandBox(value:Boolean):void
		{
			_useSandBox = value;
		}
		
		public function get responseFormat():String
		{
			return _responseFormat;
		}

		public function set responseFormat(value:String):void
		{
			_responseFormat = value;
		}

		/**
		 * @returns true if authentication is based on OAuth 1.0a and requires
		 * 		the verification code from the authentication page
		 */
		public function get verificationRequired():Boolean
		{
			return _verificationRequired;
		}
		
		
		// HELPER METHODS

		protected function createTokenFromURLVariables(data:URLVariables):OAuthToken
		{
			return new OAuthToken(data["oauth_token"], data["oauth_token_secret"]);
		}
		
		protected function get authURL():String
		{
			return useSandBox ? SoundcloudURLs.SANDBOX_AUTH_URL : SoundcloudURLs.LIVE_AUTH_URL;
		}
		
		protected function get apiURL():String
		{
			return useSandBox ? SoundcloudURLs.SANDBOX_URL : SoundcloudURLs.LIVE_URL;
		}
		
	}
}

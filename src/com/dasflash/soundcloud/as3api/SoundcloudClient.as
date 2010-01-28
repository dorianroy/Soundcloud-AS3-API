package com.dasflash.soundcloud.as3api
{
	import com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent;
	import com.dasflash.soundcloud.as3api.events.SoundcloudEvent;
	import com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent;
	
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import org.iotashan.oauth.OAuthConsumer;
	import org.iotashan.oauth.OAuthToken;
	
	/**
	 * Dispatched when the client receives a request token after <code>getRequestToken</code> has
	 * been called.
	 * 
	 * <p>Wait for this event before continuing with the next step in the authentication process,
	 * <code>authorizeUser</code>.</p>
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent.REQUEST_TOKEN
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent", name="requestToken")]
 
 	/**
	 * Dispatched when the client receives an access token after <code>getAccessToken</code> has
	 * been called.
	 * 
	 * <p>Wait for this event before calling any non-public resources. If you're building an AIR
	 * application you can also use this event to store the access token in the local file system.</p>
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent.ACCESS_TOKEN
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudAuthEvent", name="accessToken")]
	
	/**
	 * Dispatched when the request of <code>getRequestToken</code> has failed.
	 * 
	 * <p>This event most likely occurs when there are network problems. You can check this events
	 * <code>message</code> and <code>errorCode</code> properties for details.</p>
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent.REQUEST_TOKEN_FAULT
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent", name="requestTokenFault")]
 
 	/**
	 * Dispatched when the request of <code>getAccessToken</code> has failed.
	 * 
	 * <p>The most likely reason is that the verification code was wrong. Other reasons could be network
	 * problems, a bad request token or an invalid user. You can check this events <code>message</code> and
	 * <code>errorCode</code> properties for details.</p>
	 *
	 * @eventType com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent.ACCESS_TOKEN_FAULT
	 */
	[Event(type="com.dasflash.soundcloud.as3api.events.SoundcloudFaultEvent", name="accessTokenFault")]
	 
	/**
	 * Central class of the Soundcloud API wrapper for AS3.
	 * 
	 * <p>Create an instance of this class and call its authentication methods to	
	 * connect your app with the Soundcloud REST API. Once you're authenticated you
	 * can call every resource through the <code>sendRequest</code> method.</p>
	 * 
	 * <p>You can also call public resources without going through the authentication
	 * process.</p>
	 * 
	 * @example The following code retrieves a list of public tracks:
	 * <listing version="3.0">
	 * var scClient:SoundcloudClient = new SoundcloudClient();
	 * 
	 * var delegate:SoundcloudDelegate = scClient.sendRequest("tracks");
	 * 
	 * delegate.addEventListener(SoundcloudEvent.REQUEST_COMPLETE, requestCompleteHandler);
	 * 
	 * protected function requestCompleteHandler(event:SoundcloudEvent):void
	 * {
	 * 	 trace(event.data);
	 * }
	 * </listing>
	 * 
	 * @see http://github.com/dasflash/Soundcloud-AS3-API
	 * @see http://api.soundcloud.com/api
	 * 
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	public class SoundcloudClient extends EventDispatcher
	{
		// SC resource locations
		protected const requestTokenResource:String		= "oauth/request_token";
		protected const accessTokenResource:String		= "oauth/access_token";
		
		protected var consumerKey:String;
		protected var consumerSecret:String;
		protected var consumer:OAuthConsumer;
		protected var requestToken:OAuthToken;
		protected var accessToken:OAuthToken;
		protected var callbackURL:String;
		
		private var _verificationRequired:Boolean;
		private var _useOAuth1_0:Boolean;
		private var _useSandBox:Boolean;
		private var _responseFormat:String;
		
		
		/**
		 * Creates a Soundcloud API client. <p>If no <code>consumerKey</code> and <code>consumerSecret</code> are passed
		 * to this function you can only access public resources (e.g. "tracks") and cannot retrieve a request token.
		 * Else if you have <code>consumerKey</code> and <code>consumerSecret</code> but no <code>accessToken</code>,
		 * you can only call public resources and <code>getRequestToken</code>.</p>
		 * 
		 * @param consumerKey		The consumer key you receive when registering your app with Soundcloud (optional).
		 * 
		 * @param consumerSecret	The consumer secret you receive when registering your app with Soundcloud (optional).
		 * 
		 * @param accessToken		A previously retrieved access token for the current user (optional).
		 * 	
		 * @param useSandbox		Switch between the Soundcloud live system (false) and the developer.
		 * 							sandbox system (true, default)
		 * 
		 * @param responseFormat	"json" or "xml" (default).
		 */
		public function SoundcloudClient(	consumerKey:String="",
											consumerSecret:String="",
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
		 * Retrieves a request token.
		 * 
		 * <p>This token must be traded for an access token by calling
		 * getAccessToken() after user authentication</p>
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
			
			// clear tokens
			// needed in case you want to re-authenticate to get a new token
			accessToken = null;
			requestToken = null;
			
			// create parameter object
			var requestParams:Object = {};
			
			// add OAuth version
			requestParams.oauth_version = "1.0";
			
			// add oauth_callback parameter for OAuth 1.0a authentication
			// if no callback is passed, this parameter is set to "oob" (out-of-band)
			// @see http://oauth.googlecode.com/svn/spec/core/1.0a/drafts/3/oauth-core-1_0a.html#auth_step1
			// if useOAuth1_0 is true the callback is passed later in @see authorizeUser()
			if (!useOAuth1_0) requestParams.oauth_callback = callbackURL || "oob";
			
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
			delegate.addEventListener(SoundcloudFaultEvent.FAULT, requestTokenFaultHandler);
			
			return delegate;
		}
		
		/**
		 * @private
		 */
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
		 * @private
		 */
		protected function requestTokenFaultHandler(event:SoundcloudFaultEvent):void
		{
			dispatchEvent(new SoundcloudFaultEvent(SoundcloudFaultEvent.REQUEST_TOKEN_FAULT, event.message, event.errorCode));
		}
		
		/**
		 * Opens authorization page to grant data access for your app.
		 * 
		 * @param targetWindow (optional)
		 * 		Target window name, defaults to "_blank". Use "_self" to open the
		 * 		authentication page in the current window
		 */
		public function authorizeUser(targetWindow:String="_blank"):void
		{
			// create url request
			var userAuthReq:URLRequest = new URLRequest(authURL);
			
			// add request parameters
			var params:URLVariables = new URLVariables();
			params["oauth_token"] = requestToken.key;
			
			// add callback URL if it has been set before and useOAuth1_0 is true
			if (useOAuth1_0 && callbackURL) params["oauth_callback"] = callbackURL;
			
			// assign parameters
			userAuthReq.data = params;
			
			// open url in browser
			navigateToURL(userAuthReq, targetWindow);
		}
		
		/**
		 * Retrieves the access token.
		 * 
		 * <p>This token will be used for all subsequent API calls. You should store it 
		 * and reuse it the next time the current user opens your app.</p>
		 * 
		 * @param verificationCode The code that is displayed on the confirmation page
		 * 			after user authorization. This parameter is optional because it 
		 * 			won't be generated when you use legacy OAuth 1.0 authentication
		 * 
		 * @param externalRequestToken A previously saved request token. You need to use this
		 * 			parameter when you want to call getAccessToken from the callbackURL page
		 * 
		 * @return 	A SoundcloudDelegate instance you can attach a listener to for
		 * 			the SoundcloudEvent and SoundcloudFault events
		 */		
		public function getAccessToken(verificationCode:String=null, externalRequestToken:OAuthToken=null):SoundcloudDelegate
		{
			// create parameter object
			var requestParams:Object = {};
			
			// throw error if verification is required but not provided
			if (verificationRequired && !verificationCode) {
				throw new IllegalOperationError("verification code is required but no code has been provided");
			}
			
			// add verification code if available 
			if (verificationCode) requestParams.oauth_verifier = verificationCode;
			
			// external request token overrides the class variable
			var token:OAuthToken = externalRequestToken || requestToken;
			
			// create request
			var delegate:SoundcloudDelegate = createDelegate(	accessTokenResource,
																URLRequestMethod.GET,
																requestParams,
																"",
																URLLoaderDataFormat.VARIABLES,
																token);
			
			// send request
			delegate.execute();
			
			// listen for response
			delegate.addEventListener(SoundcloudEvent.REQUEST_COMPLETE, getAccessTokenCompleteHandler);
			delegate.addEventListener(SoundcloudFaultEvent.FAULT, accessTokenFaultHandler);
			
			return delegate;
		}
		
		/**
		 * @private
		 */
		protected function getAccessTokenCompleteHandler(event:SoundcloudEvent):void
		{
			accessToken = createTokenFromURLVariables( URLVariables(event.data) );
			
			dispatchEvent( new SoundcloudAuthEvent(SoundcloudAuthEvent.ACCESS_TOKEN, accessToken) ); 
		}
		
		/**
		 * @private
		 */
		protected function accessTokenFaultHandler(event:SoundcloudFaultEvent):void
		{
			dispatchEvent(new SoundcloudFaultEvent(SoundcloudFaultEvent.ACCESS_TOKEN_FAULT, event.message, event.errorCode));
		}
		
		/**
		 * Make a request to the API.
		 * 
		 * @param resource	The resource locator, e.g. "user/myUserId/tracks"
		 * 
		 * @param method	GET, POST, PUT or DELETE. Note that FlashPlayer	only supports GET
		 * 					and POST as of this writing. AIR supports all four methods.
		 * 
		 * @param params	(optional) A generic object containing the request parameters
		 * 
		 * @return 			A SoundcloudDelegate instance you can attach a listener to for
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
		 * Sends the actual API call.
		 * 
		 * @param resource			The resource locator, e.g. "user/myUserId/tracks"
		 * 
		 * @param method			GET, POST, PUT or DELETE. Note that FlashPlayer
		 * 							only supports GET and POST as of this writing.
		 * 							AIR supports all four methods.
		 * 
		 * @param data				(optional) The data to be sent. This can be a generic object
		 * 							containing request parameters as key/value pairs or a XML object
		 * 
		 * @param responseFormat	(optional) Tells Soundcloud whether to render response as JSON or XML.
		 * 							Value must be SoundcloudResponseFormat.JSON, .XML or an empty String 
		 * 							(default) which will also return XML 
		 * 
		 * @param dataFormat		(optional) "binary", "text" (default) or "variables"
		 * 
		 * @param requestToken		(optional) Overwrites the access token. Used to pass the 
		 * 							request token when requesting an access token.
		 * 
		 * @return 					A SoundcloudDelegate instance you can attach a listener to
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
		
		/**
		 * Determines whether the SoundCloud sandbox system is used (recommended for testing) 
		 * or the live service.
		 * 
		 * @return 
		 */
		public function get useSandBox():Boolean
		{
			return _useSandBox;
		}

		public function set useSandBox(value:Boolean):void
		{
			_useSandBox = value;
		}
		
		/**
		 * Sets the format of the server response (XML or JSON). The value must be
		 * SoundcloudResponseFormat.JSON, .XML or an empty String (default) which
		 * will also return XML.
		 * 
		 * @return 
		 */
		public function get responseFormat():String
		{
			return _responseFormat;
		}

		public function set responseFormat(value:String):void
		{
			_responseFormat = value;
		}

		/**
		 * Set to <code>true</code> for legacy OAuth 1.0 authentication (not recommended).
		 * @return 
		 */
		public function get useOAuth1_0():Boolean
		{
			return _useOAuth1_0;
		}

		public function set useOAuth1_0(value:Boolean):void
		{
			_useOAuth1_0 = value;
		}

		/**
		 * @private
		 * @return true if authentication is based on OAuth 1.0a and requires
		 * 		the verification code from the authentication page
		 */
		protected function get verificationRequired():Boolean
		{
			return _verificationRequired;
		}
		
		
		// HELPER METHODS

		/**
		 * @private 
		 */
		protected function createTokenFromURLVariables(data:URLVariables):OAuthToken
		{
			return new OAuthToken(data["oauth_token"], data["oauth_token_secret"]);
		}
		
		/**
		 * @private 
		 */
		protected function get authURL():String
		{
			return useSandBox ? SoundcloudURLs.SANDBOX_AUTH_URL : SoundcloudURLs.LIVE_AUTH_URL;
		}
		
		/**
		 * @private 
		 */
		protected function get apiURL():String
		{
			return useSandBox ? SoundcloudURLs.SANDBOX_URL : SoundcloudURLs.LIVE_URL;
		}
		
	}
}

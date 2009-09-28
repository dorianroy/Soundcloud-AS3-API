package com.dasflash.soundcloud.as3api.events
{
	import flash.events.Event;
	
	import org.iotashan.oauth.OAuthToken;
	
	/**
	 * Event fired on successful authentication requests
	 * 
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	public class SoundcloudAuthEvent extends Event
	{
		
		public static const REQUEST_TOKEN:String = "requestToken";
		
		public static const ACCESS_TOKEN:String = "accessToken";
		
		
		public var token:OAuthToken;
		
		
		public function SoundcloudAuthEvent(type:String, token:OAuthToken, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.token = token;
		}
		
		override public function clone():Event
		{
			return new SoundcloudAuthEvent(type, token, bubbles, cancelable);
		}
	}
}

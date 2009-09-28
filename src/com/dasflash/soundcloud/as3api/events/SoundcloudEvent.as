package com.dasflash.soundcloud.as3api.events
{
	import flash.events.Event;
	
	/**
	 * Basic event fired on successful requests to the Soundcloud API.
	 * 
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	public class SoundcloudEvent extends Event
	{
		
		public static const REQUEST_COMPLETE:String = "requestComplete";
		
		
		/**
		 * Contains the parsed response of an API call if it returns
		 * XML or JSON format.
		 */
		public var data:Object;
		
		/**
		 * Contains the raw response of an API call.
		 */
		public var rawData:Object;
		
		
		public function SoundcloudEvent(type:String, data:Object, rawData:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
			
			this.rawData = rawData;
		}
		
		override public function clone():Event
		{
			return new SoundcloudEvent(type, data, rawData, bubbles, cancelable);
		}
	}
}

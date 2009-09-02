package com.dasflash.soundcloud.as3api.events
{
	import flash.events.Event;
	
	/**
	 * Event fired on erroneous API requests
	 * 
	 * @see http://github.com/dasflash/Soundcloud-AS3-API
	 * 
	 * @author Dorian Roy
	 * http://dasflash.com
	 */
	public class SoundcloudFaultEvent extends Event
	{
		
		public static const FAULT:String = "fault";
		
		/**
		 * contains a text message describing the error 
		 */
		public var message:String;
		
		/**
		 * contains the HTTP code in case of an HTTP response 
		 */
		public var errorCode:int;
		
		
		public function SoundcloudFaultEvent(type:String, message:String, errorCode:int=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.message = message;
			
			this.errorCode = errorCode;
		}
		
		override public function clone():Event
		{
			return new SoundcloudFaultEvent(type, message, errorCode, bubbles, cancelable);
		}
	}
}
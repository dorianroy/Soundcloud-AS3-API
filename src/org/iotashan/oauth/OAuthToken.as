package org.iotashan.oauth
{
	/**
	 * The OAuthToken class is for holding on to a Token key and private strings.
	*/
	public class OAuthToken
	{
		private var _key:String;
		private var _secret:String;
		
		/**
		 * Constructor class.
		 * 
		 * @param key Token key. Default is an empty string.
		 * @param secret Token secret. Default is an empty string.
		*/
		public function OAuthToken(key:String="",secret:String="")
		{
			_key = key;
			_secret = secret;
		}
		
		/**
		 * Token key
		*/
		public function get key():String {
			return _key;
		}
		
		/**
		 * @private
		*/
		public function set key(val:String):void {
			if (val != _key)
				_key = val;
		}
		
		/**
		 * Token secret
		*/
		public function get secret():String {
			return _secret;
		}
		
		/**
		 * @private
		*/
		public function set secret(val:String):void {
			if (val != _secret)
				_secret = val;
		}
		
		/**
		 * Returns if the Token is empty or not
		*/
		public function get isEmpty():Boolean {
			if (key.length == 0 && secret.length == 0) {
				return true;
			} else {
				return false;
			}
		}
	}
}
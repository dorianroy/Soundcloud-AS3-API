package org.iotashan.oauth
{
	public interface IOAuthSignatureMethod
	{
		public function IOAuthSignatureMethod()
		
		function get name():String
		
		function signRequest(request:OAuthRequest):String
	}
}
package org.iotashan.oauth
{
    import org.iotashan.utils.URLEncoding;
	
    import com.hurlant.crypto.Crypto;
    import com.hurlant.crypto.hash.HMAC;
    import com.hurlant.util.Base64;
    import com.hurlant.util.Hex;
    
    import flash.utils.ByteArray;
    
	public class OAuthSignatureMethod_HMAC_SHA1 implements IOAuthSignatureMethod
	{
		public function OAuthSignatureMethod_HMAC_SHA1()
		{
		}
		
		public function get name():String {
			return "HMAC-SHA1";
		}
		
        public function signRequest(request:OAuthRequest):String {
                // get the signable string
                var toBeSigned:String = request.getSignableString();
                
                // get the secrets to encrypt with
                var sSec:String = URLEncoding.encode(request.consumer.secret) + "&"
                if (request.token)
                        sSec += URLEncoding.encode(request.token.secret);
                
                // hash them
                var hmac:HMAC = Crypto.getHMAC("sha1");
                var key:ByteArray = Hex.toArray(Hex.fromString(sSec));
                var message:ByteArray = Hex.toArray(Hex.fromString(toBeSigned));

                var result:ByteArray = hmac.compute(key,message);
                var ret:String = Base64.encodeByteArray(result);
                
                return ret;
        }
	}
}
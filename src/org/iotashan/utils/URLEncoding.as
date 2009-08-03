package org.iotashan.utils
{
	/**
	 * Encodes and decodes strings into URL format.
	 * 
	 * Code ported from the javascript code at:
	 * http://cass-hacks.com/articles/code/js_url_encode_decode/
	*/
	public class URLEncoding
	{
		public function URLEncoding()
		{
		}
		
		/**
		 * Encodes a string into a URL compliant format
		*/
		public static function encode(input:String,usePlusForSpace:Boolean=false):String {
			var output:String = "";
			var i:Number = 0;
			var exclude:RegExp = /(^[a-zA-Z0-9_\.~-]*)/;
			
			var match:Object;
			var charCode:Number;
			var hexVal:String;
			
			// loop over the string, skipping blocks of excluded characters
			while (i < input.length) {
				match = exclude.exec(input.substr(i));
				
				if (match != null && match.length > 1 && match[1] != '') {
					output += match[1];
					i += match[1].length;
				} else {
					if (input.substr(i,1) == " ") {
						if (usePlusForSpace) {
							output += "+";
						} else {
							output += "%20";
						}
					} else {
						charCode = input.charCodeAt(i);
						hexVal = charCode.toString(16);
						output += "%" + ( hexVal.length < 2 ? "0" : "" ) + hexVal.toUpperCase();
					}
					i++;
				}
			}
			
			return output;
		}
		
		/**
		 * Decodes a string from a URL compliant format.
		 * 
		 * @param encodedString String to be decoded
		*/
		public static function decode(encodedString:String):* {
			var output:String = encodedString;
			var myregexp:RegExp = /(%[^%]{2})/;
			
			var binVal:Number;
			var thisString:String;
			
			var match:Object;
			
			// change "+" to spaces
			var plusPattern:RegExp = /\+/gm;
			output = output.replace(plusPattern," ");
			
			// convert all other characters
			while ((match = myregexp.exec(output)) != null && match.length > 1 && match[1] != '') {
				binVal = parseInt(match[1].substr(1),16);
				thisString = String.fromCharCode(binVal);
				output = output.replace(match[1], thisString);
			}
			
			return output;
		}
	}
}